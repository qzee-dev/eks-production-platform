#!/usr/bin/env bash
# Convenience targets for Terraform operations.

set -euo pipefail

TARGET=${1:-help}

case $TARGET in
  help)
    cat << EOF
Terraform EKS Project - Operation Guide

Usage: bash scripts/ops.sh [target]

Environment Setup:
  validate-all       - Validate all environments without using remote state
  format             - Check Terraform formatting

Initial Deployment:
  bash scripts/plan-foundation.sh <env>  - Plan VPC, EKS, and system nodes
  bash scripts/apply-foundation.sh <env> - Apply the reviewed foundation plan

Development:
  init-dev           - Initialize dev from backend.hcl
  plan-dev           - Create a reviewed dev plan
  apply-dev          - Apply the saved dev plan

Staging:
  init-staging       - Initialize staging from backend.hcl
  plan-staging       - Create a reviewed staging plan
  apply-staging      - Apply the saved staging plan

Production:
  init-prod          - Initialize production from backend.hcl
  plan-prod          - Create a reviewed production plan
  apply-prod         - Apply the saved production plan (requires confirmation)

EOF
    ;;

  validate-all)
    bash scripts/validate-all.sh
    ;;

  format)
    terraform fmt -check -recursive terraform/
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

  init-staging)
    bash scripts/init-env.sh staging
    ;;

  plan-staging)
    bash scripts/plan-env.sh staging
    ;;

  apply-staging)
    bash scripts/apply-env.sh staging
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

  *)
    echo "Unknown target: $TARGET"
    echo "Run '$0 help' for available targets"
    exit 1
    ;;
esac
