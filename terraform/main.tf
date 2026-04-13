terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  # Uncomment to store state in S3 (recommended for teams)
  # backend "s3" {
  #   bucket = "foodexpress-tfstate"
  #   key    = "prod/terraform.tfstate"
  #   region = "ap-southeast-1"
  # }
}

provider "aws" {
  region = var.aws_region
}

# ── SSH Key Pair ─────────────────────────────────
resource "aws_key_pair" "foodexpress_key" {
  key_name   = "foodexpress-key-${var.environment}"
  public_key = var.ssh_public_key
}

# ── Security Group ───────────────────────────────
resource "aws_security_group" "foodexpress_sg" {
  name        = "foodexpress-sg-${var.environment}"
  description = "FoodExpress API security group"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Restrict in production!
  }
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "App Port"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "foodexpress-sg" }
}

# ── Fetch Latest Amazon Linux 2023 AMI ───────────
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# ── EC2 Instance ─────────────────────────────────
resource "aws_instance" "foodexpress_server" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.foodexpress_key.key_name
  vpc_security_group_ids = [aws_security_group.foodexpress_sg.id]

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y docker
    systemctl start docker
    systemctl enable docker
    usermod -a -G docker ec2-user
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    echo "Bootstrap complete" > /tmp/bootstrap.log
  EOF

  tags = {
    Name        = "foodexpress-${var.environment}"
    Environment = var.environment
    Project     = "FoodExpress"
    ManagedBy   = "Terraform"
  }
}

# ── Elastic IP (keeps IP after restart) ──────────
resource "aws_eip" "foodexpress_eip" {
  instance = aws_instance.foodexpress_server.id
  domain   = "vpc"
  tags     = { Name = "foodexpress-eip" }
}