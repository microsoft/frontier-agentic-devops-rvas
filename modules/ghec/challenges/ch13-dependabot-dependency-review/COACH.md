# Ch13 — Dependabot & Dependency Review — Delivery Assurance

This is a concise review overlay. Apply the [Delivery Assurance Standard](../../../DELIVERY_ASSURANCE.md); the paired `README.md` is the canonical source for tasks, evidence, commands, and Definition of Done.

## Assurance record

- **Authorized scope:** record the customer target and approving owner.
- **Evidence:** inspect the completed Definition of Done in `README.md`; link or attach the evidence.
- **Open risk:** record the unresolved risk and accountable owner, or `none`.
- **Next decision:** record the handover, pilot, rollout, cutover, or follow-up action with owner and date.

## Session-specific reviewer focus

- Customer adoption outcome: the customer implementation owner turns a vulnerable dependency tree into a managed supply chain — alerts triaged, security PRs merged, scheduled...
- Implementation risks to verify:
- Delivery lead prompts: ask "which Dependabot feature opens a PR, and which just notifies?" and "where does dependency review run — on the alert list or on the PR diff?"
