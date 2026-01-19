resource "aws_lb_target_group_attachment" "app" {
  target_group_arn = module.alb.target_group_arn
  target_id        = module.app.instance_id
  port             = 80
}