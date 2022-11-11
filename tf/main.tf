data "aws_caller_identity" "current" {}


locals {
  stack_name = "django_website"
  env        = "dev"

  # vpc
  vpc_name             = "website"
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

# 1 repo for each compose container
resource "aws_ecr_repository" "webapp" {
  name                 = "django_webapp"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }
}

resource "aws_ecr_repository" "nginx" {
  name                 = "django_nginx"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }
}

resource "aws_ecs_cluster" "main" {
  name = "${local.stack_name}-cluster"
}

resource "aws_ecs_cluster_capacity_providers" "example" {
  cluster_name       = aws_ecs_cluster.main.name
  capacity_providers = ["FARGATE"]

  # TODO: use spot instances here??
  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

resource "aws_ecs_task_definition" "webapp" {
  family                   = "test_task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
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
