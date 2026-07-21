# Ch15 — Security Campaigns & Overview — Delivery Assurance

This is a concise review overlay. Apply the [Delivery Assurance Standard](../../../DELIVERY_ASSURANCE.md); the paired `README.md` is the canonical source for tasks, evidence, commands, and Definition of Done.

## Assurance record

- **Authorized scope:** record the customer target and approving owner.
- **Evidence:** inspect the completed Definition of Done in `README.md`; link or attach the evidence.
- **Open risk:** record the unresolved risk and accountable owner, or `none`.
- **Next decision:** record the handover, pilot, rollout, cutover, or follow-up action with owner and date.

## Session-specific reviewer focus

- Customer adoption outcome: the customer implementation owner moves from "we have alerts" to "we run a security program" — measures coverage, prioritizes risky repos, and communicates remediation deadlines.
- **Governance register row:** Confirm one register row added for security program baseline (coverage metrics tracked, risk-prioritized repo list, alert communication cadence). Row uses `approved pilot` status with links to coverage report and risk scoring criteria.
- Implementation risks to verify: ask "what's the difference between a repo being covered and being risky?" (→ covered means scans run, risky means high-severity findings or compliance scope) and "how would a developer know which alerts to fix by when?" (→ labeled by severity + SLA).
- Delivery lead prompts: ask "what repos are you covering first?" (→ customer-prioritized based on risk) and "what's your backlog priority?" (→ critical/high findings, then medium, then tech-debt).
