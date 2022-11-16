resource "aws_lb_target_group" "main" {
  name        = "${var.stack_name}-tg-${var.env}"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  # health_check {
  #   path                = "/"
  #   interval            = 30
  #   timeout             = 5
  #   healthy_threshold   = 2
  #   unhealthy_threshold = 2
  # }
}

resource "aws_lb" "main" {
  name               = "${var.stack_name}-lb-${var.env}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ecs_tasks.id]
  subnets            = var.pub_subnet_ids
}

resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

# create listener rule
# resource "aws_lb_listener_rule" "main" {
#   listener_arn = aws_lb_listener.main.arn
#   priority     = 1
#
#   action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.main.arn
#   }
#
#   condition {
#     field  = "path-pattern"
#     values = ["/"]
#   }
# }
