#!/usr/bin/env bash
# Bootstrap script for per-environment Terraform state setup
# Creates S3 buckets and DynamoDB lock tables for each environment
# Each environment has independent state isolation

set -euo pipefail

AWS_REGION="us-east-1"
PROJECT="myapp"

echo "========================================="
echo "Terraform State Bootstrap - Per Environment"
echo "Project: $PROJECT"
echo "Region: $AWS_REGION"
echo "========================================="
echo ""

# Function to create S3 bucket with encryption and versioning
setup_s3_bucket() {
  local ENV=$1
  local BUCKET="${PROJECT}-terraform-state-${ENV}"
  
  echo "[${ENV}] Creating S3 state bucket: $BUCKET"
  
  # Create bucket
  if aws s3api head-bucket --bucket "$BUCKET" 2>/dev/null; then
    echo "  ✓ Bucket already exists: $BUCKET"
  else
    if [ "$AWS_REGION" = "us-east-1" ]; then
      aws s3api create-bucket --bucket "$BUCKET" --region "$AWS_REGION" 2>/dev/null || true
    else
      aws s3api create-bucket \
        --bucket "$BUCKET" \
        --region "$AWS_REGION" \
        --create-bucket-configuration LocationConstraint="$AWS_REGION" 2>/dev/null || true
    fi
    echo "  ✓ Created bucket: $BUCKET"
  fi
  
  # Enable versioning
  aws s3api put-bucket-versioning \
    --bucket "$BUCKET" \
    --versioning-configuration Status=Enabled 2>/dev/null || true
  echo "  ✓ Enabled versioning"
  
  # Enable encryption
  aws s3api put-bucket-encryption \
    --bucket "$BUCKET" \
    --server-side-encryption-configuration '{
      "Rules": [
        {
          "ApplyServerSideEncryptionByDefault": {
            "SSEAlgorithm": "AES256"
          }
        }
      ]
    }' 2>/dev/null || true
  echo "  ✓ Enabled encryption"
  
  # Block public access
  aws s3api put-public-access-block \
    --bucket "$BUCKET" \
    --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" 2>/dev/null || true
  echo "  ✓ Blocked public access"
  
  echo ""
}

# Function to create DynamoDB lock table
setup_lock_table() {
  local ENV=$1
  local LOCK_TABLE="${PROJECT}-terraform-state-${ENV}-lock"
  
  echo "[${ENV}] Creating DynamoDB lock table: $LOCK_TABLE"
  
  if aws dynamodb describe-table --table-name "$LOCK_TABLE" --region "$AWS_REGION" 2>/dev/null; then
    echo "  ✓ Lock table already exists: $LOCK_TABLE"
  else
    aws dynamodb create-table \
      --table-name "$LOCK_TABLE" \
      --attribute-definitions AttributeName=LockID,AttributeType=S \
      --key-schema AttributeName=LockID,KeyType=HASH \
      --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
      --region "$AWS_REGION" 2>/dev/null || true
    echo "  ✓ Created lock table: $LOCK_TABLE"
  fi
  
  echo ""
}

# Bootstrap each environment
for ENV in dev staging production; do
  setup_s3_bucket "$ENV"
  setup_lock_table "$ENV"
done

echo "========================================="
echo "✓ Bootstrap Complete!"
echo "========================================="
echo ""
echo "State Configuration:"
echo "  Dev:        ${PROJECT}-terraform-state-dev"
echo "  Staging:    ${PROJECT}-terraform-state-staging"
echo "  Production: ${PROJECT}-terraform-state-prod"
echo ""
echo "Lock Tables:"
echo "  Dev:        ${PROJECT}-terraform-state-dev-lock"
echo "  Staging:    ${PROJECT}-terraform-state-staging-lock"
echo "  Production: ${PROJECT}-terraform-state-prod-lock"
echo ""
echo "Next Steps:"
echo "  1. cd terraform/environments/dev"
echo "  2. terraform init"
echo "  3. terraform plan -var-file=terraform.tfvars"
echo "  4. terraform apply -var-file=terraform.tfvars"
echo ""
echo "Repeat for staging and production environments."
echo ""
