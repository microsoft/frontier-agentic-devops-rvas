# Coach Guide: Challenge 04 — Deploy to Azure with GitHub Actions

### Expected Outcome

Teams can show validation and deployment flow through GitHub Actions, or use a fallback packet with the same evidence shape. They can explain the deterministic/probabilistic seam in the pipeline.

## Grounding conversation (you will be called)

Students are **expected to call you** to talk through this challenge's real-world impact before they consider it done. This is a required completion step, not optional — it is how we keep the learning grounded in their actual day-to-day work.

**Their question:** Coach conversation — in your real deployment pipeline, where does the deterministic/probabilistic seam sit today: what does automation decide on its own, and what requires a human approval or deterministic gate before reaching production? Talk it through with your coach and connect it to a real project, task, or workflow you own.

Use these follow-ups to steer the conversation:
- Ask them to describe a specific service or pipeline they own — what is the last stage before production, and who (or what) currently owns that gate?
- Ask what the cost would be if a model-suggested workflow change bypassed their current gate: what is the blast radius, and how would they detect it?
- Ask them to identify one gate in their real pipeline they would harden or formalize before their team starts letting Copilot propose workflow changes.

### Strong Evidence

- Workflow stages are understandable.
- Secrets are stored safely and not printed; use GitHub's [Actions security hardening](https://docs.github.com/en/actions/security-for-github-actions/security-guides/security-hardening-for-github-actions) language to coach this point.
- [Environment controls or approvals](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment) are visible when available.
- Deployment evidence includes commit SHA, run link, environment, endpoint, and warnings.
- Gate map identifies tests, schemas, allowlists, permissions, environment approvals, and human checkpoints.

### Common Gaps

- Credentials are copied into files.
- Teams cannot explain workflow stages.
- Deployment succeeds but no evidence is recorded.
- Failed deployment is abandoned instead of turned into a remediation issue.
- Agent-generated workflow suggestions are treated as deployable without gate review.

### Coach Hint

Ask: Which piece of deployment evidence will matter if there is an incident in 30 minutes?
Ask: What can the model propose, and what must the deterministic substrate or a human approve?
