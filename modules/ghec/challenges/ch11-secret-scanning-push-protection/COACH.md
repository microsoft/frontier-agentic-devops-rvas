# Ch11 — Secret Scanning & Push Protection — Delivery Assurance

This is a concise review overlay. Apply the [Delivery Assurance Standard](../../../DELIVERY_ASSURANCE.md); the paired `README.md` is the canonical source for tasks, evidence, commands, and Definition of Done.

## Assurance record

- **Authorized scope:** record the customer target and approving owner.
- **Evidence:** inspect the completed Definition of Done in `README.md`; link or attach the evidence.
- **Open risk:** record the unresolved risk and accountable owner, or `none`.
- **Next decision:** record the handover, pilot, rollout, cutover, or follow-up action with owner and date.

## Session-specific reviewer focus

- Customer adoption outcome: the customer implementation owner surfaces and triages every leaked credential in a repo's history, then proves push protection stops the next secret...
- Implementation risks to verify:
- Delivery lead prompts: ask "what makes a secret detectable by a partner — what shape does GitHub recognize?" (→ provider prefixes like AKIA/ghp), and "where does the block...
