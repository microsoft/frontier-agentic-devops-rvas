# Coach Guide: Challenge 04 — Deploy to Azure with GitHub Actions

### Expected Outcome

Teams can show validation and deployment flow through GitHub Actions, or use a fallback packet with the same evidence shape. They can explain the deterministic/probabilistic seam in the pipeline.

### Strong Evidence

- Workflow stages are understandable.
- Secrets are stored safely and not printed.
- Environment controls or approvals are visible when available.
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
