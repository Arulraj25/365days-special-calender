terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Create VPC
module "vpc" {
  source = "./modules/vpc"
  vpc_cidr = var.vpc_cidr
}

# Create Security Groups
module "security_groups" {
  source = "./modules/security-groups"
  vpc_id = module.vpc.vpc_id
}

# Create EC2 Instance for Jenkins + Application
resource "aws_instance" "jenkins_ec2" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.deployer.key_name
  vpc_security_group_ids      = [module.security_groups.jenkins_sg_id]
  subnet_id                   = module.vpc.public_subnets[0]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.jenkins_instance_profile.name
  
  user_data = templatefile("${path.module}/scripts/user-data.sh", {
    jenkins_admin_password = var.jenkins_admin_password
    github_token           = var.github_token
    dockerhub_username     = var.dockerhub_username
    dockerhub_password     = var.dockerhub_password
  })
  
  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }
  
  tags = {
    Name = "Jenkins-CI-CD-Server"
  }
  
  depends_on = [aws_key_pair.deployer]
}

# Create Application Load Balancer
resource "aws_lb" "application_lb" {
  name               = "special-days-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [module.security_groups.alb_sg_id]
  subnets            = module.vpc.public_subnets

  enable_deletion_protection = false

  tags = {
    Environment = "production"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.application_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

resource "aws_lb_target_group" "app_tg" {
  name     = "special-days-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

  health_check {
    enabled             = true
    interval            = 30
    path                = "/"
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
  }
}

resource "aws_lb_target_group_attachment" "app_tg_attachment" {
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = aws_instance.jenkins_ec2.id
  port             = 80
}

# Key Pair
resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key-${random_id.suffix.hex}"
  public_key = file(var.public_key_path)
}

resource "random_id" "suffix" {
  byte_length = 4
}

# IAM Role for Jenkins
resource "aws_iam_role" "jenkins_role" {
  name = "jenkins-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_full_access" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_iam_role_policy_attachment" "s3_full_access" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "ecr_full_access" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

resource "aws_iam_instance_profile" "jenkins_instance_profile" {
  name = "jenkins-instance-profile"
  role = aws_iam_role.jenkins_role.name
}

# Outputs
output "jenkins_server_ip" {
  value       = aws_instance.jenkins_ec2.public_ip
  description = "Jenkins Server Public IP"
}

output "alb_dns_name" {
  value       = aws_lb.application_lb.dns_name
  description = "Application Load Balancer DNS Name"
}

output "jenkins_url" {
  value       = "http://${aws_instance.jenkins_ec2.public_ip}:8080"
  description = "Jenkins URL"
}

output "application_url" {
  value       = "http://${aws_lb.application_lb.dns_name}"
  description = "Application URL"
}