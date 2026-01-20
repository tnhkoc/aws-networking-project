data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  name = "${var.project}-${var.environment}"

  common_tags = {
    Project     = var.project
    Environment = var.environment
  }
}

module "vpc" {
  source = "./modules/vpc"

  name = local.name

  vpc_cidr = var.vpc_cidr

  azs = slice(data.aws_availability_zones.available.names, 0, 2)

  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.101.0/24", "10.0.102.0/24"]

  tags = local.common_tags
}

module "security_groups" {
  source = "./modules/security_groups"

  name   = local.name
  vpc_id = module.vpc.vpc_id

  app_port = var.app_port
  db_port  = var.db_port

  admin_cidr_blocks = []

  tags = local.common_tags
}

module "alb" {
  source = "./modules/alb"

  name              = local.name
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  alb_sg_id         = module.security_groups.alb_sg_id

  tags = local.common_tags
}

module "app" {
  source = "./modules/app_ec2"

  name      = local.name
  subnet_id = module.vpc.private_subnet_ids[0] # şimdilik 1 instance
  app_sg_id = module.security_groups.app_sg_id

  tags = local.common_tags
}

module "nacls" {
  source = "./modules/nacls"

  name = local.name

  vpc_id   = module.vpc.vpc_id
  vpc_cidr = var.vpc_cidr

  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids

  app_port = var.app_port
  db_port  = var.db_port

  tags = local.common_tags
}