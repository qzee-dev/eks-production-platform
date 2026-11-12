#!/usr/bin/env bash
# Apply a reviewed foundation plan before installing Kubernetes add-ons.
# Usage: ./apply-foundation.sh [dev|staging|production]

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
PLAN="$ENV_DIR/foundation.${ENV}"

if [ ! -f "$ENV_DIR/backend.hcl" ]; then
  echo "✗ Missing $ENV_DIR/backend.hcl; configure it before applying."
  exit 1
fi

if [ ! -f "$PLAN" ]; then
  echo "✗ Foundation plan not found: $PLAN"
  echo "Run './scripts/plan-foundation.sh $ENV' first."
  exit 1
fi

if [ "$ENV" = "production" ]; then
  echo "⚠️  PRODUCTION FOUNDATION DEPLOYMENT"
  read -r -p "Type 'yes' to confirm: " CONFIRM
  if [ "$CONFIRM" != "yes" ]; then
    echo "✗ Deployment cancelled"
    exit 1
  fi
fi

terraform -chdir="$ENV_DIR" apply "foundation.${ENV}"
