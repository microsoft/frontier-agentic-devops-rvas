# Ch14 — SSO, SAML & SCIM Identity — Delivery Assurance

This is a concise review overlay. Apply the [Delivery Assurance Standard](../../../DELIVERY_ASSURANCE.md); the paired `README.md` is the canonical source for tasks, evidence, commands, and Definition of Done.

## Assurance record

- **Authorized scope:** record the customer target and approving owner.
- **Evidence:** inspect the completed Definition of Done in `README.md`; link or attach the evidence.
- **Open risk:** record the unresolved risk and accountable owner, or `none`.
- **Next decision:** record the handover, pilot, rollout, cutover, or follow-up action with owner and date.

## Session-specific reviewer focus

- Customer adoption outcome: the customer implementation owner wires a real IdP to a GitHub org via SAML, proves the SCIM join/leave lifecycle, audits identity links, and...
- Implementation risks to verify:
- Delivery lead prompts: ask "what happens to your API token the moment SAML is enforced?" (→ must authorize for SSO), and "how would HR disabling someone reach GitHub...
