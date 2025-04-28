output "cpu_alarm_name" {
  description = "Name of the CPU alarm"
  value       = aws_cloudwatch_metric_alarm.cpu_high.alarm_name
}

output "network_in_alarm_name" {
  description = "Name of the NetworkIn alarm"
  value       = aws_cloudwatch_metric_alarm.network_in_high.alarm_name
}
