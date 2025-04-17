output "private_instance_id" {
  value = aws_instance.app.id
}

output "private_instance_private_ip" {
  value = aws_instance.app.private_ip
}
