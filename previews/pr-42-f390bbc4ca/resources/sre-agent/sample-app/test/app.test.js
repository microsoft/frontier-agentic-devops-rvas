import { describe, it } from "node:test";
import assert from "node:assert/strict";
import http from "node:http";
import { createApp } from "../src/app.js";

async function request(app, path) {
  const server = http.createServer(app);
  await new Promise((resolve) => server.listen(0, resolve));
  const port = server.address().port;

  try {
    const response = await fetch(`http://127.0.0.1:${port}${path}`, {
      headers: {
        "x-request-id": "test-request"
      }
    });
    const body = await response.json();
    return { status: response.status, body };
  } finally {
    await new Promise((resolve) => server.close(resolve));
  }
}

describe("sample app", () => {
  it("returns a healthy status by default", async () => {
    const response = await request(createApp({ incidentMode: "" }), "/healthz");

    assert.equal(response.status, 200);
    assert.equal(response.body.ok, true);
    assert.equal(response.body.status, "healthy");
  });

  it("returns a successful checkout by default", async () => {
    const response = await request(createApp({ incidentMode: "" }), "/api/checkout");

    assert.equal(response.status, 200);
    assert.equal(response.body.ok, true);
    assert.equal(response.body.service, "checkout");
  });

  it("reports degraded health during checkout latency incident", async () => {
    const response = await request(createApp({ incidentMode: "checkout_latency" }), "/healthz");

    assert.equal(response.status, 503);
    assert.equal(response.body.status, "degraded");
    assert.equal(response.body.incidentMode, "checkout_latency");
  });

  it("returns realistic failure evidence during checkout error incident", async () => {
    const response = await request(createApp({ incidentMode: "checkout_error" }), "/api/checkout");

    assert.equal(response.status, 500);
    assert.equal(response.body.ok, false);
    assert.equal(response.body.error, "payment_configuration_missing");
  });
});
