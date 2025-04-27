variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group to associate with VPC endpoints"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for naming"
  type        = string
}
