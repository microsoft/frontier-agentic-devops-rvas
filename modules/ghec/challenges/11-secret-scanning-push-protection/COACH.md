# Ch11 — Secret Scanning & Push Protection — Delivery Assurance

Use this review overlay with the [Delivery Assurance Standard](../../../DELIVERY_ASSURANCE.md). The paired `README.md` defines the tasks, evidence, commands, and Definition of Done.

## Assurance record

- **Authorized scope:** record the customer target and approving owner.
- **Evidence:** inspect the completed Definition of Done in `README.md`; link or attach the evidence.
- **Open risk:** record the unresolved risk and accountable owner, or `none`.
- **Next decision:** record the handover, pilot, rollout, cutover, or follow-up action with owner and date.

## Session-specific reviewer focus

- Expected outcome: the customer owner triages leaked credentials in repository history, enables push protection, and adds patterns for internal secrets.
- Confirm secret scanning and push protection are enabled through the settings API, then inspect the triage, custom-pattern, block, and bypass evidence.
- Ask "what makes a secret detectable by a partner?" (→ provider prefixes such as `AKIA` and `ghp_`) and "where does the block happen?" (→ before the push completes).
- Ask "what's the false-positive risk of custom patterns?" (→ a broad pattern catches valid strings) and "what friction does default push protection create for the team?"
