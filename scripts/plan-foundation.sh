#!/usr/bin/env bash
# Plan the VPC, EKS control plane, and fixed system node group.
# Usage: ./plan-foundation.sh [dev|staging|production]

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
  echo "✗ Missing $ENV_DIR/backend.hcl; configure it before planning."
  exit 1
fi

cd "$ENV_DIR"
terraform init -backend-config=backend.hcl -input=false
terraform plan \
  -var-file=terraform.tfvars \
  -target=module.vpc \
  -target=module.eks \
  -target=module.node_group \
  -out="foundation.${ENV}"

echo "Review foundation.${ENV}, then run: bash scripts/apply-foundation.sh $ENV"
