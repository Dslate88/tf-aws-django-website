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
  # priv_nat_gateway = false

  enable_s3_endpoint      = false
  enable_ecr_dkr_endpoint = false
  enable_ecr_api_endpoint = false
  enable_ssm_endpoint     = false

  # ecr
  ecr_containers = ["django_nginx", "django_webapp"]
  deploy_ecs_service = true
  # deploy_ecs_service = false
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

module "fargate" {
  source     = "./infra/fargate"
  stack_name = local.stack_name
  env        = local.env

  ecr_containers     = local.ecr_containers
  vpc_id             = module.vpc.vpc_id
  pub_subnet_ids     = module.vpc.pub_subnets
  priv_subnet_ids    = module.vpc.priv_subnets
  deploy_ecs_service = local.deploy_ecs_service
}


# ## RDS
# resource "aws_db_subnet_group" "default" {
#   name       = "main"
#   subnet_ids = [aws_subnet.frontend.id, aws_subnet.backend.id]
#
#   tags = {
#     Name = "My DB subnet group"
#   }
# }
#
# # create aws rds mysql database resource
# resource "aws_db_instance" "website_db" {
#   allocated_storage    = 20
#   storage_type         = "gp2"
#   engine               = "mysql"
#   engine_version       = "5.7"
#   instance_class       = "db.t3.micro"
#   name                 = "website_db"
#   username             = "website_user"
#   password             = "website_password"
#   db_subnet_group_name = "dev-website-us-east-1a-private-subnet"
#   # db_subnet_group_name = module.vpc.priv_subnets
#   # vpc_security_group_ids = [
#   #   module.vpc.vpc_security_group_id
#   # ]
#   publicly_accessible = false
#   skip_final_snapshot = true
# }
