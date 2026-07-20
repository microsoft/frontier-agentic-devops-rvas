# Coach Guide: Activity 04 — Investigate a Controlled Azure Incident

## Expected Outcome

Teams intentionally trigger or inspect a controlled Grubify incident, then use Azure SRE Agent to gather evidence from Azure telemetry and runbooks before choosing a mitigation.

## Coach Prep

Have one break path ready:

| Path | Artifacts |
| --- | --- |
| Live | `bash scripts/break-app.sh`, Azure Monitor incident, portal access |
| Shared | Coach-triggered incident and shared agent view |
| Fallback | Alert text, KQL/log excerpt, App Insights exception, transcript |

Prepare a known recovery path so the activity does not stall after investigation.

## Strong Evidence

- Teams capture symptom, start time, affected action, and alert.
- Agent output cites logs, metrics, traces, runbook, or resource state.
- Likely cause, alternatives, and unknowns are separate.
- Mitigation is reviewed before execution.
- Recovery is proven with UI or endpoint evidence.

## Common Gaps

- Jumping straight to source code before confirming Azure symptoms.
- Treating the agent's likely cause as proof.
- Not capturing the first signal.
- Forgetting to recover the lab environment.

## Coach Hints

Ask:

- What evidence would make this hypothesis wrong?
- Which signal is user-impacting and which is supporting evidence?
- What validation proves the mitigation worked?

## Final Demo Pattern

Teams should show an incident note, the agent investigation, one inspectable telemetry artifact, and recovery evidence.
