resource "aws_ecr_repository" "my_service_repo" {
  name                 = "my-service-repo"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}

output "repository_url" {
  value = aws_ecr_repository.my_service_repo.repository_url
}
