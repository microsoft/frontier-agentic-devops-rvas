# Ch10 — Billing, Cost Centers & Usage — Delivery Assurance

This is a concise review overlay. Apply the [Delivery Assurance Standard](../../../DELIVERY_ASSURANCE.md); the paired `README.md` is the canonical source for tasks, evidence, commands, and Definition of Done.

## Assurance record

- **Authorized scope:** record the customer target and approving owner.
- **Evidence:** inspect the completed Definition of Done in `README.md`; link or attach the evidence.
- **Open risk:** record the unresolved risk and accountable owner, or `none`.
- **Next decision:** record the handover, pilot, rollout, cutover, or follow-up action with owner and date.

## Session-specific reviewer focus

- Customer adoption outcome: the customer implementation owner builds the org's cost-governance baseline — read usage, generate a little real metered usage, wire a budget with alerts.
- **Governance register row:** Confirm one register row added for billing domain: budgets configured (alert thresholds), usage reconciliation (before/after API snapshots), cost-report script committed. Row uses `approved pilot` status and documents owner + review cadence.
- Implementation risks to verify: ask "what's the difference between getting warned at 90% and being stopped at 100%?" and "which runner OS would blow the budget fastest for the same dollar spend?" (→ Windows and macOS cost more per minute than Linux).
- Delivery lead prompts: ask "what attribution gap would surprise the billing owner?" (→ unattributed spend in shared repos / cross-team runners).
