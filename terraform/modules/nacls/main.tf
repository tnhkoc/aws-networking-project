############################
# Public NACL
############################
resource "aws_network_acl" "public" {
  vpc_id = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name}-nacl-public"
  })
}

#tfsec:ignore:aws-ec2-no-public-ingress-acl -- Public subnet NACL allows inbound for internet-facing ALB; access is controlled at SG layer. Inbound: HTTP 80 from Internet
resource "aws_network_acl_rule" "public_in_http" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

#tfsec:ignore:aws-ec2-no-public-ingress-acl -- Public subnet NACL allows inbound for internet-facing ALB; access is controlled at SG layer. HTTPS 443 from Internet (future-proof)
resource "aws_network_acl_rule" "public_in_https" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 110
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

#tfsec:ignore:aws-ec2-no-public-ingress-acl -- Public subnet NACL allows inbound for internet-facing ALB; access is controlled at SG layer. Ephemeral ports for return traffic
resource "aws_network_acl_rule" "public_in_ephemeral" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 120
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "public_out_http" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 100
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "public_out_https" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 110
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "public_out_ephemeral" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 120
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

# Associate public NACL to public subnets
resource "aws_network_acl_association" "public" {
  for_each       = toset(var.public_subnet_ids)
  network_acl_id = aws_network_acl.public.id
  subnet_id      = each.value
}

############################
# Private NACL
############################
resource "aws_network_acl" "private" {
  vpc_id = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name}-nacl-private"
  })
}

# Inbound: App port from within VPC (ALB -> App, intra-vpc)
resource "aws_network_acl_rule" "private_in_app" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr
  from_port      = var.app_port
  to_port        = var.app_port
}

# Inbound: DB port from within VPC (App -> DB)
resource "aws_network_acl_rule" "private_in_db" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 110
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr
  from_port      = var.db_port
  to_port        = var.db_port
}

# Inbound: Ephemeral ports for return traffic (stateless NACL)
resource "aws_network_acl_rule" "private_in_ephemeral" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 120
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "private_out_http" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 100
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "private_out_https" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 110
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "private_out_ephemeral" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 120
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

# Associate private NACL to private subnets
resource "aws_network_acl_association" "private" {
  for_each       = toset(var.private_subnet_ids)
  network_acl_id = aws_network_acl.private.id
  subnet_id      = each.value
}