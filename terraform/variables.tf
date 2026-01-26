variable "aws_region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t3.medium"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  default     = "10.0.0.0/16"
}

variable "public_key_path" {
  description = "Path to SSH public key"
  default     = "~/.ssh/id_rsa.pub"
}

variable "jenkins_admin_password" {
  description = "Jenkins admin password"
  type        = string
  sensitive   = true
}

variable "github_token" {
  description = "GitHub Personal Access Token"
  type        = string
  sensitive   = true
}

variable "dockerhub_username" {
  description = "Docker Hub username"
  type        = string
  sensitive   = false
}

variable "dockerhub_password" {
  description = "Docker Hub password/token"
  type        = string
  sensitive   = true
}