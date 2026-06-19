# Ch06 — Enterprise & Organization 101 — Coach Guide

> Audience: facilitators and graders. Pair with the student `README.md`.

## Grounding conversation (you will be called)

Students are **expected to call you** to talk through this challenge's real-world impact before they consider it done. This is a required completion step, not optional — it is how we keep the learning grounded in their actual day-to-day work.

**Their question:** Coach conversation — if you were the org owner of your team's GitHub organization today, what is the first enterprise policy or default repository setting you would change, and what risk or inefficiency is it currently causing? Talk it through with your coach and connect it to a real project, task, or workflow you own.

Use these follow-ups to steer the conversation:
- Describe your current GitHub org structure — how many repos, who are the admins, is there a parent enterprise?
- What repository default (visibility, merge strategy, Actions permissions) do you know is wrong but haven't had access to fix?
- What org-level setting change would you propose in writing to your security or platform team this week?

## Facilitation notes
- **Goal in one line:** the student turns a wide-open org into a documented, least-privilege baseline and proves every setting from the API rather than from screenshots.
- **Where students get stuck:**
  - **Base permission vs team permission.** Students assume base `Read` caps everyone; remind them the **more permissive** of base permission and any explicit team/collaborator grant wins.
  - **Public / internal / private.** "Internal" is the one people misread — it means visible to **all enterprise members**, not the public. Use the visibility change in Part C to make it concrete.
  - **Changing visibility on a repo with consequences.** The CLI needs `--accept-visibility-change-consequences`; the UI shows a scary warning. That's expected.
  - **2FA requirement is a foot-gun.** If they flip "require 2FA" on an org with members lacking 2FA, those members get **removed**. Keep Part D as awareness unless they truly own the org.
- **How to unblock without giving the answer:** ask "if base permission is Read but a team grants Write, what can the member do?" (→ Write) and "where does a setting you clicked show up in `gh api /orgs/<org>`?"
- **Org-scoped note:** this challenge runs with just an org + org-owner token. `admin:org` is the scope that lets the member-privilege and repo-creation settings be written and read. No enterprise owner needed.

## Grading rubric (point-weighted, 100 pts)
| Criterion | Points | What "full marks" looks like |
|---|---:|---|
| Baseline read (Part A) | 15 | Before-snapshot captured from the API; members/owners and outside collaborators correctly distinguished |
| Member privileges (Part B) | 25 | Default permission `read`/`none`; public-repo creation off; delete/transfer restricted; fork policy set & verified |
| Visibility in practice (Part C) | 20 | Three repos' visibility confirmed; one repo changed; public/internal/private explained correctly |
| Security & workflow defaults (Part D) | 20 | Default Actions workflow permission read-only; security/dependency defaults reviewed; 2FA posture reasoned about safely |
| Verify & document (Part E) | 20 | Before/after API diff exists; `POLICY.md`/baseline doc lists every setting + rationale |
| **Total** | **100** | |

## Automated verification hints
Use these to check Definition of Done quickly (prefer `gh` CLI / API over manual clicks):
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
  gh repo view $ORG/wth-ch06-$r --json name,visibility
done

# Default Actions workflow permissions for the org (expect "read")
gh api /orgs/$ORG/actions/permissions/workflow --jq '.default_workflow_permissions'

# Members vs outside collaborators
gh api /orgs/$ORG/members --jq '.[].login'
gh api /orgs/$ORG/outside_collaborators --jq '.[].login'
```
- The single `/orgs/$ORG` JSON object is the fastest mastery signal — every Part B/D change should be reflected there.
- For the policy doc, confirm it lists the **value** of each setting, not just the name, plus a one-line rationale.
- A real before/after diff (e.g., the student saved Part A output and `diff`s it) earns the documentation points cleanly.

## Common pitfalls
- **Token missing `admin:org`.** Reads work, but writing member-privilege/repo-creation settings 403s. Fix: `gh auth refresh -s admin:org,repo,read:org`.
- **Confusing "internal" with "public."** Internal = enterprise-wide visibility; on a standalone org without an enterprise it behaves like private to non-members. Make sure they read the visibility doc.
- **Visibility change blocked from CLI** without `--accept-visibility-change-consequences`.
- **Flipping 2FA requirement on a live org** and removing members. Keep it awareness-only unless they fully own membership.
- **Assuming base `Read` overrides explicit grants.** It doesn't — the more permissive of base and team/collaborator grant applies.

## Useful references for coaching

- [About organizations](https://docs.github.com/en/organizations/collaborating-with-groups-in-organizations/about-organizations), [Setting permissions for adding outside collaborators](https://docs.github.com/en/organizations/managing-organization-settings/setting-permissions-for-adding-outside-collaborators).

## Teardown
```bash
wth teardown ch06 --org <org> --yes        # wraps the scripts below
./scripts/teardown.sh ch06 --org <org> --yes   # Bash
./scripts/teardown.ps1 ch06 --org <org> --yes  # PowerShell
```
- Removes only `wth-ch06-*` artifacts (prefix-guarded): the three sample repos and the `wth-ch06-members` team.
- **Manual cleanup (required):** the **organization-level settings** the student changed — base permission, repo-creation flags, fork policy, default workflow permissions — are **not** namespaced and are **not** reverted by teardown. If the org is a reusable sandbox, have the student record the original "before" values from Part A and restore them, or accept the new (safer) baseline. This is expected for admin challenges and worth calling out at the start.

## Time budget
- Setup + baseline read: ~30 min
- Part B (member privileges): ~45 min
- Part C (visibility): ~30 min
- Part D (security/workflow defaults): ~45 min
- Part E (verify + document): ~30 min
- Stretch: ~45 min
- **Total facilitated:** ~3–4 hrs across sessions.
