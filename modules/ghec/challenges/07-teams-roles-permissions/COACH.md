# Ch07 — Teams, Roles & Base Permissions — Delivery Assurance

Use this review overlay with the [Delivery Assurance Standard](../../../DELIVERY_ASSURANCE.md). The paired `README.md` defines the tasks, evidence, commands, and Definition of Done.

## Assurance record

- **Authorized scope:** record the customer target and approving owner.
- **Evidence:** inspect the completed Definition of Done in `README.md`; link or attach the evidence.
- **Open risk:** record the unresolved risk and accountable owner, or `none`.
- **Next decision:** record the handover, pilot, rollout, cutover, or follow-up action with owner and date.

## Session-specific reviewer focus

- Expected outcome: the customer owner replaces ad-hoc collaborator access with a nested team model, grants repository access through teams, and creates custom roles where predefined roles do not fit.
- **Governance controls:** Confirm `ORG-TEAM-ACCESS` and `ORG-CUSTOM-ROLES` in the existing register with effective-setting evidence and the selected path.
- Ask "if the parent team has Read and the child team has Write on the same repo, what can a child member do?" (→ Write wins, most-permissive).
- Ask "how would you remove someone from all repos at once?" (→ remove from parent team, inherited removes propagate).
