# DevOps Observability Lab

A hands-on lab for learning observability with a real Docker Compose stack. A small Node.js app exposes metrics and structured logs; Prometheus, Grafana, Loki, and Promtail collect and visualize them.

## Tech Stack

- **App:** Node.js, Express, prom-client
- **Metrics:** Prometheus
- **Dashboards & alerts:** Grafana
- **Logs:** Loki + Promtail
- **Orchestration:** Docker Compose
- **CI:** GitHub Actions

## Architecture

```mermaid
flowchart LR
    User([User / Browser]) --> App[Express App :3000]
    App -->|stdout JSON logs| Docker[Docker Engine]
    App -->|/metrics| Prometheus[Prometheus :9090]
    Docker -->|container logs| Promtail[Promtail]
    Promtail -->|push| Loki[Loki :3100]
    Prometheus --> Grafana[Grafana :3001]
    Loki --> Grafana
```

**How it fits together:**

1. The Express app writes one JSON log line per request to stdout.
2. Docker captures container stdout; Promtail reads those logs and ships them to Loki.
3. Prometheus scrapes `/metrics` from the app every 15 seconds.
4. Grafana connects to both Prometheus and Loki and loads a pre-built dashboard.

## Getting Started

### Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (or Docker Engine + Compose)
- Node.js 20+ (for local development and tests)

### Start the full stack

From the project root:

```bash
docker compose up --build
```

Wait until all five services are running. The app rebuilds on first start.

### Service URLs

| Service    | URL                          |
|------------|------------------------------|
| App        | http://localhost:3000        |
| Prometheus | http://localhost:9090        |
| Grafana    | http://localhost:3001        |
| Loki       | http://localhost:3100        |

**Grafana login:** `admin` / `admin`

### Try it out

1. Open http://localhost:3000 — browse the endpoints listed on the home page.
2. Open Grafana → **Observability Lab Dashboard** — watch request and error metrics update.
3. Trigger a **CRITICAL** alert:
   - Visit http://localhost:3000/simulate-errors (simulates 10 errors at once)
   - In Prometheus: **Alerts** → look for `CriticalHighErrorRate`
   - In Grafana: **Alerting** or the dashboard panels

### Local development (without Docker)

```bash
npm install
npm start        # runs on http://localhost:3000
npm test         # Jest + Supertest
npm run lint     # ESLint
```

## Logging Strategy

Every HTTP request produces exactly one JSON log line on stdout. Errors from `/error` and `/simulate-errors` also emit separate log lines with `"level": "error"`.

Docker stores container stdout. Promtail discovers containers via the Docker socket, reads their log files, parses JSON fields, and pushes labeled log streams to Loki. In Grafana you can filter by `service="observability-app"` or by log level.

### JSON log format

Each line is a single JSON object:

```json
{
  "timestamp": "2026-06-09T12:00:00.000Z",
  "level": "info",
  "method": "GET",
  "path": "/health",
  "statusCode": 200,
  "message": "GET /health 200 2ms"
}
```

This format is easy to parse, search in Loki, and ship to other tools without custom regex.

## Metrics vs Logs

| | Prometheus (metrics) | Loki (logs) |
|---|---------------------|-------------|
| **What** | Aggregated counters and rates | Individual event records |
| **Example** | `app_errors_total`, request rate | Full error message with timestamp |
| **Best for** | Dashboards, alerts, trends | Debugging specific requests |
| **Retention** | Short-to-medium (time-series) | Configurable text retention |

Use **metrics** to know *that* something is wrong. Use **logs** to understand *why*.

## Long-Term Log Retention

Loki is configured with a **7-day retention period** (`168h` in `loki/loki-config.yml`). The compactor runs periodically and deletes chunks older than that.

For production you would typically:

- Increase retention based on compliance needs
- Move old logs to object storage (S3, GCS)
- Use Grafana Cloud or a managed Loki instance for scale

Prometheus metrics retention is separate (default ~15 days in Prometheus itself) and tuned for operational alerting, not audit history.

## Project Layout

```
app/server.js              Express app with metrics and logging
tests/app.test.js          API tests
prometheus/                Prometheus scrape config and alert rules
loki/                      Loki storage and retention config
promtail/                  Log shipping from Docker containers
grafana/                   Datasources, dashboard provisioning
docker-compose.yml         Full observability stack
.github/workflows/ci.yml   Lint and test on push/PR
```

## Screenshots

Add your own screenshots to the `screenshots/` folder:

| File | Description |
|------|-------------|
| `screenshots/grafana-dashboard.png` | Grafana dashboard with request/error panels |
| `screenshots/grafana-logs.png` | Loki log panel in Grafana |
| `screenshots/grafana-alert.png` | CriticalHighErrorRate alert firing |
| `screenshots/docker-compose-running.png` | All services up in Docker |
| `screenshots/ci-success.png` | GitHub Actions CI passing |

## License

MIT
