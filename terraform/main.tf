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

  vpc_cidr = "10.0.0.0/16"

  azs = slice(data.aws_availability_zones.available.names, 0, 2)

  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.101.0/24", "10.0.102.0/24"]

  tags = local.common_tags
}

module "security_groups" {
  source = "./modules/security_groups"

  name   = local.name
  vpc_id = module.vpc.vpc_id

  app_port = 80
  db_port  = 5432

  # SSH açmak istersen kendi IP'ni /32 verirsin; şimdilik boş bırak (daha güvenli)
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