# Ch14 — SSO, SAML & SCIM Identity — Delivery Assurance

This is a concise review overlay. Apply the [Delivery Assurance Standard](../../../DELIVERY_ASSURANCE.md); the paired `README.md` is the canonical source for tasks, evidence, commands, and Definition of Done.

## Assurance record

- **Authorized scope:** record the customer target and approving owner.
- **Evidence:** inspect the completed Definition of Done in `README.md`; link or attach the evidence.
- **Open risk:** record the unresolved risk and accountable owner, or `none`.
- **Next decision:** record the handover, pilot, rollout, cutover, or follow-up action with owner and date.

## Session-specific reviewer focus

- Customer adoption outcome: the customer implementation owner wires a real IdP to GitHub org via SAML, proves the SCIM join/leave lifecycle, audits identity links, and demonstrates SSO-enforced access control.
- **Governance register row:** Confirm one register row added for SSO / SAML enforcement (linked IdP with attribute mappings, SCIM provisioning configured, IdP test connectivity). Row uses `inspect-and-propose` status (enterprise feature, not org-scoped deployment) with links to SAML config export and IdP team contacts.
- Implementation risks to verify: ask "what happens to an API token the moment SAML is enforced?" (→ must authorize for SSO or token becomes invalid) and "how does HR disabling someone reach GitHub?" (→ SCIM deprovisioning removes org membership).
- Delivery lead prompts: ask "what's the rollback plan if the IdP breaks?" (→ org owner override path, testing in non-prod first).
