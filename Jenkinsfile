pipeline {
    agent any
    
    environment {
        EC2_IP = '44.201.53.10'
        EC2_USER = 'ec2-user'
    }
    
    stages {
        stage('Test SSH Connection') {
            steps {
                sshagent(['aws-ec2-key']) {
                    sh """
                        echo "Testing SSH connection to EC2..."
                        ssh -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_IP} "
                            echo '✅ Connected to EC2!'
                            echo 'Hostname: \$(hostname)'
                            echo 'OS: \$(cat /etc/os-release | grep PRETTY_NAME)'
                        "
                    """
                }
            }
        }
        
        stage('Setup EC2') {
            steps {
                sshagent(['aws-ec2-key']) {
                    sh """
                        echo "Setting up Docker on EC2..."
                        
                        # Copy files to EC2
                        scp -o StrictHostKeyChecking=no docker-compose.yml ${EC2_USER}@${EC2_IP}:/tmp/
                        
                        # Install Docker and Docker Compose on EC2
                        ssh -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_IP} "
                            echo '=== Installing Docker ==='
                            sudo yum update -y
                            sudo yum install -y docker
                            sudo systemctl start docker
                            sudo systemctl enable docker
                            sudo usermod -aG docker ec2-user
                            
                            echo '=== Installing Docker Compose ==='
                            sudo curl -L \"https://github.com/docker/compose/releases/latest/download/docker-compose-\$(uname -s)-\$(uname -m)\" -o /usr/local/bin/docker-compose
                            sudo chmod +x /usr/local/bin/docker-compose
                            
                            echo '=== Checking versions ==='
                            docker --version
                            docker-compose --version
                        "
                    """
                }
            }
        }
        
        stage('Deploy Application') {
            steps {
                sshagent(['aws-ec2-key']) {
                    sh """
                        echo "Deploying application..."
                        
                        # Copy all files to EC2
                        scp -o StrictHostKeyChecking=no -r backend frontend docker-compose.yml ${EC2_USER}@${EC2_IP}:/tmp/special-days/
                        
                        # Build and run on EC2
                        ssh -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_IP} "
                            cd /tmp/special-days
                            
                            echo 'Stopping old containers...'
                            sudo docker-compose down || true
                            
                            echo 'Building and starting containers...'
                            sudo docker-compose up --build -d
                            
                            echo 'Checking containers...'
                            sudo docker ps
                            
                            echo 'Waiting for services to start...'
                            sleep 10
                            
                            echo 'Testing backend...'
                            curl -f http://localhost:5000/api/health || echo 'Backend not ready yet'
                        "
                    """
                }
            }
        }
        
        stage('Verify Deployment') {
            steps {
                sh """
                    echo "Waiting for deployment to complete..."
                    sleep 15
                    
                    echo "=== VERIFICATION ==="
                    echo "Testing application..."
                    
                    # Test backend API
                    BACKEND_STATUS=\$(curl -s -o /dev/null -w '%{http_code}' http://${EC2_IP}/api/health || echo '000')
                    if [ "\$BACKEND_STATUS" = "200" ]; then
                        echo "✅ Backend is healthy (HTTP \$BACKEND_STATUS)"
                    else
                        echo "❌ Backend check failed (HTTP \$BACKEND_STATUS)"
                        exit 1
                    fi
                    
                    # Test frontend
                    FRONTEND_STATUS=\$(curl -s -o /dev/null -w '%{http_code}' http://${EC2_IP}/ || echo '000')
                    if [ "\$FRONTEND_STATUS" = "200" ]; then
                        echo "✅ Frontend is accessible (HTTP \$FRONTEND_STATUS)"
                    else
                        echo "⚠️ Frontend returned HTTP \$FRONTEND_STATUS"
                    fi
                    
                    echo ""
                    echo "🎉 DEPLOYMENT SUCCESSFUL!"
                    echo "Your application is now live at:"
                    echo "🌐 http://${EC2_IP}"
                    echo "🔧 API Health: http://${EC2_IP}/api/health"
                    echo "📅 Today's Special: http://${EC2_IP}/api/today"
                """
            }
        }
    }
    
    post {
        success {
            echo '🎉 Pipeline succeeded! Application is deployed.'
        }
        failure {
            echo '❌ Pipeline failed. Check the logs above.'
        }
    }
}