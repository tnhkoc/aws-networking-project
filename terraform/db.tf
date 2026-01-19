resource "aws_db_subnet_group" "this" {
  name        = "${local.name}-db-subnet-group"
  description = "DB subnet group (private subnets) for optional RDS"
  subnet_ids  = module.vpc.private_subnet_ids

  tags = merge(local.common_tags, {
    Name = "${local.name}-db-subnet-group"
  })
}