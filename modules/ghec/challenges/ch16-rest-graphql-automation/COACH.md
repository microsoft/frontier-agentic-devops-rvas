# Ch16 — REST & GraphQL API Automation — Delivery Assurance

This is a concise review overlay. Apply the [Delivery Assurance Standard](../../../DELIVERY_ASSURANCE.md); the paired `README.md` is the canonical source for tasks, evidence, commands, and Definition of Done.

## Assurance record

- **Authorized scope:** record the customer target and approving owner.
- **Evidence:** inspect the completed Definition of Done in `README.md`; link or attach the evidence.
- **Open risk:** record the unresolved risk and accountable owner, or `none`.
- **Next decision:** record the handover, pilot, rollout, cutover, or follow-up action with owner and date.

## Session-specific reviewer focus

- Customer adoption outcome: the customer implementation owner drives GitHub entirely from its APIs — REST and GraphQL reads/writes — and ships an idempotent, rate-limit-aware...
- Implementation risks to verify:
- Delivery lead prompts: ask "how do you know you've read every issue?" (→ count vs total, pageInfo.hasNextPage), and "what would happen if you ran this twice in a row?" (→...
