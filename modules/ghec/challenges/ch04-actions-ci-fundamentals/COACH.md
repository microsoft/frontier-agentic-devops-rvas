# Ch04 — GitHub Actions CI Fundamentals — Delivery Assurance

This is a concise review overlay. Apply the [Delivery Assurance Standard](../../../DELIVERY_ASSURANCE.md); the paired `README.md` is the canonical source for tasks, evidence, commands, and Definition of Done.

## Assurance record

- **Authorized scope:** record the customer target and approving owner.
- **Evidence:** inspect the completed Definition of Done in `README.md`; link or attach the evidence.
- **Open risk:** record the unresolved risk and accountable owner, or `none`.
- **Next decision:** record the handover, pilot, rollout, cutover, or follow-up action with owner and date.

## Session-specific reviewer focus

- Customer adoption outcome: the customer implementation owner builds a real CI pipeline that runs across a matrix, caches deps, publishes artifacts, and — the key outcome —...
- Implementation risks to verify:
- Delivery lead prompts: ask "what exact string does the merge gate look for?" (→ check name), and "what makes the second run faster than the first?" (→ cache hit).
