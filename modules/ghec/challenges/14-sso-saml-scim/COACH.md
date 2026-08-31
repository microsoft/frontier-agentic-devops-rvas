# Ch14 — SSO, SAML & SCIM Identity — Delivery Assurance

Use this review overlay with the [Delivery Assurance Standard](../../../DELIVERY_ASSURANCE.md). The paired `README.md` defines the tasks, evidence, commands, and Definition of Done.

## Assurance record

- **Authorized scope:** record the customer target and approving owner.
- **Evidence:** inspect the completed Definition of Done in `README.md`; link or attach the evidence.
- **Open risk:** record the unresolved risk and accountable owner, or `none`.
- **Next decision:** record the handover, pilot, rollout, cutover, or follow-up action with owner and date.

## Session-specific reviewer focus

- Expected outcome: the customer owner connects an IdP to a GitHub organization through SAML, proves the SCIM join/leave lifecycle, audits identity links, and tests SSO-enforced access.
- **Governance controls:** Confirm `ENT-IDENTITY-MODEL`, conditional `ENT-EMU-LIFECYCLE`, and applicable `ORG-SAML-SCIM` in the existing register with objective identity-lifecycle evidence.
- Ask "what happens to an API token when SAML is enforced?" (→ it must be authorized for SSO) and "how does HR disabling someone reach GitHub?" (→ SCIM deprovisioning removes organization membership).
- Ask "what's the rollback plan if the IdP breaks?" (→ use the organization owner override path and test in non-production first).
