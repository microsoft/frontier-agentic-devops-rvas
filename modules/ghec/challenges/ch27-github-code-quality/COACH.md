# Ch27 - GitHub Code Quality: Code Health & Coverage — Delivery Assurance

This is a concise review overlay. Apply the [Delivery Assurance Standard](../../../DELIVERY_ASSURANCE.md); the paired `README.md` is the canonical source for tasks, evidence, commands, and Definition of Done.

## Assurance record

- **Authorized scope:** record the customer target and approving owner.
- **Evidence:** inspect the completed Definition of Done in `README.md`; link or attach the evidence.
- **Open risk:** record the unresolved risk and accountable owner, or `none`.
- **Next decision:** record the handover, pilot, rollout, cutover, or follow-up action with owner and date.

## Session-specific reviewer focus

- Keep the product boundary clear
- Product and tenant constraints
- **Control-catalogue evidence:** Using `modules/ghec/resources/GOVERNANCE-CONTROL-CATALOGUE.md`, confirm `QLT-CODE-QUALITY-GATES` is `approved pilot` only after availability and effective-setting inspection, with baseline, coverage, gate, and pilot-decision evidence.
- Threshold and remediation guardrails: ask "what's too strict that would block legitimate code?" (→ coverage % targets, severity thresholds) and "what team budget exists to fix tech-debt alerts?"
