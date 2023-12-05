locals {
  ecr_list = toset([
    "api",
    "nginx"
  ])
}

####################
# ECR
####################
resource "aws_ecr_repository" "main" {
  for_each = local.ecr_list
  name = "${var.project}-${each.key}-${var.env}"
}

resource "aws_ecr_lifecycle_policy" "main" {
  for_each = local.ecr_list
  policy = jsonencode({
    rules = [
      {
        action = {
          type = "expire"
        }
        description  = "delete images"
        rulePriority = 1
        selection = {
          countNumber = 3
          countType   = "imageCountMoreThan"
          tagStatus   = "any"
        }
      },
    ]
  })
  repository = aws_ecr_repository.main[each.key].name
}
