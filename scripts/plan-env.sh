#!/usr/bin/env bash
# Plan Terraform deployment for a specific environment
# Usage: ./plan-env.sh [dev|staging|production]

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
echo "Planning Terraform Deployment: $ENV"
echo "========================================="
echo ""

cd "terraform/environments/$ENV"

echo "[${ENV}] Running terraform plan..."
terraform plan \
  -var-file=terraform.tfvars \
  -out="plan.${ENV}"

echo ""
echo "========================================="
echo "✓ Plan Complete for $ENV"
echo "========================================="
echo ""
echo "Review the plan above carefully."
echo ""
echo "To apply this plan:"
echo "  cd terraform/environments/$ENV"
echo "  terraform apply plan.${ENV}"
echo ""
