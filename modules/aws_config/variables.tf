variable "name_prefix" {
  description = "Prefix for AWS Config resources"
  type        = string
}

variable "sns_topic_arn" {
type        = string
description = "ARN of the SNS topic to use for AWS Config notifications"
}