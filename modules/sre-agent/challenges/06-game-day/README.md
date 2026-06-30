# Challenge 06: Run the Azure SRE Agent Game Day

## Scenario

This is the end-to-end Azure SRE Agent demo. Your team will run a controlled game day from operational signal to investigation, remediation work, recovery proof, and post-incident improvement.

The hero of the flow is Azure SRE Agent. GitHub is used only where it helps track source-aware remediation.

## Goals

- Start from user impact and Azure alert evidence.
- Use Azure SRE Agent to investigate with telemetry, runbooks, source context, and memory.
- Produce a defensible incident timeline.
- Create or review remediation work.
- Prove recovery.
- Identify one improvement before allowing more autonomy.

## Estimated Time

75 minutes.

## Run the Game Day

Choose one path:

| Path | Starting point |
| --- | --- |
| Live | Trigger `bash scripts/break-app.sh` in the official starter lab |
| Shared coach lab | Coach triggers the incident and shares the portal/resources |
| Fallback | Use the provided incident packet, logs, agent transcript, and source references |

## Response Flow

1. **Declare the incident.** Name the user-visible symptom and start time.
2. **Inspect Azure signal.** Capture alert, affected resource, and first telemetry source.
3. **Ask Azure SRE Agent to investigate.** Require evidence, likely cause, alternatives, unknowns, and mitigation.
4. **Validate claims.** Check logs, traces, metrics, runbooks, source references, and resource state.
5. **Create remediation work.** Issue, draft PR, runbook update, response-plan change, or monitoring improvement.
6. **Recover.** Apply lab-safe mitigation or follow the coach recovery path.
7. **Prove recovery.** Show endpoint, browser, metric, or alert-resolution evidence.
8. **Improve the system.** Add one follow-up that makes the next incident easier.

## Incident Timeline Template

```md
## Timeline
- T0:
- Detection:
- Investigation started:
- Likely cause identified:
- Mitigation chosen:
- Recovery verified:

## Evidence
- Alert:
- Log/metric/trace:
- Runbook or knowledge:
- Source-code context:
- Human validation:

## Decision
- Action taken:
- Why it was safe:
- What remains uncertain:

## Follow-up
- Monitoring:
- Runbook:
- Source context:
- Response plan or hook:
- Approval policy:
```

## Customer-Safe Summary

Write a short summary that could be shared outside the incident room:

```md
We observed <impact> affecting <scope>. Azure SRE Agent reviewed <signals> and identified <likely cause> with <confidence/evidence>. The team validated <checks>, applied <mitigation>, and confirmed recovery with <evidence>. Follow-up work is tracked in <issue/PR/runbook>.
```

Remove secrets, tenant identifiers, personal data, and unsupported claims.

## Deliverables

- Incident timeline.
- Azure SRE Agent investigation evidence.
- Remediation work item or reviewed PR.
- Recovery evidence.
- Customer-safe summary.
- One autonomy-readiness improvement.

## Success Criteria

- The response starts with Azure operational evidence.
- Azure SRE Agent output is validated against inspectable evidence.
- Remediation is governed through a human review point.
- Recovery is proven.
- The team can explain what must change before allowing autonomous action on a real service.
