# Activity 04 triage template

Use the existing incident record when it has these fields. Label sample or packet
work as practice.

## Incident summary

- Incident ID:
- Service: Grubify (replace with your service if needed)
- Detected at:
- Current status:
- Customer impact:
- Investigation start and end times:
- Elapsed investigation time:

## Evidence collected

| Evidence | Location or query | What it shows |
| --- | --- | --- |
| Azure Monitor alert | | |
| Log Analytics result | | |
| Application Insights trace/exception | | |
| Grubify or customer service UI or endpoint check | | |
| Runbook or knowledge reference | | |
| Source-code reference | | |

## Working theory

- Likely cause:
- Confidence: Low / Medium / High
- Why this theory fits:
- Alternative hypothesis:
- What would disprove it:

## Azure SRE Agent notes

- Azure SRE Agent available? Yes / No / Fallback transcript
- Response plan or custom agent used?
- Evidence cited by the agent:
- Unsupported or corrected claims:
- Suggested mitigation:
- Suggested issue or pull request:

## Response plan

- Immediate mitigation:
- Human approval required:
- Validation check:
- Recovery result and timestamp, or not tested with reason:
- Rollback or forward-fix decision:

## Customer-safe update

```text
We are investigating increased failures in the Grubify ordering flow. Browsing remains available. Azure SRE Agent has reviewed the telemetry. The team is checking the proposed mitigation before applying it. We will provide the next update by <time>.
```

## Follow-up actions

| Action | Owner | Due | Tracking link |
| --- | --- | --- | --- |
| | | | |
