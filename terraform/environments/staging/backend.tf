terraform {
  backend "s3" {
    bucket         = "myapp-terraform-state-staging"
    key            = "eks/staging/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "myapp-terraform-state-staging-lock"
  }
}
