terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# --- AWS Provider ---
provider "aws" {
  region = "ap-south-1"
}

# --- Security Group (with Ingress and Egress) ---
resource "aws_security_group" "k8s_sg" {
  name        = "k8s-sg"
  description = "Allow inbound traffic for SSH, HTTP, HTTPS, and Kubernetes"
  vpc_id      = data.aws_vpc.default.id

  # Ingress (inbound) rules
  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow Kubernetes API"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow NodePort range"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Egress (outbound) rule
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "k8s-security-group"
  }
}

# --- Get default VPC and subnet ---
data "aws_vpc" "default" {
  default = true
}

data "aws_subnet" "default_subnet" {
  availability_zone = "ap-south-1b"
  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

# --- EC2 Instance ---
resource "aws_instance" "k8s_instance" {
  ami           = "ami-02d26659fd82cf299" # Ubuntu 22.04 LTS for ap-south-1
  instance_type = "t2.micro"
  subnet_id     = data.aws_subnet.default_subnet.id
  key_name      = "Key_pair1"
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]

  tags = {
    Name = "k8s-server"
  }

  user_data = <<-EOF
              #!/bin/bash
              apt update -y
              apt install -y python3
              EOF
}

# --- Output ---
output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.k8s_instance.public_ip
}
