output "public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_eip.foodexpress_eip.public_ip
}

output "app_url" {
  description = "Application URL"
  value       = "http://${aws_eip.foodexpress_eip.public_ip}:3000"
}

output "ssh_command" {
  description = "SSH command to access server"
  value       = "ssh -i ~/.ssh/foodexpress ec2-user@${aws_eip.foodexpress_eip.public_ip}"
}