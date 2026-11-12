#!/usr/bin/env bash
# Validate Terraform configuration across all environments
# Ensures all environments are syntactically correct

set -euo pipefail

echo "========================================="
echo "Validating Terraform Across Environments"
echo "========================================="
echo ""

FAILED=0

for ENV in dev staging production; do
  echo "[${ENV}] Validating..."
  
  if terraform -chdir="terraform/environments/${ENV}" init -backend=false -input=false; then
    if terraform -chdir="terraform/environments/${ENV}" validate; then
      echo "  ✓ Validation passed"
    else
      echo "  ✗ Validation failed"
      FAILED=$((FAILED + 1))
    fi
  else
    echo "  ✗ Initialization failed"
    FAILED=$((FAILED + 1))
  fi
  
  echo ""
done

if [ $FAILED -eq 0 ]; then
  echo "========================================="
  echo "✓ All environments validated successfully!"
  echo "========================================="
  exit 0
else
  echo "========================================="
  echo "✗ $FAILED environment(s) failed validation"
  echo "========================================="
  exit 1
fi
