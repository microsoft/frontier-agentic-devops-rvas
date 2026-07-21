# Fix Broken Access Control — Delivery Assurance

This is a concise review overlay. Apply the [Delivery Assurance Standard](../../../DELIVERY_ASSURANCE.md); the paired `README.md` is the canonical source for tasks, evidence, commands, and Definition of Done.

## Assurance record

- **Authorized scope:** record the customer target and approving owner.
- **Evidence:** inspect the completed Definition of Done in `README.md`; link or attach the evidence.
- **Open risk:** record the unresolved risk and accountable owner, or `none`.
- **Next decision:** record the handover, pilot, rollout, cutover, or follow-up action with owner and date.

## Session-specific reviewer focus

- Delivery team members may assume a hidden button or frontend route guard is enough; redirect them to backend enforcement.
- They may add authentication without authorization; ask who is allowed to access the specific record or action.
- When multiple middleware layers exist, delivery team members can lose track of where checks happen; have them trace request flow end to end.
