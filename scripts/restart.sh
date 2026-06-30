#!/usr/bin/env bash
# Restart only the application container and wait for /health.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

echo "=========================================="
echo " Restarting application container"
echo "=========================================="

if docker compose version >/dev/null 2>&1; then
  COMPOSE_CMD="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
  COMPOSE_CMD="docker-compose"
else
  echo "FAIL: Docker Compose is not available."
  exit 1
fi

echo "Running: $COMPOSE_CMD restart app"
$COMPOSE_CMD restart app

MAX_ATTEMPTS=30
ATTEMPT=1
HEALTH_URL="http://localhost:3000/health"

echo -n "Waiting for $HEALTH_URL"
while [ "$ATTEMPT" -le "$MAX_ATTEMPTS" ]; do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$HEALTH_URL" 2>/dev/null || echo "000")
  if [ "$STATUS" = "200" ]; then
    echo ""
    echo "PASS: App restarted successfully. Health check returned HTTP 200."
    exit 0
  fi
  echo -n "."
  sleep 2
  ATTEMPT=$((ATTEMPT + 1))
done

echo ""
echo "FAIL: App did not return a healthy response after restart."
echo "      Check logs: docker compose logs app"
exit 1
