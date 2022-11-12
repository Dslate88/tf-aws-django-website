data "aws_caller_identity" "current" {}

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
  pub_map_ip      = true

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

resource "aws_security_group" "alb-internal" {
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

resource "aws_security_group" "ecs_tasks" {
  name   = "${local.stack_name}-sg-task-${local.env}"
  vpc_id = module.vpc.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = 80 # TODO:
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${local.stack_name}-ecs-task-execution-role-${local.env}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role" {
  # TODO:  # scope permissions down
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "main" {
  # TODO: add task_role_arn with needed perms...
  family = "test_annoyed_9371"
  # family                   = "${local.stack_name}-${local.env}"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
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
    }
    ]
  )

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }
}

resource "aws_ecs_service" "main" {
  name            = "${local.stack_name}-service-${local.env}"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.arn
  launch_type     = "FARGATE"
  desired_count   = 1
  # deployment_maximum_percent         = 200
  # deployment_minimum_healthy_percent = 100
  scheduling_strategy = "REPLICA"

  deployment_controller {
    type = "ECS"
  }

  # TODO: add security_groups
  # TODO: convert to priv_subs and use alb
  network_configuration {
    subnets          = module.vpc.pub_subnets
    assign_public_ip = true
    security_groups  = [aws_security_group.allow-external.id]
  }
}

resource "aws_security_group" "allow-external" {
  vpc_id      = module.vpc.vpc_id
  name        = "${local.stack_name}-${local.env}-allow-external-ecs"
  description = "Allows external traffic"

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
  }

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = "443"
    to_port     = "443"
    protocol    = "tcp"
  }

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = "8000"
    to_port     = "8000"
    protocol    = "tcp"
  }

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = "80"
    to_port     = "80"
    protocol    = "tcp"
  }
}
