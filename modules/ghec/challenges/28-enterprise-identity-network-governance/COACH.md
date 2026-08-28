# Ch28 — Enterprise Identity & Network Governance — Delivery Assurance

This is a concise review overlay. Apply the [Delivery Assurance Standard](../../../DELIVERY_ASSURANCE.md); `README.md` is the canonical source for tasks, evidence, and Definition of Done.

## Assurance record

- **Authorized scope:** enterprise, policy-export date, and approving enterprise owner.
- **Evidence:** link the four control-register rows and source exports.
- **Open risk:** record the accountable owner or `none`.
- **Next decision:** record the pilot, rollout, risk acceptance, or follow-up owner and date.

## Session-specific reviewer focus

- Confirm the boundary: Ch14's org SAML/SCIM and Ch07's org roles do not prove enterprise governance.
- Confirm `ENT-IDP-CONDITIONAL-ACCESS` evidence shows EMU + OIDC + Microsoft Entra ID; CAP and the GitHub IP allow list are not combined.
- Confirm any IP pilot added and removed one test-org entry without enforcement, and any SSH CA pilot only registered a test-org CA without requiring certificates.
- Confirm all four rows show effective level, evidence, owner, lifecycle, and next decision; enterprise owners are minimized and two-owner/break-glass recovery is documented.
