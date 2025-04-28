variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC to capture Flow Logs"
  type        = string
}

variable "retention_in_days" {
  description = "Retention period for logs"
  type        = number
  default     = 30
}

variable "notification_email" {
  description = "Email address to receive notifications"
  type        = string
}

variable "instance_id" {
  description = "ID of the EC2 instance to monitor"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

