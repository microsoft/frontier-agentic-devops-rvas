# Ch07 — Teams, Roles & Base Permissions

> Deliver a verifiable least-privilege access model with nested teams, base permissions, predefined roles, and a custom repository role.

| | |
|---|---|
| Track | Admin/Governance |
| Difficulty | Intermediate *(per-track ramp)* |
| Duration | ~4–5 hrs total, multi-session |
| Minimum input | An org + an org-owner token. *(All activities are org-scoped — no enterprise owner required.)* |
| App | Provisioned starter repository (created by setup) |
| EMU compatible | yes |

## Delivery target

- Delivery target: the customer organisation’s approved team hierarchy, repository grants, custom role, and access matrix.
- Safety boundary: change memberships, roles, and grants only with the accountable organisation owner’s approval; use the seeded structure as a sample test environment when access is constrained.
- Evidence: retain API-derived before/after snapshots, the access matrix, and role rationale.
- Owner: the customer access owner accepts the model and the team/repository maintainers receive the matrix.
- Next decision: approve tenant implementation for the selected teams or deliver the access-model proposal for owner decision.

## Prerequisites
- Recommended: Ch52 (Enterprise Landing Zone & Organization Strategy) completed first — its delegation register is the preferred source for enterprise-level team/role decisions (see the closing note); otherwise this activity's organization-level model stands on its own.
- An organization you own (or org-owner rights) on GitHub Enterprise Cloud.
- A token with the scopes listed by `modules/ghec/resources/provisioning/scripts/setup.sh doctor ch07 --org <org>` (least-privilege; for this activity: `admin:org` + `repo` + `read:org`).
- Local tooling: `gh >= 2.x`, `git`, `jq` (run `modules/ghec/resources/provisioning/scripts/setup.sh doctor` to verify).
- No GHAS, Codespaces, or enterprise-owner features are required. Custom repository roles are an org capability available on GHEC.

## What you will deliver
- Create a team hierarchy (parent + child teams) and understand how nested teams inherit access from their parent.
- Grant teams access to repositories at the correct predefined repository role (Read / Triage / Write / Maintain / Admin).
- Reason about how base (org) permission combines with team grants (the more permissive wins).
- Create and assign a custom repository role with a precise permission set that no predefined role matches.
- Add members to teams (and via teams to repos) and verify effective permissions from the API.
- Map an org chart to a least-privilege access model and document it.

## Scenario
A GHEC customer's engineering org has grown past the point where ad-hoc collaborator adds make sense. People are added directly to repos, leavers keep access, and nobody can answer "who can merge to the payments repo?" You'll replace the chaos with a team-based model: a parent team for the whole department, child teams per squad, repository access granted to teams (never to individuals), and one custom role for a contractor pattern that the built-in roles don't capture. Access becomes something you can read from an org chart — and from the API.

> [!IMPORTANT]
> Use an approved customer target first. If you have a candidate team structure and repository access model, use it wherever this guide names `ghec-ch07-frontend` or the sibling `ghec-ch07-*` artifacts, and skip Setup. Otherwise use the fallback seeded repos and starter team below, then move the validated access model to an approved customer organisation.
>
> Record the selected target, access owner, and next action.

## Sample test repository or environment
Skip if you brought your own team/repo access model.

```bash
# Bash
bash modules/ghec/resources/provisioning/scripts/setup.sh provision ch07 --org <org>
```
```powershell
# PowerShell
modules/ghec/resources/provisioning/scripts/setup.ps1 provision ch07 --org <org>
```

Setup creates these resources (all names use the `ghec-ch07-*` prefix, and teardown is prefix-guarded):
- Three seeded repos — `ghec-ch07-frontend`, `ghec-ch07-backend`, and `ghec-ch07-platform` — each with a short `README` and a `src/` tree.
- A single flat starter team `ghec-ch07-engineering` with one member (you) and no repository access yet, deliberately under-modeled so you build the hierarchy.
- A printed access snapshot (current teams + repo grants from the API) so you can prove "before" → "after."
- A printed Next steps block telling you where to start.

## Tasks
> Throughout, `ghec-ch07-frontend` is the fallback sample. If you brought your own artifact, substitute its name in every command and use your real history, teams, settings, or data as the material to work from.

### Part A — Build the team hierarchy
1. Create a parent team `ghec-ch07-engineering` (reuse the seeded one) and two child teams under it: `ghec-ch07-frontend-squad` and `ghec-ch07-backend-squad`. Create children with the parent set, e.g. `gh api -X POST /orgs/<org>/teams -f name='ghec-ch07-frontend-squad' -F parent_team_id=<parent-id>`.
2. Confirm nesting via `gh api /orgs/<org>/teams/ghec-ch07-frontend-squad --jq '.parent.name'` (should print the parent).
3. Understand inheritance: any repository access you grant the parent flows down to both child teams. You'll use this in Part B.

### Part B — Grant repository access via teams
4. Grant the parent team `Read` on all three repos (so the whole department can see everything): `gh api -X PUT /orgs/<org>/teams/ghec-ch07-engineering/repos/<org>/ghec-ch07-frontend -f permission=pull` (repeat for backend/platform).
5. Grant child teams elevated, scoped access:
   - `ghec-ch07-frontend-squad` → Write (`push`) on `ghec-ch07-frontend`.
   - `ghec-ch07-backend-squad` → Write (`push`) on `ghec-ch07-backend`.
   - Neither squad gets Write on `ghec-ch07-platform` (that's a protected, shared repo).
6. Verify effective access: `gh api /orgs/<org>/teams/ghec-ch07-frontend-squad/repos/<org>/ghec-ch07-frontend --jq '.permissions'`. Confirm the squad has push on its own repo but only the inherited pull on others.

### Part C — Predefined repository roles
7. Assign Maintain, not Admin. Create a child team `ghec-ch07-maintainers` and grant it the Maintain predefined role on `ghec-ch07-platform` (`-f permission=maintain`). Document *why* Maintain (manage settings/issues without full admin) fits a tech-lead pattern better than Admin.
8. Demonstrate Triage. Grant a team or member the Triage role somewhere and explain what Triage can do (manage issues/PRs) and cannot (push code). Use the role list reference to back your explanation.
9. Map the five predefined roles (Read / Triage / Write / Maintain / Admin) to one sentence each describing the real-world persona that fits.

### Part D — Custom repository role
10. Design a custom role the built-ins don't cover — e.g., a "contractor" who can push and manage issues but cannot manage webhooks, deploy keys, or delete the repo. Create it at the org: Org Settings → Repository roles → Create a role, basing it on Write and *removing* the sensitive permissions. (Or via `gh api -X POST /orgs/<org>/custom-repository-roles`.)
11. Assign the custom role to a team on one repo (`-f permission=<custom-role-name>`), and verify it appears: `gh api /orgs/<org>/custom-repository-roles --jq '.custom_roles[].name'`.
12. Prove the boundary: document which actions the custom role allows vs blocks, referencing the base role + the removed permissions.

### Part E — Members and access matrix
13. Add at least one member to each squad (or model it with your own account across teams) and confirm membership: `gh api /orgs/<org>/teams/ghec-ch07-frontend-squad/members --jq '.[].login'`.
14. Produce an access matrix: for each repo, list which teams have which role, pulled from the API. Save it as `ACCESS.md` in `ghec-ch07-platform`.
15. Diff against the "before" snapshot from setup to prove the org went from flat to modeled.
16. Record the enterprise-level team/role delegation decision (enterprise teams, custom organization roles, IdP-driven team sync) in `ACCESS.md`: cite Ch52's delegation register entry, or an authorized enterprise export/inspection; if neither exists, record `enterprise policy not available / not applicable`. Don't infer enterprise-wide delegation from this one organization's team model — see the closing note.

## Reference links
- About teams — https://docs.github.com/en/organizations/organizing-members-into-teams/about-teams
- Creating a team / adding a parent team — https://docs.github.com/en/organizations/organizing-members-into-teams/creating-a-team
- Managing team access to an organization repository — https://docs.github.com/en/organizations/managing-user-access-to-your-organizations-repositories/managing-team-access-to-an-organization-repository
- Repository roles for an organization — https://docs.github.com/en/organizations/managing-user-access-to-your-organizations-repositories/managing-repository-roles/repository-roles-for-an-organization
- Managing custom repository roles for an organization — https://docs.github.com/en/organizations/managing-peoples-access-to-your-organization-with-roles/managing-custom-repository-roles-for-an-organization
- Setting base permissions for an organization — https://docs.github.com/en/organizations/managing-user-access-to-your-organizations-repositories/managing-repository-roles/setting-base-permissions-for-an-organization
- Teams REST API — https://docs.github.com/en/rest/teams/teams
