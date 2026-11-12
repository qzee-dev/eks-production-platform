#!/usr/bin/env bash
# Apply Terraform deployment for a specific environment
# Usage: ./apply-env.sh [dev|staging|production]

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
  echo "✗ Missing $ENV_DIR/backend.hcl; run init after configuring the backend."
  exit 1
fi

if [ ! -f "$ENV_DIR/plan.${ENV}" ]; then
  echo "✗ Plan file not found: $ENV_DIR/plan.${ENV}"
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
