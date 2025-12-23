terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"
    key            = "eks-cluster/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
