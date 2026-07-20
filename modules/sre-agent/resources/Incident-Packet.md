# Azure SRE Agent Incident Packet Template

Use this packet when live Azure SRE Agent access is not available. Replace placeholders with sanitized workshop-specific values before delivery.

## Incident Summary

- Service: Grubify
- Detected by: Azure Monitor alert, synthetic check, or coach-provided signal
- Start time: `<timestamp>`
- Affected flow: Add to Cart / Grubify API
- Customer impact: `<brief customer-safe impact statement>`
- Current status: Investigating

## Azure Context

- Azure SRE Agent: `<agent name or simulated>`
- Resource group: `<resource group>`
- Region: `<region>`
- Container App: `<name>`
- Log Analytics workspace: `<name>`
- Application Insights resource: `<name>`
- Alert rule: `<name>`

## Observed Signals

| Signal | Evidence |
| --- | --- |
| Alert | `<alert text or screenshot reference>` |
| Error rate | `<metric or simulated value>` |
| Logs | `<sanitized log lines>` |
| Trace/exception | `<sanitized App Insights detail>` |
| User report | `<short summary>` |

## Azure SRE Agent Transcript

Include or link to a sanitized transcript that shows:

- evidence gathered;
- runbook or knowledge used;
- likely cause;
- alternative hypothesis;
- mitigation recommendation;
- validation plan.

## Source-Code Context

Use this section only when source context is part of the exercise.

| Candidate area | Evidence | Confidence |
| --- | --- | --- |
| `<file:line>` | `<why this file is relevant>` | Low/Medium/High |

## Remediation Path

- GitHub issue: `<link or simulated issue>`
- Pull request: `<link or simulated packet>`
- Human reviewer role: `<role>`
- Validation before acceptance: `<endpoint, metric, test, or log check>`

## Customer-Safe Update

```text
We are investigating elevated failures in the Grubify ordering flow. Azure SRE Agent has reviewed the connected operational signals and the team is validating the safest mitigation. Next update by <time>.
```

## Learning Note

`<What should the team improve: monitoring, runbook, source context, response plan, hook, or approval policy?>`
