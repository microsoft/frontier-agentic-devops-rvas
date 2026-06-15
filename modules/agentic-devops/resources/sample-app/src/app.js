import { randomUUID } from "node:crypto";

const defaultPort = 3000;

function jsonResponse(response, statusCode, body) {
  response.writeHead(statusCode, {
    "content-type": "application/json; charset=utf-8",
    "cache-control": "no-store"
  });
  response.end(JSON.stringify(body));
}

function requestId(request) {
  return request.headers["x-request-id"] || randomUUID();
}

async function handleCheckout(response, incidentMode, id) {
  if (incidentMode === "checkout_latency") {
    await new Promise((resolve) => setTimeout(resolve, 900));
    jsonResponse(response, 503, {
      ok: false,
      requestId: id,
      service: "checkout",
      error: "upstream_inventory_timeout",
      hint: "Inventory dependency exceeded the checkout timeout budget."
    });
    return;
  }

  if (incidentMode === "checkout_error") {
    jsonResponse(response, 500, {
      ok: false,
      requestId: id,
      service: "checkout",
      error: "payment_configuration_missing",
      hint: "Expected PAYMENT_PROVIDER_MODE to be set before deployment."
    });
    return;
  }

  jsonResponse(response, 200, {
    ok: true,
    requestId: id,
    service: "checkout",
    cartTotal: 42.5,
    currency: "USD"
  });
}

export function createApp(options = {}) {
  const incidentMode = options.incidentMode ?? process.env.INCIDENT_MODE ?? "";
  const startedAt = new Date().toISOString();

  return async function app(request, response) {
    const url = new URL(request.url, `http://${request.headers.host ?? `localhost:${defaultPort}`}`);
    const id = requestId(request);

    if (url.pathname === "/healthz") {
      const degraded = incidentMode === "checkout_latency" || incidentMode === "checkout_error";
      jsonResponse(response, degraded ? 503 : 200, {
        ok: !degraded,
        status: degraded ? "degraded" : "healthy",
        incidentMode: incidentMode || "none",
        startedAt,
        requestId: id
      });
      return;
    }

    if (url.pathname === "/api/checkout") {
      await handleCheckout(response, incidentMode, id);
      return;
    }

    jsonResponse(response, 404, {
      ok: false,
      requestId: id,
      error: "not_found",
      routes: ["/healthz", "/api/checkout"]
    });
  };
}
