variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1" 
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"  # Free tier eligible
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "production"
}

variable "ssh_public_key" {
  description = "SSH public key for EC2 access"
  type        = string
  sensitive   = true
}