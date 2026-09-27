#!/usr/bin/env bash
# Apply Terraform deployment for a specific environment
# Usage: ./apply-env.sh [dev|staging|production]

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

if [ ! -f "terraform/environments/$ENV/plan.${ENV}" ]; then
  echo "✗ Plan file not found: terraform/environments/$ENV/plan.${ENV}"
  echo "Run './scripts/plan-env.sh $ENV' first"
  exit 1
fi

echo "========================================="
echo "Applying Terraform Deployment: $ENV"
echo "========================================="
echo ""

if [ "$ENV" = "production" ]; then
  echo "⚠️  PRODUCTION DEPLOYMENT"
  echo "This will modify production infrastructure."
  echo ""
  read -p "Type 'yes' to confirm: " CONFIRM
  
  if [ "$CONFIRM" != "yes" ]; then
    echo "✗ Deployment cancelled"
    exit 1
  fi
  echo ""
fi

cd "terraform/environments/$ENV"

echo "[${ENV}] Running terraform apply..."
terraform apply "plan.${ENV}"

echo ""
echo "========================================="
echo "✓ Deployment Complete for $ENV"
echo "========================================="
echo ""
echo "Cluster Information:"
terraform output
echo ""
