# Coach Guide: Challenge 06 — Respond with Azure SRE Agent

### Expected Outcome

Teams use incident evidence and source-code context to produce an investigation plan, likely cause, remediation issue or pull request, and human review path. They also evaluate whether earlier repo instrumentation improved incident response.

## Grounding conversation (you will be called)

Students are **expected to call you** to talk through this challenge's real-world impact before they consider it done. This is a required completion step, not optional — it is how we keep the learning grounded in their actual day-to-day work.

**Their question:** Coach conversation — in your last real incident, how long did it take to connect a production symptom to a specific commit or file, and which instrumentation artifact (logs, deployment SHA, PR link, or decision note) was missing or hardest to find? Talk it through with your coach and connect it to a real project, task, or workflow you own.

Use these follow-ups to steer the conversation:
- Ask them to describe a real incident or on-call page they personally handled — what was the first signal, and how did they get from that signal to a suspected file or commit?
- Ask what single artifact, if it had existed, would have cut their investigation time in half — and why it was not there.
- Ask them to commit to one specific instrumentation improvement (a decision note, a deployment SHA in the alert, a PR link in the runbook) they will add to their service before their next on-call rotation.

### Strong Evidence

- Investigation starts from symptom, timestamp, deployment SHA, affected flow, and any available [Azure Monitor alert](https://learn.microsoft.com/en-us/azure/azure-monitor/alerts/alerts-overview) context.
- To-Do plan separates completed checks from open questions.
- Likely cause references file, line, commit, or pull request evidence where available.
- Remediation returns to GitHub as an issue or pull request.
- Incident summary is customer-safe and avoids unsupported claims.
- Investigation references useful prior artifacts: issue, PR, deployment run, gate map, decision note, or instructions.

### Common Gaps

- Team jumps directly to a fix without evidence.
- Source-code references are treated as proof without validation against logs, metrics, or [Application Insights traces](https://learn.microsoft.com/en-us/azure/azure-monitor/app/distributed-trace-data).
- Incident notes include sensitive information.
- Remediation bypasses review because an agent suggested it.
- The team cannot identify which missing context primitive would have improved the investigation.

### Coach Hint

Ask: What evidence would change your mind about the likely cause?
Ask: Which artifact should be updated so the next incident is easier to investigate?

## Final Demo Pattern

Each team should show:

1. Issue-to-PR evidence from the SDLC baseline.
2. One Copilot or agent-assisted artifact and how humans validated it.
3. Deployment evidence or fallback packet.
4. Starter instrumentation: instruction, persona, reusable prompt or workflow spec, and decision note.
5. Incident investigation chain from signal to source context to GitHub remediation.
6. One adoption practice they would take back to their real team.
