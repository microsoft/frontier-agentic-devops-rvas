# Ch14 — SSO, SAML & SCIM Identity

> By the end of this challenge you can configure SAML single sign-on for an organization, connect a real identity provider in test mode, provision and de-provision members automatically with SCIM, and audit who is linked to which external identity — all org-scoped, with the enterprise-level model as an awareness callout.

| | |
|---|---|
| **Track** | Security |
| **Difficulty** | Advanced *(per-track ramp)* |
| **Duration** | ~5 hrs total, multi-session |
| **Minimum input** | An **org** + an **org-owner token**. *(All challenges are org-scoped — no enterprise owner required.)* |
| **App** | none *(identity & access configuration — no application repo)* |
| **EMU compatible** | no *(organizations inside an Enterprise Managed Users enterprise authenticate at the enterprise level; org-level SAML SSO and org-level SCIM are not available to EMU orgs — use a non-EMU org)* |

## Prerequisites
- An organization you own (or org-owner rights) on GitHub Enterprise Cloud.
- A token with the scopes listed by `wth doctor ch14 --org <org>` (least-privilege; for this challenge: `admin:org` + `read:org` + `scim`).
- Local tooling: `gh >= 2.x`, `git`, `jq` (run `wth doctor` to verify).
- **A test IdP you control.** A free **Microsoft Entra ID** tenant (or an Okta developer org) is recommended — you'll register a SAML app and a SCIM provisioning connector against your test org. You can complete most tasks with a single IdP test app.
- **⚠️ Identity is disruptive.** Enabling enforced SAML on an org you depend on can lock out members who haven't linked. Use a **dedicated test org** (the provisioner creates supporting test members) and keep SSO in **test/non-enforced** mode until the final step.

## Learning objectives
By completing this challenge you will:
- Explain the three GHEC auth models — **personal accounts**, **SAML-restricted orgs/enterprises**, and **EMU + SCIM** — and where org-level SSO fits.
- Configure **SAML SSO** for an organization against a real IdP (Entra ID / Okta), validate it in **test mode**, then enforce it.
- Authorize a **PAT/SSH key for SSO** so API and git access keep working under SAML.
- Enable **SCIM provisioning** so creating/deactivating a user in the IdP creates/suspends the GitHub org membership automatically.
- Audit **external identities** (who is linked to which IdP identity) via the SCIM/SAML API.

## Scenario
A GHEC customer runs identity centrally in their IdP and wants GitHub to obey it: people sign in through corporate SSO, joiners are provisioned automatically, and leavers lose access the moment HR disables them — no orphaned accounts, no manual offboarding. You'll stand this up at the **organization** level (the primary, most common GHEC pattern), connecting a test IdP, proving the SCIM join/leave lifecycle, and auditing the identity links. The enterprise-account variant (centralized across many orgs, and EMU where GitHub identities are fully managed) is covered as an awareness callout so you know when to reach for it.

> **Awareness callout — enterprise vs org:** SAML and SCIM can be configured at the **enterprise** level (applies across all orgs) or, as here, at a **single org**. **Enterprise Managed Users (EMU)** go further — every member is a managed user created only via SCIM at the **enterprise** level, with no personal account. Because EMU authenticates and provisions at the enterprise tier, the **org-level** SAML SSO and org-level SCIM you configure in this challenge are **not available inside an EMU organization** — run it in a non-EMU org. EMU and enterprise-level SSO require an **enterprise owner** and are out of scope for the hands-on tasks; this challenge delivers the org-scoped experience that any org owner can complete. Note the trade-offs where relevant, but you are **not required** to configure anything at the enterprise tier.

## Setup
Run the provisioning entrypoint (Bash or PowerShell — both supported). `wth` is the documented command surface; it wraps the scripts in `modules/ghec/resources/provisioning/scripts/`.

```bash
# Bash
wth setup ch14 --org <org>
# or directly:
bash modules/ghec/resources/provisioning/scripts/setup.sh setup ch14 --org <org>
```
```powershell
# PowerShell
wth setup ch14 --org <org>
# or directly:
modules/ghec/resources/provisioning/scripts/setup.ps1 setup ch14 --org <org>
```

**What setup creates** (all artifacts namespaced `wth-ch14-*`, idempotent, prefix-guarded teardown):
- A `wth-ch14-identity-runbook` **repo** containing a **runbook** you fill in as you go: the IdP app settings (entity ID, ACL/ACS URL, certificate fingerprint), a SCIM rollout checklist, and a join/leave test script.
- A documented list of the **org-scoped identity settings** you'll touch (the org's **Authentication security** page) — the provisioner does **not** flip SSO on for you (that's the learning), it stages the runbook and validation helpers.
- A printed **Next steps** block, including the exact org **Settings → Authentication security** URL and the SCIM API base.

> Re-running `setup` reconciles (create-if-absent). `wth teardown ch14 --org <org> --yes` removes only `wth-ch14-*` artifacts (the runbook repo). **SSO/SCIM settings you change on the org are NOT auto-reverted** — see the manual-cleanup note in `COACH.md`.

## Tasks

### Part A — Identity models & IdP app
1. **Map the three auth models.** In the runbook, write one paragraph each on personal accounts, SAML-restricted org, and EMU+SCIM — when each is appropriate. (Cite the IAM fundamentals doc in References.)
2. **Register a SAML app in your IdP.** In Entra ID (Enterprise applications → New → GitHub.com Organization) or Okta, create the SAML app. Record the **entity ID**, **ACS/Reply URL** (`https://github.com/orgs/<org>/saml/consume`), **sign-on URL**, and **issuer** in the runbook.
3. **Capture the signing certificate** from the IdP; you'll paste its public cert into GitHub.

### Part B — Configure SAML in test mode
4. **Open the org's authentication settings.** Go to **Org Settings → Authentication security** and enter the **Sign-on URL**, **Issuer**, and the IdP **public certificate**.
5. **Validate WITHOUT enforcing.** Use **Test SAML configuration** (do NOT check "Require SAML SSO" yet). Confirm the test round-trip succeeds and your own account links to the IdP identity.
6. **Authorize a PAT for SSO.** Confirm that under SAML your existing token must be **authorized for SSO**:
   ```bash
   # After enabling, an un-authorized token gets a SAML-enforcement error on org resources:
   gh api orgs/<org>/members --jq 'length'   # should work once your token is SSO-authorized
   ```
   Authorize your token (Settings → Developer settings → token → Configure SSO) and re-run.

### Part C — SCIM provisioning
7. **Enable SCIM in the IdP.** In the same IdP app, turn on **Provisioning (SCIM)**: set the **tenant URL** (`https://api.github.com/scim/v2/organizations/<org>/`) and a **SCIM token** (a PAT with `admin:org`/`scim`). Map IdP attributes (userName, emails, name) to the GitHub SCIM schema.
8. **Provision a test user (join).** Assign a test user in the IdP to the app; confirm SCIM creates/invites the GitHub org membership. Verify via the SCIM API:
   ```bash
   gh api scim/v2/organizations/<org>/Users --jq '.Resources[] | {userName, active}'
   ```
9. **De-provision (leave).** Unassign/disable the test user in the IdP; confirm SCIM **suspends** the membership and the user loses org access. Re-query the SCIM API and confirm `active: false` (or the user is gone).

### Part D — Audit external identities
10. **List external identities.** Pull the SAML/SCIM identity links so you can answer "who is this GitHub login in our IdP?":
    ```bash
    gh api orgs/<org>/team/... 2>/dev/null; \
    gh api scim/v2/organizations/<org>/Users --jq '.Resources[] | {githubLogin: .userName, externalId, active}'
    ```
11. **Document the offboarding guarantee.** In the runbook, record the SCIM join/leave evidence (timestamps, API output) — this is the proof a security/compliance reviewer asks for.

### Part E — Enforce (capstone) and roll back safely
12. **Enforce SAML SSO.** Now check **Require SAML SSO** for the org. Confirm that a member without a linked identity is prompted to authenticate via the IdP, and that unauthorized tokens are rejected on org resources.
13. **Practice safe rollback.** Document (and, in the test org, perform) the rollback: un-enforce SAML, revoke the SCIM token, and remove the IdP app — capturing why each step matters so a real rollout has a tested exit.

## Validation / Definition of Done
You are done when ALL of the following are true:
- [ ] The runbook explains the **three auth models** and records your IdP app's SAML settings.
- [ ] **SAML SSO is configured** for the org and **validated in test mode** (test round-trip succeeded before enforcement).
- [ ] A **token is SSO-authorized** and works against org resources under SAML (`gh api orgs/<org>/members` succeeds).
- [ ] **SCIM provisioning is enabled** and you demonstrated a **join** (user created via SCIM) and a **leave** (user suspended via SCIM), verifiable via the SCIM API.
- [ ] You produced an **external-identity audit** listing GitHub logins ↔ IdP identities.
- [ ] **SAML SSO is enforced** on the org (and you documented a tested rollback).
- [ ] Coach conversation — think about your org's identity lifecycle right now: when a developer joins or leaves your company, how many hours does it take for their GitHub access to be correctly provisioned or deprovisioned, and where is the manual step that SCIM would remove? Talk it through with your coach and connect it to a real project, task, or workflow you own.

> Coaches verify these via the automated hints in `COACH.md`.

## Stretch goals
- Configure **team sync** (Entra/Okta groups → GitHub org teams) so group membership drives team membership.
- Add a **conditional access / MFA** policy in the IdP and confirm GitHub honors the IdP's MFA outcome.
- Compare org-level SSO with the **enterprise-level** model in writing: what changes, what EMU adds, and which customers need each (awareness only — no enterprise config required).

## Reference links
- Identity and access management fundamentals — https://docs.github.com/en/enterprise-cloud@latest/admin/managing-iam/understanding-iam-for-enterprises/about-identity-and-access-management
- About SAML SSO for your organization — https://docs.github.com/en/organizations/managing-saml-single-sign-on-for-your-organization/about-identity-and-access-management-with-saml-single-sign-on
- Configuring SAML SSO for your organization — https://docs.github.com/en/organizations/managing-saml-single-sign-on-for-your-organization/connecting-your-identity-provider-to-your-organization
- About SCIM for organizations — https://docs.github.com/en/organizations/managing-saml-single-sign-on-for-your-organization/about-scim-for-organizations
- Authorizing a personal access token for use with SAML SSO — https://docs.github.com/en/enterprise-cloud@latest/authentication/authenticating-with-saml-single-sign-on/authorizing-a-personal-access-token-for-use-with-saml-single-sign-on
- About Enterprise Managed Users — https://docs.github.com/en/enterprise-cloud@latest/admin/managing-iam/understanding-iam-for-enterprises/about-enterprise-managed-users
- SCIM REST API for organizations — https://docs.github.com/en/rest/scim/scim
