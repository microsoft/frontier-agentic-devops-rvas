# Ch14: SSO, SAML and SCIM identity

This optional session needs an authorized non-EMU test organization, an IdP administrator, and a recovery account. An export can support an assessment, but cannot prove that user provisioning and removal work.

**Session outcome:** You have tested SAML sign-in and the SCIM user lifecycle in an approved environment, and checked the external identities in GitHub. You enable enforcement only after approval, with a recovery path ready.

## Prerequisites
- An organization you own (or org-owner rights) on GitHub Enterprise Cloud.
- A token with the scopes listed by `modules/ghec/resources/provisioning/scripts/setup.sh doctor ch14 --org <org>` (least-privilege; for this activity: `admin:org` + `read:org` + `scim`).
- Local tooling: `gh >= 2.x`, `git`, `jq` (run `modules/ghec/resources/provisioning/scripts/setup.sh doctor` to verify).
- A test IdP you control. Use a free Microsoft Entra ID tenant or an Okta developer org to register a SAML app and SCIM provisioning connector against your test org. You can complete most tasks with a single IdP test app.
- **Enforced SAML can lock out members who haven't linked their identities.** Use a dedicated test org (the provisioner creates supporting test members) and keep SSO in test/non-enforced mode until the final step. In a customer tenant, enforce only with the identity and organisation owners' approval, a tested rollback, and an agreed change window.

## What you will deliver
- Explain personal accounts, SAML-restricted orgs/enterprises, and EMU + SCIM, including where org-level SSO fits.
- Configure SAML SSO for an organization against a real IdP (Entra ID / Okta), validate it in test mode, then enforce it.
- Authorize a PAT/SSH key for SSO so API and git access keep working under SAML.
- Enable SCIM provisioning so creating/deactivating a user in the IdP creates/suspends the GitHub org membership automatically.
- Audit external identities (who is linked to which IdP identity) via the SCIM/SAML API.

## Scenario
A GHEC customer manages identity in its IdP and wants corporate SSO and automated GitHub membership provisioning and removal. Connect a test IdP at organization scope, test the SCIM join/leave lifecycle, and audit identity links. Review the enterprise-account and EMU variants without configuring them.

> SAML and SCIM can be configured at enterprise scope, across all orgs, or at a single org as in this activity. In Enterprise Managed Users (EMU), every member is a managed user created only via enterprise-level SCIM, with no personal account. Org-level SAML SSO and SCIM are unavailable inside an EMU organization. Run this activity in a non-EMU org. EMU and enterprise-level SSO require an enterprise owner and are outside the hands-on scope.
>
> Confirm the customer's identity model with its owner before configuring the non-EMU target. Reuse an existing decision when it still applies.

## Scope boundary

This is an **organization-scoped identity** activity. Part E verifies the organization's SAML/SCIM lifecycle only. Use Ch28 for enterprise-level identity governance, including CAP and EMU decisions.

> [!IMPORTANT]
> Use an approved customer target first. If you have a candidate identity runbook, SAML/SCIM rollout plan, or organisation authentication setting, use it everywhere this guide says `ghec-ch14-identity-runbook` and skip Setup. Otherwise use the fallback seeded runbook repo and validation helpers below.
>
> Record the selected target, identity owner, risk decision, and next action.

## Sample test repository or environment
Skip if you brought your own identity runbook or org setting.

```bash
# Bash
bash modules/ghec/resources/provisioning/scripts/setup.sh provision ch14 --org <org>
```
```powershell
# PowerShell
modules/ghec/resources/provisioning/scripts/setup.ps1 provision ch14 --org <org>
```

Setup creates these resources (all names use the `ghec-ch14-*` prefix, and teardown is prefix-guarded):
- A `ghec-ch14-identity-runbook` repo containing a runbook you fill in as you go: the IdP app settings (entity ID, ACL/ACS URL, certificate fingerprint), a SCIM rollout checklist, and a join/leave test script.
- A documented list of settings on the org's Authentication security page. The provisioner does not enable SSO.
- A printed Next steps block, including the exact org Settings → Authentication security URL and the SCIM API base.

## Tasks

### Part A: Identity models and IdP app
1. Confirm with the identity owner that the target uses personal accounts and supports organization SAML/SCIM. Record the identity model in the existing runbook. Use the IAM reference if the model is unclear; do not configure organization SAML/SCIM in EMU.
2. In Entra ID (Enterprise applications → New → GitHub.com Organization) or Okta, create the SAML app. Record the entity ID, ACS/Reply URL (`https://github.com/orgs/<org>/saml/consume`), sign-on URL, and issuer in the runbook.
3. Capture the signing certificate from the IdP; you'll paste its public cert into GitHub.

### Part B: Configure SAML in test mode
4. Go to Org Settings → Authentication security and enter the Sign-on URL, Issuer, and the IdP public certificate.
5. Validate WITHOUT enforcing. Use Test SAML configuration (do NOT check "Require SAML SSO" yet). Confirm the test round-trip succeeds and your own account links to the IdP identity.
6. Confirm that under SAML your existing token must be authorized for SSO:
   ```bash
   # After enabling, an un-authorized token gets a SAML-enforcement error on org resources:
   gh api orgs/<org>/members --jq 'length'   # should work once your token is SSO-authorized
   ```
   Authorize your token (Settings → Developer settings → token → Configure SSO) and re-run.

### Part C: SCIM provisioning
7. In the same IdP app, turn on Provisioning (SCIM): set the tenant URL (`https://api.github.com/scim/v2/organizations/<org>/`) and a SCIM token (a PAT with `admin:org`/`scim`). Map IdP attributes (userName, emails, name) to the GitHub SCIM schema.
8. Assign a test user in the IdP to the app (join); confirm SCIM creates/invites the GitHub org membership. Verify via the SCIM API:
   ```bash
   gh api scim/v2/organizations/<org>/Users --jq '.Resources[] | {userName, active}'
   ```
9. Unassign/disable the test user in the IdP (leave); confirm SCIM suspends the membership and the user loses org access. Re-query the SCIM API and confirm `active: false` (or the user is gone).

### Part D: Audit external identities
10. Use the SCIM user record to map the IdP `userName` and `externalId` to the GitHub account and confirm whether the identity is active:
    ```bash
    gh api scim/v2/organizations/<org>/Users --jq '.Resources[] | {githubLogin: .userName, externalId, active}'
    ```
11. Record the SCIM join/leave evidence (timestamps, API output) in the runbook for security/compliance review.

### Part E: Enforce (capstone) and roll back safely
12. Check Require SAML SSO on the dedicated test organization only during an approved change window, after testing recovery. Use a consenting non-owner account and an unauthorized token. Without enforcement approval, leave it disabled and record the blocked test.
13. Document the rollback and perform it in the test org: remove SAML enforcement, revoke the SCIM token, and remove the IdP app. Record why each step is needed.

## Reference links
- [Identity and access management fundamentals](https://docs.github.com/en/enterprise-cloud@latest/admin/managing-iam/understanding-iam-for-enterprises/about-identity-and-access-management)
- [About SAML SSO for your organization](https://docs.github.com/en/organizations/managing-saml-single-sign-on-for-your-organization/about-identity-and-access-management-with-saml-single-sign-on)
- [Configuring SAML SSO for your organization](https://docs.github.com/en/organizations/managing-saml-single-sign-on-for-your-organization/connecting-your-identity-provider-to-your-organization)
- [About SCIM for organizations](https://docs.github.com/en/organizations/managing-saml-single-sign-on-for-your-organization/about-scim-for-organizations)
- [Authorizing a personal access token for use with SAML SSO](https://docs.github.com/en/enterprise-cloud@latest/authentication/authenticating-with-saml-single-sign-on/authorizing-a-personal-access-token-for-use-with-saml-single-sign-on)
- [About Enterprise Managed Users](https://docs.github.com/en/enterprise-cloud@latest/admin/managing-iam/understanding-iam-for-enterprises/about-enterprise-managed-users)
- [SCIM REST API for organizations](https://docs.github.com/en/rest/scim/scim)
