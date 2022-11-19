data "aws_caller_identity" "current" {}
data "aws_region" "current" {}


resource "aws_ecr_repository" "containers" {
  for_each             = toset(var.ecr_containers)
  name                 = each.value
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }
}

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
  name   = "${var.stack_name}-sg-task-${var.env}"
  vpc_id = var.vpc_id

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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    self        = false
  }

}

resource "aws_ecs_cluster" "main" {
  name = "${var.stack_name}-cluster-${var.env}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_cluster_capacity_providers" "example" {
  cluster_name       = aws_ecs_cluster.main.name
  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

resource "aws_cloudwatch_log_group" "nginx_container" {
  name              = "/ecs/${var.stack_name}/container-nginx-${var.env}"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "django_container" {
  name              = "/ecs/${var.stack_name}/container-django-${var.env}"
  retention_in_days = 14
}

# TODO: clean this up into a module
resource "aws_ecs_task_definition" "main" {
  # TODO: add task_role_arn with needed perms...
  family                   = "${var.stack_name}-${var.env}-4"
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
      environment = [
        {
          name = "DEPLOY_ENV", value = "prod"
        }
      ]
      # environmentFiles = [
      #   {
      #     value = "s3://my-bucket/ecs-env-files/django.env"
      #     type  = "s3"
      #   }
      # ]
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
  count                              = var.deploy_ecs_service ? 1 : 0
  name                               = "${var.stack_name}-service-${var.env}"
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

  network_configuration {
    subnets          = var.priv_subnet_ids
    assign_public_ip = false
    security_groups  = [aws_security_group.ecs_tasks.id]
    # security_groups  = [aws_security_group.ecs_tasks.id, aws_security_group.alb.id]
  }
  # lifecycle {
  #   ignore_changes = [task_definition]
  #   # ignore_changes = [desired_count, task_definition]
  # }
}

resource "aws_route53_record" "main" {
  zone_id         = data.aws_route53_zone.main.id
  name            = "devinslate.com"
  allow_overwrite = true
  type            = "A"
  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = false
  }
}

resource "aws_acm_certificate" "cert" {
  domain_name       = "devinslate.com"
  validation_method = "DNS"
}

data "aws_route53_zone" "main" {
  name         = "devinslate.com"
  private_zone = false
}

resource "aws_route53_record" "validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.main.zone_id
}
