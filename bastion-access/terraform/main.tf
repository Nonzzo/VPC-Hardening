provider "aws" {
  region = var.region
}

module "vpc" {
  source             = "../../modules/vpc"
  vpc_name           = var.vpc_name
  vpc_cidr           = var.vpc_cidr
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
  availability_zones = var.availability_zones
}

module "security" {
  source                  = "../../modules/security"
  vpc_id                  = module.vpc.vpc_id
  name_prefix             = var.vpc_name
  public_subnet_ids       = module.vpc.public_subnet_ids
  private_subnet_ids      = module.vpc.private_subnet_ids
  allowed_ssh_cidr_blocks = ["XXX.118.XX.10/32"] # On mac/linux use 'curl ifconfig.me' to get your ip
}

module "bastion" {
  source           = "../../modules/bastion"
  vpc_id           = module.vpc.vpc_id
  public_subnet_id = module.vpc.public_subnet_ids[0]
  bastion_sg_id    = module.security.bastion_sg_id
  key_name         = "Nonso-EC2Key" # Replace with your actual key
  instance_type    = "t2.micro"
}

module "private_instance" {
  source            = "../../modules/private_instance"
  vpc_id            = module.vpc.vpc_id
  private_subnet_id = module.vpc.private_subnet_ids[0]
  private_sg_id     = module.security.private_sg_id
  key_name          = "Nonso-EC2Key" # Same as bastion
  instance_type     = "t2.micro"
}

module "nat_gateway" {
  source              = "../../modules/nat_gateway"
  vpc_id              = module.vpc.vpc_id
  public_subnet_id    = module.vpc.public_subnet_ids[0]
  private_subnet_ids  = module.vpc.private_subnet_ids
  internet_gateway_id = module.vpc.igw_id
}







