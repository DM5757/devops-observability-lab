#!/usr/bin/env bash
# Validate that all observability stack endpoints are reachable.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

FAILURES=0

echo "=========================================="
echo " DevOps Observability Lab - Validation"
echo "=========================================="
echo ""

check_http() {
  local name="$1"
  local url="$2"
  local expected="${3:-200}"

  local status
  status=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")

  if [ "$status" = "$expected" ]; then
    echo "PASS: $name ($url) -> HTTP $status"
  else
    echo "FAIL: $name ($url) -> HTTP $status (expected $expected)"
    FAILURES=$((FAILURES + 1))
  fi
}

check_http "App health" "http://localhost:3000/health" "200"
check_http "App metrics" "http://localhost:3000/metrics" "200"
check_http "Prometheus" "http://localhost:9090/-/ready" "200"
check_http "Grafana" "http://localhost:3001/api/health" "200"
# Loki /ready can return 503 in single-binary mode while the API is still operational.
check_http "Loki" "http://localhost:3100/loki/api/v1/status/buildinfo" "200"

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=========================================="
  echo " RESULT: ALL CHECKS PASSED"
  echo "=========================================="
  exit 0
else
  echo "=========================================="
  echo " RESULT: $FAILURES CHECK(S) FAILED"
  echo "=========================================="
  echo "Tip: run 'bash scripts/setup.sh' or 'docker compose up -d'"
  exit 1
fi
