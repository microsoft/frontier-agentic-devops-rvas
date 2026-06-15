# Incident Packet Template

Use this packet for Challenge 06 when live incident data or Azure SRE Agent access is not available. Replace placeholders with workshop-specific values before delivery.

## Incident Summary

- **Service:** Contoso Claims
- **Detected by:** Synthetic monitor, support report, or coach-provided signal
- **Start time:** `<timestamp>`
- **Affected flow:** `<endpoint or user workflow>`
- **Customer impact:** `<brief customer-safe impact statement>`
- **Current status:** Investigating

## Deployment Context

- **Last deployment time:** `<timestamp>`
- **Commit SHA:** `<sha>`
- **Pull request:** `<link or number>`
- **GitHub Actions run:** `<link or simulated run id>`
- **Environment:** `<dev/test/prod-sim>`
- **Known deployment warnings:** `<warnings or none>`

## Observed Signals

| Signal | Evidence |
| --- | --- |
| Error rate | `<metric or simulated value>` |
| Latency | `<metric or simulated value>` |
| Logs | `<sample log lines with secrets removed>` |
| User reports | `<short summary>` |
| Recent code changes | `<file, commit, or PR references>` |

## Source-Code Context

Use this section to simulate or record what source-connected investigation provides.

| Candidate Area | Evidence | Confidence |
| --- | --- | --- |
| `<file:line>` | `<why this file is relevant>` | Low/Medium/High |
| `<file:line>` | `<why this file is relevant>` | Low/Medium/High |

## Investigation To-Do Plan

- [ ] Confirm affected endpoint or workflow.
- [ ] Compare incident start time with deployment time.
- [ ] Inspect recent pull requests touching affected files.
- [ ] Review logs for error shape and repeated messages.
- [ ] Identify likely code cause and alternative hypotheses.
- [ ] Create remediation issue or pull request.
- [ ] Define validation required before merge.

## Likely Cause

`<Write the likely cause only after connecting symptoms, deployment evidence, and source-code context.>`

## Alternative Hypotheses

- `<hypothesis 1>`
- `<hypothesis 2>`

## Remediation Path

- **GitHub issue:** `<link>`
- **Pull request:** `<link or simulated packet>`
- **Human reviewer:** `<name or role>`
- **Validation before merge:** `<tests, logs, metrics, or manual checks>`

## Customer-Safe Update

`<Short, factual update. Avoid unsupported claims, secrets, or personal data.>`

## Learning Note

`<What should the team change to prevent, detect, or recover faster next time?>`
