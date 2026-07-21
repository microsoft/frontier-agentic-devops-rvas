# Ch09 — Audit Log & Streaming — Delivery Assurance

This is a concise review overlay. Apply the [Delivery Assurance Standard](../../../DELIVERY_ASSURANCE.md); the paired `README.md` is the canonical source for tasks, evidence, commands, and Definition of Done.

## Assurance record

- **Authorized scope:** record the customer target and approving owner.
- **Evidence:** inspect the completed Definition of Done in `README.md`; link or attach the evidence.
- **Open risk:** record the unresolved risk and accountable owner, or `none`.
- **Next decision:** record the handover, pilot, rollout, cutover, or follow-up action with owner and date.

## Session-specific reviewer focus

- Customer adoption outcome: the customer implementation owner treats the org audit log as the authoritative record — reads standard events, configures streaming for long-term retention, and verifies audit capture accuracy.
- **Governance register rows:** Confirm two register rows added: (1) audit log retention & streaming (retention policy, streaming target/SIEM endpoint configured, export script committed) with API snapshot links; (2) standard event capture (all events enabled by default, sample filters like `action:team.add_member` documented). Both rows use `approved pilot` or `inspect-and-propose` depending on streaming scope (org-scoped).
- Implementation risks to verify: ask "what exact action: string did the docs say a team-to-repo grant emits?" (→ `team.add_member` or `team_repository.added`) and "how would you reconstruct yesterday's changes?" (→ `created:>=<yesterday>` filter).
- Delivery lead prompts: ask "what's lost if retention expires?" (→ forensics window closes; what's the compliance baseline?).
