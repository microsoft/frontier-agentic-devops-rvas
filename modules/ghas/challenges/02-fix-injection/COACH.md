# Fix Injection Vulnerabilities — Delivery Assurance

This is a concise review overlay. Apply the [Delivery Assurance Standard](../../../DELIVERY_ASSURANCE.md); the paired `README.md` is the canonical source for tasks, evidence, commands, and Definition of Done.

## Assurance record

- **Authorized scope:** record the customer target and approving owner.
- **Evidence:** inspect the completed Definition of Done in `README.md`; link or attach the evidence.
- **Open risk:** record the unresolved risk and accountable owner, or `none`.
- **Next decision:** record the handover, pilot, rollout, cutover, or follow-up action with owner and date.

## Session-specific reviewer focus

- Delivery team members may try input sanitization or regex filtering first; explain that validation can enforce an input policy but does not reliably prevent injection, then...
- A team may fix one file but miss a parallel vulnerable path; ask them to search for the same unsafe query pattern elsewhere.
- Copilot Autofix or assistance may be helpful but incomplete; coach the team to treat it as proposed work and review it through existing PR and GHAS controls.
