# Ch06 — Enterprise & Organization 101 — Delivery Assurance

This is a concise review overlay. Apply the [Delivery Assurance Standard](../../../DELIVERY_ASSURANCE.md); the paired `README.md` is the canonical source for tasks, evidence, commands, and Definition of Done.

## Assurance record

- **Authorized scope:** record the customer target and approving owner.
- **Evidence:** inspect the completed Definition of Done in `README.md`; link or attach the evidence.
- **Open risk:** record the unresolved risk and accountable owner, or `none`.
- **Next decision:** record the handover, pilot, rollout, cutover, or follow-up action with owner and date.

## Session-specific reviewer focus

- **Governance register:** Confirm the customer team initialized the register from the template (docs/GOVERNANCE-SETTINGS-REGISTER.md or equivalent). Verify rows for all settings from Parts A–E; Evidence column links real artifacts (policy doc, API snapshots, screenshots).
- **API verification:** Every setting in the Definition of Done must be verifiable via `gh api /orgs/<org> --jq ...` command, not UI screenshots. Spot-check 3–5 settings; re-run the jq filter yourself.
- **Customer-owned baseline:** Confirm `POLICY.md` or equivalent is stored in a customer-owned location (real repo, not sample). Rationale one-liners must be specific to customer risk posture, not generic ("reduces attack surface" → "blocks external fork-to-public per security team request").
- **Scope clarity:** If using sample repos, confirm handover plan states the org and timeline to move validated settings to customer production org. If using real org, confirm org owner approved the baseline and assigned ongoing ownership.
