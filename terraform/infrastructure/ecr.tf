resource "aws_ecr_repository" "main_ecr" {
  name                 = "app-images"
  image_tag_mutability = "MUTABLE"
}