provider "aws" {
  region = var.aws_region
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
  allowed_ssh_cidr_blocks = []
  private_subnet_ids      = module.vpc.private_subnet_ids

}

module "nat_gateway" {
  source              = "../../modules/nat_gateway"
  public_subnet_id    = module.vpc.public_subnet_ids[0]
  private_subnet_ids  = module.vpc.private_subnet_ids
  internet_gateway_id = module.vpc.igw_id
  vpc_id              = module.vpc.vpc_id

}

module "ssm_role" {
  source      = "../../modules/ssm_role"
  name_prefix = var.vpc_name

}


module "private_instance" {
  source                    = "../../modules/private_instance"
  vpc_id                    = module.vpc.vpc_id
  private_subnet_id         = module.vpc.private_subnet_ids[0]
  private_sg_id             = module.security.private_sg_id
  key_name                  = null  # you don't need key pair for ssm-access
  instance_type             = "t2.micro"
  iam_instance_profile_name = module.ssm_role.instance_profile_name
}

module "vpc_endpoints" {
  source             = "../../modules/vpc_endpoints"
  region             = var.aws_region
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  name_prefix        = var.vpc_name
  security_group_id  = module.security.ssm_sg_id
}

module "cloudwatch" {
  source             = "../../modules/cloudwatch"
  name_prefix        = var.name_prefix
  vpc_id             = module.vpc.vpc_id
  retention_in_days  = 30
  instance_id        = module.private_instance.private_instance_id
  notification_email = "nonzo404@yahoo.com"
  aws_region         = var.aws_region

}

module "cloudwatch_alarms" {
  source        = "../../modules/cloudwatch_alarms"
  name_prefix   = var.name_prefix
  sns_topic_arn = module.cloudwatch.sns_topic_arn
  instance_id   = module.private_instance.private_instance_id
}

module "aws_config" {
source        = "../../modules/aws_config"
name_prefix   = var.name_prefix
sns_topic_arn = module.cloudwatch.sns_topic_arn
}



