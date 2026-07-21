# Ch13 — Dependabot & Dependency Review — Delivery Assurance

This is a concise review overlay. Apply the [Delivery Assurance Standard](../../../DELIVERY_ASSURANCE.md); the paired `README.md` is the canonical source for tasks, evidence, commands, and Definition of Done.

## Assurance record

- **Authorized scope:** record the customer target and approving owner.
- **Evidence:** inspect the completed Definition of Done in `README.md`; link or attach the evidence.
- **Open risk:** record the unresolved risk and accountable owner, or `none`.
- **Next decision:** record the handover, pilot, rollout, cutover, or follow-up action with owner and date.

## Session-specific reviewer focus

- Customer adoption outcome: the customer implementation owner turns a vulnerable dependency tree into a managed supply chain — enables Dependabot, triages alerts, auto-merges safe patches, and gates PRs on dependency review.
- **Governance register row:** Confirm one register row added for Dependency scanning & Dependabot (enabled on production repos, auto-merge policy for patch updates, alert triage baseline). Row uses `approved pilot` status with links to alert report, auto-merge workflow runs, and update frequency metrics.
- Implementation risks to verify: ask "which Dependabot feature opens a PR, and which just notifies?" (→ security alerts open PR, version updates notify only) and "where does dependency review run?" (→ on the PR diff, not the alert list).
- Delivery lead prompts: ask "what's the risk of auto-merging without review?" (→ rare bad updates, but catch quickly via test failures) and "how do you handle dependencies a team won't upgrade?"
