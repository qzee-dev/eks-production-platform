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
  
  if cd "terraform/environments/${ENV}" 2>/dev/null; then
    if terraform validate > /dev/null 2>&1; then
      echo "  ✓ Validation passed"
    else
      echo "  ✗ Validation failed"
      FAILED=$((FAILED + 1))
    fi
    cd - > /dev/null
  else
    echo "  ✗ Environment directory not found"
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
