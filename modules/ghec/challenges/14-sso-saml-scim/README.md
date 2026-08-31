# Ch14 — SSO, SAML & SCIM Identity

> Deliver an approved SAML/SCIM identity-lifecycle configuration with IdP validation, lifecycle evidence, and external-identity auditability.

| | |
|---|---|
| Track | Security |
| Difficulty | Advanced *(per-track ramp)* |
| Duration | ~5 hrs total, multi-session |
| Minimum input | An org + an org-owner token. *(All activities are org-scoped — no enterprise owner required.)* |
| App | none *(identity & access configuration — no application repo)* |
| EMU compatible | no *(organizations inside an Enterprise Managed Users enterprise authenticate at the enterprise level; org-level SAML SSO and org-level SCIM are not available to EMU orgs — use a non-EMU org)* |

## Delivery target

- Delivery target: the customer's approved SAML/SCIM configuration, IdP application, lifecycle runbook, and external-identity audit.
- Safety boundary: disruptive identity changes proceed in the customer tenant only with the accountable identity and organisation owners' approval, a tested rollback, and an agreed change window; otherwise validate in the controlled test organisation and leave an approved rollout/cutover proposal.
- Evidence: IdP settings, join/leave evidence, external-identity audit, rollback record, and risk decision.
- Owner: the identity owner accepts the runbook; the organisation owner accepts enforcement and rollback accountability.

## Prerequisites
- An organization you own (or org-owner rights) on GitHub Enterprise Cloud.
- A token with the scopes listed by `modules/ghec/resources/provisioning/scripts/setup.sh doctor ch14 --org <org>` (least-privilege; for this activity: `admin:org` + `read:org` + `scim`).
- Local tooling: `gh >= 2.x`, `git`, `jq` (run `modules/ghec/resources/provisioning/scripts/setup.sh doctor` to verify).
- A test IdP you control. A free Microsoft Entra ID tenant (or an Okta developer org) is recommended — you'll register a SAML app and a SCIM provisioning connector against your test org. You can complete most tasks with a single IdP test app.
- ⚠️ Identity is disruptive. Enabling enforced SAML on an org you depend on can lock out members who haven't linked. Use a dedicated test org (the provisioner creates supporting test members) and keep SSO in test/non-enforced mode until the final step.

## What you will deliver
- Explain the three GHEC auth models — personal accounts, SAML-restricted orgs/enterprises, and EMU + SCIM — and where org-level SSO fits.
- Configure SAML SSO for an organization against a real IdP (Entra ID / Okta), validate it in test mode, then enforce it.
- Authorize a PAT/SSH key for SSO so API and git access keep working under SAML.
- Enable SCIM provisioning so creating/deactivating a user in the IdP creates/suspends the GitHub org membership automatically.
- Audit external identities (who is linked to which IdP identity) via the SCIM/SAML API.

## Scenario
A GHEC customer runs identity centrally in their IdP and wants GitHub to obey it: people sign in through corporate SSO, joiners are provisioned automatically, and leavers lose access the moment HR disables them. You'll stand this up at the organization level (the primary GHEC pattern), connecting a test IdP, proving the SCIM join/leave lifecycle, and auditing the identity links. The enterprise-account and EMU variants are covered as an awareness callout.

> Awareness callout — enterprise vs org: SAML and SCIM can be configured at the enterprise level (applies across all orgs) or, as here, at a single org. Enterprise Managed Users (EMU) go further — every member is a managed user created only via SCIM at the enterprise level, with no personal account. Because EMU authenticates and provisions at the enterprise tier, the org-level SAML SSO and SCIM configured in this activity are not available inside an EMU organization — run it in a non-EMU org. EMU and enterprise-level SSO require an enterprise owner and are out of scope for the hands-on tasks.
>
> Check whether `ghec-ch52` (Enterprise Landing Zone & Organization Strategy) has already established this customer's identity model. If so, cite its personal-accounts-vs-SAML-restricted-org-vs-EMU decision as the authoritative source confirming this org is the correct non-EMU target. If not, make that determination independently using Part A's auth-model mapping and record `ghec-ch52 not completed — identity model determined independently`.

## Scope boundary

This is an **organization-scoped identity** activity. Completing it — even the enforcement step in Part E — is evidence of an organization's SAML/SCIM lifecycle only. It does not prove, satisfy, or substitute for an enterprise-level SSO/SCIM decision, an EMU determination, or `ghec-ch52`'s identity-model record, and it is not enterprise identity-governance evidence for Ch28. Route any enterprise-level SAML/SCIM, CAP, or EMU decision to `ghec-ch52` or Ch28.

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
- A documented list of the org-scoped identity settings you'll touch (the org's Authentication security page) — the provisioner does not flip SSO on for you.
- A printed Next steps block, including the exact org Settings → Authentication security URL and the SCIM API base.

## Tasks
> Throughout, `ghec-ch14-identity-runbook` is the fallback sample. If you brought your own artifact, substitute its name in every command and use your real history, teams, settings, or data as the material to work from.

### Part A — Identity models & IdP app
1. Map the three auth models. In the runbook, write one paragraph each on personal accounts, SAML-restricted org, and EMU+SCIM — when each is appropriate. (Cite the IAM fundamentals doc in References.) Check whether `ghec-ch52`'s identity-model decision is already established for this customer; if so, cite it here instead of re-deriving it, and if not, complete this mapping independently and record that `ghec-ch52` was not available.
2. In Entra ID (Enterprise applications → New → GitHub.com Organization) or Okta, create the SAML app. Record the entity ID, ACS/Reply URL (`https://github.com/orgs/<org>/saml/consume`), sign-on URL, and issuer in the runbook.
3. Capture the signing certificate from the IdP; you'll paste its public cert into GitHub.

### Part B — Configure SAML in test mode
4. Go to Org Settings → Authentication security and enter the Sign-on URL, Issuer, and the IdP public certificate.
5. Validate WITHOUT enforcing. Use Test SAML configuration (do NOT check "Require SAML SSO" yet). Confirm the test round-trip succeeds and your own account links to the IdP identity.
6. Confirm that under SAML your existing token must be authorized for SSO:
   ```bash
   # After enabling, an un-authorized token gets a SAML-enforcement error on org resources:
   gh api orgs/<org>/members --jq 'length'   # should work once your token is SSO-authorized
   ```
   Authorize your token (Settings → Developer settings → token → Configure SSO) and re-run.

### Part C — SCIM provisioning
7. In the same IdP app, turn on Provisioning (SCIM): set the tenant URL (`https://api.github.com/scim/v2/organizations/<org>/`) and a SCIM token (a PAT with `admin:org`/`scim`). Map IdP attributes (userName, emails, name) to the GitHub SCIM schema.
8. Assign a test user in the IdP to the app (join); confirm SCIM creates/invites the GitHub org membership. Verify via the SCIM API:
   ```bash
   gh api scim/v2/organizations/<org>/Users --jq '.Resources[] | {userName, active}'
   ```
9. Unassign/disable the test user in the IdP (leave); confirm SCIM suspends the membership and the user loses org access. Re-query the SCIM API and confirm `active: false` (or the user is gone).

### Part D — Audit external identities
10. Use the SCIM user record to map the IdP `userName` and `externalId` to the GitHub account and confirm whether the identity is active:
    ```bash
    gh api scim/v2/organizations/<org>/Users --jq '.Resources[] | {githubLogin: .userName, externalId, active}'
    ```
11. In the runbook, record the SCIM join/leave evidence (timestamps, API output) — the proof a security/compliance reviewer asks for.

### Part E — Enforce (capstone) and roll back safely
12. Check Require SAML SSO for the org. Confirm that a member without a linked identity is prompted to authenticate via the IdP, and that unauthorized tokens are rejected on org resources.
13. Validate safe rollback. Document (and, in the test org, perform) the rollback: un-enforce SAML, revoke the SCIM token, and remove the IdP app — capturing why each step matters so a real rollout has a tested exit.

## Reference links
- Identity and access management fundamentals — https://docs.github.com/en/enterprise-cloud@latest/admin/managing-iam/understanding-iam-for-enterprises/about-identity-and-access-management
- About SAML SSO for your organization — https://docs.github.com/en/organizations/managing-saml-single-sign-on-for-your-organization/about-identity-and-access-management-with-saml-single-sign-on
- Configuring SAML SSO for your organization — https://docs.github.com/en/organizations/managing-saml-single-sign-on-for-your-organization/connecting-your-identity-provider-to-your-organization
- About SCIM for organizations — https://docs.github.com/en/organizations/managing-saml-single-sign-on-for-your-organization/about-scim-for-organizations
- Authorizing a personal access token for use with SAML SSO — https://docs.github.com/en/enterprise-cloud@latest/authentication/authenticating-with-saml-single-sign-on/authorizing-a-personal-access-token-for-use-with-saml-single-sign-on
- About Enterprise Managed Users — https://docs.github.com/en/enterprise-cloud@latest/admin/managing-iam/understanding-iam-for-enterprises/about-enterprise-managed-users
- SCIM REST API for organizations — https://docs.github.com/en/rest/scim/scim
