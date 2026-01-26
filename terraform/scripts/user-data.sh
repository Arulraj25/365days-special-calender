#!/bin/bash
set -ex

# Update system
apt-get update
apt-get upgrade -y

# Install Docker
apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io
usermod -aG docker ubuntu
systemctl enable docker
systemctl start docker

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install Jenkins
wget -q -O - https://pkg.jenkins.io/debian/jenkins.io-2023.key | apt-key add -
sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
apt-get update
apt-get install -y openjdk-17-jre jenkins
usermod -aG docker jenkins
systemctl enable jenkins
systemctl start jenkins

# Install Terraform
apt-get install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
apt-get update
apt-get install -y terraform

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
apt-get install -y unzip
unzip awscliv2.zip
./aws/install
rm -rf awscliv2.zip aws/

# Install Git
apt-get install -y git

# Configure Jenkins
JENKINS_HOME="/var/lib/jenkins"

# Wait for Jenkins to start
sleep 60

# Get initial admin password
INITIAL_PASSWORD=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)

# Create Jenkins credentials for GitHub
cat > /tmp/jenkins_configure.sh << 'EOF'
#!/bin/bash
set -ex

# Wait for Jenkins to be ready
until curl -s http://localhost:8080/login; do
    sleep 10
done

# Install plugins via CLI
java -jar /var/cache/jenkins/war/WEB-INF/jenkins-cli.jar -s http://localhost:8080/ -auth admin:${1} install-plugin git github docker-workflow pipeline-utility-steps docker-plugin -restart
EOF

chmod +x /tmp/jenkins_configure.sh
nohup /tmp/jenkins_configure.sh ${INITIAL_PASSWORD} &

# Create docker-compose for the application
mkdir -p /opt/app
cat > /opt/app/docker-compose.yml << 'EOF'
version: '3.8'

services:
  frontend:
    build: ./frontend
    ports:
      - "80:80"
    depends_on:
      - backend
    networks:
      - app-network

  backend:
    build: ./backend
    ports:
      - "5000:5000"
    networks:
      - app-network

networks:
  app-network:
    driver: bridge
EOF

# Create Jenkins pipeline script
mkdir -p /opt/jenkins
cat > /opt/jenkins/Jenkinsfile << 'EOF'
pipeline {
    agent any
    
    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
        GITHUB_TOKEN = credentials('github-token')
    }
    
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/${GITHUB_TOKEN}@github.com/YOUR_USERNAME/special-days-calendar.git',
                    credentialsId: 'github-token'
            }
        }
        
        stage('Build Docker Images') {
            steps {
                dir('backend') {
                    sh 'docker build -t special-days-backend:${BUILD_TAG} .'
                }
                dir('frontend') {
                    sh 'docker build -t special-days-frontend:${BUILD_TAG} .'
                }
            }
        }
        
        stage('Run Tests') {
            steps {
                sh '''
                    cd backend
                    docker-compose run backend python -m pytest tests/
                '''
            }
        }
        
        stage('Push to Docker Hub') {
            steps {
                sh '''
                    echo "${DOCKERHUB_CREDENTIALS_PSW}" | docker login -u "${DOCKERHUB_CREDENTIALS_USR}" --password-stdin
                    docker tag special-days-backend:${BUILD_TAG} ${DOCKERHUB_CREDENTIALS_USR}/special-days-backend:${BUILD_TAG}
                    docker tag special-days-frontend:${BUILD_TAG} ${DOCKERHUB_CREDENTIALS_USR}/special-days-frontend:${BUILD_TAG}
                    docker push ${DOCKERHUB_CREDENTIALS_USR}/special-days-backend:${BUILD_TAG}
                    docker push ${DOCKERHUB_CREDENTIALS_USR}/special-days-frontend:${BUILD_TAG}
                    docker logout
                '''
            }
        }
        
        stage('Deploy') {
            steps {
                sh '''
                    cd /opt/app
                    docker-compose down
                    docker-compose up -d --build
                '''
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
        success {
            echo 'Pipeline succeeded!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}
EOF

# Set permissions
chown -R ubuntu:ubuntu /opt/app
chown -R jenkins:jenkins /opt/jenkins

echo "Installation complete!"
echo "Jenkins Initial Admin Password: ${INITIAL_PASSWORD}"