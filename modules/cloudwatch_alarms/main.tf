

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.name_prefix}-cpu-utilization-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "CWAgent"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alarm when CPU exceeds 80% for 10 minutes."
  dimensions = {
    InstanceId = var.instance_id
  }
  alarm_actions = [var.sns_topic_arn]
}

resource "aws_cloudwatch_metric_alarm" "network_in_high" {
  alarm_name          = "${var.name_prefix}-high-network-in-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "NetworkIn"
  namespace           = "CWAgent"
  period              = "300"
  statistic           = "Average"
  threshold           = 50000000 # ~50MB
  alarm_description   = "Alarm when NetworkIn is unusually high"
  dimensions = {
    InstanceId = var.instance_id
  }
}

resource "aws_cloudwatch_metric_alarm" "memory_high" {
  alarm_name          = "${var.name_prefix}-memory-usage-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alarm when memory usage exceeds 80% for 10 minutes."
  dimensions = {
    InstanceId = var.instance_id
  }
  alarm_actions = [var.sns_topic_arn]
}

resource "aws_cloudwatch_metric_alarm" "disk_high" {
  alarm_name          = "${var.name_prefix}-disk-usage-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "disk_used_percent"
  namespace           = "CWAgent"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alarm when disk usage exceeds 80% for 10 minutes."
  dimensions = {
    InstanceId = var.instance_id,
    path       = "/",
    fstype     = "ext4"
  }
  alarm_actions = [var.sns_topic_arn]
}

resource "aws_cloudwatch_metric_alarm" "swap_high" {
  alarm_name          = "${var.name_prefix}-swap-usage-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "swap_used_percent"
  namespace           = "CWAgent"
  period              = 300
  statistic           = "Average"
  threshold           = 50
  alarm_description   = "Alarm when swap usage exceeds 50% for 10 minutes."
  dimensions = {
    InstanceId = var.instance_id
  }
  alarm_actions = [var.sns_topic_arn]
}
