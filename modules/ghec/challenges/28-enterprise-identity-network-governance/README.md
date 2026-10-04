# Ch28: Enterprise identity and network governance

**Session outcome:** One approved enterprise access control works for its intended users and denies an out-of-scope action. The owner can repeat the check before expanding it.

Choose one actual access gap. Inspect the sections below that affect that gap; a full identity, network, SSH, and role assessment is not required.

## Scope boundary

This activity covers **enterprise governance**. Ch14 tests organization SAML/SCIM lifecycle controls; it does not establish enterprise identity-model, CAP, or network-policy decisions. Ch07 models organization teams and repository roles but does not review enterprise roles. Reuse relevant evidence from those activities, then record the effective enterprise settings and accountable enterprise owner here.

Reuse the customer's organization and identity-boundary decisions. Verify current roles and the recovery path here.

## Prerequisites

- An enterprise owner **or** an authorized, current export of enterprise authentication, network, SSH CA, and role policies.
- A named customer IdP owner to interpret identity-model, OIDC, and conditional-access evidence.
- A named enterprise governance owner and a second enterprise owner or documented break-glass owner.
- Customer approval before any test change and separate identities or network paths for allowed and denied tests. Enterprise-owner access is required for a settings change; an export-only session remains inspection-only.

## Tasks

### Part A: Establish the effective enterprise baseline

1. Select the customer enterprise and record the policy export's source and date. Name the IdP owner and contacts for governance and recovery. Reuse existing decisions.
2. Inspect the identity model, enterprise authentication protocol, effective enterprise settings, organization-level additions, and existing exceptions. Capture immutable exports, setting screenshots, or API output rather than an assertion alone.
3. Confirm inheritance explicitly: identify each setting's effective enterprise or organization level and whether an organization can add a stricter/additive entry. Do not infer enterprise coverage from a single organization.

### Part B: Decide the identity and network enforcement path

4. Inspect whether the enterprise uses EMU, OIDC, and Microsoft Entra ID. IdP Conditional Access Policy (CAP) is eligible **only** for EMU with OIDC and Microsoft Entra ID.
5. Record the CAP decision and IdP policy evidence. CAP and the GitHub enterprise IP allow list are mutually exclusive enforcement paths: do not propose or enable both for the same enterprise. If CAP is ineligible or not selected, assess the IP allow-list path instead.
6. Inspect the effective enterprise allow list, organization additions, service and automation exceptions, and the break-glass access path. Include web, API, Git, PAT, OAuth, SSH, and app impact in the risk decision.
7. If the customer authorizes a bounded test, add and then remove **one test-organization IP entry only**, while leaving IP-allow-list enforcement disabled. Capture before/after evidence and the rollback result. Do not test against a production organization or enable enforcement.

### Part C: Assess SSH certificate authority use

8. Inspect existing SSH CA settings, Git-over-SSH usage, automation and deploy-key exceptions, certificate issuer ownership, and revocation/rotation expectations.
9. Leave SSH CA settings unchanged by default. A customer-authorized test may register one CA in a test organization only; it must be removed or have a documented rollback. Never require a user to obtain or use an SSH certificate to complete this activity.

### Part D: Review enterprise roles and recovery

10. Export the enterprise People/role view and identify every enterprise owner, delegated enterprise role, role purpose, and review cadence. Minimize enterprise-owner assignment; name delegated roles rather than using owners for routine administration.
11. Confirm at least two enterprise owners, or document the approved exception, and test the **process** for break-glass recovery without removing an owner or changing production access. Record the contact route, authority, response expectation, and rollback owner.

### Part E: Verify and hand over

12. Reconcile the identity, network, SSH CA, and enterprise-role findings with the source exports. Confirm each effective level, accountable owner, exception, review/rotation date, and rollback or break-glass path.
13. Have the enterprise owner approve the selected control, affected users, and rollback. Keep the baseline and approval in the existing change record.

### Part F: Put the selected control to work

Choose **one** of these cases. Reuse an existing control when it already matches the approved requirement.

| Customer need | Configure and verify |
|---|---|
| Delegate a real administrative duty without enterprise-owner access | In the enterprise's **People** settings, have an enterprise owner assign the approved available role to the intended person or team. Read its permissions before assigning it. Custom enterprise roles are in public preview; use them only when approved and available. Have a non-owner recipient perform one permitted task, such as reading the audit log when the role allows it, and attempt one task outside that role. Check their other grants before attributing either result to this role. |
| Restrict access by network | Use an approved isolated organization and the documented IP allow-list setup. Have the owner add the approved addresses and verify a working recovery path before enabling enforcement. Test an allowed address and a separate denied address against the same private resource. Do not enable this path alongside enterprise CAP. Do not use a production organization as a learning exercise. |
| Prove an existing identity boundary | With the IdP owner, select a non-production user and verify allowed sign-in and denied access after the approved offboarding action. Use [Ch14](../14-sso-saml-scim/README.md) for organization SAML/SCIM steps. Check the enterprise's effective policy as well; an organization test alone does not prove enterprise-wide coverage. |

Keep the allowed and denied results with the selected setting and rollback instructions. Leave an approved useful control in place; remove temporary test access. Have the owner identify the next users or organization to include.

An accepted assessment alone does not complete this setup. If no authorized pilot can run, record **blocked / not tested** and the owner who can approve it. Never change production identity or network enforcement just to finish the session.

## Reference links

- [About Enterprise Managed Users](https://docs.github.com/en/enterprise-cloud@latest/admin/concepts/identity-and-access-management/enterprise-managed-users)
- [Configuring OIDC for Enterprise Managed Users](https://docs.github.com/en/enterprise-cloud@latest/admin/managing-iam/configuring-authentication-for-enterprise-managed-users/configuring-oidc-for-enterprise-managed-users)
- [About support for your IdP's Conditional Access Policy](https://docs.github.com/en/enterprise-cloud@latest/admin/managing-iam/configuring-authentication-for-enterprise-managed-users/about-support-for-your-idps-conditional-access-policy)
- [Restricting network traffic to your enterprise with an IP allow list](https://docs.github.com/en/enterprise-cloud@latest/admin/configuring-settings/hardening-security-for-your-enterprise/restricting-network-traffic-to-your-enterprise-with-an-ip-allow-list)
- [About SSH certificate authorities](https://docs.github.com/en/enterprise-cloud@latest/authentication/connecting-to-github-with-ssh/about-ssh-certificate-authorities)
- [Roles in an enterprise](https://docs.github.com/en/enterprise-cloud@latest/admin/concepts/enterprise-fundamentals/roles-in-an-enterprise)
