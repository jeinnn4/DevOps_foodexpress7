output "public_ip" {
  description = "EC2 public IP"
  value       = aws_eip.foodexpress_eip.public_ip
}

output "app_url" {
  value = "http://${aws_eip.foodexpress_eip.public_ip}:3000"
}

output "ssh_command" {
  value = "ssh -i ~/.ssh/foodexpress ubuntu@${aws_eip.foodexpress_eip.public_ip}"
}
