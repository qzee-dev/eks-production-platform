terraform {
  backend "s3" {
    bucket         = "myapp-terraform-state-dev"
    key            = "eks/dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "myapp-terraform-state-dev-lock"
  }
}
