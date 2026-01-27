terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "app_server" {
  ami           = "ami-0532be01f26a3de55"
  instance_type = "t3.micro"
  
  subnet_id              = "subnet-051cd7a2d21af2227"
  vpc_security_group_ids = ["sg-01f3333811fd152ca"]
  key_name               = "special-days-key"
  
  associate_public_ip_address = true
  monitoring                  = false
  disable_api_termination     = false
  
  cpu_options {
    core_count       = 1
    threads_per_core = 2
  }
  
  credit_specification {
    cpu_credits = "unlimited"
  }
  
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
    instance_metadata_tags      = "disabled"
  }
  
  root_block_device {
    delete_on_termination = true
    volume_size           = 8
    volume_type           = "gp3"
    iops                  = 3000
    throughput            = 125
    encrypted             = false
  }
  
  tags = {
    Name = "special-days-calendar-app"
  }
  
  lifecycle {
    prevent_destroy = true
    
    ignore_changes = [
      associate_public_ip_address,
      private_ip,
      public_ip,
      public_dns,
      private_dns,
      
      availability_zone,
      tenancy,
      host_id,
      primary_network_interface_id,
      
      arn,
      id,
      instance_state,
      
      root_block_device[0].volume_id,
      root_block_device[0].tags,
      root_block_device[0].tags_all,
    ]
  }
}

output "instance_id" {
  value       = aws_instance.app_server.id
  description = "The ID of the EC2 instance"
}

output "public_ip" {
  value       = aws_instance.app_server.public_ip
  description = "The public IP address of the EC2 instance"
}

output "public_dns" {
  value       = aws_instance.app_server.public_dns
  description = "The public DNS name of the EC2 instance"
}

output "instance_state" {
  value       = aws_instance.app_server.instance_state
  description = "The state of the EC2 instance"
}

output "ssh_command" {
  value       = "ssh -i ~/.ssh/id_rsa ec2-user@${aws_instance.app_server.public_ip}"
  description = "SSH command to connect to the instance"
}

output "application_urls" {
  value = {
    frontend = "http://${aws_instance.app_server.public_ip}"
    backend  = "http://${aws_instance.app_server.public_ip}:5000/api/today"
    api      = "http://${aws_instance.app_server.public_ip}:5000/api/health"
  }
  description = "URLs to access the application"
}
