#!/usr/bin/env bash
# Set executable permissions on all scripts

echo "Setting executable permissions on scripts..."

for script in scripts/*.sh; do
  chmod +x "$script"
  echo "✓ $script"
done

echo ""
echo "Scripts are now executable."
echo ""
echo "Quick start:"
echo "  bash scripts/bootstrap-state.sh   # One-time setup"
echo "  bash scripts/init-env.sh dev      # Initialize dev"
echo "  bash scripts/plan-env.sh dev      # Plan dev deployment"
echo "  bash scripts/apply-env.sh dev     # Apply dev deployment"
echo ""
