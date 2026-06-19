# Challenge 06: Respond with Azure SRE Agent

## Scenario

Shortly after deployment, support reports elevated failures in Contoso Claims. The team has deployment evidence, source code history, and recent pull requests. Now operations needs a focused investigation that connects production symptoms to likely code causes and drives a fix back through GitHub.

Your mission is to use Azure SRE Agent practices to investigate the incident, connect source-code context, create a To-Do style investigation plan, identify likely cause, and produce a reviewed remediation path.

Use the agentic SDLC evidence you created earlier. The issue, pull request, deployment run, gate map, instructions, decision notes, and workflow specs are part of the investigation context.

## Goals

- Start from incident evidence rather than a guessed code change.
- Connect source-code context so investigation can reference repositories and files.
- Build a concise investigation plan with clear next steps.
- Correlate symptoms, deployment evidence, and likely code causes.
- Drive remediation back into GitHub as an issue or pull request for human review.
- Show how repo instrumentation helped or failed during incident response.

## Estimated Time

60 minutes.

## Source Context

Azure SRE Agent capabilities may vary by environment and availability. The curriculum uses the following source-aligned concepts:

- [`microsoft/sre-agent`](https://github.com/microsoft/sre-agent) is the community hub for Azure SRE Agent labs and resources.
- Azure SRE Agent can connect source code so investigations can analyze repositories, provide file and line references, create To-Do investigation plans, correlate production symptoms to code changes, and create pull requests in review or autonomous modes when source branches exist.
- [`Azure/sre-agent-plugins`](https://github.com/Azure/sre-agent-plugins) contains official plugin examples and marketplace structure, with plugins under [`plugins/`](https://github.com/Azure/sre-agent-plugins/tree/main/plugins) and marketplace registration in `.github/plugin/marketplace.json`.
- If live access is not available, coaches provide a simulated incident packet and source-code evidence so teams can still practice the reasoning flow.

## Tasks

1. Review the incident packet: symptom, timestamp, affected endpoint or workflow, deployment evidence, and recent change history.
2. If live Azure SRE Agent access is available, connect or confirm source-code context for the workshop repository according to coach instructions.
3. Ask the agent or use the simulation packet to build a To-Do investigation plan.
4. Inspect correlated evidence: deployment SHA, recent pull requests, relevant logs or metrics such as [Azure Monitor alerts](https://learn.microsoft.com/en-us/azure/azure-monitor/alerts/alerts-overview), and file/line references when available.
5. Check whether your Challenge 03 instrumentation and Challenge 04 gate map gave the investigation useful context. If not, write down the missing primitive.
6. Identify the most likely code cause and at least one alternative hypothesis.
7. Create a GitHub issue that captures customer-safe incident summary, evidence, likely cause, validation plan, remediation owner, and human review gate.
8. If live capability and source branches are available, review any generated pull request in review/autonomous mode. Otherwise, use the coach-provided simulated pull request or draft a remediation plan.
9. Close with a short incident learning note: what would prevent, detect, or reduce time to recover next time, and which context artifact should be improved.

## Success Criteria

- The investigation starts from incident evidence and deployment context.
- The team produces a To-Do style investigation plan with completed and open items.
- Source-code context is connected live or represented through the simulation packet.
- The likely cause references specific files, lines, commits, or pull requests when evidence supports it.
- A GitHub issue or pull request carries the remediation back into the SDLC.
- A human review decision is required before any fix is treated as production-ready.
- The team identifies at least one instrumentation artifact that helped the response, or one missing artifact to add after the incident.
- Coach conversation — in your last real incident, how long did it take to connect a production symptom to a specific commit or file, and which instrumentation artifact (logs, deployment SHA, PR link, or decision note) was missing or hardest to find? Talk it through with your coach and connect it to a real project, task, or workflow you own.

## Hints

- Do not jump from symptom to fix. Write down the evidence chain; application telemetry such as [Application Insights distributed traces](https://learn.microsoft.com/en-us/azure/azure-monitor/app/distributed-trace-data) is evidence, not decoration.
- A file/line reference is a lead, not proof. Validate it against logs, tests, and recent changes.
- Keep incident notes customer-safe: avoid secrets, personal data, and unsupported claims.
- If the agent creates a pull request, review it with the same rigor as Challenge 05.
- If live Azure SRE Agent access is unavailable, focus on the investigation shape and decision quality.
- Use the ADAPT loop: Audit evidence, Plan the investigation, Wave through scoped actions, Validate hypotheses, Ship remediation only after review.

## Coach Validation Checkpoints

- Ask the team to show the incident evidence they started from.
- Confirm the investigation plan separates completed checks from remaining questions.
- Inspect whether source-code references are tied to evidence rather than speculation.
- Check that remediation returns to GitHub as an issue or pull request.
- Ask which earlier artifact saved time during response, and which missing artifact caused friction.
- Ask who must review the fix before merge and what validation would prove recovery.
- Verify the team uses preview/fallback language when describing capabilities not available live.

## Deliverables

- Incident investigation note with evidence, timeline, hypotheses, and next actions.
- GitHub issue or reviewed pull request for remediation.
- Customer-safe incident summary.
- Operational learning note for future prevention, detection, or recovery improvement.
- Instrumentation improvement note for the repo's instructions, prompts, workflow specs, or memory/decision artifacts.
