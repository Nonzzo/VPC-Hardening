output "vpc_flow_log_group_name" {
  description = "The name of the VPC Flow Logs CloudWatch Log Group"
  value       = aws_cloudwatch_log_group.vpc_flow_logs.name
}
