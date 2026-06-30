# Coach Guide: Challenge 06 — Run the Azure SRE Agent Game Day

## Expected Outcome

Teams demonstrate the full Azure SRE Agent loop: signal, investigation, evidence validation, remediation work, recovery proof, and one autonomy-readiness improvement.

## Coach Prep

Prepare a complete game-day path:

| Path | Required artifacts |
| --- | --- |
| Live | Healthy lab, break script, portal access, recovery path |
| Shared | Coach-run incident, shared screenshots/transcript, recovery evidence |
| Fallback | Timeline packet, Azure evidence, source context, simulated issue/PR |

Know in advance whether teams may perform mitigation themselves or must describe the action.

## Strong Evidence

- Timeline starts with user impact and Azure alert.
- Agent investigation cites inspectable signals.
- Source context is used only after operational evidence is established.
- Recovery is verified, not assumed.
- Post-incident follow-up improves monitoring, runbook, source context, response plan, hook, or approval policy.

## Common Gaps

- Turning the demo into a GitHub PR exercise.
- Skipping recovery proof.
- Writing a customer summary with sensitive details.
- Claiming autonomous readiness without naming guardrails.

## Coach Hints

Ask:

- What did Azure SRE Agent do that reduced toil?
- What did a human still need to decide?
- What guardrail would you require before autonomous mitigation?

## Final Demo Pattern

Each team should show:

1. Incident timeline.
2. Azure SRE Agent evidence.
3. Remediation work item or reviewed PR.
4. Recovery proof.
5. One improvement before production autonomy.
