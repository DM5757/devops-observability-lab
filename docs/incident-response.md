# Incident Response Guide

Use this guide when the observability stack or application is unhealthy during a demo or local testing session.

## Service Availability Objective

| Item | Value |
|------|-------|
| **Target** | 99% local availability during demo/testing |
| **Health endpoint** | `GET /health` → `{"status":"ok","service":"observability-lab"}` |
| **Monitoring interval** | Prometheus scrape interval (15 seconds in `prometheus/prometheus.yml`) |

## 1. App is unhealthy

**Symptoms:** `/health` returns non-200, browser cannot load http://localhost:3000

**Checks:**

```bash
curl -i http://localhost:3000/health
docker compose ps app
docker compose logs --tail=50 app
```

**Fix:** Restart only the app:

```bash
bash scripts/restart.sh
# or
make restart
```

If restart fails, rebuild:

```bash
docker compose up --build -d app
bash scripts/validate.sh
```

## 2. Inspect Docker containers

```bash
docker compose ps
docker compose logs app
docker compose logs prometheus
docker compose logs grafana
docker compose logs loki
docker compose logs promtail
```

All five services should show `Up`. If a container keeps restarting, read its logs first.

## 3. Check Prometheus targets

1. Open http://localhost:9090/targets
2. Confirm `observability-app` job is **UP** and scraping `app:3000/metrics`
3. If **DOWN**, check that the app container is running and reachable on the Docker network

Query metrics manually:

```bash
curl http://localhost:3000/metrics | grep app_requests_total
```

## 4. Check Grafana dashboard

1. Open http://localhost:3001 (login: `admin` / `admin`)
2. Go to **Observability Lab Dashboard**
3. Verify request rate and error panels show data
4. If panels are empty, confirm Prometheus datasource is connected under **Connections → Data sources**

## 5. Check Loki logs

1. In Grafana, open the **Application Logs** panel on the dashboard
2. Or use **Explore** → Loki → query: `{service="observability-app"}`
3. Generate traffic: `curl http://localhost:3000/health`
4. If no logs appear, check Promtail:

```bash
docker compose logs promtail
```

## 6. Alerts firing unexpectedly

1. Open http://localhost:9090/alerts
2. Review `CriticalHighErrorRate` — it fires when `increase(app_errors_total[1m]) > 5`
3. If triggered by `/simulate-errors`, this is expected behavior
4. Wait one minute for the alert to clear if no new errors occur

## 7. Rollback procedure

If a recent change broke the stack:

```bash
git log --oneline
bash scripts/rollback.sh <stable_commit_hash>
```

Then follow the printed commands. Always run `bash scripts/validate.sh` after rollback.

## 8. Full stack reset (last resort)

This stops all containers but does not delete config files:

```bash
docker compose down
bash scripts/setup.sh
bash scripts/validate.sh
```

## Quick reference

| Action | Command |
|--------|---------|
| Validate all endpoints | `bash scripts/validate.sh` |
| Restart app only | `bash scripts/restart.sh` |
| View app logs | `docker compose logs -f app` |
| Rollback guide | `bash scripts/rollback.sh` |
| Simulate errors (test alert) | `curl http://localhost:3000/simulate-errors` |
