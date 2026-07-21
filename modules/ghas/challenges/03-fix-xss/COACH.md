# Fix XSS & Unsafe Output — Delivery Assurance

This is a concise review overlay. Apply the [Delivery Assurance Standard](../../../DELIVERY_ASSURANCE.md); the paired `README.md` is the canonical source for tasks, evidence, commands, and Definition of Done.

## Assurance record

- **Authorized scope:** record the customer target and approving owner.
- **Evidence:** inspect the completed Definition of Done in `README.md`; link or attach the evidence.
- **Open risk:** record the unresolved risk and accountable owner, or `none`.
- **Next decision:** record the handover, pilot, rollout, cutover, or follow-up action with owner and date.

## Session-specific reviewer focus

- Delivery team members often stop at the alert location without understanding where the data originates; ask them to trace both ends of the flow.
- Some try input filtering alone; remind them the preferred fix is safe rendering or context-appropriate encoding.
- Security fixes can accidentally break page rendering; have them test the affected UI path after each change.
