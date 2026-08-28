# Ch02 — Branches, Pull Requests & Code Review — Delivery Assurance

This is a concise review overlay. Apply the [Delivery Assurance Standard](../../../DELIVERY_ASSURANCE.md); the paired `README.md` is the canonical source for tasks, evidence, commands, and Definition of Done.

## Assurance record

- **Authorized scope:** record the customer target and approving owner.
- **Evidence:** inspect the completed Definition of Done in `README.md`; link or attach the evidence.
- **Open risk:** record the unresolved risk and accountable owner, or `none`.
- **Next decision:** record the handover, pilot, rollout, cutover, or follow-up action with owner and date.

## Session-specific reviewer focus

- Customer adoption outcome: the customer implementation owner establishes a review culture with feature branches, required code-owner review, conflict resolution, and a documented merge strategy.
- Implementation risks to verify: branch rules require reviews and code-owner approval, and the team can explain the history produced by each merge strategy.
- Delivery lead prompts: ask "who must look at this code before it ships?" (→ CODEOWNERS), and "what does the history look like after each merge type?" (→ git log --graph).
