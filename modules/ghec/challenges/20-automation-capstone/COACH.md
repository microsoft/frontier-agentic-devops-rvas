# Ch20 — Automation Capstone — Delivery Assurance

Review the completed work against the [Delivery Assurance Standard](../../../DELIVERY_ASSURANCE.md) and the paired `README.md` Definition of Done.

## Assurance record

- **Authorized scope:** record the customer target and approving owner.
- **Evidence:** inspect the completed Definition of Done in `README.md`; link or attach the evidence.
- **Open risk:** record the unresolved risk and accountable owner, or `none`.
- **Next decision:** record the handover, pilot, rollout, cutover, or follow-up action with owner and date.

## Reviewer focus

- **Expected outcome:** the customer implementation owner delivers one end-to-end automation. A GitHub App reacts to a signature-verified webhook, updates GitHub through REST and GraphQL, and Actions orchestrates the flow.
- Independence matters. This implementation creates its own `ghec-ch20-*` state and requires no earlier activity. Learners may reuse concepts from earlier activities, but must provision and validate the Ch20 artifacts independently.
- **Check these risks:** the handler verifies the raw request body, uses an installation token for API calls, prevents duplicate actions on redelivery, and stores secrets only in Actions secrets.
