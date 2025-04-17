variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "public_subnet_id" {
  type        = string
  description = "Subnet ID to launch bastion in"
}

variable "bastion_sg_id" {
  type        = string
  description = "Security Group ID for the bastion host"
}

variable "key_name" {
  type        = string
  description = "EC2 key pair name"
}

variable "instance_type" {
  type        = string
  default     = "t2.micro"
}


