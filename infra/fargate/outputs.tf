variable "ecr_containers" {
  type        = list(string)
  description = "List of ECR containers"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "env" {
  type        = string
  description = "Environment"
}

variable "stack_name" {
  type        = string
  description = "Stack name"
}

variable "priv_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs"
}

variable "pub_subnet_ids" {
  type        = list(string)
  description = "Public subnet IDs"
}
