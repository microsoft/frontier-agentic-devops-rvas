# Ch07 — Teams, Roles & Base Permissions — Coach Guide

> Audience: facilitators and graders. Pair with the student `README.md`.

## Facilitation notes
- **Goal in one line:** the student replaces ad-hoc collaborator adds with a nested team model, grants repo access through teams at the right predefined role, and builds one custom role the built-ins can't express — all verifiable from the API.
- **Where students get stuck:**
  - **Inheritance direction.** Nested teams inherit access **down** from the parent, not up. A grant on the parent reaches children; a grant on a child does *not* reach siblings or the parent.
  - **"More permissive wins."** Effective access = the **maximum** of base org permission, any team grant, and any direct collaborator grant. Students expect a strict ceiling; there isn't one without enterprise policy.
  - **Predefined role names map to API permission strings.** Read=`pull`, Write=`push`, Admin=`admin`; Triage and Maintain use their own names. The mismatch (push≠Push-button) trips people up.
  - **Custom roles are org-scoped repository roles**, not org roles. They're created once at the org and assigned per repo/team.
- **How to unblock without giving the answer:** ask "if the parent has Read and the child has Write on the same repo, what can a child member do?" (→ Write) and "which built-in role lets a lead manage settings but not delete the repo?" (→ Maintain).
- **Org-scoped note:** runs with an org + org-owner token. `admin:org` is required to create teams, grant repo roles, and create custom repository roles. No enterprise owner needed.

## Grading rubric (point-weighted, 100 pts)
| Criterion | Points | What "full marks" looks like |
|---|---:|---|
| Team hierarchy (Part A) | 20 | Parent + two children created; nesting confirmed via `.parent.name`; inheritance explained |
| Team repo access (Part B) | 20 | Parent grants Read on all three; each squad has Write on its own repo only; verified via API |
| Predefined roles (Part C) | 20 | Maintain granted on platform with rationale; Triage demonstrated; five roles mapped to personas |
| Custom repository role (Part D) | 25 | Custom role created (base Write minus sensitive perms), assigned to a team, boundary documented |
| Members + verification (Part E) | 15 | Members added to squads; `ACCESS.md` matrix generated from API; before/after diff shown |
| **Total** | **100** | |

## Automated verification hints
Use these to check Definition of Done quickly (prefer `gh` CLI / API over manual clicks):
```bash
ORG=<org>

# Team list + nesting (child should report a parent)
gh api /orgs/$ORG/teams --jq '.[] | {slug, parent: .parent.slug}'
gh api /orgs/$ORG/teams/wth-ch07-frontend-squad --jq '.parent.name'   # non-null

# Effective repo permission for a team on a repo
gh api /orgs/$ORG/teams/wth-ch07-frontend-squad/repos/$ORG/wth-ch07-frontend --jq '.role_name, .permissions'

# Parent grant should appear (inherited) on a child for the shared repos
gh api /orgs/$ORG/teams/wth-ch07-engineering/repos/$ORG/wth-ch07-platform --jq '.permissions'

# Custom repository roles defined at the org
gh api /orgs/$ORG/custom-repository-roles --jq '.custom_roles[] | {name, base_role}'

# Which teams have access to a given repo, and at what role
gh api /repos/$ORG/wth-ch07-platform/teams --jq '.[] | {slug, permission}'

# Team membership
gh api /orgs/$ORG/teams/wth-ch07-backend-squad/members --jq '.[].login'
```
- The `role_name` field on the team→repo endpoint is the fastest mastery signal — it shows `read`/`write`/`maintain` or the **custom role name** directly.
- For the custom role, confirm `base_role` is `push`/`write` and that the sensitive permissions were removed (the role's `permissions` array shouldn't include webhook/deploy-key management).
- `ACCESS.md` should be reproducible from the API calls above, not hand-typed guesses.

## Common pitfalls
- **Granting access to individuals instead of teams.** The whole point is team-based access — direct collaborator grants defeat it. Coach toward team grants.
- **Expecting base permission to cap team grants.** It doesn't; the more permissive wins. Enterprise policy would be needed to enforce a ceiling.
- **Wrong API permission string.** `permission=read` is invalid for the team→repo PUT; use `pull`/`triage`/`push`/`maintain`/`admin` or the custom role name.
- **Custom role assigned but role name typo'd** in the PUT — the grant 422s or silently falls back.
- **Token missing `admin:org`.** Team creation and custom-role creation fail. Fix: `gh auth refresh -s admin:org,repo,read:org`.

## Teardown
```bash
wth teardown ch07 --org <org> --yes
./scripts/teardown.sh ch07 --org <org> --yes   # Bash
./scripts/teardown.ps1 ch07 --org <org> --yes  # PowerShell
```
- Removes only `wth-ch07-*` artifacts (prefix-guarded): the three sample repos and all `wth-ch07-*` teams.
- **Manual cleanup (required):** the **custom repository role** the student created is org-scoped and **not** `wth-ch07-*` prefixed, so teardown leaves it in place. Have the student delete it by hand (**Org Settings → Repository roles**, or `gh api -X DELETE /orgs/<org>/custom-repository-roles/<role-id>`) if the org is a reusable sandbox.

## Time budget
- Setup + access snapshot: ~30 min
- Part A (hierarchy): ~45 min
- Part B (team grants): ~45 min
- Part C (predefined roles): ~45 min
- Part D (custom role): ~1 hr
- Part E (members + matrix): ~30 min
- Stretch: ~45 min
- **Total facilitated:** ~4–5 hrs across sessions.
