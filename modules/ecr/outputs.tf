output "backend_repository_url" {
  value = aws_ecr_repository.backend_ecr_repo.repository_url
}

output "frontend_repository_url" {
  value = aws_ecr_repository.frontend_ecr_repo.repository_url
}