pipeline {
    agent any
    
    environment {
        EC2_HOST = 'YOUR_EC2_PUBLIC_IP'  // <-- CHANGE THIS!
        EC2_USER = 'ubuntu'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Build Docker Images') {
            steps {
                dir('backend') {
                    sh 'docker build -t special-days-backend:latest .'
                }
                dir('frontend') {
                    sh 'docker build -t special-days-frontend:latest .'
                }
            }
        }
        
        stage('Deploy to EC2') {
            steps {
                sshagent(['aws-ec2-key']) {
                    script {
                        // Copy docker-compose.yml to EC2
                        sh """
                            scp -o StrictHostKeyChecking=no docker-compose.yml ${EC2_USER}@${EC2_HOST}:/tmp/
                        """
                        
                        // Deploy on EC2
                        sh """
                            ssh -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_HOST} '
                                cd /tmp
                                docker-compose down || true
                                docker-compose up -d
                            '
                        """
                    }
                }
            }
        }
        
        stage('Verify') {
            steps {
                sh """
                    sleep 10
                    curl -f http://${EC2_HOST}/api/health || exit 1
                    echo "✅ Deployment successful!"
                """
            }
        }
    }
}