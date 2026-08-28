# Ch20 — Automation Capstone — Delivery Assurance

This is a concise review overlay. Apply the [Delivery Assurance Standard](../../../DELIVERY_ASSURANCE.md); the paired `README.md` is the canonical source for tasks, evidence, commands, and Definition of Done.

## Assurance record

- **Authorized scope:** record the customer target and approving owner.
- **Evidence:** inspect the completed Definition of Done in `README.md`; link or attach the evidence.
- **Open risk:** record the unresolved risk and accountable owner, or `none`.
- **Next decision:** record the handover, pilot, rollout, cutover, or follow-up action with owner and date.

## Session-specific reviewer focus

- Customer adoption outcome: the customer implementation owner delivers one end-to-end automation in which a GitHub App reacts to a signature-verified webhook, updates GitHub through REST and GraphQL, and is orchestrated by Actions.
- Independence matters. This implementation creates its own `ghec-ch20-*` state and requires no earlier activity. Learners may reuse concepts from earlier activities, but must provision and validate the Ch20 artifacts independently.
- Implementation risks to verify: the handler verifies the raw request body, uses an installation token for API calls, prevents duplicate actions on redelivery, and stores secrets only in Actions secrets.
