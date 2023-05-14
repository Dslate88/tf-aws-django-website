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
  family                   = "${var.stack_name}-${var.env}-4"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
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
        "daemon off;" # TODO: might want to change this to "on" for prod
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
      command = [
        "/bin/sh",
        "-c",
        "python manage.py collectstatic --noinput && gunicorn base.wsgi:application --bind localhost:8000"
      ]
      mountPoints = [{
        sourceVolume  = "media_volume"
        containerPath = "/home/app/web/media"
        readOnly = false
      }]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.django_container.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "django"
        }
      }
    }
  ])

  volume {
    name = "media_volume"
  }

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }
}

resource "aws_ecs_service" "main" {
  # count                              = var.deploy_ecs_service ? 1 : 0
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
  zone_id = data.aws_route53_zone.main.id
  name    = "devinslate.com"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
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

resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = 10
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_policy" {
  name               = "cpu-utilization"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 50.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "high_cpu_utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric checks for high CPU utilization in ECS django-webapplication"
  alarm_actions       = [aws_sns_topic.alarm.arn]
  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.main.name
  }
}

resource "aws_sns_topic" "alarm" {
  name = "django-high-cpu-utilization"
}

resource "aws_sns_topic_subscription" "alarm_sms" {
  topic_arn = aws_sns_topic.alarm.arn
  protocol  = "sms"
  endpoint  = var.alert_phone_number
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_lb.main.dns_name
    origin_id   = "alb_origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.1", "TLSv1.2"]
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Cloudfront Distribution pointing to ALB"
  default_root_object = "home.html"

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "alb_origin"

    forwarded_values {
      query_string = true
      headers      = ["*"]

      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  viewer_certificate {
    acm_certificate_arn            = aws_acm_certificate.cert.arn
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.2_2018"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Environment = "production"
  }
}
