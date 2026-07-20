# Ch14 — SSO, SAML & SCIM Identity — Delivery Assurance Guide

> Audience: delivery assurance leads and authorized customer implementation owners. Pair with the corresponding customer implementation `README.md`.
> Customer authorization and rollout boundary: Apply changes in a customer-owned tenant or repository only after the named customer owner authorizes the scope. A fallback is a sample test repository or environment, not the destination: record its evidence, risks and controls, accountable owner, handover, and the explicit tenant adoption, cutover, or rollout decision.


## Customer adoption decision

Required delivery assurance check: before implementation is accepted, confirm the authorized tenant scope, implementation evidence, risk controls, accountable owner, handover, and next adoption action.

Decision prompt: think about your org's identity lifecycle right now: when a developer joins or leaves your company, how many hours does it take for their GitHub access to be correctly provisioned or deprovisioned, and where is the manual step that SCIM would remove? Record the accountable owner, implementation evidence, risk or blocker, and next customer adoption action.

> Customer implementation preference: prioritize an authorized customer tenant or artifact over the `ghec-ch14-identity-runbook` sample. If a sample is necessary, record the target tenant scope, accountable owner, authorization blocker, evidence to carry forward, and the adoption, cutover, or rollout decision. The sample is a safe fallback, not the destination.

Use these prompts to verify customer ownership and the next action:
- Walk me through the actual steps today when a new engineer joins — who does what to give them GitHub access?
- Where has a departed employee or contractor retained access longer than they should have in the last year?
- What is the one IdP group-to-GitHub-team mapping you would configure first, and who needs to approve it?

## Delivery assurance notes
- Customer adoption outcome: the customer implementation owner wires a real IdP to a GitHub org via SAML, proves the SCIM join/leave lifecycle, audits identity links, and enforces SSO with a tested rollback — all at org scope.
- Implementation risks to verify:
  - Test mode vs enforce. The #1 safety lesson: validate SAML in test mode before checking "Require SAML SSO". Customer implementation owners who enforce first risk locking themselves out. Make them use the test org and the Test SAML button.
  - PAT not authorized for SSO. Under SAML, existing tokens must be explicitly authorized for SSO or every org API call fails. Record this as a required authorization control, not a product defect.
  - SCIM tenant URL + token. The SCIM connector needs the exact org tenant URL and a token with `admin:org`/`scim`. Wrong URL or scope → provisioning silently no-ops.
  - Org vs enterprise scope. Some customer implementation owners try to find enterprise SAML settings. Keep them at org scope — that's the primary experience; enterprise/EMU is awareness-only.
  - IdP friction. Standing up an Entra/Okta test app is the slowest part. Encourage a free dev tenant ahead of time.
- Delivery lead prompts: ask "what happens to your API token the moment SAML is enforced?" (→ must authorize for SSO), and "how would HR disabling someone reach GitHub automatically?" (→ SCIM de-provision).
- Org-scoped note: runs with just an org + org-owner token. No enterprise owner needed — this is the org-level identity experience. EMU and enterprise SSO are called out for awareness only.

## Implementation acceptance evidence
| Criterion | Assurance weight | Customer-owned evidence |
|---|---:|---|
| Identity models + IdP app (Part A) | 15 | Three models explained; SAML app registered with settings captured in the runbook |
| SAML in test mode + token authz (Part B) | 25 | Test SAML round-trip succeeds before enforcement; PAT authorized for SSO and working |
| SCIM provisioning lifecycle (Part C) | 30 | Join (user created via SCIM) AND leave (suspended via SCIM) both demonstrated via API |
| External-identity audit (Part D) | 15 | Identity links listed (login ↔ external ID); offboarding evidence recorded |
| Enforce + safe rollback (Part E) | 15 | SAML enforced on the org; tested rollback documented |
| Assurance coverage | 100 | |

## Implementation verification evidence
Use these to verify the customer implementation evidence (prefer `gh` CLI / API over manual clicks). Some SAML state is only visible in the org settings UI — pair API checks with a screenshot.
```bash
ORG=<org>

# Runbook repo exists
gh repo view $ORG/ghec-ch14-identity-runbook --json name,visibility

# Token works against org resources (proves it's SSO-authorized once SAML is on)
gh api orgs/$ORG/members --jq 'length'

# SCIM users provisioned via the IdP (join/leave evidence: active true/false)
gh api scim/v2/organizations/$ORG/Users --jq '.Resources[] | {userName, externalId, active}'

# External identity / SAML linkage via GraphQL (samlIdentityProvider + externalIdentities)
gh api graphql -f query='
  query($login:String!){ organization(login:$login){
    samlIdentityProvider { ssoUrl
      externalIdentities(first:25){ nodes {
        guid samlIdentity { nameId } user { login } } } } } }' -f login=$ORG
```
- SAML config truth source: the GraphQL `samlIdentityProvider.ssoUrl` is non-null once SAML is configured. `externalIdentities` lists the login ↔ nameId links — that's the audit artifact.
- SCIM lifecycle: the join shows a new `Resources[]` entry; the leave shows `active: false` (or the entry removed). Have the customer implementation owner show both states (before/after) from the runbook.
- Enforcement: confirm an unauthorized token is rejected on org resources, and an SSO-authorized one succeeds.

## Common pitfalls
- Enforcing before testing → lockout risk. Always validate in test mode first; use the test org.
- Token not authorized for SSO → every org API call 403s with a SAML enforcement message. Authorize it.
- SCIM token scope missing `admin:org`/`scim` → provisioning does nothing. Re-issue the token.
- Wrong SCIM tenant URL (enterprise vs org path) → no users provision. Use `.../scim/v2/organizations/<org>/`.
- Hunting for enterprise settings — keep it org-scoped; enterprise/EMU is awareness-only and needs an enterprise owner.

## References for delivery leads

- [Identity and access management for enterprises](https://docs.github.com/en/enterprise-cloud@latest/admin/managing-iam/understanding-iam-for-enterprises/about-identity-and-access-management), [SAML SSO for organizations](https://docs.github.com/en/organizations/managing-saml-single-sign-on-for-your-organization/about-identity-and-access-management-with-saml-single-sign-on).

## Teardown
```bash
bash modules/ghec/resources/provisioning/scripts/setup.sh teardown ch14 --org <org> --yes   # Bash
modules/ghec/resources/provisioning/scripts/setup.ps1 teardown ch14 --org <org> --yes  # PowerShell
```
- Removes only `ghec-ch14-*` artifacts (prefix-guarded): the `ghec-ch14-identity-runbook` repo.
- Manual cleanup (REQUIRED — scripts cannot revert identity settings):
  - Un-enforce and disable SAML SSO on the org (Settings → Authentication security).
  - Revoke the SCIM token and remove SCIM provisioning in the IdP.
  - Delete the IdP app (Entra/Okta) you created for the test.
  - Remove any test members that were provisioned via SCIM if they linger.

## Time budget
- Setup + read + IdP app: ~1 hr
- Part A (models + app): ~45 min
- Part B (SAML test mode + token authz): ~1 hr
- Part C (SCIM lifecycle): ~1.25 hrs
- Part D (audit): ~30 min
- Part E (enforce + rollback): ~30 min
- Indicative implementation effort: ~5 hrs across sessions.
