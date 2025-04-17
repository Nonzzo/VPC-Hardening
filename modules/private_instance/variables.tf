variable "private_subnet_id" {
  description = "Private subnet to launch instance"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_sg_id" {
  description = "Security Group ID for private instance"
  type        = string
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
}

variable "instance_type" {
  type        = string
  default     = "t3.micro"
}
