output "private_instance_ip" {
  description = "Private IP of the instance"
  value       = module.private_instance.private_instance_private_ip
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "ssm_endpoint_id" {
  value = module.vpc_endpoints.ssm_endpoint_id
}
