# Ch16 — REST & GraphQL API Automation — Delivery Assurance

This is a concise review overlay. Apply the [Delivery Assurance Standard](../../../DELIVERY_ASSURANCE.md); the paired `README.md` is the canonical source for tasks, evidence, commands, and Definition of Done.

## Assurance record

- **Authorized scope:** record the customer target and approving owner.
- **Evidence:** inspect the completed Definition of Done in `README.md`; link or attach the evidence.
- **Open risk:** record the unresolved risk and accountable owner, or `none`.
- **Next decision:** record the handover, pilot, rollout, cutover, or follow-up action with owner and date.

## Session-specific reviewer focus

- Customer adoption outcome: the customer implementation owner uses REST and GraphQL reads and writes to deliver an idempotent, rate-limit-aware reconciliation script.
- Implementation risks to verify: REST and GraphQL pagination finish completely, the script respects rate limits, and a second run makes no changes.
- Delivery lead prompts: ask "how do you know you've read every issue?" (compare the count with the total and check `pageInfo.hasNextPage`), and "what would happen if you ran this twice in a row?" (the reconcile script should make no changes).
