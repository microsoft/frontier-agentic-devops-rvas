# Ch18 — Self-Hosted & Larger Runners — Delivery Assurance

This is a concise review overlay. Apply the [Delivery Assurance Standard](../../../DELIVERY_ASSURANCE.md); the paired `README.md` is the canonical source for tasks, evidence, commands, and Definition of Done.

## Assurance record

- **Authorized scope:** record the customer target and approving owner.
- **Evidence:** inspect the completed Definition of Done in `README.md`; link or attach the evidence.
- **Open risk:** record the unresolved risk and accountable owner, or `none`.
- **Next decision:** record the handover, pilot, rollout, cutover, or follow-up action with owner and date.

## Session-specific reviewer focus

- Customer adoption outcome: the customer implementation owner registers self-hosted runners in an org runner group, targets workflows with labels, hardens runner isolation, and documents operational ownership.
- **Governance register row:** Confirm one register row added for self-hosted runner policy (approved runner labels/OS, compute tier, rotation schedule, security audit trail documented). Row uses `inspect-and-propose` status (runners are powerful; rollout needs platform team decision) with links to runner group config and security runbook.
- Implementation risks to verify: ask "which credential does config.sh want, and how long does it live?" (→ registration token, good for one registration) and "what stops a rogue runner from stealing secrets?" (→ network isolation, secrets not passed to untrusted runners).
- Delivery lead prompts: ask "how do you audit which repos are using which runners?" (→ labels in workflow file + org runner API) and "what's the update/rotation cadence?" (→ quarterly or on OS patch).
