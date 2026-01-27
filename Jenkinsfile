pipeline {
    agent any
    
    environment {
        EC2_IP = '44.201.53.10'
        EC2_USER = 'ubuntu'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Test SSH Connection') {
            steps {
                script {
                    // Test if we can connect to EC2
                    withCredentials([sshUserPrivateKey(
                        credentialsId: 'aws-ec2-key',
                        keyFileVariable: 'SSH_KEY'
                    )]) {
                        sh """
                            echo "Testing SSH connection..."
                            chmod 600 ${SSH_KEY}
                            ssh -o StrictHostKeyChecking=no -i ${SSH_KEY} ${EC2_USER}@${EC2_IP} "echo 'SSH connection successful!'"
                        """
                    }
                }
            }
        }
        
        stage('Setup EC2') {
            steps {
                script {
                    withCredentials([sshUserPrivateKey(
                        credentialsId: 'aws-ec2-key',
                        keyFileVariable: 'SSH_KEY'
                    )]) {
                        sh """
                            # Copy files to EC2
                            scp -o StrictHostKeyChecking=no -i ${SSH_KEY} docker-compose.yml ${EC2_USER}@${EC2_IP}:/tmp/
                            
                            # Setup Docker on EC2 if not installed
                            ssh -o StrictHostKeyChecking=no -i ${SSH_KEY} ${EC2_USER}@${EC2_IP} '
                                echo "Checking Docker installation..."
                                if ! command -v docker &> /dev/null; then
                                    echo "Installing Docker..."
                                    sudo apt update
                                    sudo apt install -y docker.io
                                    sudo systemctl start docker
                                    sudo usermod -aG docker ubuntu
                                fi
                                
                                if ! command -v docker-compose &> /dev/null; then
                                    echo "Installing Docker Compose..."
                                    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-\$(uname -s)-\$(uname -m)" -o /usr/local/bin/docker-compose
                                    sudo chmod +x /usr/local/bin/docker-compose
                                fi
                                
                                echo "Docker version: \$(docker --version)"
                                echo "Docker Compose version: \$(docker-compose --version)"
                            '
                        """
                    }
                }
            }
        }
        
        stage('Deploy') {
            steps {
                script {
                    withCredentials([sshUserPrivateKey(
                        credentialsId: 'aws-ec2-key',
                        keyFileVariable: 'SSH_KEY'
                    )]) {
                        sh """
                            # Deploy application
                            ssh -o StrictHostKeyChecking=no -i ${SSH_KEY} ${EC2_USER}@${EC2_IP} '
                                cd /tmp
                                
                                # Stop and remove old containers
                                docker-compose down || true
                                
                                # Remove old images
                                docker rmi special-days-backend:latest special-days-frontend:latest 2>/dev/null || true
                                
                                # Build and start new containers
                                docker-compose up --build -d
                                
                                echo "Containers started:"
                                docker ps
                            '
                        """
                    }
                }
            }
        }
        
        stage('Verify') {
            steps {
                script {
                    withCredentials([sshUserPrivateKey(
                        credentialsId: 'aws-ec2-key',
                        keyFileVariable: 'SSH_KEY'
                    )]) {
                        sh """
                            echo "Waiting for services to start..."
                            sleep 15
                            
                            # Test backend
                            echo "Testing backend..."
                            BACKEND_STATUS=\$(ssh -o StrictHostKeyChecking=no -i ${SSH_KEY} ${EC2_USER}@${EC2_IP} "curl -s -o /dev/null -w '%{http_code}' http://localhost:5000/api/health || echo '000'")
                            
                            if [ "\$BACKEND_STATUS" = "200" ]; then
                                echo "✅ Backend is healthy!"
                            else
                                echo "❌ Backend health check failed: HTTP \$BACKEND_STATUS"
                                ssh -o StrictHostKeyChecking=no -i ${SSH_KEY} ${EC2_USER}@${EC2_IP} "docker logs special-days-backend --tail 20"
                                exit 1
                            fi
                            
                            # Test frontend
                            echo "Testing frontend..."
                            FRONTEND_STATUS=\$(ssh -o StrictHostKeyChecking=no -i ${SSH_KEY} ${EC2_USER}@${EC2_IP} "curl -s -o /dev/null -w '%{http_code}' http://localhost/" || echo '000')
                            
                            if [ "\$FRONTEND_STATUS" = "200" ] || [ "\$FRONTEND_STATUS" = "304" ]; then
                                echo "✅ Frontend is healthy!"
                            else
                                echo "⚠️ Frontend returned HTTP \$FRONTEND_STATUS"
                            fi
                            
                            echo ""
                            echo "🎉 Deployment successful!"
                            echo "Application URL: http://${EC2_IP}"
                            echo "API Health: http://${EC2_IP}/api/health"
                        """
                    }
                }
            }
        }
    }
    
    post {
        success {
            echo '🎉 Pipeline succeeded! Application deployed.'
        }
        failure {
            echo '❌ Pipeline failed! Check the logs above.'
        }
    }
}