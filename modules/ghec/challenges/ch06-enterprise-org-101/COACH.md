# Ch06 — Enterprise & Organization 101 — Delivery Assurance Guide

> Audience: delivery assurance leads and authorized customer implementation owners. Pair with the corresponding customer implementation `README.md`.
> Customer authorization and rollout boundary: Apply changes in a customer-owned tenant or repository only after the named customer owner authorizes the scope. A fallback is a sample test repository or environment, not the destination: record its evidence, risks and controls, accountable owner, handover, and the explicit tenant adoption, cutover, or rollout decision.


## Customer adoption decision

Required delivery assurance check: before implementation is accepted, confirm the authorized tenant scope, implementation evidence, risk controls, accountable owner, handover, and next adoption action.

Decision prompt: if you were the org owner of your team's GitHub organization today, what is the first enterprise policy or default repository setting you would change, and what risk or inefficiency is it currently causing? Record the accountable owner, implementation evidence, risk or blocker, and next customer adoption action.

> Customer implementation preference: prioritize an authorized customer tenant or artifact over the `ghec-ch06-public-sample` sample. If a sample is necessary, record the target tenant scope, accountable owner, authorization blocker, evidence to carry forward, and the adoption, cutover, or rollout decision. The sample is a safe fallback, not the destination.

Use these prompts to verify customer ownership and the next action:
- Describe your current GitHub org structure — how many repos, who are the admins, is there a parent enterprise?
- What repository default (visibility, merge strategy, Actions permissions) do you know is wrong but haven't had access to fix?
- What org-level setting change would you propose in writing to your security or platform team this week?

## Delivery assurance notes
- Customer adoption outcome: the customer implementation owner turns a wide-open org into a documented, least-privilege baseline and proves every setting from the API rather than from screenshots.
- Implementation risks to verify:
  - Base permission vs team permission. Customer implementation owners assume base `Read` caps everyone; remind them the more permissive of base permission and any explicit team/collaborator grant wins.
  - Public / internal / private. "Internal" is the one people misread — it means visible to all enterprise members, not the public. Use the visibility change in Part C to make it concrete.
  - Changing visibility on a repo with consequences. The CLI needs `--accept-visibility-change-consequences`; the UI shows a scary warning. That's expected.
  - 2FA requirement is a foot-gun. If they flip "require 2FA" on an org with members lacking 2FA, those members get removed. Keep Part D as awareness unless they truly own the org.
- Delivery lead prompts: ask "if base permission is Read but a team grants Write, what can the member do?" (→ Write) and "where does a setting you clicked show up in `gh api /orgs/<org>`?"
- Org-scoped note: this activity runs with just an org + org-owner token. `admin:org` is the scope that lets the member-privilege and repo-creation settings be written and read. No enterprise owner needed.

## Implementation acceptance evidence
| Criterion | Assurance weight | Customer-owned evidence |
|---|---:|---|
| Baseline read (Part A) | 15 | Before-snapshot captured from the API; members/owners and outside collaborators correctly distinguished |
| Member privileges (Part B) | 25 | Default permission `read`/`none`; public-repo creation off; delete/transfer restricted; fork policy set & verified |
| Visibility evidence (Part C) | 20 | Three repos' visibility confirmed; one repo changed; public/internal/private documented correctly |
| Security & workflow defaults (Part D) | 20 | Default Actions workflow permission read-only; security/dependency defaults reviewed; 2FA posture reasoned about safely |
| Verify & document (Part E) | 20 | Before/after API diff exists; `POLICY.md`/baseline doc lists every setting + rationale |
| Assurance coverage | 100 | |

## Implementation verification evidence
Use these to verify the customer implementation evidence (prefer `gh` CLI / API over manual clicks):
```bash
ORG=<org>

# The whole member-privilege baseline in one shot
gh api /orgs/$ORG --jq '{
  default_repository_permission,
  members_can_create_repositories,
  members_can_create_public_repositories,
  members_can_create_private_repositories,
  members_can_create_internal_repositories,
  members_can_fork_private_repositories,
  two_factor_requirement_enabled,
  web_commit_signoff_required
}'

# Default permission must be read or none
gh api /orgs/$ORG --jq '.default_repository_permission'      # expect "read" or "none"

# Public repo creation must be disabled
gh api /orgs/$ORG --jq '.members_can_create_public_repositories'   # expect false

# Sample repos + their visibility
for r in public-sample private-sample internal-sample; do
  gh repo view $ORG/ghec-ch06-$r --json name,visibility
done

# Default Actions workflow permissions for the org (expect "read")
gh api /orgs/$ORG/actions/permissions/workflow --jq '.default_workflow_permissions'

# Members vs outside collaborators
gh api /orgs/$ORG/members --jq '.[].login'
gh api /orgs/$ORG/outside_collaborators --jq '.[].login'
```
- The single `/orgs/$ORG` JSON object is the fastest mastery signal — every Part B/D change should be reflected there.
- For the policy doc, confirm it lists the value of each setting, not just the name, plus a one-line rationale.
- A real before/after diff (e.g., the customer implementation owner saved Part A output and `diff`s it) earns the documentation points cleanly.

## Common pitfalls
- Token missing `admin:org`. Reads work, but writing member-privilege/repo-creation settings 403s. Fix: `gh auth refresh -s admin:org,repo,read:org`.
- Confusing "internal" with "public." Internal = enterprise-wide visibility; on a standalone org without an enterprise it behaves like private to non-members. Make sure they read the visibility doc.
- Visibility change blocked from CLI without `--accept-visibility-change-consequences`.
- Flipping 2FA requirement on a live org and removing members. Keep it awareness-only unless they fully own membership.
- Assuming base `Read` overrides explicit grants. It doesn't — the more permissive of base and team/collaborator grant applies.

## References for delivery leads

- [About organizations](https://docs.github.com/en/organizations/collaborating-with-groups-in-organizations/about-organizations), [Setting permissions for adding outside collaborators](https://docs.github.com/en/organizations/managing-organization-settings/setting-permissions-for-adding-outside-collaborators).

## Teardown
```bash
bash modules/ghec/resources/provisioning/scripts/setup.sh teardown ch06 --org <org> --yes   # Bash
modules/ghec/resources/provisioning/scripts/setup.ps1 teardown ch06 --org <org> --yes  # PowerShell
```
- Removes only `ghec-ch06-*` artifacts (prefix-guarded): the three sample repos and the `ghec-ch06-members` team.
- Manual cleanup (required): the organization-level settings the customer implementation owner changed — base permission, repo-creation flags, fork policy, default workflow permissions — are not namespaced and are not reverted by teardown. If the org is a reusable sandbox, have the customer implementation owner record the original "before" values from Part A and restore them, or accept the new (safer) baseline. This is expected for admin activities and worth calling out at the start.

## Time budget
- Setup + baseline read: ~30 min
- Part B (member privileges): ~45 min
- Part C (visibility): ~30 min
- Part D (security/workflow defaults): ~45 min
- Part E (verify + document): ~30 min
- Stretch: ~45 min
- Indicative implementation effort: ~3–4 hrs across sessions.
