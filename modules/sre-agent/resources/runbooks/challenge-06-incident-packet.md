# Challenge 06 Incident Packet: Checkout Failure

## Situation

At 15:22 UTC, synthetic monitoring began reporting elevated failures on the checkout path after a deployment. Customers can browse the site, but checkout intermittently fails or exceeds the response-time budget.

## Starting Evidence

| Signal | Value |
| --- | --- |
| Service | `frontier-sample-app` |
| Endpoint | `/api/checkout` |
| Health endpoint | `/healthz` |
| Observed status | HTTP 500 or HTTP 503 depending on incident mode |
| First detected | 15:22 UTC |
| Change window | Deployment completed roughly 10 minutes before first alert |
| Customer impact | Checkout attempts fail; browsing remains available |

## Local Reproduction

From the repository root:

```bash
modules/sre-agent/resources/scripts/simulate-checkout-incident.sh checkout_error
```

or:

```bash
modules/sre-agent/resources/scripts/simulate-checkout-incident.sh checkout_latency
```

The script starts the sample service locally, captures health and checkout responses, and writes evidence to `modules/sre-agent/resources/runbooks/generated/`.

## Azure SRE Agent Use

If Azure SRE Agent access is available, connect it to the deployed service, logs, and the GitHub repository source branch. Ask it to:

- Correlate the failing endpoint to source files.
- Produce an investigation To-Do Plan.
- Identify the likely code or configuration cause.
- Draft a remediation pull request only after a human reviews the plan.

If Azure SRE Agent access is unavailable, use the generated evidence and the triage template in this folder. The learning objective is the same: preserve evidence, explain likely cause, and produce a reviewable remediation path.

## Expected Participant Outcome

Teams should finish with a concise incident response summary that includes:

- Customer-safe status.
- Technical symptoms and evidence.
- Likely cause and confidence level.
- Immediate mitigation.
- Follow-up issue or pull request recommendation.
