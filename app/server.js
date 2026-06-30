const express = require("express");
const helmet = require("helmet");
const client = require("prom-client");

const app = express();
const PORT = process.env.PORT || 3000;

client.collectDefaultMetrics();

const appRequestsTotal = new client.Counter({
  name: "app_requests_total",
  help: "Total number of HTTP requests",
  labelNames: ["method", "route", "status_code"],
});

const appErrorsTotal = new client.Counter({
  name: "app_errors_total",
  help: "Total number of application errors",
  labelNames: ["route"],
});

function logEntry({ level, method, path, statusCode, message }) {
  const entry = {
    timestamp: new Date().toISOString(),
    level,
    method,
    path,
    statusCode,
    message,
  };
  console.log(JSON.stringify(entry));
}

function recordRequest(method, route, statusCode) {
  appRequestsTotal.inc({
    method,
    route,
    status_code: String(statusCode),
  });
}

function recordError(route, message) {
  appErrorsTotal.inc({ route });
  logEntry({
    level: "error",
    method: "GET",
    path: route,
    statusCode: 500,
    message,
  });
}

app.use(
  helmet({
    contentSecurityPolicy: false,
  })
);

app.use((req, res, next) => {
  const start = Date.now();

  res.on("finish", () => {
    const route = req.route ? req.route.path : req.path;
    recordRequest(req.method, route, res.statusCode);
    logEntry({
      level: res.statusCode >= 500 ? "error" : "info",
      method: req.method,
      path: req.path,
      statusCode: res.statusCode,
      message: `${req.method} ${req.path} ${res.statusCode} ${Date.now() - start}ms`,
    });
  });

  next();
});

app.get("/", (_req, res) => {
  res.type("html").send(`<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>DevOps Observability Lab</title>
  <style>
    body { font-family: system-ui, sans-serif; max-width: 640px; margin: 2rem auto; line-height: 1.6; }
    h1 { color: #1a1a2e; }
    a { color: #0066cc; }
    code { background: #f4f4f4; padding: 2px 6px; border-radius: 3px; }
  </style>
</head>
<body>
  <h1>DevOps Observability Lab</h1>
  <p>A small Express app wired into Prometheus, Grafana, and Loki.</p>
  <h2>Endpoints</h2>
  <ul>
    <li><a href="/health">/health</a> — health check (JSON)</li>
    <li><a href="/metrics">/metrics</a> — Prometheus metrics</li>
    <li><a href="/error">/error</a> — simulate a single error</li>
    <li><a href="/simulate-errors">/simulate-errors</a> — simulate 10 errors (triggers alert)</li>
  </ul>
  <h2>Observability stack</h2>
  <p>Metrics go to Prometheus. Logs go to Loki via Promtail. Grafana visualizes both.</p>
</body>
</html>`);
});

app.get("/health", (_req, res) => {
  res.json({ status: "ok", service: "observability-lab" });
});

app.get("/metrics", async (_req, res) => {
  res.set("Content-Type", client.register.contentType);
  res.end(await client.register.metrics());
});

app.get("/error", (_req, res) => {
  recordError("/error", "Simulated application error");
  res.status(500).json({ error: "Simulated application error" });
});

app.get("/simulate-errors", (_req, res) => {
  const count = 10;
  for (let i = 0; i < count; i++) {
    recordError("/simulate-errors", `Simulated error ${i + 1} of ${count}`);
  }
  res.json({
    message: `Simulated ${count} errors. Check Prometheus alerts and Grafana dashboards.`,
    errorsSimulated: count,
  });
});

if (require.main === module) {
  app.listen(PORT, () => {
    console.log(
      JSON.stringify({
        timestamp: new Date().toISOString(),
        level: "info",
        message: `Server listening on port ${PORT}`,
      })
    );
  });
}

module.exports = app;
