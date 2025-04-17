output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "bastion_public_ip" {
  value = module.bastion.bastion_public_ip
}

output "bastion_sg_id" {
  value = module.security.bastion_sg_id
}

output "private_instance_private_ip" {
  value = module.private_instance.private_instance_private_ip
}



