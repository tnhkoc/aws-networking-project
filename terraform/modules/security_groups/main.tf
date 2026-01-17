resource "aws_security_group" "alb" {
  name_prefix = "${var.name}-alb-"
  description = "ALB security group"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = "${var.name}-sg-alb" })
}

resource "aws_security_group" "bastion" {
  name_prefix = "${var.name}-bastion-"
  description = "Bastion security group"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = "${var.name}-sg-bastion" })
}

resource "aws_security_group" "app" {
  name_prefix = "${var.name}-app-"
  description = "App security group"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = "${var.name}-sg-app" })
}

resource "aws_security_group" "db" {
  name_prefix = "${var.name}-db-"
  description = "DB security group"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = "${var.name}-sg-db" })
}

resource "aws_vpc_security_group_ingress_rule" "alb_http_in" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTP from internet"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "alb_to_app" {
  security_group_id            = aws_security_group.alb.id
  description                  = "Forward to app"
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = var.app_port
  to_port                      = var.app_port
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "bastion_ssh_in" {
  for_each = toset(var.admin_cidr_blocks)

  security_group_id = aws_security_group.bastion.id
  description       = "SSH from admin CIDR"
  cidr_ipv4         = each.value
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "bastion_to_app_ssh" {
  security_group_id            = aws_security_group.bastion.id
  description                  = "SSH to app"
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = 22
  to_port                      = 22
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "app_from_alb" {
  security_group_id            = aws_security_group.app.id
  description                  = "App traffic from ALB"
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = var.app_port
  to_port                      = var.app_port
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "app_ssh_from_bastion" {
  security_group_id            = aws_security_group.app.id
  description                  = "SSH from bastion"
  referenced_security_group_id = aws_security_group.bastion.id
  from_port                    = 22
  to_port                      = 22
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "app_https_out" {
  security_group_id = aws_security_group.app.id
  description       = "Outbound HTTPS"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "app_to_db" {
  security_group_id            = aws_security_group.app.id
  description                  = "DB access"
  referenced_security_group_id = aws_security_group.db.id
  from_port                    = var.db_port
  to_port                      = var.db_port
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "db_from_app" {
  security_group_id            = aws_security_group.db.id
  description                  = "DB from app"
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = var.db_port
  to_port                      = var.db_port
  ip_protocol                  = "tcp"
}