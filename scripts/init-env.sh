#!/usr/bin/env bash
# Initialize Terraform for a specific environment
# Usage: ./init-env.sh [dev|staging|production]

set -euo pipefail

ENV=${1:-}

if [ -z "$ENV" ]; then
  echo "Usage: $0 [dev|staging|production]"
  exit 1
fi

if [ ! -d "terraform/environments/$ENV" ]; then
  echo "✗ Environment directory not found: terraform/environments/$ENV"
  exit 1
fi

echo "========================================="
echo "Initializing Terraform: $ENV"
echo "========================================="
echo ""

cd "terraform/environments/$ENV"

echo "[${ENV}] Running terraform init..."
terraform init

echo ""
echo "[${ENV}] Running terraform validate..."
terraform validate

echo ""
echo "========================================="
echo "✓ Initialization Complete for $ENV"
echo "========================================="
echo ""
echo "Next steps:"
echo "  1. terraform plan -var-file=terraform.tfvars -out=plan.$ENV"
echo "  2. Review the plan carefully"
echo "  3. terraform apply plan.$ENV"
echo ""
