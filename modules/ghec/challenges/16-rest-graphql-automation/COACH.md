# Ch16 — REST & GraphQL API Automation — Delivery Assurance

Use this review overlay with the [Delivery Assurance Standard](../../../DELIVERY_ASSURANCE.md). The paired `README.md` defines the tasks, evidence, commands, and Definition of Done.

## Assurance record

- **Authorized scope:** record the customer target and approving owner.
- **Evidence:** inspect the completed Definition of Done in `README.md`; link or attach the evidence.
- **Open risk:** record the unresolved risk and accountable owner, or `none`.
- **Next decision:** record the handover, pilot, rollout, cutover, or follow-up action with owner and date.

## Session-specific reviewer focus

- Expected outcome: the customer owner uses REST and GraphQL reads and writes to build an idempotent, rate-limit-aware reconciliation script.
- Check that REST and GraphQL pagination finish, the script respects rate limits, and a second run makes no changes.
- Ask "how do you know you've read every issue?" (compare the count with the total and check `pageInfo.hasNextPage`) and "what happens if you run this twice?" (the reconcile script should make no changes).
