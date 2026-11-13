# Ch29: Programmatic access governance

**Session outcome:** Fine-grained PAT approval is enforced in a test organization. A non-owner's token is denied until approved, reads only the selected repository, and stops working after revocation.

## Prerequisites

- Organization owner access in a non-production organization, and approval from the token-policy owner to change its PAT policy.
- A private test repository and a consenting non-owner member who can request a token.
- `gh` 2.x.
- If the organization inherits PAT policy from the enterprise, an enterprise owner. Don't override an enterprise policy.

Look at OAuth App restrictions, GitHub Apps, or classic PATs only if they affect the automation you're covering.

## Tasks

### Part A: Check the current policy

1. Open **Settings → Personal access tokens**. Note the fine-grained and classic token policies, whether approval is required, and whether each setting is organization-managed or enterprise-enforced.
2. Optional: list installed Apps if the automation uses one. This shows installations only, not their permissions or scope:

   ```bash
   gh api /orgs/<org>/installations --paginate \
     --jq '.installations[] | {id, app_slug, app_id, target_type}'
   ```

### Part B: Require approval and test it

3. Open **Settings → Personal access tokens → Settings → Fine-grained tokens**. Require administrator approval, or verify that it's already enforced.
4. Have the non-owner member create a short-lived fine-grained PAT with the organization as resource owner, **Only select repositories**, and **Contents: Read-only** for the test repository. Organization owners can bypass approval for their own requests, so an owner-created token doesn't prove the gate works.
5. Use the token only in the member's shell as `GH_TOKEN`, loaded from approved secret storage. Don't replace your own CLI credential or put the token in command history.

   ```bash
   gh api repos/<org>/<test-repo>/contents/README.md --jq '.path'
   ```

   **Denied:** the read fails while the request is pending.
6. In a separate owner session, approve the request under **Settings → Personal access tokens → Pending requests**. Retry the read. **Allowed:** it succeeds. Reading another private repository outside the token's selection must still fail, even if the member has access to it.
7. Revoke the token in the member's token settings and repeat the read. It must fail. Run `unset GH_TOKEN`.

Don't test first-time OAuth restrictions, classic PAT restrictions, or broad lifetime enforcement here. Enabling OAuth restrictions for the first time immediately disrupts existing OAuth Apps. Each of these needs its own impact analysis and rollback plan.

### Part C: Hand over

8. Keep the policy as approved unless you need to roll back. In the adoption issue, link the pending, approved, out-of-scope, and revoked results. Never record a token value. The owner can repeat the sequence for the next request.

**Blocked:** if you can't change the policy, get approval, or use a non-owner test member, stop and note the blocker in the adoption issue. The session isn't complete without the tested approval and revocation.

## Reference links

- [Setting a personal access token policy for your organization](https://docs.github.com/en/enterprise-cloud@latest/organizations/managing-programmatic-access-to-your-organization/setting-a-personal-access-token-policy-for-your-organization)
- [Managing requests for personal access tokens in your organization](https://docs.github.com/en/enterprise-cloud@latest/organizations/managing-programmatic-access-to-your-organization/managing-requests-for-personal-access-tokens-in-your-organization)
- [Enforcing policies for personal access tokens in your enterprise](https://docs.github.com/en/enterprise-cloud@latest/admin/enforcing-policies/enforcing-policies-for-your-enterprise/enforcing-policies-for-personal-access-tokens-in-your-enterprise)
- [Managing your personal access tokens](https://docs.github.com/en/enterprise-cloud@latest/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens)
- [OAuth app access restrictions](https://docs.github.com/en/enterprise-cloud@latest/organizations/managing-oauth-access-to-your-organizations-data/about-oauth-app-access-restrictions)
- [Reviewing GitHub Apps installed in your organization](https://docs.github.com/en/enterprise-cloud@latest/organizations/managing-programmatic-access-to-your-organization/reviewing-github-apps-installed-in-your-organization)
