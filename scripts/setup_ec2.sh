#!/bin/bash
# One-time setup after Terraform creates EC2
EC2_IP="$1"
KEY="~/.ssh/foodexpress"

ssh -i "$KEY" -o StrictHostKeyChecking=no ec2-user@"$EC2_IP" '
  # Update system
  sudo yum update -y

  # Install CloudWatch agent for monitoring
  sudo yum install -y amazon-cloudwatch-agent

  # Configure automatic Docker restarts
  sudo systemctl enable docker

  # Set up log rotation for Docker
  sudo tee /etc/docker/daemon.json << EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF
  sudo systemctl restart docker

  # Install nginx as reverse proxy (optional)
  sudo yum install -y nginx
  sudo systemctl enable nginx

  echo "EC2 setup complete!"
'

echo "Setup complete for $EC2_IP"