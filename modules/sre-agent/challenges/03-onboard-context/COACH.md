# Coach Guide: Activity 03 — Onboard Service Context and Response Plans

## Expected Outcome

Teams understand the context Azure SRE Agent will use during an incident: Azure resources, knowledge files, runbooks, custom agents, response plans, and safe team memory.

## Coach Prep

Prepare examples of:

- HTTP errors runbook.
- Grubify architecture knowledge.
- Response plan or incident routing summary.
- Custom agents such as `incident-handler`, `code-analyzer`, and `issue-triager`.
- A safe memory example that does not include personal or sensitive details.

## Strong Evidence

- Team can explain where each context item comes from.
- Agent summarizes architecture or runbook content with connected context.
- Missing context is documented as a follow-up.
- Team memory states roles and gates, not private escalation details.

## Common Gaps

- Treating memory as a place for secrets or personal contact details.
- Accepting vague agent summaries without checking the source.
- Not understanding how alerts route to the agent.
- Confusing custom agents with GitHub coding agents.

## Coach Hints

Ask:

- What context would make the next investigation faster?
- Which runbook step should the agent follow before mitigation?
- What approval is required before restart, scale, or config changes?

## Final Demo Pattern

Teams should show a context map and one agent answer that they validated against a knowledge source or setup screen.
