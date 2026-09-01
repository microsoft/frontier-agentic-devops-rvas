# Ch29 — Programmatic Access Governance

> Deliver an evidence-backed inventory and policy decision for OAuth Apps, installed GitHub Apps, fine-grained PATs, and classic PATs—without changing a production access control by default.

## Prerequisites

- GitHub Enterprise Cloud organization and organization-owner access for inspection.
- `gh >= 2.x` and `jq` for the optional read-only API inventory.
- An enterprise owner or an authorized export of enterprise PAT policy only when enterprise-level PAT policy must be assessed.
- A named customer owner for OAuth Apps, GitHub Apps, and token policy. No repository, App, or provisioning setup is required.

## Scope and guardrails

This activity inspects four distinct surfaces: OAuth App restrictions, installed
GitHub App review, fine-grained PAT policy, and classic PAT policy. It is governance, not integration work: do not create, install, provision, or reconfigure an App.

Check whether `ghec-ch52` (Enterprise Landing Zone & Organization Strategy) has already established this customer's enterprise app-registration governance boundary and organization-scope decision. If so, reuse and cite its register entry as the starting scope for the inventory below instead of re-deriving it. If `ghec-ch52` has not been completed, define the inspection boundary independently in Part A and record that `ghec-ch52` was not available — apply the same rule wherever this activity references `ghec-ch52` below.

First establish the **effective source level** for every setting: organization-managed, enterprise-enforced/inherited, or unavailable to the current inspector. An organization owner may inspect organization settings; do not infer enterprise policy from a missing organization control.

OAuth App restrictions and GitHub App review are different controls. OAuth restrictions are organization-only; enabling OAuth restrictions **for the first time immediately disrupts existing OAuth Apps** until they are approved. Installed GitHub Apps instead require an authority, permission/repository-scope review, and recurring review cadence.

> **EMU and SCIM caveat:** EMU is compatible because this activity inventories and governs access rather than creating identities. Treat identity lifecycle as enterprise/SCIM managed. If an enterprise policy allows an administrator exemption for an EMU or another user, record its approver, affected automation, scope, expiry, and reconciliation with SCIM joiner/leaver controls. An administrator exemption is not a substitute for least privilege or SCIM deprovisioning.

## Tasks

### Part A — Establish the inspection boundary

1. Record the organization, customer owner, approval boundary, whether it is EMU, and the available role: organization owner, enterprise owner, or authorized enterprise-policy export (see the `ghec-ch52` note above).
2. In organization **Settings → Third-party access**, inspect OAuth App access and installed GitHub Apps. Record whether OAuth restrictions are already enabled, the approved or denied OAuth Apps, installed Apps, their installation authority, repository reach, permissions, and accountable owner.
3. Capture a read-only installed-App snapshot where API access is available:

   ```bash
   gh api /orgs/<org>/installations --paginate \
     --jq '.installations[] | {id, app_slug, app_id, target_type}'
   ```

   Add the Settings evidence needed to identify repository selection and permissions; this endpoint alone is not a complete authority or scope record.
4. Inspect **Settings → Personal access tokens**: fine-grained token policy, classic-token policy, active tokens, and pending fine-grained token requests. Record approval requirement, maximum lifetime, restriction status, active-token owners/purpose, request decision, and the effective source level. Use audit-log or API insights where available and permitted to corroborate owner, approval, installation, or policy events; attach the query/export and date rather than claiming unavailable data.

### Part B — Build the programmatic-access inventory

5. Create one customer inventory covering OAuth Apps, installed GitHub Apps, fine-grained PATs, and classic PATs — extending `ghec-ch52`'s register when it already exists rather than building a parallel, disconnected inventory (see the `ghec-ch52` note above). For every entry, capture:
   - credential/application type, name or identifier, owner and business purpose;
   - organization/repository reach and permissions or scopes;
   - active, pending, approved, denied, or exception status;
   - effective policy/source level and supporting Settings, audit, or API evidence;
   - automation/SCIM/EMU compatibility risk, migration path or exception owner, and review due date.
6. For each installed GitHub App, decide who is allowed to install it, whether its current installation authority was appropriate, whether the permission and repository scope remain justified, and who performs recurring review. Record the cadence and revocation/escalation path.
7. For OAuth Apps, identify existing consumers before proposing a restriction. Record their accountable owners and an approval/exception path. Do not confuse this organization-only restriction with installed GitHub App review.

### Part C — Make a safe policy decision

8. Evaluate fine-grained PAT approval and lifetime separately from classic PAT restriction. Fine-grained PATs should have a documented approval decision and an approved lifetime; assess automation and SCIM/EMU impact before enforcement. Classic PAT access should be restricted only after each affected workflow has a migration path to a GitHub App or fine-grained PAT, or an approved time-bound exception.
9. Produce a policy recommendation for all four surfaces: retain, change, test, or grant a time-bound exception. Identify the source level, accountable owner, affected population, dependencies, rollback or exception path, evidence, and recurring review cadence.
10. Complete the inventory **and one** of the following:
    - With customer approval, require approval for fine-grained PATs in a non-production organization and record one compatibility/request outcome; or
    - When no safe authorized test exists, use the inventory and direct Settings/API/audit evidence to recommend the next policy action.

    Do **not** make OAuth-restrictions first enablement, classic-PAT restriction, or broad token-lifetime enforcement a required test. Those changes require their own approved impact analysis, exception handling, and rollback/change plan.

### Part D — Verify evidence and hand over

11. Recheck the effective setting and source level for each surface. Confirm the inventory links the objective Settings/API/audit evidence, owner, and next review date.
12. Hand over the inventory and decision to the customer organization owner. If enterprise PAT policy is in scope, include the enterprise owner or authorized policy-export owner. Name the next action: approve a low-risk pilot, obtain a policy export, sponsor a migration, approve an exception, or schedule review.

## Reference links

- [OAuth app access restrictions](https://docs.github.com/en/enterprise-cloud@latest/organizations/managing-oauth-access-to-your-organizations-data/about-oauth-app-access-restrictions)
- [Reviewing GitHub Apps installed in your organization](https://docs.github.com/en/enterprise-cloud@latest/organizations/managing-programmatic-access-to-your-organization/reviewing-github-apps-installed-in-your-organization)
- [Limiting OAuth App and GitHub App access requests and installations](https://docs.github.com/en/enterprise-cloud@latest/organizations/managing-programmatic-access-to-your-organization/limiting-oauth-app-and-github-app-access-requests-and-installations)
- [Setting a personal access token policy for your organization](https://docs.github.com/en/enterprise-cloud@latest/organizations/managing-programmatic-access-to-your-organization/setting-a-personal-access-token-policy-for-your-organization)
- [Enforcing policies for personal access tokens in your enterprise](https://docs.github.com/en/enterprise-cloud@latest/admin/enforcing-policies/enforcing-policies-for-your-enterprise/enforcing-policies-for-personal-access-tokens-in-your-enterprise)
- [Managing requests for personal access tokens in your organization](https://docs.github.com/en/enterprise-cloud@latest/organizations/managing-programmatic-access-to-your-organization/managing-requests-for-personal-access-tokens-in-your-organization)
- [Managing your personal access tokens](https://docs.github.com/en/enterprise-cloud@latest/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens)
