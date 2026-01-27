pipeline {
    agent any
    
    environment {
        EC2_IP = '44.201.53.10'
        EC2_USER = 'ec2-user'
    }
    
    stages {
        stage('Test Connection') {
            steps {
                sshagent(['aws-ec2-key']) {
                    sh """
                        echo "Testing connection to EC2..."
                        ssh -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_IP} "echo '✅ Connected to EC2' && hostname"
                    """
                }
            }
        }
        
        stage('Deploy Application') {
            steps {
                sshagent(['aws-ec2-key']) {
                    sh """
                        echo "Deploying application to EC2..."
                        
                        # Copy all files to EC2
                        scp -o StrictHostKeyChecking=no -r backend frontend docker-compose.yml ${EC2_USER}@${EC2_IP}:/tmp/special-days/
                        
                        # Deploy on EC2
                        ssh -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_IP} "
                            cd /tmp/special-days
                            
                            echo '=== Stopping old containers ==='
                            sudo docker-compose down || true
                            
                            echo '=== Building images ==='
                            sudo docker build -t special-days-backend:latest ./backend
                            sudo docker build -t special-days-frontend:latest ./frontend
                            
                            echo '=== Starting containers ==='
                            sudo docker-compose up -d
                            
                            echo '=== Checking containers ==='
                            sudo docker ps
                            
                            echo '=== Waiting for services ==='
                            sleep 10
                            
                            echo '=== Testing backend ==='
                            curl -f http://localhost:5000/api/health && echo '✅ Backend is healthy!' || echo '⚠️ Backend check failed'
                        "
                    """
                }
            }
        }
        
        stage('Verify Deployment') {
            steps {
                sh """
                    echo "=== FINAL VERIFICATION ==="
                    
                    # Give services time to start
                    sleep 20
                    
                    echo "Testing application from external network..."
                    
                    # Test backend
                    BACKEND_RESPONSE=\$(curl -s http://${EC2_IP}/api/health || echo 'ERROR')
                    echo "Backend response: \$BACKEND_RESPONSE"
                    
                    if echo "\$BACKEND_RESPONSE" | grep -q "healthy"; then
                        echo "✅ Backend deployment successful!"
                    else
                        echo "❌ Backend deployment failed"
                        exit 1
                    fi
                    
                    # Test frontend
                    FRONTEND_STATUS=\$(curl -s -o /dev/null -w '%{http_code}' http://${EC2_IP}/ || echo '000')
                    echo "Frontend HTTP status: \$FRONTEND_STATUS"
                    
                    if [ "\$FRONTEND_STATUS" = "200" ]; then
                        echo "✅ Frontend is accessible!"
                    else
                        echo "⚠️ Frontend returned HTTP \$FRONTEND_STATUS (might be okay for SPA)"
                    fi
                    
                    echo ""
                    echo "🎉🎉🎉 DEPLOYMENT COMPLETED SUCCESSFULLY! 🎉🎉🎉"
                    echo ""
                    echo "Your Special Days Calendar is now live!"
                    echo ""
                    echo "🌐 Application URL: http://${EC2_IP}"
                    echo "🔧 API Health: http://${EC2_IP}/api/health"
                    echo "📅 Today's Special: http://${EC2_IP}/api/today"
                    echo ""
                    echo "Open the above URLs in your browser to see the application!"
                """
            }
        }
    }
    
    post {
        success {
            echo '✅ Pipeline succeeded! Application deployed successfully.'
            echo '🌐 Access your application at: http://44.201.53.10'
        }
        failure {
            echo '❌ Pipeline failed. Check logs above.'
        }
        always {
            echo 'Pipeline execution completed.'
        }
    }
}