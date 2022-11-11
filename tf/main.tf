data "aws_caller_identity" "current" {}

locals {
  stack_name = "django-website"
  env        = "dev"

  # vpc
  vpc_name             = "${local.env}-website"
  vpc_cidr             = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_igw           = true

  # subnet pub: evens
  pub_cidrs       = ["10.0.0.0/24", "10.0.2.0/24"]
  pub_avail_zones = ["us-east-1a", "us-east-1b"]
  pub_map_ip      = true

  # subnet priv: odds
  priv_cidrs       = ["10.0.1.0/24", "10.0.3.0/24"]
  priv_avail_zones = ["us-east-1a", "us-east-1b"]
  priv_nat_gateway = false # for now

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

  # subnet public
  pub_cidrs       = local.pub_cidrs
  pub_avail_zones = local.pub_avail_zones
  pub_map_ip      = local.pub_map_ip

  # subnet private
  priv_cidrs       = local.priv_cidrs
  priv_avail_zones = local.priv_avail_zones
  priv_nat_gateway = local.priv_nat_gateway
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
  name = "${local.stack_name}-cluster-${local.env}"
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

resource "aws_ecs_task_definition" "webapp" {
  family                   = "test_task"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.task.arn
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  # TODO: dynamnic generate containers...
  container_definitions = jsonencode([
    {
      name  = "test_nginx"
      image = "${data.aws_caller_identity.current.account_id}.dkr.ecr.us-east-1.amazonaws.com/django_nginx"
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
      essential = true
    }
    ]
  )

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }
}

resource "aws_ecs_service" "webapp" {
  name                               = "webapp"
  cluster                            = aws_ecs_cluster.main.id
  task_definition                    = aws_ecs_task_definition.webapp.arn
  launch_type                        = "FARGATE"
  desired_count                      = 1
  wait_for_steady_state              = true
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  deployment_controller {
    type = "ECS"
  }

  # TODO: add security_groups
  network_configuration {
    subnets          = module.vpc.pub_subnets
    assign_public_ip = false
  }
}
