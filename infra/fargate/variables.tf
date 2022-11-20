variable "deploy_ecs_service" {
  type        = bool
  description = "Deploy ECS Service"
  default     = true
}

variable "bucket" {
  type        = string
  description = "S3 Bucket Name"
  default     = "account-keeps-nonversioned"
}

variable "media_dir" {
  type        = string
  description = "media directory for django"
  default     = "test_media_fargate"
}
