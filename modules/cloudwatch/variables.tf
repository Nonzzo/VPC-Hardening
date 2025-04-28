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
