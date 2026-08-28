# Ch28 — Enterprise Identity & Network Governance

> Deliver an evidence-based enterprise decision package for identity, network, SSH, and privileged-role controls—without configuring an IdP or disrupting production.

| | |
|---|---|
| Track | Admin/Governance |
| Difficulty | Advanced |
| Duration | ~3 hrs, multi-session |
| Minimum input | Enterprise owner **or** authorized enterprise-policy export; named IdP owner |
| App | none |
| EMU compatible | yes, subject to the control-specific constraints below |

## Customer delivery target

- **Objective:** make accountable enterprise-level decisions for identity and network controls, with the effective inherited setting, owner, evidence, lifecycle, and next decision recorded.
- **Target:** a customer-owned governance decision package and control register—not an IdP setup, provisioning exercise, or production rollout.
- **Default path:** `inspect-and-propose`. An `approved pilot` is permitted only when the customer has authorized a safe, bounded test-org action.
- **Safety boundary:** no production-disruptive action is required. Do not enable enforcement, change production IP access, provision users, or require SSH certificates.

## Scope boundary

This is an **enterprise governance** activity. Ch14 configures and evidences organization SAML/SCIM lifecycle controls; it is not a substitute for an enterprise identity-model, CAP, or network-policy decision. Ch07 models organization teams and repository roles; its evidence is not an enterprise-role review. Reuse their evidence where relevant, but record the enterprise effective level and accountable enterprise owner here.

## Prerequisites

- An enterprise owner **or** an authorized, current export of enterprise authentication, network, SSH CA, and role policies.
- A named customer IdP owner to interpret identity-model, OIDC, and conditional-access evidence.
- A named enterprise governance owner and a second enterprise owner or documented break-glass owner.
- Customer approval before any pilot change. Enterprise-owner access is required for a settings change; an export-only session remains inspect-and-propose.

> [!IMPORTANT]
> Start with the customer register
>
> For every control below, record: **Control ID, effective level, objective evidence, accountable owner, lifecycle state, and next decision**. State whether the path is `inspect-and-propose`, `approved pilot`, or not applicable, and link the decision package.

## Tasks

### Part A — Establish the effective enterprise baseline

1. Select the customer enterprise and record the source and date of the policy export or the approving enterprise owner. Name the IdP owner, enterprise governance owner, and break-glass owner.
2. Inspect the identity model, enterprise authentication protocol, effective enterprise settings, organization-level additions, and existing exceptions. Capture immutable exports, setting screenshots, or API output rather than an assertion alone.
3. Confirm inheritance explicitly: identify each setting's effective enterprise or organization level and whether an organization can add a stricter/additive entry. Do not infer enterprise coverage from a single organization.

### Part B — Decide the identity and network enforcement path

4. Register `ENT-IDP-CONDITIONAL-ACCESS`. Inspect whether the enterprise uses EMU, OIDC, and Microsoft Entra ID. IdP Conditional Access Policy (CAP) is eligible **only** for EMU with OIDC and Microsoft Entra ID.
5. Record the CAP decision and IdP policy evidence. CAP and the GitHub enterprise IP allow list are mutually exclusive enforcement paths: do not propose or enable both for the same enterprise. If CAP is ineligible or not selected, assess the IP allow-list path instead.
6. Register `ENT-IP-ALLOW-LIST`. Inspect the effective enterprise allow list, organization additions, service and automation exceptions, and the break-glass access path. Include web, API, Git, PAT, OAuth, SSH, and app impact in the risk decision.
7. If an approved pilot is needed, add and then remove **one test-organization IP entry only**, while leaving IP-allow-list enforcement disabled. Capture before/after evidence and the rollback result. Do not test against a production organization or enable enforcement.

### Part C — Assess SSH certificate authority use

8. Register `ENT-SSH-CA`. Inspect existing SSH CA settings, Git-over-SSH usage, automation and deploy-key exceptions, certificate issuer ownership, and revocation/rotation expectations.
9. Default to an inspect-and-propose decision. A customer-approved pilot may register one CA in a test organization only; it must be removed or have a documented rollback. Never require a user to obtain or use an SSH certificate to complete this activity.

### Part D — Review enterprise roles and recovery

10. Register `ENT-OWNER-ROLES`. Export the enterprise People/role view and identify every enterprise owner, delegated enterprise role, role purpose, and review cadence. Minimize enterprise-owner assignment; name delegated roles rather than using owners for routine administration.
11. Confirm at least two enterprise owners, or document the approved exception, and test the **process** for break-glass recovery without removing an owner or changing production access. Record the contact route, authority, response expectation, and rollback owner.

### Part E — Produce the decision package

12. For each control, record the effective level, selected lifecycle state, accountable owner, evidence links, exceptions, review/rotation date, rollback or break-glass path, and next decision with owner and date.
13. Present the four decisions to the enterprise owner and IdP owner: accept current state, authorize a bounded pilot, schedule a rollout, or accept/document the risk. No production change is necessary to complete the activity.

## Required customer-register rows

| Control ID | Decision evidence |
|---|---|
| `ENT-IDP-CONDITIONAL-ACCESS` | EMU/OIDC/Entra eligibility, IdP CAP export, effective level, and CAP-versus-IP-allow-list decision |
| `ENT-IP-ALLOW-LIST` | Effective allow-list export, inheritance/additions, service and break-glass exceptions, and pilot evidence if authorized |
| `ENT-SSH-CA` | SSH CA inspection, automation/deploy-key exceptions, issuer/rotation owner, and proposal or bounded test-org evidence |
| `ENT-OWNER-ROLES` | Enterprise-role export, minimized owner list, named delegated roles, two-owner/break-glass evidence, and review date |

## Validation / Definition of Done

- [ ] The decision package names the enterprise, IdP owner, governance owner, and break-glass/rollback owner.
- [ ] The customer register contains all four Control IDs with effective level, objective evidence, owner, lifecycle state, and next decision.
- [ ] CAP eligibility is evidenced as EMU + OIDC + Microsoft Entra ID, and the mutually exclusive CAP-versus-GitHub-IP-allow-list choice is recorded.
- [ ] The IP allow-list decision includes effective inheritance, service exceptions, and a break-glass path; any pilot added and removed one test-org entry without enforcement.
- [ ] SSH CA is inspect-and-propose by default; any approved action was limited to test-org CA registration and did not require SSH certificates.
- [ ] Enterprise owners are minimized, delegated roles are named, and two owners or an approved exception plus a break-glass process is evidenced.
- [ ] The enterprise owner and IdP owner have an accountable next decision; no production-disruptive action or user provisioning was required.

## Reference links

- [About Enterprise Managed Users](https://docs.github.com/en/enterprise-cloud@latest/admin/concepts/identity-and-access-management/enterprise-managed-users)
- [Configuring OIDC for Enterprise Managed Users](https://docs.github.com/en/enterprise-cloud@latest/admin/managing-iam/configuring-authentication-for-enterprise-managed-users/configuring-oidc-for-enterprise-managed-users)
- [About support for your IdP's Conditional Access Policy](https://docs.github.com/en/enterprise-cloud@latest/admin/managing-iam/configuring-authentication-for-enterprise-managed-users/about-support-for-your-idps-conditional-access-policy)
- [Restricting network traffic to your enterprise with an IP allow list](https://docs.github.com/en/enterprise-cloud@latest/admin/configuring-settings/hardening-security-for-your-enterprise/restricting-network-traffic-to-your-enterprise-with-an-ip-allow-list)
- [About SSH certificate authorities](https://docs.github.com/en/enterprise-cloud@latest/authentication/connecting-to-github-with-ssh/about-ssh-certificate-authorities)
- [Roles in an enterprise](https://docs.github.com/en/enterprise-cloud@latest/admin/concepts/enterprise-fundamentals/roles-in-an-enterprise)
