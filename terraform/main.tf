terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}

provider "aws" {
  region = var.aws_region
}

# ── SSH Key Pair ──────────────────────────────────────────────────
resource "aws_key_pair" "foodexpress_key" {
  key_name   = "foodexpress-key-${var.environment}"
  public_key = var.ssh_public_key
}

# ── Security Group ────────────────────────────────────────────────
resource "aws_security_group" "foodexpress_sg" {
  name        = "foodexpress-sg-${var.environment}"
  description = "FoodExpress API security group"

  ingress { description="SSH";     from_port=22;   to_port=22;   protocol="tcp"; cidr_blocks=["0.0.0.0/0"] }
  ingress { description="HTTP";    from_port=80;   to_port=80;   protocol="tcp"; cidr_blocks=["0.0.0.0/0"] }
  ingress { description="App";     from_port=3000; to_port=3000; protocol="tcp"; cidr_blocks=["0.0.0.0/0"] }
  ingress { description="Jenkins"; from_port=8080; to_port=8080; protocol="tcp"; cidr_blocks=["0.0.0.0/0"] }
  egress  { from_port=0; to_port=0; protocol="-1"; cidr_blocks=["0.0.0.0/0"] }

  tags = { Name = "foodexpress-sg" }
}

# ── Fetch latest Ubuntu 22.04 LTS AMI ────────────────────────────
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]   # Canonical (Ubuntu official)
  filter { name = "name";                values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"] }
  filter { name = "virtualization-type"; values = ["hvm"] }
}

# ── EC2 Instance ──────────────────────────────────────────────────
resource "aws_instance" "foodexpress_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.foodexpress_key.key_name
  vpc_security_group_ids = [aws_security_group.foodexpress_sg.id]

  user_data = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y ca-certificates curl gnupg
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu jammy stable" > /etc/apt/sources.list.d/docker.list
    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io
    systemctl start docker
    systemctl enable docker
    usermod -a -G docker ubuntu
  EOF

  tags = {
    Name        = "foodexpress-${var.environment}"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ── Elastic IP ────────────────────────────────────────────────────
resource "aws_eip" "foodexpress_eip" {
  instance = aws_instance.foodexpress_server.id
  domain   = "vpc"
  tags     = { Name = "foodexpress-eip" }
}
