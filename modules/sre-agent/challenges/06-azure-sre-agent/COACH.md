# Coach Guide: Challenge 06 — Respond with Azure SRE Agent

### Expected Outcome

Teams start from healthy and degraded evidence, produce an investigation plan, connect symptoms to source context, create a remediation issue or reviewed pull request, and show recovery evidence.

## Coach Prep

Have at least one evidence path ready:

| Path | Artifacts |
| --- | --- |
| Live Azure SRE Agent | Connected repo/source branch, deployed app, alert/log access, degraded deployment from Challenge 04 |
| Azure fallback | Healthy and degraded deployment evidence notes, Actions logs, endpoint responses, recent PR/change summary |
| Local fallback | `challenge-06-incident-packet.md`, generated local evidence, triage template, simulated remediation PR or issue |

If teams get stuck on Azure access, switch them to the fallback path quickly. The learning objective is the incident loop, not subscription troubleshooting.

## Grounding conversation

Students are **expected to call you** before they consider this done.

**Their question:** In your last real incident, how long did it take to connect a production symptom to a specific commit or file, and which instrumentation artifact was missing or hardest to find?

Use these follow-ups:

- What was the first signal, and how many tools did you need to open before finding the suspected change?
- Which artifact would have cut the investigation time in half: deployment SHA, PR link, alert context, trace ID, runbook, or decision note?
- What will you add to your service before the next on-call rotation?

### Strong Evidence

- Investigation starts with symptom, timestamp, endpoint, deployment SHA, and healthy/degraded comparison.
- To-Do plan distinguishes completed checks from open questions.
- Azure SRE Agent output, if used, is treated as evidence to verify rather than proof.
- Likely cause references file, line, commit, PR, environment variable, or deployment run only when supported.
- Remediation returns to GitHub with a human review gate.
- Recovery evidence proves `/healthz` and `/api/checkout` are healthy again.
- Team identifies one context primitive to improve for the next incident.

### Common Gaps

- Team jumps directly to changing code without writing the evidence chain.
- The controlled failure is confused with an accidental production outage.
- Agent-created file references are accepted without checking logs or tests.
- Incident notes include secrets, tenant-specific details, or unsupported customer claims.
- Remediation bypasses review because an agent suggested it.

### Coach Hint

Ask: What evidence would change your mind about the likely cause?

Ask: Which artifact should be updated so the next incident is easier to investigate?

## Final Demo Pattern

Each team should show:

1. Issue-to-PR evidence from the SDLC baseline.
2. One Copilot or agent-assisted artifact and how humans validated it.
3. Healthy Azure deployment evidence or fallback packet.
4. Controlled failure evidence.
5. Incident investigation chain from signal to source context to GitHub remediation.
6. Recovery evidence.
7. One adoption practice they would take back to their real team.
