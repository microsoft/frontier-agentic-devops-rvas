# Ch28: Enterprise identity and network governance

**Session outcome:** One approved enterprise access control works for its intended users and denies an out-of-scope action. The owner can repeat the check before expanding it.

Pick one real access gap. Work through only the sections that affect it. You don't need a full identity, network, SSH, and role assessment.

## Scope boundary

This session covers **enterprise governance**. Ch14 tests organization SAML/SCIM lifecycle controls, but not enterprise identity-model, CAP, or network-policy decisions. Ch07 models organization teams and repository roles, but doesn't review enterprise roles. Reuse evidence from those sessions, then record the effective enterprise settings and the accountable enterprise owner here.

Reuse the customer's organization and identity-boundary decisions. Verify current roles and the recovery path here.

## Prerequisites

- An enterprise owner **or** an authorized, current export of the enterprise authentication, network, SSH CA, and role policies.
- A named customer IdP owner who can interpret the identity-model, OIDC, and conditional-access evidence.
- A named enterprise governance owner and a second enterprise owner or documented break-glass owner.
- Customer approval before any test change, and separate identities or network paths for the allowed and denied tests. Changing a setting takes enterprise-owner access. With an export only, you can inspect but not change.

## Tasks

### Part A: Establish the effective enterprise baseline

1. Select the customer enterprise and record the source and date of the policy export. Name the IdP owner and the governance and recovery contacts. Reuse existing decisions.
2. Inspect the identity model, enterprise authentication protocol, effective enterprise settings, organization-level additions, and existing exceptions. Capture immutable exports, screenshots of settings, or API output. A claim isn't evidence.
3. Check inheritance. For each setting, find the level where it takes effect (enterprise or organization) and whether an organization can add a stricter rule or another entry. Don't infer enterprise coverage from one organization.

### Part B: Decide the identity and network enforcement path

4. Check whether the enterprise uses EMU, OIDC, and Microsoft Entra ID. IdP Conditional Access Policy (CAP) is eligible **only** for EMU with OIDC and Microsoft Entra ID.
5. Record the CAP decision and IdP policy evidence. CAP and the GitHub enterprise IP allow list are mutually exclusive enforcement paths: don't propose or enable both for the same enterprise. If CAP isn't eligible or isn't selected, assess the IP allow list instead.
6. Inspect the effective enterprise allow list, organization additions, service and automation exceptions, and the break-glass access path. Weigh the impact on web, API, Git, PAT, OAuth, SSH, and apps.
7. If the customer authorizes a limited test, add and then remove **one test-organization IP entry only**, while leaving IP allow list enforcement disabled. Capture before and after evidence and the rollback result. Don't test against a production organization or enable enforcement.

### Part C: Assess SSH certificate authority use

8. Check the existing SSH CA settings, Git-over-SSH usage, automation and deploy-key exceptions, who owns certificate issuing, and the revocation and rotation expectations.
9. Leave SSH CA settings unchanged by default. With customer authorization, you may register one CA in a test organization only, and you must remove it or document the rollback. Never make a user get or use an SSH certificate to finish this session.

### Part D: Review enterprise roles and recovery

10. Export the enterprise People/role view and list every enterprise owner and delegated enterprise role, with its purpose and review cadence. Keep enterprise owners few, and use named delegated roles for routine administration.
11. Confirm at least two enterprise owners, or document the approved exception, and test the break-glass recovery **process** without removing an owner or changing production access. Record the contact route, who has authority, the expected response time, and the rollback owner.

### Part E: Verify and hand over

12. Check your identity, network, SSH CA, and enterprise-role findings against the source exports. For each setting, confirm the effective level, owner, exceptions, review or rotation date, and rollback or break-glass path.
13. Have the enterprise owner approve the control, the affected users, and the rollback. Keep the baseline and approval in the existing change record.

### Part F: Put the selected control to work

Choose **one** case. If an existing control already meets the approved requirement, reuse it.

| Customer need | Configure and verify |
|---|---|
| Delegate a real administrative duty without enterprise-owner access | In the enterprise's **People** settings, have an enterprise owner assign the approved role to the person or team. Read its permissions first. Custom enterprise roles are in public preview, so use them only if approved and available. Have a non-owner recipient do one permitted task, such as reading the audit log if the role allows it, and try one task outside the role. Check their other grants before crediting either result to this role. |
| Restrict access by network | Use an approved, isolated organization and the documented IP allow list setup. Have the owner add the approved addresses and confirm a working recovery path before enabling enforcement. Test an allowed address and a separate denied address against the same private resource. Don't enable this alongside enterprise CAP, and don't use a production organization to learn. |
| Prove an existing identity boundary | With the IdP owner, pick a non-production user. Verify the allowed sign-in, then the denied access after the approved offboarding action. Use [Ch14](../14-sso-saml-scim/README.md) for the organization SAML/SCIM steps. Also check the enterprise's effective policy: an organization test alone doesn't prove enterprise-wide coverage. |

Keep the allowed and denied results together with the setting and the rollback instructions. Leave an approved, useful control in place and remove temporary test access. Have the owner name the next users or organization to cover.

An accepted assessment alone doesn't complete this setup. If no authorized pilot can run, record **blocked / not tested** and the owner who can approve it. Never change production identity or network enforcement just to finish the session.

## Reference links

- [About Enterprise Managed Users](https://docs.github.com/en/enterprise-cloud@latest/admin/concepts/identity-and-access-management/enterprise-managed-users)
- [Configuring OIDC for Enterprise Managed Users](https://docs.github.com/en/enterprise-cloud@latest/admin/managing-iam/configuring-authentication-for-enterprise-managed-users/configuring-oidc-for-enterprise-managed-users)
- [About support for your IdP's Conditional Access Policy](https://docs.github.com/en/enterprise-cloud@latest/admin/managing-iam/configuring-authentication-for-enterprise-managed-users/about-support-for-your-idps-conditional-access-policy)
- [Restricting network traffic to your enterprise with an IP allow list](https://docs.github.com/en/enterprise-cloud@latest/admin/configuring-settings/hardening-security-for-your-enterprise/restricting-network-traffic-to-your-enterprise-with-an-ip-allow-list)
- [About SSH certificate authorities](https://docs.github.com/en/enterprise-cloud@latest/authentication/connecting-to-github-with-ssh/about-ssh-certificate-authorities)
- [Roles in an enterprise](https://docs.github.com/en/enterprise-cloud@latest/admin/concepts/enterprise-fundamentals/roles-in-an-enterprise)
