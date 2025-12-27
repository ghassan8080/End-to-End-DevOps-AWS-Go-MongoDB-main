resource "aws_ecr_repository" "ecr_repo" {
  name                 = "goapp-survey"
  force_delete         = true
  image_scanning_configuration {
    scan_on_push = true
  }
}
