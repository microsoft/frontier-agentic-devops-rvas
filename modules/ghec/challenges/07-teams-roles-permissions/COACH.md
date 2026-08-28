# Ch07 — Teams, Roles & Base Permissions — Delivery Assurance

This is a concise review overlay. Apply the [Delivery Assurance Standard](../../../DELIVERY_ASSURANCE.md); the paired `README.md` is the canonical source for tasks, evidence, commands, and Definition of Done.

## Assurance record

- **Authorized scope:** record the customer target and approving owner.
- **Evidence:** inspect the completed Definition of Done in `README.md`; link or attach the evidence.
- **Open risk:** record the unresolved risk and accountable owner, or `none`.
- **Next decision:** record the handover, pilot, rollout, cutover, or follow-up action with owner and date.

## Session-specific reviewer focus

- Customer adoption outcome: the customer implementation owner replaces ad-hoc collaborator adds with a nested team model, grants repo access through teams at the right level, and creates custom roles for specialized access.
- **Governance controls:** Confirm `ORG-TEAM-ACCESS` and `ORG-CUSTOM-ROLES` in the existing register with effective-setting evidence and the selected path.
- Implementation risks to verify: ask "if the parent team has Read and the child team has Write on the same repo, what can a child member do?" (→ Write wins, most-permissive).
- Delivery lead prompts: ask "how would you remove someone from all repos at once?" (→ remove from parent team, inherited removes propagate).
