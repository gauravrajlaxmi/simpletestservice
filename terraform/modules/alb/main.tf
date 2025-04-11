variable "public_subnet_ids" {}
variable "vpc_id" {}
variable "alb_sg_id" {}

resource "aws_lb" "app" {
  name               = "ecs-lb"
  load_balancer_type = "application"
  subnets            = var.public_subnet_ids
  security_groups    = [var.alb_sg_id]

  tags = { Name = "ecs-alb" }
}

resource "aws_lb_target_group" "ecs_tg" {
  name        = "ecs-tg-5000"
  port        = 5000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path     = "/"
    protocol = "HTTP"
  }

  tags = { Name = "ecs-target-group" }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 5000
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_tg.arn
  }
}

output "alb_dns" {
  value = aws_lb.app.dns_name
}

output "target_group_arn" {
  value = aws_lb_target_group.ecs_tg.arn
}
