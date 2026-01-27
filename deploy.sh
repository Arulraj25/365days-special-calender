#!/bin/bash
set -e

BUILD_ID=$1
EC2_USER=${EC2_USER:-ec2-user}
DEPLOY_DIR="/home/$EC2_USER/app"
BACKUP_DIR="/home/$EC2_USER/app_backup_$(date +%Y%m%d_%H%M%S)"

echo "Starting deployment with BUILD_ID: $BUILD_ID"

# Create backup of current deployment
if [ -d "$DEPLOY_DIR" ]; then
    echo "Creating backup of current deployment..."
    sudo cp -r $DEPLOY_DIR $BACKUP_DIR
fi

# Create deployment directory
sudo mkdir -p $DEPLOY_DIR
sudo chown -R $EC2_USER:$EC2_USER $DEPLOY_DIR

# Extract and load Docker images
echo "Loading Docker images..."
cd /tmp

# Extract images
gunzip -f backend-${BUILD_ID}.tar.gz
gunzip -f frontend-${BUILD_ID}.tar.gz

# Load images into Docker
sudo docker load -i backend-${BUILD_ID}.tar
sudo docker load -i frontend-${BUILD_ID}.tar

# Tag as latest
sudo docker tag calculator-backend:${BUILD_ID} calculator-backend:latest
sudo docker tag calculator-frontend:${BUILD_ID} calculator-frontend:latest

# Copy docker-compose.yml
cp /tmp/docker-compose.yml $DEPLOY_DIR/

# Create production docker-compose
cat > $DEPLOY_DIR/docker-compose.prod.yml << 'EOF'
version: '3.8'

services:
  backend:
    image: calculator-backend:latest
    container_name: calculator-backend
    restart: always
    ports:
      - "5000:5000"
    environment:
      - FLASK_ENV=production
    networks:
      - calculator-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  frontend:
    image: calculator-frontend:latest
    container_name: calculator-frontend
    restart: always
    ports:
      - "80:80"
    depends_on:
      - backend
    networks:
      - calculator-network

networks:
  calculator-network:
    driver: bridge
EOF

# Stop and remove old containers
echo "Stopping old containers..."
cd $DEPLOY_DIR
sudo docker-compose -f docker-compose.prod.yml down || true

# Clean up old images
echo "Cleaning up old images..."
sudo docker system prune -f

# Start new containers
echo "Starting new containers..."
sudo docker-compose -f docker-compose.prod.yml up -d

# Verify deployment
echo "Verifying deployment..."
sleep 10

# Check if containers are running
if sudo docker ps | grep -q "calculator-backend" && sudo docker ps | grep -q "calculator-frontend"; then
    echo "✅ Deployment successful!"
    echo "Containers are running:"
    sudo docker ps --filter "name=calculator"
    
    # Health check
    echo "Performing health checks..."
    curl -f http://localhost:5000/health && echo "Backend health: OK"
    curl -f http://localhost:80 && echo "Frontend health: OK"
    
    # Cleanup old backups (keep last 5)
    echo "Cleaning up old backups..."
    ls -dt /home/$EC2_USER/app_backup_* | tail -n +6 | xargs rm -rf || true
    
    # Cleanup temp files
    rm -f /tmp/backend-*.tar /tmp/frontend-*.tar
else
    echo "❌ Deployment failed!"
    
    # Rollback to backup if exists
    if [ -d "$BACKUP_DIR" ]; then
        echo "Attempting rollback..."
        sudo docker-compose -f docker-compose.prod.yml down || true
        sudo rm -rf $DEPLOY_DIR
        sudo cp -r $BACKUP_DIR $DEPLOY_DIR
        cd $DEPLOY_DIR
        sudo docker-compose -f docker-compose.prod.yml up -d
        echo "Rollback completed to backup."
    fi
    exit 1
fi