#!/usr/bin/env bash
# Start the full observability stack and wait for core services to be ready.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

echo "=========================================="
echo " DevOps Observability Lab - Setup"
echo "=========================================="
echo ""

# --- Check Docker ---
echo "[1/5] Checking Docker..."
if ! command -v docker >/dev/null 2>&1; then
  echo "FAIL: Docker is not installed."
  echo "      Install Docker Desktop: https://www.docker.com/products/docker-desktop/"
  exit 1
fi
if ! docker info >/dev/null 2>&1; then
  echo "FAIL: Docker is installed but not running."
  echo "      Start Docker Desktop and try again."
  exit 1
fi
echo "PASS: Docker is installed and running."
echo ""

# --- Check Docker Compose ---
echo "[2/5] Checking Docker Compose..."
if docker compose version >/dev/null 2>&1; then
  COMPOSE_CMD="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
  COMPOSE_CMD="docker-compose"
else
  echo "FAIL: Docker Compose is not available."
  exit 1
fi
echo "PASS: Docker Compose is available ($COMPOSE_CMD)."
echo ""

# --- Start stack ---
echo "[3/5] Starting the full stack (build + detached)..."
$COMPOSE_CMD up --build -d
echo "PASS: docker compose up --build -d completed."
echo ""

# --- Wait for services ---
wait_for_url() {
  local name="$1"
  local url="$2"
  local max_attempts=60
  local attempt=1

  echo -n "      Waiting for $name"
  while [ "$attempt" -le "$max_attempts" ]; do
    if curl -sf "$url" >/dev/null 2>&1; then
      echo " - ready"
      return 0
    fi
    echo -n "."
    sleep 2
    attempt=$((attempt + 1))
  done
  echo ""
  echo "FAIL: $name did not become ready at $url"
  return 1
}

echo "[4/5] Waiting for services to become healthy..."
wait_for_url "App (/health)" "http://localhost:3000/health"
wait_for_url "Prometheus" "http://localhost:9090/-/ready"
wait_for_url "Grafana" "http://localhost:3001/api/health"
echo "PASS: Core services are responding."
echo ""

# --- Success summary ---
echo "[5/5] Setup complete!"
echo ""
echo "=========================================="
echo " Service URLs"
echo "=========================================="
echo "  App:        http://localhost:3000"
echo "  Prometheus: http://localhost:9090"
echo "  Grafana:    http://localhost:3001  (login: admin / admin)"
echo "  Loki:       http://localhost:3100"
echo ""
echo "Next steps:"
echo "  bash scripts/validate.sh   # run health checks"
echo "  make validate              # same, via Makefile"
echo "=========================================="
