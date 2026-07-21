# Ch11 — Secret Scanning & Push Protection — Delivery Assurance

This is a concise review overlay. Apply the [Delivery Assurance Standard](../../../DELIVERY_ASSURANCE.md); the paired `README.md` is the canonical source for tasks, evidence, commands, and Definition of Done.

## Assurance record

- **Authorized scope:** record the customer target and approving owner.
- **Evidence:** inspect the completed Definition of Done in `README.md`; link or attach the evidence.
- **Open risk:** record the unresolved risk and accountable owner, or `none`.
- **Next decision:** record the handover, pilot, rollout, cutover, or follow-up action with owner and date.

## Session-specific reviewer focus

- Customer adoption outcome: the customer implementation owner surfaces and triages every leaked credential in a repo's history, enables push protection to block future leaks, and customizes detection patterns for company-internal secrets.
- **Control-catalogue evidence:** Using `modules/ghec/resources/GOVERNANCE-CONTROL-CATALOGUE.md`, confirm `SEC-SECRET-SCANNING` and `SEC-PUSH-PROTECTION` are `approved pilot` only after effective-setting inspection, with settings, triage/custom-pattern, and bypass-audit evidence.
- Implementation risks to verify: ask "what makes a secret detectable by a partner — what shape does GitHub recognize?" (→ provider prefixes like AKIA, ghp_, etc.) and "where does the block happen?" (→ pre-commit, before push).
- Delivery lead prompts: ask "what's the false-positive risk of custom patterns?" (→ too broad catches legit strings) and "what's the team adoption friction if push protection is ON by default?"
