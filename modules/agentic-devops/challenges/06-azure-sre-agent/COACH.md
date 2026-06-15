# Coach Guide: Challenge 06 — Respond with Azure SRE Agent

### Expected Outcome

Teams use incident evidence and source-code context to produce an investigation plan, likely cause, remediation issue or pull request, and human review path. They also evaluate whether earlier repo instrumentation improved incident response.

### Strong Evidence

- Investigation starts from symptom, timestamp, deployment SHA, and affected flow.
- To-Do plan separates completed checks from open questions.
- Likely cause references file, line, commit, or pull request evidence where available.
- Remediation returns to GitHub as an issue or pull request.
- Incident summary is customer-safe and avoids unsupported claims.
- Investigation references useful prior artifacts: issue, PR, deployment run, gate map, decision note, or instructions.

### Common Gaps

- Team jumps directly to a fix without evidence.
- Source-code references are treated as proof without validation.
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
