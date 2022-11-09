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
