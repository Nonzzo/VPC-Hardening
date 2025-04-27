output "instance_profile_name" {
  description = "The name of the IAM instance profile for SSM"
  value       = aws_iam_instance_profile.ssm_profile.name
}