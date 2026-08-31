# Ch02 — Branches, Pull Requests & Code Review — Delivery Assurance

Use this review overlay with the [Delivery Assurance Standard](../../../DELIVERY_ASSURANCE.md). The paired `README.md` defines the tasks, evidence, commands, and Definition of Done.

## Assurance record

- **Authorized scope:** record the customer target and approving owner.
- **Evidence:** inspect the completed Definition of Done in `README.md`; link or attach the evidence.
- **Open risk:** record the unresolved risk and accountable owner, or `none`.
- **Next decision:** record the handover, pilot, rollout, cutover, or follow-up action with owner and date.

## Session-specific reviewer focus

- Expected outcome: the customer owner establishes a review culture with feature branches, required code-owner review, conflict resolution, and a documented merge strategy.
- Check that branch rules require reviews and code-owner approval. The team must also explain the history produced by each merge strategy.
- Ask "who must look at this code before it ships?" (→ CODEOWNERS), and "what does the history look like after each merge type?" (→ git log --graph).
