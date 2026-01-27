pipeline {
    agent any
    
    environment {
        EC2_IP = '44.201.53.10'
    }
    
    stages {
        stage('Debug SSH Setup') {
            steps {
                script {
                    echo "=== STARTING DEBUG ==="
                    
                    withCredentials([sshUserPrivateKey(
                        credentialsId: 'aws-ec2-key',
                        keyFileVariable: 'SSH_KEY',
                        usernameVariable: 'SSH_USER'
                    )]) {
                        sh """
                            echo "1. Current directory: \$(pwd)"
                            echo "2. Jenkins user: \$(whoami)"
                            echo "3. SSH_KEY variable: ${SSH_KEY}"
                            echo "4. SSH_USER variable: ${SSH_USER}"
                            echo ""
                            
                            echo "=== CHECKING KEY FILE ==="
                            ls -la ${SSH_KEY} 2>/dev/null || echo "Key file not found!"
                            echo ""
                            
                            echo "=== KEY CONTENT VERIFICATION ==="
                            echo "First line: \$(head -1 ${SSH_KEY})"
                            echo "Last line: \$(tail -1 ${SSH_KEY})"
                            echo ""
                            
                            echo "=== SETTING PROPER PERMISSIONS ==="
                            chmod 600 ${SSH_KEY}
                            ls -la ${SSH_KEY}
                            echo ""
                            
                            echo "=== TESTING SSH CONNECTION ==="
                            set -x  # Enable debugging
                            ssh -v -o StrictHostKeyChecking=no -o ConnectTimeout=10 -i ${SSH_KEY} ubuntu@${EC2_IP} "echo 'SSH SUCCESS!'"
                            set +x
                            echo ""
                        """
                    }
                }
            }
        }
    }
}