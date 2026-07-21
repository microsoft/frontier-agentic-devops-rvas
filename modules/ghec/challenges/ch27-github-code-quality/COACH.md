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
- **Governance register row:** Confirm one register row added for code quality gates (approved thresholds like min 80% coverage + no new issues, status check configured on merge gate). Row uses `approved pilot` status with links to build reports and quality score baseline.
- Threshold and remediation guardrails: ask "what's too strict that would block legitimate code?" (→ coverage % targets, severity thresholds) and "what team budget exists to fix tech-debt alerts?"
