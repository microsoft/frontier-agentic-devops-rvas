# Ch20 — Automation Capstone — Delivery Assurance

This is a concise review overlay. Apply the [Delivery Assurance Standard](../../../DELIVERY_ASSURANCE.md); the paired `README.md` is the canonical source for tasks, evidence, commands, and Definition of Done.

## Assurance record

- **Authorized scope:** record the customer target and approving owner.
- **Evidence:** inspect the completed Definition of Done in `README.md`; link or attach the evidence.
- **Open risk:** record the unresolved risk and accountable owner, or `none`.
- **Next decision:** record the handover, pilot, rollout, cutover, or follow-up action with owner and date.

## Session-specific reviewer focus

- Customer adoption outcome: the customer implementation owner delivers one end-to-end automation where a GitHub App (installation auth) reacts to a signature-verified webhook,...
- Independence matters. This implementation must stand alone. It creates all its own ghec-ch20- state and assumes no other activity was run. If a customer implementation owner...
- Implementation risks to verify:
