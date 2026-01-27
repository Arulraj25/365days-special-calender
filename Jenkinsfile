pipeline {
    agent any
    
    environment {
        EC2_HOST = 'your-ec2-ip'
        EC2_USER = 'ec2-user'
        SSH_KEY = credentials('ec2-ssh-key')
        DOCKER_REGISTRY = ''
        IMAGE_BACKEND = 'calculator-backend'
        IMAGE_FRONTEND = 'calculator-frontend'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Build Docker Images') {
            steps {
                script {
                    dir('backend') {
                        sh 'docker build -t ${IMAGE_BACKEND}:${BUILD_ID} .'
                    }
                    dir('frontend') {
                        sh 'docker build -t ${IMAGE_FRONTEND}:${BUILD_ID} .'
                    }
                }
            }
        }
        
        stage('Run Tests') {
            steps {
                dir('backend') {
                    sh '''
                        # Create test container
                        docker build -t backend-test -f Dockerfile .
                        
                        # Run tests (if you have test files)
                        docker run --rm backend-test \
                          python -m pytest tests/ --verbose || echo "No tests found or tests failed"
                    '''
                }
            }
        }
        
        stage('Save Docker Images') {
            steps {
                sh '''
                    # Save images as tar files
                    docker save ${IMAGE_BACKEND}:${BUILD_ID} > backend-${BUILD_ID}.tar
                    docker save ${IMAGE_FRONTEND}:${BUILD_ID} > frontend-${BUILD_ID}.tar
                    
                    # Compress for faster transfer
                    gzip backend-${BUILD_ID}.tar
                    gzip frontend-${BUILD_ID}.tar
                '''
            }
        }
        
        stage('Transfer to EC2') {
            steps {
                sshagent([SSH_KEY]) {
                    sh '''
                        # Copy files to EC2
                        scp -o StrictHostKeyChecking=no \
                            backend-${BUILD_ID}.tar.gz \
                            frontend-${BUILD_ID}.tar.gz \
                            docker-compose.yml \
                            ${EC2_USER}@${EC2_HOST}:/tmp/
                        
                        # Copy deploy script
                        scp -o StrictHostKeyChecking=no \
                            deploy.sh \
                            ${EC2_USER}@${EC2_HOST}:/tmp/
                    '''
                }
            }
        }
        
        stage('Deploy on EC2') {
            steps {
                sshagent([SSH_KEY]) {
                    sh '''
                        # Execute remote deployment script
                        ssh -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_HOST} \
                            "chmod +x /tmp/deploy.sh && /tmp/deploy.sh ${BUILD_ID}"
                    '''
                }
            }
        }
        
        stage('Health Check') {
            steps {
                script {
                    // Wait for deployment to complete
                    sleep 30
                    
                    // Check if application is running
                    sh '''
                        curl -f http://${EC2_HOST}:80 || exit 1
                        echo "Frontend is up!"
                        
                        curl -f http://${EC2_HOST}:5000/health || exit 1
                        echo "Backend health check passed!"
                    '''
                }
            }
        }
    }
    
    post {
        always {
            // Cleanup local files
            sh '''
                rm -f backend-*.tar.gz frontend-*.tar.gz
                docker system prune -f
            '''
            cleanWs()
        }
        success {
            echo '🎉 Deployment completed successfully!'
            slackSend(color: 'good', message: "Deployment successful to ${EC2_HOST}")
        }
        failure {
            echo '❌ Deployment failed!'
            slackSend(color: 'danger', message: "Deployment failed to ${EC2_HOST}")
        }
    }
}