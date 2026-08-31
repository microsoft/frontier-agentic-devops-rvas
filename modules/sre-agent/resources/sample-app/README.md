# Sample App

This small Node.js service supports the delivery session. Participants can make an AI-assisted change, validate it locally, ship it through CI/CD, and investigate a simulated checkout incident. It has no runtime dependencies, uses Node's built-in test runner, and runs on a laptop, in Codespaces, or in CI.

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

Set `INCIDENT_MODE` before starting the service to simulate a production symptom:

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
