#!/usr/bin/env bash
# Rollback helper — shows safe steps to return to a previous stable version.
# This script does NOT modify files or Git state automatically.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

COMMIT_HASH="${1:-}"

echo "=========================================="
echo " DevOps Observability Lab - Rollback Guide"
echo "=========================================="
echo ""
echo "Rollback means returning to a previous stable Git commit or image version."
echo "This script only prints instructions — it will not change your files."
echo ""

if [ -n "$COMMIT_HASH" ]; then
  echo "Target commit: $COMMIT_HASH"
  echo ""
  echo "Run these commands manually:"
  echo ""
  echo "  git checkout $COMMIT_HASH"
  echo "  docker compose up --build -d"
  echo "  bash scripts/validate.sh"
  echo ""
  echo "To return to your branch afterward:"
  echo "  git checkout -"
  exit 0
fi

echo "Manual rollback steps:"
echo ""
echo "  1. Find a stable commit:"
echo "       git log --oneline"
echo ""
echo "  2. Check out that commit (replace HASH with the real hash):"
echo "       git checkout <stable_commit_hash>"
echo ""
echo "  3. Rebuild and restart the stack:"
echo "       docker compose up --build -d"
echo ""
echo "  4. Validate everything is working:"
echo "       bash scripts/validate.sh"
echo ""
echo "Or pass a commit hash to this script for ready-made commands:"
echo "  bash scripts/rollback.sh abc1234"
echo "=========================================="
