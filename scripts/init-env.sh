#!/usr/bin/env bash
# Initialize Terraform for a specific environment
# Usage: ./init-env.sh [dev|staging|production]

set -euo pipefail

ENV=${1:-}

case "$ENV" in
  dev|staging|production) ;;
  *)
  echo "Usage: $0 [dev|staging|production]"
  exit 1
  ;;
esac

ENV_DIR="terraform/environments/$ENV"
if [ ! -f "$ENV_DIR/backend.hcl" ]; then
  echo "✗ Missing $ENV_DIR/backend.hcl"
  echo "Copy backend.hcl.example to backend.hcl and enter the pre-created bucket details."
  exit 1
fi

echo "========================================="
echo "Initializing Terraform: $ENV"
echo "========================================="
echo ""

cd "$ENV_DIR"

echo "[${ENV}] Running terraform init..."
terraform init -backend-config=backend.hcl

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
