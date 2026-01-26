variable "aws_region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t2.micro"
}

variable "key_name" {
  description = "SSH key pair name"
  default     = "special-days-key"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "Public subnet CIDR block"
  default     = "10.0.1.0/24"
}

variable "ami_id" {
  description = "Amazon Linux 2 AMI ID"
  default     = "ami-0c55b159cbfafe1f0" # Amazon Linux 2 in us-east-1
}

variable "jenkins_ip" {
  description = "Jenkins server IP for security group"
  default     = "0.0.0.0/0" # Change to your Jenkins IP
}