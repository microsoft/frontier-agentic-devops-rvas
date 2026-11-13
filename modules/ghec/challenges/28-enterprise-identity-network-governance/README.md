# Ch28: Enterprise identity and network governance

**Session outcome:** One enterprise access control is live. It allows the intended users and denies an out-of-scope action, and the owner can repeat both tests.

Pick **one** real access gap and one control from Part B. Skip the rest.

## Prerequisites

- An enterprise owner who can change the setting, plus a second owner or a documented break-glass contact.
- For the identity option: the customer IdP owner.
- Customer approval for the test, and separate identities or network paths for the allowed and denied checks.

[Ch14](../14-sso-saml-scim/README.md) covers organization SAML/SCIM and [Ch07](../07-teams-roles-permissions/README.md) covers organization teams and roles. This session covers the **enterprise** level.

## Tasks

### Part A: Check what applies today

1. In **Enterprise settings**, check the identity model (EMU or not), the authentication protocol, and any existing enterprise policy, organization additions, and exceptions for the control you picked. Don't infer enterprise coverage from one organization.
2. Confirm the enterprise has at least two owners, or a documented break-glass path. Don't test recovery by removing an owner.

### Part B: Configure and test one control

Choose one row. If an existing control already meets the need, reuse it.

| Customer need | Configure and verify |
|---|---|
| Delegate an admin duty without enterprise-owner access | In the enterprise **People** settings, assign the approved role to a person or team. Read its permissions first. Custom enterprise roles are in public preview, so use them only if available. **Allowed:** the non-owner does one permitted task, such as reading the audit log. **Denied:** they try one task outside the role. Check their other grants first, so you credit the result to this role. |
| Restrict access by network | Use an isolated test organization and the [IP allow list](https://docs.github.com/en/enterprise-cloud@latest/admin/configuring-settings/hardening-security-for-your-enterprise/restricting-network-traffic-to-your-enterprise-with-an-ip-allow-list) setup. Add the approved addresses and confirm a recovery path **before** enabling enforcement. **Allowed:** reach a private resource from an approved address. **Denied:** try the same resource from another address. |
| Enforce your IdP's Conditional Access Policy (CAP) | CAP works **only** with EMU, OIDC, and Microsoft Entra ID. It and the IP allow list are mutually exclusive: don't enable both. With the IdP owner, sign in as a test user who meets the policy, then as one who doesn't. |
| Prove an existing identity boundary | With the IdP owner, pick a non-production user. Verify the allowed sign-in, then the denied access after the approved offboarding action (steps in [Ch14](../14-sso-saml-scim/README.md)). An organization test alone doesn't prove enterprise-wide coverage. |

### Part C: Hand over

3. Leave the approved control in place and remove temporary test access. Check that you can roll it back.
4. In the existing change record, note the setting, the allowed and denied results, and the rollback steps. Name the next users or organizations to cover.

> [!WARNING]
> Never change production identity or network enforcement just to finish this session. Don't enable an IP allow list without a working recovery path.

**Blocked:** if you have no enterprise-owner access, no authorized test environment, or no approval, stop and note the blocker in the adoption issue. The session isn't complete without the allowed and denied results.

**Optional:** SSH certificate authorities are out of scope here. See [About SSH certificate authorities](https://docs.github.com/en/enterprise-cloud@latest/authentication/connecting-to-github-with-ssh/about-ssh-certificate-authorities).

## Reference links

- [About Enterprise Managed Users](https://docs.github.com/en/enterprise-cloud@latest/admin/concepts/identity-and-access-management/enterprise-managed-users)
- [Configuring OIDC for Enterprise Managed Users](https://docs.github.com/en/enterprise-cloud@latest/admin/managing-iam/configuring-authentication-for-enterprise-managed-users/configuring-oidc-for-enterprise-managed-users)
- [About support for your IdP's Conditional Access Policy](https://docs.github.com/en/enterprise-cloud@latest/admin/managing-iam/configuring-authentication-for-enterprise-managed-users/about-support-for-your-idps-conditional-access-policy)
- [Restricting network traffic to your enterprise with an IP allow list](https://docs.github.com/en/enterprise-cloud@latest/admin/configuring-settings/hardening-security-for-your-enterprise/restricting-network-traffic-to-your-enterprise-with-an-ip-allow-list)
- [Roles in an enterprise](https://docs.github.com/en/enterprise-cloud@latest/admin/concepts/enterprise-fundamentals/roles-in-an-enterprise)
