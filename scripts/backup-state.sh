#!/usr/bin/env bash
# Backup Terraform state files for all environments
# Creates timestamped backups of each environment's state

set -euo pipefail

BACKUP_TIMESTAMP=$(date +%Y-%m-%d-%H%M%S)
BACKUP_DIR="./state-backups/${BACKUP_TIMESTAMP}"

mkdir -p "$BACKUP_DIR"

echo "========================================="
echo "Backing Up Terraform State Files"
echo "Backup Directory: $BACKUP_DIR"
echo "========================================="
echo ""

for ENV in dev staging production; do
  BUCKET="myapp-terraform-state-${ENV}"
  STATE_FILE="eks/${ENV}/terraform.tfstate"
  BACKUP_FILE="${BACKUP_DIR}/terraform-${ENV}.tfstate"
  
  echo "[${ENV}] Backing up state..."
  
  if aws s3 cp "s3://${BUCKET}/${STATE_FILE}" "$BACKUP_FILE" 2>/dev/null; then
    echo "  ✓ Backup saved to: $BACKUP_FILE"
  else
    echo "  ✗ Failed to backup $ENV state"
  fi
  
  echo ""
done

echo "========================================="
echo "✓ Backup Complete!"
echo "========================================="
echo ""
echo "Backup Location: $BACKUP_DIR"
echo ""
echo "To restore a state file:"
echo "  aws s3 cp $BACKUP_DIR/terraform-[env].tfstate s3://myapp-terraform-state-[env]/eks/[env]/terraform.tfstate"
echo ""
