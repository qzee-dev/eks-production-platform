terraform {
  backend "s3" {
    bucket         = "myapp-terraform-state-prod"
    key            = "eks/production/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "myapp-terraform-state-lock"
  }
}
