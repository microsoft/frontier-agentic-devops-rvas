# Azure SRE Agent incident packet template

Use this packet when live Azure SRE Agent access is unavailable. Replace each placeholder with a sanitized workshop value before delivery.

A simulated issue is practice only. It cannot complete the customer engineering handoff.

## Incident summary

- Service: Grubify
- Detected by: Azure Monitor alert, synthetic check, or organizer-provided signal
- Start time: `<timestamp>`
- Affected flow: Add to Cart / Grubify API
- Customer impact: `<brief customer-safe impact statement>`
- Current status: Investigating
- Investigation start and end times, with elapsed time: `<observed times>`
- Evidence quality: `<which claims were supported, corrected, or unverified>`
- Recovery: `<verified result or not tested, with reason>`

## Azure context

- Azure SRE Agent: `<agent name or simulated>`
- Resource group: `<resource group>`
- Region: `<region>`
- Container App: `<name>`
- Log Analytics workspace: `<name>`
- Application Insights resource: `<name>`
- Alert rule: `<name>`

## Observed signals

| Signal | Evidence |
| --- | --- |
| Alert | `<alert text or screenshot reference>` |
| Error rate | `<metric or simulated value>` |
| Logs | `<sanitized log lines>` |
| Trace/exception | `<sanitized App Insights detail>` |
| User report | `<short summary>` |

## Azure SRE Agent transcript

Include or link to a sanitized transcript with:

- evidence gathered;
- runbook or knowledge used;
- likely cause;
- alternative hypothesis;
- mitigation recommendation;
- validation plan.

## Source-code context

Use this section only when source context is part of the exercise.

| Candidate area | Evidence | Confidence |
| --- | --- | --- |
| `<file:line>` | `<why this file is relevant>` | Low/Medium/High |

## Remediation path

- GitHub issue: `<link or simulated issue>`
- Pull request: `<link or simulated packet>`
- Human reviewer role: `<role>`
- Validation before acceptance: `<endpoint, metric, test, or log check>`

## Customer-safe update

```text
We are investigating increased failures in the Grubify ordering flow. Azure SRE Agent has reviewed the telemetry. The team is checking the proposed mitigation before applying it. We will provide the next update by <time>.
```

## Learning note

`<What should the team improve: monitoring, runbook, source context, response plan, hook, or approval policy?>`
