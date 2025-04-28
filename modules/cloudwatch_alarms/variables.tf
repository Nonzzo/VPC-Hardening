variable "name_prefix" {
  description = "Prefix for alarm names"
  type        = string
}

variable "instance_id" {
  description = "ID of the EC2 instance to monitor"
  type        = string
}
