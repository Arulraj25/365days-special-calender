output "ssh_connection_command" {
  value = "ssh -i ~/.ssh/id_rsa ubuntu@${aws_instance.jenkins_ec2.public_ip}"
}

output "initial_admin_password_command" {
  value = "ssh -i ~/.ssh/id_rsa ubuntu@${aws_instance.jenkins_ec2.public_ip} 'sudo cat /var/lib/jenkins/secrets/initialAdminPassword'"
}