# Sample App

This tiny Node.js service anchors the delivery session story: participants can make an AI-assisted code change, validate it locally, ship it through CI/CD, and then investigate a simulated checkout incident during the SRE activity. It has no runtime dependencies and uses Node's built-in test runner so it works cleanly on a laptop, in Codespaces, or in CI.

## Run Locally

```bash
cd modules/sre-agent/resources/sample-app
npm install
npm start
```

Open `http://localhost:3000/healthz` or `http://localhost:3000/api/checkout`.

## Test

```bash
cd modules/sre-agent/resources/sample-app
npm test
```

## Incident Mode

The controlled incident activity can simulate a production symptom by setting `INCIDENT_MODE` before starting the service:

```bash
INCIDENT_MODE=checkout_latency npm start
```

Supported modes:

| Mode | Symptom |
| --- | --- |
| unset | Healthy service. |
| `checkout_latency` | `/api/checkout` returns HTTP 503 after a short delay and `/healthz` reports degraded status. |
| `checkout_error` | `/api/checkout` immediately returns HTTP 500 and `/healthz` reports degraded status. |

## SRE Agent Note

Azure SRE Agent access is not required for the local simulation. If Azure SRE Agent is available, coaches can connect the deployed app and repository source branch so the agent can correlate symptoms to code and propose a To-Do Plan. Pull request creation should be treated as optional and depends on repository connection, run mode, and an existing branch with committed changes.

[Back to resources](../README.md)
