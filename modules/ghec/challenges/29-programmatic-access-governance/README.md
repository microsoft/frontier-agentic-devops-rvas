# Ch29: Programmatic access governance

**Session outcome:** The approved fine-grained PAT policy controls a non-owner's test request. The approved token reads only the selected repository, and revocation removes that access.

Use this session for a token-approval or access-scope gap. Review only the applications and tokens affected by the proposed change. A portfolio-wide inventory is optional.

## Prerequisites

- GitHub Enterprise Cloud organization and organization-owner access for inspection.
- `gh >= 2.x` and `jq` for the optional read-only API inventory.
- An enterprise owner or an authorized export of enterprise PAT policy only when enterprise-level PAT policy must be assessed.
- A named token-policy owner, an approved private test repository, and a consenting non-owner organization member who can request a test token.

## Scope and guardrails

Fine-grained PAT approval is the required pilot. Inspect OAuth App restrictions,
installed GitHub Apps, or classic PAT policy only when they affect the selected
automation. Do not create or reconfigure an App.

Use the customer's approved organization scope. Check current App permissions and approval settings here.

First establish the **effective source level** for every setting: organization-managed, enterprise-enforced/inherited, or unavailable to the current inspector. An organization owner may inspect organization settings; do not infer enterprise policy from a missing organization control.

OAuth App restrictions and GitHub App review are different controls. OAuth restrictions are organization-only; enabling OAuth restrictions **for the first time immediately disrupts existing OAuth Apps** until they are approved. Installed GitHub Apps instead require an authority, permission/repository-scope review, and recurring review cadence.

> This activity supports EMU because it inventories access without creating identities. Treat identity lifecycle as enterprise/SCIM managed. If enterprise policy allows an administrator exemption for an EMU or another user, record its approver, affected automation, scope, expiry, and compatibility with SCIM joiner/leaver controls. An exemption does not replace least privilege or SCIM deprovisioning.

## Tasks

### Part A: Establish the inspection boundary

1. Record the organization, customer owner, approval boundary, whether it is EMU, and the available role: organization owner, enterprise owner, or authorized enterprise-policy export.
2. If the selected automation also uses an App, inspect its access under **Settings → Third-party access**. Identify the owner, repository selection, and permissions. Otherwise skip App inventory.
3. For that App review, capture a read-only installed-App snapshot where API access is available:

   ```bash
   gh api /orgs/<org>/installations --paginate \
     --jq '.installations[] | {id, app_slug, app_id, target_type}'
   ```

   Add the Settings evidence needed to identify repository selection and permissions; this endpoint alone is not a complete authority or scope record.
4. Inspect **Settings → Personal access tokens**: fine-grained token policy, classic-token policy, active tokens, and pending fine-grained token requests. Record approval requirement, maximum lifetime, restriction status, active-token owners/purpose, request decision, and the effective source level. Use audit-log or API insights where available and permitted to corroborate owner, approval, installation, or policy events; attach the query/export and date rather than claiming unavailable data.

### Part B: Build the programmatic-access inventory

5. In the existing adoption issue or access inventory, record the selected token's purpose, owner, allowed repositories, permissions, and expiry. Never record its value. Add other entries only when they affect this change.
6. If an installed GitHub App is in scope, confirm its installation authority and repository reach with its owner.
7. If an OAuth restriction is proposed, identify existing consumers and their approval path before changing it. Otherwise leave that separate control alone.

### Part C: Make a safe policy decision

8. Evaluate fine-grained PAT approval and lifetime separately from classic PAT restriction. Fine-grained PATs should have a documented approval decision and an approved lifetime; assess automation and SCIM/EMU impact before enforcement. Classic PAT access should be restricted only after each affected workflow has a migration path to a GitHub App or fine-grained PAT, or an approved time-bound exception.
9. Have the token-policy owner approve the pilot policy and rollback. Identify whether the organization controls it or inherits it from the enterprise.
10. In the approved non-production organization, open **Settings → Personal access tokens → Settings → Fine-grained tokens**. With the owner's approval, require administrator approval, or verify the inherited requirement when it is already enforced. Do not override an enterprise policy.

    Have the non-owner test member create a short-lived fine-grained PAT with the organization as resource owner, **Only select repositories**, and **Contents: Read-only** for the approved private test repository. Organization owners can bypass approval for their own requests, so an owner-created token does not prove this gate.

    Before approval, use that token to attempt the private repository read and verify it is denied. In a separate authenticated owner session, approve the request under **Settings → Personal access tokens → Pending requests**. Retry the read and verify it succeeds. A read of another private repository outside the token's selection must still fail, even if the user otherwise has access to it.

    Use the test token only in the test member's shell as `GH_TOKEN`, loaded from approved secret storage. Do not replace the owner's CLI credential or put the token in command history. The test read is:

    ```bash
    gh api repos/<org>/<approved-test-repo>/contents/README.md --jq '.path'
    ```

    Finally, revoke the test token from the member's token settings and repeat the same read. It must fail. Clear the test token from the shell with `unset GH_TOKEN`.

    Do **not** make OAuth-restrictions first enablement, classic-PAT restriction, or broad token-lifetime enforcement a required test. Those changes require their own approved impact analysis, exception handling, and rollback/change plan.

### Part D: Verify evidence and hand over

11. Recheck the effective token setting and source level. Link the access tests rather than duplicating them in another register.
12. Hand over the inventory and decision to the customer organization owner. If enterprise PAT policy is in scope, include the enterprise owner or authorized policy-export owner. Name the next action: approve a low-risk pilot, obtain a policy export, sponsor a migration, approve an exception, or schedule review.

Keep the policy and the pending, approved, out-of-scope, and revoked results in the existing change record. The owner can use this sequence for the next approved request. Retain the approved policy unless the change requires rollback.

An inventory alone is **assessment accepted**, not an implemented access control. If a safe pilot or the required approval is unavailable, record **blocked / not tested**. Do not enable broad OAuth or classic-PAT restrictions merely to complete this session.

## Reference links

- [OAuth app access restrictions](https://docs.github.com/en/enterprise-cloud@latest/organizations/managing-oauth-access-to-your-organizations-data/about-oauth-app-access-restrictions)
- [Reviewing GitHub Apps installed in your organization](https://docs.github.com/en/enterprise-cloud@latest/organizations/managing-programmatic-access-to-your-organization/reviewing-github-apps-installed-in-your-organization)
- [Limiting OAuth App and GitHub App access requests and installations](https://docs.github.com/en/enterprise-cloud@latest/organizations/managing-programmatic-access-to-your-organization/limiting-oauth-app-and-github-app-access-requests-and-installations)
- [Setting a personal access token policy for your organization](https://docs.github.com/en/enterprise-cloud@latest/organizations/managing-programmatic-access-to-your-organization/setting-a-personal-access-token-policy-for-your-organization)
- [Enforcing policies for personal access tokens in your enterprise](https://docs.github.com/en/enterprise-cloud@latest/admin/enforcing-policies/enforcing-policies-for-your-enterprise/enforcing-policies-for-personal-access-tokens-in-your-enterprise)
- [Managing requests for personal access tokens in your organization](https://docs.github.com/en/enterprise-cloud@latest/organizations/managing-programmatic-access-to-your-organization/managing-requests-for-personal-access-tokens-in-your-organization)
- [Managing your personal access tokens](https://docs.github.com/en/enterprise-cloud@latest/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens)
