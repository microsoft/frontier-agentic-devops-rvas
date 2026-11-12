# Ch29: Programmatic access governance

**Session outcome:** The approved fine-grained PAT policy controls a non-owner's test request. The approved token reads only the selected repository, and revocation removes that access.

Use this session for a token-approval or access-scope gap. Review only the applications and tokens the change affects. A portfolio-wide inventory is optional.

## Prerequisites

- GitHub Enterprise Cloud organization and organization-owner access for inspection.
- `gh >= 2.x` and `jq` for the optional read-only API inventory.
- An enterprise owner or an authorized export of enterprise PAT policy, only if you must assess enterprise-level PAT policy.
- A named token-policy owner, an approved private test repository, and a consenting non-owner organization member who can request a test token.

## Scope and guardrails

The pilot is fine-grained PAT approval. Look at OAuth App restrictions,
installed GitHub Apps, or classic PAT policy only if they affect the selected
automation. Don't create or reconfigure an App.

Stay within the customer's approved organization scope. Check current App permissions and approval settings here.

For every setting, identify the **effective source level**: organization-managed, enterprise-enforced or inherited, or not visible to you. An organization owner can inspect organization settings, but a missing organization control doesn't tell you the enterprise policy.

OAuth App restrictions and GitHub App review are different controls. OAuth restrictions are organization-only, and enabling them **for the first time immediately disrupts existing OAuth Apps** until they're approved. For installed GitHub Apps, find out who authorized the installation, review permissions and repository scope, and set a recurring review date.

> This session works with EMU because it inventories access and creates no identities. Identity lifecycle is managed by the enterprise and SCIM. If enterprise policy lets an administrator exempt an EMU or other user, record the approver, affected automation, scope, expiry, and whether it fits SCIM joiner and leaver controls. An exemption doesn't replace least privilege or SCIM deprovisioning.

## Tasks

### Part A: Establish the inspection boundary

1. Record the organization, customer owner, what's approved, whether it's EMU, and your role: organization owner, enterprise owner, or authorized enterprise-policy export.
2. If the selected automation also uses an App, inspect its access under **Settings → Third-party access**. Note the owner, repository selection, and permissions. Otherwise skip the App inventory.
3. If API access is available, capture the installed-App snapshot:

   ```bash
   gh api /orgs/<org>/installations --paginate \
     --jq '.installations[] | {id, app_slug, app_id, target_type}'
   ```

   Add evidence from Settings for repository selection and permissions. This endpoint alone doesn't show authority or scope.
4. Inspect **Settings → Personal access tokens**: fine-grained token policy, classic-token policy, active tokens, and pending fine-grained token requests. Record the approval requirement, maximum lifetime, restriction status, active-token owners and purposes, request decision, and effective source level. If you have access, confirm owner, approval, installation, and policy events from audit logs or API data, and attach the query or export and its date. Don't claim data you can't see.

### Part B: Build the programmatic-access inventory

5. In the existing adoption issue or access inventory, record the selected token's purpose, owner, allowed repositories, permissions, and expiry. Never record its value. Add other entries only if they affect this change.
6. If an installed GitHub App is in scope, confirm its installation authority and repository reach with its owner.
7. If you propose an OAuth restriction, find the existing consumers and their approval path before changing it. Otherwise leave that control alone.

### Part C: Make a safe policy decision

8. Evaluate fine-grained PAT approval and lifetime separately from classic PAT restriction. Fine-grained PATs need a documented approval decision and an approved lifetime, and you should assess the impact on automation and SCIM/EMU before enforcing. Restrict classic PAT access only after each affected workflow has a migration path to a GitHub App or fine-grained PAT, or an approved time-bound exception.
9. Have the token-policy owner approve the pilot policy and the rollback. Note whether the organization controls the policy or inherits it from the enterprise.
10. In the approved non-production organization, open **Settings → Personal access tokens → Settings → Fine-grained tokens**. With the owner's approval, require administrator approval, or verify the inherited requirement if it's already enforced. Don't override an enterprise policy.

    Have the non-owner test member create a short-lived fine-grained PAT with the organization as resource owner, **Only select repositories**, and **Contents: Read-only** for the approved private test repository. Organization owners can bypass approval for their own requests, so an owner-created token doesn't prove the gate works.

    Before approval, use that token to try reading the private repository and verify it's denied. In a separate owner session, approve the request under **Settings → Personal access tokens → Pending requests**. Retry the read and verify it succeeds. A read of another private repository outside the token's selection must still fail, even if the user has access to it.

    Use the test token only in the test member's shell as `GH_TOKEN`, loaded from approved secret storage. Don't replace the owner's CLI credential or put the token in command history. The test read is:

    ```bash
    gh api repos/<org>/<approved-test-repo>/contents/README.md --jq '.path'
    ```

    Finally, revoke the test token in the member's token settings and repeat the read. It must fail. Clear the token from the shell with `unset GH_TOKEN`.

    Do **not** test first-time OAuth restrictions, classic PAT restrictions, or broad token lifetime enforcement here. Each needs its own approved impact analysis, exception handling, and change plan with rollback.

### Part D: Verify evidence and hand over

11. Recheck the effective token setting and source level. Link to the access tests instead of copying them into another register.
12. Hand over the inventory and decision to the customer organization owner. If enterprise PAT policy is in scope, include the enterprise owner or authorized policy-export owner. Name the next action: approve a low-risk pilot, get a policy export, sponsor a migration, approve an exception, or schedule a review.

Keep the policy and the pending, approved, out-of-scope, and revoked results in the existing change record. The owner can repeat this sequence for the next request. Keep the approved policy unless you need to roll back.

An inventory alone is **assessment accepted**, not an implemented access control. If you can't run a safe pilot or get the approval, record **blocked / not tested**. Don't enable broad OAuth or classic PAT restrictions just to finish this session.

## Reference links

- [OAuth app access restrictions](https://docs.github.com/en/enterprise-cloud@latest/organizations/managing-oauth-access-to-your-organizations-data/about-oauth-app-access-restrictions)
- [Reviewing GitHub Apps installed in your organization](https://docs.github.com/en/enterprise-cloud@latest/organizations/managing-programmatic-access-to-your-organization/reviewing-github-apps-installed-in-your-organization)
- [Limiting OAuth App and GitHub App access requests and installations](https://docs.github.com/en/enterprise-cloud@latest/organizations/managing-programmatic-access-to-your-organization/limiting-oauth-app-and-github-app-access-requests-and-installations)
- [Setting a personal access token policy for your organization](https://docs.github.com/en/enterprise-cloud@latest/organizations/managing-programmatic-access-to-your-organization/setting-a-personal-access-token-policy-for-your-organization)
- [Enforcing policies for personal access tokens in your enterprise](https://docs.github.com/en/enterprise-cloud@latest/admin/enforcing-policies/enforcing-policies-for-your-enterprise/enforcing-policies-for-personal-access-tokens-in-your-enterprise)
- [Managing requests for personal access tokens in your organization](https://docs.github.com/en/enterprise-cloud@latest/organizations/managing-programmatic-access-to-your-organization/managing-requests-for-personal-access-tokens-in-your-organization)
- [Managing your personal access tokens](https://docs.github.com/en/enterprise-cloud@latest/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens)
