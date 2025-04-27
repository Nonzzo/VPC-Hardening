variable "aws_region" {
  default = "us-east-1"
}


variable "vpc_name" {
  type    = string
  default = "hardened-vpc"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "ami_owner" {
  default = "099720109477" # Canonical (Ubuntu)
}

variable "tags" {
  type    = map(string)
  default = {
    Project = "VPC-Hardening"
  }
}

variable "public_subnets" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets" {
  type    = list(string)
  default = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}
