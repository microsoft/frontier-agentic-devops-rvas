# Ch29 — Programmatic Access Governance

> Deliver an evidence-backed inventory and policy decision for OAuth Apps, installed GitHub Apps, fine-grained PATs, and classic PATs—without changing a production access control by default.

| | |
|---|---|
| Track | Admin & Governance |
| Difficulty | Advanced |
| Duration | ~3 hrs, multi-session |
| Minimum input | Organization owner for inspection; enterprise owner or an authorized enterprise-policy export is optional for enterprise PAT policy |
| App | none |
| EMU compatible | yes — see the EMU and SCIM caveat below |

## Customer delivery target

- **Customer objective:** know which programmatic identities can access the organization, who owns them, and which controls can safely change.
- **Customer-tenant target:** a programmatic-access inventory, effective-policy/source assessment, compatibility and migration or exception plan, review cadence, and an accountable decision.
- **Safety boundary:** this is governance, not an integration or API-development session. Do not create, install, provision, or reconfigure an App.
- **Records to keep:** inventory snapshot, effective source level, owner and business purpose, permission/scope and repository reach, compatibility impact, exception or migration plan, policy decision, review cadence, and evidence links.
- **Adoption handover:** the organization owner accepts the organization decision; the enterprise owner accepts an enterprise PAT-policy decision when applicable.

> [!IMPORTANT]
> Use the existing customer governance register. Record the authorized scope, customer owner, risk decision, evidence links, next action, owner, and date. Do not copy the control catalogue or create a parallel register.

## Prerequisites

- GitHub Enterprise Cloud organization and organization-owner access for inspection.
- `gh >= 2.x` and `jq` for the optional read-only API inventory.
- An enterprise owner or an authorized export of enterprise PAT policy only when enterprise-level PAT policy must be assessed.
- A named customer owner for OAuth Apps, GitHub Apps, and token policy. No repository, App, or provisioning setup is required.

## Scope and guardrails

This activity governs four controls from `modules/ghec/resources/GOVERNANCE-CONTROL-CATALOGUE.md`:

- `INT-OAUTH-RESTRICTIONS`
- `INT-APP-REVIEW`
- `INT-FINE-GRAINED-PATS`
- `INT-CLASSIC-PATS`

First establish the **effective source level** for every setting: organization-managed, enterprise-enforced/inherited, or unavailable to the current inspector. An organization owner may inspect organization settings; do not infer enterprise policy from a missing organization control.

OAuth App restrictions and GitHub App review are different controls. OAuth restrictions are organization-only; enabling OAuth restrictions **for the first time immediately disrupts existing OAuth Apps** until they are approved. Installed GitHub Apps instead require an authority, permission/repository-scope review, and recurring review cadence.

> **EMU and SCIM caveat:** EMU is compatible because this activity inventories and governs access rather than creating identities. Treat identity lifecycle as enterprise/SCIM managed. If an enterprise policy allows an administrator exemption for an EMU or another user, record its approver, affected automation, scope, expiry, and reconciliation with SCIM joiner/leaver controls. An administrator exemption is not a substitute for least privilege or SCIM deprovisioning.

## Tasks

### Part A — Establish the inspection boundary

1. Record the organization, customer owner, approval boundary, whether it is EMU, and the available role: organization owner, enterprise owner, or authorized enterprise-policy export.
2. In organization **Settings → Third-party access**, inspect OAuth App access and installed GitHub Apps. Record whether OAuth restrictions are already enabled, the approved or denied OAuth Apps, installed Apps, their installation authority, repository reach, permissions, and accountable owner.
3. Capture a read-only installed-App snapshot where API access is available:

   ```bash
   gh api /orgs/<org>/installations --paginate \
     --jq '.installations[] | {id, app_slug, app_id, target_type}'
   ```

   Add the Settings evidence needed to identify repository selection and permissions; this endpoint alone is not a complete authority or scope record.
4. Inspect **Settings → Personal access tokens**: fine-grained token policy, classic-token policy, active tokens, and pending fine-grained token requests. Record approval requirement, maximum lifetime, restriction status, active-token owners/purpose, request decision, and the effective source level. Use audit-log or API insights where available and permitted to corroborate owner, approval, installation, or policy events; attach the query/export and date rather than claiming unavailable data.

### Part B — Build the programmatic-access inventory

5. Create one customer inventory covering OAuth Apps, installed GitHub Apps, fine-grained PATs, and classic PATs. For every entry, capture:
   - credential/application type, name or identifier, owner and business purpose;
   - organization/repository reach and permissions or scopes;
   - active, pending, approved, denied, or exception status;
   - effective policy/source level and supporting Settings, audit, or API evidence;
   - automation/SCIM/EMU compatibility risk, migration path or exception owner, and review due date.
6. For each installed GitHub App, decide who is allowed to install it, whether its current installation authority was appropriate, whether the permission and repository scope remain justified, and who performs recurring review. Record the cadence and revocation/escalation path.
7. For OAuth Apps, identify existing consumers before proposing a restriction. Record their accountable owners and an approval/exception path. Do not confuse this organization-only restriction with installed GitHub App review.

### Part C — Make a safe policy decision

8. Evaluate fine-grained PAT approval and lifetime separately from classic PAT restriction. Fine-grained PATs should have a documented approval decision and an approved lifetime; assess automation and SCIM/EMU impact before enforcement. Classic PAT access should be restricted only after each affected workflow has a migration path to a GitHub App or fine-grained PAT, or an approved time-bound exception.
9. Produce a policy decision for all four controls: retain, change, pilot, exception, or inspect-and-propose. Identify the source level, accountable owner, affected population, dependencies, rollback or exception path, evidence, and recurring review cadence.
10. Complete the inventory **and one** of the following:
    - **Recommended optional pilot:** with customer approval, require approval for fine-grained PATs in a non-production organization and record one compatibility/request outcome; or
    - **Inspect-and-propose package:** provide the inventory, effective-policy assessment, impact analysis, migration/exception plan, decision record, and proposed review cadence when no safe authorized pilot exists.

    Do **not** make OAuth-restrictions first enablement, classic-PAT restriction, or broad token-lifetime enforcement a required pilot. Those changes require their own approved impact analysis, exception handling, and rollback/change plan.

### Part D — Register evidence and hand over

11. Update the existing customer register with all four controls. For each, record the effective setting/source level, selected path (`approved pilot` only for the authorized non-production fine-grained-PAT pilot; otherwise `inspect-and-propose`), objective evidence, owner, and next review date.
12. Hand over the inventory and decision to the customer organization owner. If enterprise PAT policy is in scope, include the enterprise owner or authorized policy-export owner. Name the next action: approve a low-risk pilot, obtain a policy export, sponsor a migration, approve an exception, or schedule review.

## Validation / Definition of Done

You are done when ALL of the following are true:

- [ ] A customer-owned inventory covers OAuth Apps, installed GitHub Apps, fine-grained PATs, and classic PATs, with owners, purpose, reach, permissions/scopes, state, and evidence.
- [ ] The effective organization, enterprise/inherited, or unavailable source level is recorded for OAuth, App, and PAT controls.
- [ ] Third-party access, installed-App, PAT settings, active-token, and pending-request surfaces were inspected; read-only API and audit evidence is attached where available.
- [ ] Every installed GitHub App has an installation-authority decision, permission/repository-scope assessment, accountable owner, and recurring review cadence.
- [ ] OAuth restriction impact is distinguished from GitHub App review, including the first-enable disruption risk and an approval/exception path.
- [ ] Fine-grained PAT approval/lifetime and classic-PAT restriction/migration are evaluated separately, with automation and EMU/SCIM administrator-exemption implications recorded.
- [ ] The delivery includes the inventory plus either an authorized non-production fine-grained-PAT approval pilot or a complete inspect-and-propose package.
- [ ] The existing customer register records `INT-OAUTH-RESTRICTIONS`, `INT-APP-REVIEW`, `INT-FINE-GRAINED-PATS`, and `INT-CLASSIC-PATS` with objective evidence, owner, selected path, and review date.
- [ ] The customer owner accepts the policy decision, migration/exception plan, and next action.

## Operational extensions

- Reconcile the inventory with a customer CMDB or service-owner directory and escalate entries without an accountable owner.
- Add a quarterly evidence refresh using approved audit-log retention and policy-export processes.
- Move a proven classic-PAT workload to a least-privilege GitHub App or fine-grained PAT only through a separately approved change.

## Reference links

- [OAuth app access restrictions](https://docs.github.com/en/enterprise-cloud@latest/organizations/managing-oauth-access-to-your-organizations-data/about-oauth-app-access-restrictions)
- [Reviewing GitHub Apps installed in your organization](https://docs.github.com/en/enterprise-cloud@latest/organizations/managing-programmatic-access-to-your-organization/reviewing-github-apps-installed-in-your-organization)
- [Limiting OAuth App and GitHub App access requests and installations](https://docs.github.com/en/enterprise-cloud@latest/organizations/managing-programmatic-access-to-your-organization/limiting-oauth-app-and-github-app-access-requests-and-installations)
- [Setting a personal access token policy for your organization](https://docs.github.com/en/enterprise-cloud@latest/organizations/managing-programmatic-access-to-your-organization/setting-a-personal-access-token-policy-for-your-organization)
- [Enforcing policies for personal access tokens in your enterprise](https://docs.github.com/en/enterprise-cloud@latest/admin/enforcing-policies/enforcing-policies-for-your-enterprise/enforcing-policies-for-personal-access-tokens-in-your-enterprise)
- [Managing requests for personal access tokens in your organization](https://docs.github.com/en/enterprise-cloud@latest/organizations/managing-programmatic-access-to-your-organization/managing-requests-for-personal-access-tokens-in-your-organization)
- [Managing your personal access tokens](https://docs.github.com/en/enterprise-cloud@latest/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens)
