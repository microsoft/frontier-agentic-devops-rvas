# Ch09 — Audit Log & Streaming — Delivery Assurance

Use this review overlay with the [Delivery Assurance Standard](../../../DELIVERY_ASSURANCE.md). The paired `README.md` defines the tasks, evidence, commands, and Definition of Done.

## Assurance record

- **Authorized scope:** record the customer target and approving owner.
- **Evidence:** inspect the completed Definition of Done in `README.md`; link or attach the evidence.
- **Open risk:** record the unresolved risk and accountable owner, or `none`.
- **Next decision:** record the handover, pilot, rollout, cutover, or follow-up action with owner and date.

## Session-specific reviewer focus

- Expected outcome: the customer owner uses the organization audit log as the source for event searches and evidence exports, then assesses enterprise streaming where it applies.
- Confirm organization audit-log export is distinct from enterprise streaming and IP-address-display settings; any enterprise inspection must cover destination, retention, privacy, investigation needs, and owner evidence.
- Ask "what exact action: string did the docs say a team-to-repo grant emits?" (→ `team.add_member` or `team_repository.added`) and "how would you reconstruct yesterday's changes?" (→ `created:>=<yesterday>` filter).
- Ask "what's lost if retention expires?" (→ the forensic window closes; compare it with the compliance baseline).
