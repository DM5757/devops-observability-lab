const request = require("supertest");
const app = require("../app/server");

describe("Observability Lab App", () => {
  it("GET /health returns status ok", async () => {
    const res = await request(app).get("/health");
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ status: "ok", service: "observability-lab" });
  });

  it("GET / returns page title", async () => {
    const res = await request(app).get("/");
    expect(res.status).toBe(200);
    expect(res.text).toContain("DevOps Observability Lab");
  });

  it("GET /metrics includes app_requests_total and app_errors_total", async () => {
    const res = await request(app).get("/metrics");
    expect(res.status).toBe(200);
    expect(res.text).toContain("app_requests_total");
    expect(res.text).toContain("app_errors_total");
  });

  it("GET /error returns 500", async () => {
    const res = await request(app).get("/error");
    expect(res.status).toBe(500);
    expect(res.body).toHaveProperty("error");
  });
});
