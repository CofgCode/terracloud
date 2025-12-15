resource "aws_ecr_repository" "backend_ecr_repo" {
  name = var.backend_ecr_repo_name
}

resource "aws_ecr_repository" "frontend_ecr_repo" {
  name = var.frontend_ecr_repo_name
}
