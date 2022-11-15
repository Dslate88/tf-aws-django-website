data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  stack_name = "django-website"
  env        = "dev"

  # vpc
  vpc_name             = "${local.env}-website"
  vpc_cidr             = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_igw           = true

  pub_cidrs       = ["10.0.0.0/24", "10.0.2.0/24"]
  pub_avail_zones = ["us-east-1a", "us-east-1b"]
  # pub_cidrs       = ["10.0.0.0/24"]
  # pub_avail_zones = ["us-east-1a"]
  pub_map_ip = true

  # priv_cidrs       = ["10.0.1.0/24"]
  # priv_avail_zones = ["us-east-1a"]
  priv_cidrs       = ["10.0.1.0/24", "10.0.3.0/24"]
  priv_avail_zones = ["us-east-1a", "us-east-1b"]
  priv_nat_gateway = true

  enable_s3_endpoint      = false
  enable_ecr_dkr_endpoint = false
  enable_ecr_api_endpoint = false
  enable_ssm_endpoint     = false

  # ecr
  ecr_containers = ["django_nginx", "django_webapp"]
}


module "vpc" {
  source     = "git@github.com:Dslate88/tf-aws-vpc"
  stack_name = local.stack_name
  env        = local.env

  # vpc
  vpc_name             = local.vpc_name
  vpc_cidr             = local.vpc_cidr
  enable_dns_hostnames = local.enable_dns_hostnames
  enable_igw           = local.enable_igw

  pub_cidrs       = local.pub_cidrs
  pub_avail_zones = local.pub_avail_zones
  pub_map_ip      = local.pub_map_ip

  priv_cidrs       = local.priv_cidrs
  priv_avail_zones = local.priv_avail_zones
  priv_nat_gateway = local.priv_nat_gateway

  enable_s3_endpoint      = local.enable_s3_endpoint
  enable_ecr_dkr_endpoint = local.enable_ecr_dkr_endpoint
  enable_ecr_api_endpoint = local.enable_ecr_api_endpoint
  enable_ssm_endpoint     = local.enable_ssm_endpoint
}

resource "aws_ecr_repository" "containers" {
  for_each             = toset(local.ecr_containers)
  name                 = each.value
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }
}

# ecr lifecycle policy for each ecr_containers
resource "aws_ecr_lifecycle_policy" "webapp" {
  for_each   = aws_ecr_repository.containers
  repository = each.value.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "keep last 10 images"
      action = {
        type = "expire"
      }
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
    }]
  })
}

resource "aws_security_group" "ecs_tasks" {
  name   = "${local.stack_name}-sg-task-${local.env}"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    self        = false
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    self        = false
  }

  ingress {
    protocol    = "tcp"
    from_port   = 8000
    to_port     = 8000
    cidr_blocks = ["0.0.0.0/0"]
    self        = false
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    self        = false
  }

}

resource "aws_ecs_cluster" "main" {
  # TODO: add cloudwatch/s3 log storage to configuration, if I need execute_command?
  name = "${local.stack_name}-cluster-${local.env}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_cluster_capacity_providers" "example" {
  cluster_name       = aws_ecs_cluster.main.name
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  # TODO: use spot instances here??
  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

resource "aws_cloudwatch_log_group" "nginx_container" {
  name              = "/ecs/${local.stack_name}/container-nginx-${local.env}"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "django_container" {
  name              = "/ecs/${local.stack_name}/container-django-${local.env}"
  retention_in_days = 14
}

resource "aws_ecs_task_definition" "main" {
  # TODO: add task_role_arn with needed perms...
  family                   = "${local.stack_name}-${local.env}-4"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  # task_role_arn            = aws_iam_role.ecs_task_role.arn
  network_mode = "awsvpc"
  cpu          = 256
  memory       = 512
  # TODO: dynamnic generate containers...
  container_definitions = jsonencode([
    {
      name      = "nginx"
      image     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.us-east-1.amazonaws.com/django_nginx"
      essential = true
      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
        }
      ]
      command = [
        "nginx",
        "-g",
        "daemon off;"
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.nginx_container.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "nginx"
        }
      }
    },
    {
      name      = "django"
      image     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.us-east-1.amazonaws.com/django_webapp"
      essential = true
      portMappings = [
        {
          containerPort = 8000
          protocol      = "tcp"
        }
      ]
      command = [
        "gunicorn",
        "base.wsgi:application",
        "--bind",
        "localhost:8000",
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.django_container.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "django"
        }
      }
    }
    ]
  )

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }
}


resource "aws_ecs_service" "main" {
  name                               = "${local.stack_name}-service-${local.env}"
  cluster                            = aws_ecs_cluster.main.id
  task_definition                    = aws_ecs_task_definition.main.arn
  launch_type                        = "FARGATE"
  desired_count                      = 1
  scheduling_strategy                = "REPLICA"
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  wait_for_steady_state              = true

  deployment_circuit_breaker {
    enable   = true
    rollback = false
  }

  deployment_controller {
    type = "ECS"
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.main.arn
    container_name   = "nginx"
    container_port   = 80
  }

  # TODO: convert to priv_subs and use alb
  network_configuration {
    subnets          = module.vpc.private_subnets
    assign_public_ip = false
    security_groups  = [aws_security_group.ecs_tasks.id]
    # security_groups  = [aws_security_group.ecs_tasks.id, aws_security_group.alb.id]
  }

  # lifecycle {
  #   ignore_changes = [task_definition]
  #   # ignore_changes = [desired_count, task_definition]
  # }
}

# get data aws route 53 zone
data "aws_route53_zone" "main" {
  name         = "devinslate.com"
  private_zone = false
}

# create alias record for the load balancer
resource "aws_route53_record" "main" {
  zone_id = data.aws_route53_zone.main.id
  name    = "devinslate.com"
  type    = "A"
  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = false
  }
}



# create target group for ecs fargate
resource "aws_lb_target_group" "main" {
  name        = "${local.stack_name}-tg-${local.env}"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"
  # health_check {
  #   path                = "/"
  #   interval            = 30
  #   timeout             = 5
  #   healthy_threshold   = 2
  #   unhealthy_threshold = 2
  # }
}

# create elastic load balancer
resource "aws_lb" "main" {
  name               = "${local.stack_name}-lb-${local.env}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = module.vpc.pub_subnets
}

# create listener
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

resource "aws_security_group" "alb" {
  name   = "${local.stack_name}-sg-alb-${local.env}"
  vpc_id = module.vpc.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}
