# Sample app

Use this Node.js service to test an AI-assisted change and deploy it through CI/CD.
It also simulates checkout failures for incident investigation. It has no runtime dependencies.
Tests use Node's built-in runner and can run locally, in Codespaces, or in CI.

## Run locally

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

## Incident mode

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

## SRE Agent access

The local simulation does not require Azure SRE Agent.
If the agent is available, connect the deployed app and repository branch.
The agent can then correlate symptoms to code and propose a To-Do Plan.
Pull request creation is optional. It requires a repository connection, a supported run mode,
and an existing branch with committed changes.

[Back to resources](../README.md)
