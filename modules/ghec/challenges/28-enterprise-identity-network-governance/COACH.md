# Ch28 — Enterprise Identity & Network Governance — Delivery Assurance

Review the completed work against the [Delivery Assurance Standard](../../../DELIVERY_ASSURANCE.md) and the `README.md` Definition of Done.

## Assurance record

- **Authorized scope:** enterprise, policy-export date, and approving enterprise owner.
- **Evidence:** link the enterprise source exports and direct setting evidence.
- **Open risk:** record the accountable owner or `none`.
- **Next decision:** record the pilot, rollout, risk acceptance, or follow-up owner and date.

## Reviewer focus

- Confirm the boundary: Ch14's org SAML/SCIM and Ch07's org roles do not prove enterprise governance.
- Confirm CAP evidence shows EMU + OIDC + Microsoft Entra ID; CAP and the GitHub IP allow list are not combined.
- Confirm any authorized IP test added and removed one test-org entry without enforcement, and any SSH CA test only registered a test-org CA without requiring certificates.
- Confirm each setting has effective-level and source evidence; enterprise owners are minimized and two-owner/break-glass recovery is documented.
