# Ch28 — Enterprise Identity & Network Governance

> Inspect enterprise identity, network, SSH, and privileged-role controls and prove the effective configuration. Do not configure an IdP or disrupt production.

| | |
|---|---|
| Track | Admin/Governance |
| Difficulty | Advanced |
| Duration | ~3 hrs, multi-session |
| Minimum input | Enterprise owner **or** authorized enterprise-policy export; named IdP owner |
| App | none |
| EMU compatible | yes, subject to the control-specific constraints below |

## Customer delivery target

- **Objective:** inspect enterprise-level identity and network controls, identify the effective inherited setting and owner, and retain direct evidence.
- **Target:** verified enterprise settings and, where authorized, a safe bounded test-organization check—not an IdP setup, provisioning exercise, or production rollout.
- **Default path:** inspection only. Change a test organization only when the customer explicitly authorizes the bounded action.
- **Safety boundary:** no production-disruptive action is required. Do not enable enforcement, change production IP access, provision users, or require SSH certificates.

## Scope boundary

This is an **enterprise governance** activity. Ch14 configures and evidences organization SAML/SCIM lifecycle controls; it is not a substitute for an enterprise identity-model, CAP, or network-policy decision. Ch07 models organization teams and repository roles; its evidence is not an enterprise-role review. Reuse their evidence where relevant, but record the enterprise effective level and accountable enterprise owner here.

## Prerequisites

- An enterprise owner **or** an authorized, current export of enterprise authentication, network, SSH CA, and role policies.
- A named customer IdP owner to interpret identity-model, OIDC, and conditional-access evidence.
- A named enterprise governance owner and a second enterprise owner or documented break-glass owner.
- Customer approval before any test change. Enterprise-owner access is required for a settings change; an export-only session remains inspection-only.

## Tasks

### Part A — Establish the effective enterprise baseline

1. Select the customer enterprise and record the source and date of the policy export or the approving enterprise owner. Name the IdP owner, enterprise governance owner, and break-glass owner.
2. Inspect the identity model, enterprise authentication protocol, effective enterprise settings, organization-level additions, and existing exceptions. Capture immutable exports, setting screenshots, or API output rather than an assertion alone.
3. Confirm inheritance explicitly: identify each setting's effective enterprise or organization level and whether an organization can add a stricter/additive entry. Do not infer enterprise coverage from a single organization.

### Part B — Decide the identity and network enforcement path

4. Inspect whether the enterprise uses EMU, OIDC, and Microsoft Entra ID. IdP Conditional Access Policy (CAP) is eligible **only** for EMU with OIDC and Microsoft Entra ID.
5. Record the CAP decision and IdP policy evidence. CAP and the GitHub enterprise IP allow list are mutually exclusive enforcement paths: do not propose or enable both for the same enterprise. If CAP is ineligible or not selected, assess the IP allow-list path instead.
6. Inspect the effective enterprise allow list, organization additions, service and automation exceptions, and the break-glass access path. Include web, API, Git, PAT, OAuth, SSH, and app impact in the risk decision.
7. If the customer authorizes a bounded test, add and then remove **one test-organization IP entry only**, while leaving IP-allow-list enforcement disabled. Capture before/after evidence and the rollback result. Do not test against a production organization or enable enforcement.

### Part C — Assess SSH certificate authority use

8. Inspect existing SSH CA settings, Git-over-SSH usage, automation and deploy-key exceptions, certificate issuer ownership, and revocation/rotation expectations.
9. Leave SSH CA settings unchanged by default. A customer-authorized test may register one CA in a test organization only; it must be removed or have a documented rollback. Never require a user to obtain or use an SSH certificate to complete this activity.

### Part D — Review enterprise roles and recovery

10. Export the enterprise People/role view and identify every enterprise owner, delegated enterprise role, role purpose, and review cadence. Minimize enterprise-owner assignment; name delegated roles rather than using owners for routine administration.
11. Confirm at least two enterprise owners, or document the approved exception, and test the **process** for break-glass recovery without removing an owner or changing production access. Record the contact route, authority, response expectation, and rollback owner.

### Part E — Verify and hand over

12. Reconcile the identity, network, SSH CA, and enterprise-role findings with the source exports. Confirm each effective level, accountable owner, exception, review/rotation date, and rollback or break-glass path.
13. Present the four decisions to the enterprise owner and IdP owner: accept current state, authorize a bounded pilot, schedule a rollout, or accept/document the risk. No production change is necessary to complete the activity.

## Validation / Definition of Done

- [ ] The evidence names the enterprise, IdP owner, governance owner, and break-glass/rollback owner.
- [ ] Identity, IP allow-list, SSH CA, and enterprise-role settings have effective-level and objective source evidence.
- [ ] CAP eligibility is evidenced as EMU + OIDC + Microsoft Entra ID, and the mutually exclusive CAP-versus-GitHub-IP-allow-list choice is recorded.
- [ ] The IP allow-list decision includes effective inheritance, service exceptions, and a break-glass path; any pilot added and removed one test-org entry without enforcement.
- [ ] SSH CA settings remained unchanged by default; any authorized action was limited to test-org CA registration and did not require SSH certificates.
- [ ] Enterprise owners are minimized, delegated roles are named, and two owners or an approved exception plus a break-glass process is evidenced.
- [ ] The enterprise owner and IdP owner have an accountable next decision; no production-disruptive action or user provisioning was required.

## Reference links

- [About Enterprise Managed Users](https://docs.github.com/en/enterprise-cloud@latest/admin/concepts/identity-and-access-management/enterprise-managed-users)
- [Configuring OIDC for Enterprise Managed Users](https://docs.github.com/en/enterprise-cloud@latest/admin/managing-iam/configuring-authentication-for-enterprise-managed-users/configuring-oidc-for-enterprise-managed-users)
- [About support for your IdP's Conditional Access Policy](https://docs.github.com/en/enterprise-cloud@latest/admin/managing-iam/configuring-authentication-for-enterprise-managed-users/about-support-for-your-idps-conditional-access-policy)
- [Restricting network traffic to your enterprise with an IP allow list](https://docs.github.com/en/enterprise-cloud@latest/admin/configuring-settings/hardening-security-for-your-enterprise/restricting-network-traffic-to-your-enterprise-with-an-ip-allow-list)
- [About SSH certificate authorities](https://docs.github.com/en/enterprise-cloud@latest/authentication/connecting-to-github-with-ssh/about-ssh-certificate-authorities)
- [Roles in an enterprise](https://docs.github.com/en/enterprise-cloud@latest/admin/concepts/enterprise-fundamentals/roles-in-an-enterprise)
