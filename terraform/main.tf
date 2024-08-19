# main.tf

provider "aws" {
  region = var.region
}

# Variables
variable "region" {
  description = "The AWS region to deploy in"
  type        = string
}

variable "ami" {
  description = "The AMI ID to use for the instance"
  type        = string
}

variable "instance_type" {
  description = "The instance type to use"
  type        = string
  default     = "t2.micro"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "The CIDR block for the subnet"
  type        = string
  default     = "10.0.1.0/24"
}

# VPC
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "peachycloudsecurity_main-vpc"
  }
}

# Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = true

  tags = {
    Name = "peachycloudsecurity_public-subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "peachycloudsecurity_main-igw"
  }
}

# Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "peachycloudsecurity_public-route-table"
  }
}

# Route Table Association
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security Group
resource "aws_security_group" "allow_http" {
  vpc_id = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "peachycloudsecurity_allow_http"
  }
}

# IAM Role for SSM
resource "aws_iam_role" "ssm_role" {
  name = "peachycloudsecurity_ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "peachycloudsecurity_ssm_role"
  }
}

resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_profile" {
  name = "peachycloudsecurity_ssm-profile"
  role = aws_iam_role.ssm_role.name
}

# EC2 Instance
resource "aws_instance" "web" {
  ami                         = var.ami
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.allow_http.id]
  iam_instance_profile        = aws_iam_instance_profile.ssm_profile.name

  root_block_device {
    volume_size = 30
  }

  user_data = file("file.sh")

  tags = {
    Name = "peachycloudsecurity_web_instance"
  }

  provisioner "local-exec" {
    command = <<EOT
      instance_status=$(aws ec2 describe-instance-status --instance-id ${self.id} --query "InstanceStatuses[0].InstanceStatus.Status" --region ${var.region} --output text)
      while [ "$instance_status" != "ok" ]; do
        echo "Waiting for instance to be in 'ok' status..."
        sleep 10
        instance_status=$(aws ec2 describe-instance-status --instance-id ${self.id} --query "InstanceStatuses[0].InstanceStatus.Status" --region ${var.region} --output text)
      done
      echo "Instance is ready!"
    EOT
    interpreter = ["bash", "-c"]
  }
}

# Outputs
output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "subnet_id" {
  description = "The ID of the public subnet"
  value       = aws_subnet.public.id
}

output "security_group_id" {
  description = "The ID of the security group"
  value       = aws_security_group.allow_http.id
}

output "instance_id" {
  description = "The ID of the EC2 instance"
  value       = aws_instance.web.id
}

output "instance_public_ip" {
  description = "The public IP address of the EC2 instance"
  value       = aws_instance.web.public_ip
}

output "instance_public_dns" {
  description = "The public DNS name of the EC2 instance"
  value       = aws_instance.web.public_dns
}

output "region" {
  description = "The AWS region in which resources are deployed"
  value       = var.region
}