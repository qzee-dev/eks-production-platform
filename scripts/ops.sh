#!/usr/bin/env bash
# Makefile-style targets for Terraform operations
# Provides convenient shortcuts for common tasks

set -euo pipefail

TARGET=${1:-help}

case $TARGET in
  help)
    cat << EOF
Terraform EKS Project - Operation Guide

Usage: make [target]

Environment Setup:
  make bootstrap          - Create S3 buckets and DynamoDB lock tables
  make validate-all       - Validate all environments
  make format             - Format all Terraform files

Development:
  make init-dev           - Initialize dev environment
  make plan-dev           - Plan dev deployment
  make apply-dev          - Apply dev deployment
  make destroy-dev        - Destroy dev environment (destructive!)

Staging:
  make init-staging       - Initialize staging environment
  make plan-staging       - Plan staging deployment
  make apply-staging      - Apply staging deployment
  make destroy-staging    - Destroy staging environment (destructive!)

Production:
  make init-prod          - Initialize production environment
  make plan-prod          - Plan production deployment
  make apply-prod         - Apply production deployment (requires approval)
  make destroy-prod       - Destroy production environment (destructive!)

State Management:
  make backup-state       - Backup all state files
  make state-status       - Show state bucket information

EOF
    ;;
  
  bootstrap)
    bash scripts/bootstrap-state.sh
    ;;
  
  validate-all)
    bash scripts/validate-all.sh
    ;;
  
  format)
    echo "Formatting Terraform files..."
    terraform fmt -recursive terraform/
    echo "✓ Formatting complete"
    ;;
  
  init-dev)
    bash scripts/init-env.sh dev
    ;;
  
  plan-dev)
    bash scripts/plan-env.sh dev
    ;;
  
  apply-dev)
    bash scripts/apply-env.sh dev
    ;;
  
  destroy-dev)
    cd terraform/environments/dev
    terraform destroy -var-file=terraform.tfvars
    ;;
  
  init-staging)
    bash scripts/init-env.sh staging
    ;;
  
  plan-staging)
    bash scripts/plan-env.sh staging
    ;;
  
  apply-staging)
    bash scripts/apply-env.sh staging
    ;;
  
  destroy-staging)
    cd terraform/environments/staging
    terraform destroy -var-file=terraform.tfvars
    ;;
  
  init-prod)
    bash scripts/init-env.sh production
    ;;
  
  plan-prod)
    bash scripts/plan-env.sh production
    ;;
  
  apply-prod)
    bash scripts/apply-env.sh production
    ;;
  
  destroy-prod)
    cd terraform/environments/production
    terraform destroy -var-file=terraform.tfvars
    ;;
  
  backup-state)
    bash scripts/backup-state.sh
    ;;
  
  state-status)
    echo "State Bucket Information:"
    for ENV in dev staging production; do
      BUCKET="myapp-terraform-state-${ENV}"
      echo ""
      echo "[$ENV] Bucket: $BUCKET"
      aws s3api head-bucket --bucket "$BUCKET" 2>/dev/null && echo "  ✓ Exists" || echo "  ✗ Not found"
      
      LOCK_TABLE="myapp-terraform-state-${ENV}-lock"
      aws dynamodb describe-table --table-name "$LOCK_TABLE" --region us-east-1 2>/dev/null && echo "  ✓ Lock table exists" || echo "  ✗ Lock table not found"
    done
    ;;
  
  *)
    echo "Unknown target: $TARGET"
    echo "Run '$0 help' for available targets"
    exit 1
    ;;
esac
