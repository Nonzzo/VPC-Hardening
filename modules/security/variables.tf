variable "vpc_id" {
  description = "VPC ID to associate NACLs and security groups"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "allowed_ssh_cidr_blocks" {
  description = "List of CIDRs allowed to access SSH (bastion)"
  type        = list(string)
}
