#!/bin/bash
# User data script for EC2 instance

# Update system
sudo yum update -y

# Install Docker
sudo amazon-linux-extras install docker -y
sudo service docker start
sudo usermod -a -G docker ec2-user

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Create application directory
mkdir -p /home/ec2-user/special-days-calendar
chown -R ec2-user:ec2-user /home/ec2-user/special-days-calendar

# Create Docker Compose file
cat > /home/ec2-user/special-days-calendar/docker-compose.yml << 'EOF'
version: '3.8'

services:
  backend:
    build: ./backend
    ports:
      - "5000:5000"
    restart: unless-stopped
    environment:
      - FLASK_ENV=production

  frontend:
    build: ./frontend
    ports:
      - "80:80"
    depends_on:
      - backend
    restart: unless-stopped
EOF

# Create directories
mkdir -p /home/ec2-user/special-days-calendar/backend
mkdir -p /home/ec2-user/special-days-calendar/frontend

# Create systemd service for auto-start
cat > /etc/systemd/system/special-days.service << EOF
[Unit]
Description=Special Days Calendar Application
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/home/ec2-user/special-days-calendar
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
User=ec2-user
Group=ec2-user

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable special-days.service

# Create deployment script
cat > /home/ec2-user/deploy.sh << 'EOF'
#!/bin/bash
cd /home/ec2-user/special-days-calendar

# Pull latest code
if [ -d ".git" ]; then
    git pull origin main
fi

# Rebuild and restart containers
docker-compose down
docker-compose build --no-cache
docker-compose up -d

# Clean up old images
docker system prune -f
EOF

chmod +x /home/ec2-user/deploy.sh
chown ec2-user:ec2-user /home/ec2-user/deploy.sh

# Mark Docker installation as complete
touch /tmp/docker-installed