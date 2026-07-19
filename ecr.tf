# One ECR repository per application component (Stage 5B publishes images
# here). Names must match the Helm chart's image.repository values.
resource "aws_ecr_repository" "this" {
  for_each = toset(var.ecr_repository_names)

  name                 = each.value
  image_tag_mutability = var.ecr_image_tag_mutability
  # Lab repos get destroyed/recreated often (instructor validation passes,
  # student re-runs) — force_delete avoids a manual "empty the repo first"
  # step before `terraform destroy`.
  force_delete = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = local.tags
}

# Expire untagged images quickly and cap the number of retained tagged
# images per repo, so scan/storage costs don't grow unbounded across a
# semester of student pushes.
resource "aws_ecr_lifecycle_policy" "this" {
  for_each = aws_ecr_repository.this

  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images after ${var.ecr_untagged_image_expiry_days} days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = var.ecr_untagged_image_expiry_days
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep only the last ${var.ecr_max_tagged_image_count} tagged images"
        selection = {
          tagStatus      = "tagged"
          tagPatternList = ["*"]
          countType      = "imageCountMoreThan"
          countNumber    = var.ecr_max_tagged_image_count
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
