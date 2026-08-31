# Ch13 — Dependabot & Dependency Review — Delivery Assurance

Use this review overlay with the [Delivery Assurance Standard](../../../DELIVERY_ASSURANCE.md). The paired `README.md` defines the tasks, evidence, commands, and Definition of Done.

## Assurance record

- **Authorized scope:** record the customer target and approving owner.
- **Evidence:** inspect the completed Definition of Done in `README.md`; link or attach the evidence.
- **Open risk:** record the unresolved risk and accountable owner, or `none`.
- **Next decision:** record the handover, pilot, rollout, cutover, or follow-up action with owner and date.

## Session-specific reviewer focus

- Expected outcome: the customer owner enables Dependabot, triages alerts, merges safe patches, and gates pull requests on dependency review.
- Confirm the dependency graph, Dependabot settings, update workflow, and required dependency-review check through the settings/API, SBOM, PR, and merge-gate evidence.
- Ask "which Dependabot feature opens a PR, and which just notifies?" (→ security alerts open PRs; version updates only notify) and "where does dependency review run?" (→ on the PR diff, not the alert list).
- Ask "what's the risk of auto-merging without review?" (→ a bad update can merge, though tests may catch it) and "how do you handle dependencies a team won't upgrade?"
