locals {
  tg_base = substr(var.name, 0, 18)
  tg_hash = substr(md5(var.name), 0, 6)
  tg_name = "${local.tg_base}-${local.tg_hash}-tg"
}

# tfsec:ignore:aws-elb-alb-not-public -- Internet-facing ALB is intentional for this reference architecture.
resource "aws_lb" "this" {
  name               = "${var.name}-alb"
  load_balancer_type = "application"
  internal           = false

  drop_invalid_header_fields = true

  security_groups = [var.alb_sg_id]
  subnets         = var.public_subnet_ids

  tags = merge(var.tags, {
    Name = "${var.name}-alb"
  })
}

resource "aws_lb_target_group" "app" {
  name        = local.tg_name
  port        = var.app_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    path                = "/"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = "200-399"
  }

  tags = merge(var.tags, {
    Name = "${var.name}-tg-app"
  })
}

# tfsec:ignore:aws-elb-http-not-used -- Demo: HTTP listener used for simple curl validation; HTTPS would require ACM cert + domain.
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}