# Ch07: Organization and team access

**Session outcome:** Organization base permissions and team grants give members the access their work needs. Non-owner tests verify allowed actions and access limits.

## Prerequisites
- Approval to test the selected teams and repositories, with consenting non-owner members. Reuse existing organization-boundary decisions when available.
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
A GHEC customer grants repository access directly to individuals. Former employees retain access, and the team cannot identify who can merge to the payments repo. Configure a parent team for the department and child teams for squads. Grant repository access through teams and define a custom contractor role where predefined roles do not fit. Verify the access model through the API.

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
- Three seeded repos: `ghec-ch07-frontend`, `ghec-ch07-backend`, and `ghec-ch07-platform`. Each has a short `README` and a `src/` tree.
- A starter team `ghec-ch07-engineering` with one member (you), no child teams, and no repository access yet.
- A printed access snapshot (current teams + repo grants from the API) so you can prove "before" → "after."
- A printed Next steps block telling you where to start.

## Tasks

### Part A: Build the team hierarchy
Before creating teams, confirm the organization boundary with its owner. Reuse the existing organization unless there is an approved isolation or ownership need. Billing allocation alone does not require another organization; organizations in one enterprise cannot select different data-residency regions.

Snapshot base permissions and membership:

```bash
export ORG="YOUR-ORG"
gh api "orgs/$ORG" --jq '{default_repository_permission,members_can_delete_repositories,members_can_fork_private_repositories,two_factor_requirement_enabled}'
gh api "orgs/$ORG/members?per_page=100" --paginate --jq '.[].login'
gh api "orgs/$ORG/outside_collaborators?per_page=100" --paginate --jq '.[].login'
```

With approval, set **Organization settings → Member privileges → Base permissions** to Read or None, according to the customer's access model. Base permission combines with direct and team grants; the highest permission wins. Outside collaborators have repository-level access, not organization membership.

Use a consenting non-owner member with no direct or team grant on a private test repository. Base Read should permit reading but not pushing; Base None should deny reading. Internal repositories remain readable to enterprise members, so they cannot prove the private-repository denial.

**Repository creation belongs to Ch36.** Preserve its App exception and active repository policy; do not disable creation with a blanket setting here.

1. Create a parent team `ghec-ch07-engineering` (reuse the seeded one) and two child teams under it: `ghec-ch07-frontend-squad` and `ghec-ch07-backend-squad`. Create children with the parent set, e.g. `gh api -X POST /orgs/<org>/teams -f name='ghec-ch07-frontend-squad' -F parent_team_id=<parent-id>`.
2. Confirm nesting via `gh api /orgs/<org>/teams/ghec-ch07-frontend-squad --jq '.parent.name'` (should print the parent).
3. Understand inheritance: any repository access you grant the parent flows down to both child teams. You'll use this in Part B.

### Part B: Grant repository access via teams
4. Grant the parent team `Read` on all three repos (so the whole department can see everything): `gh api -X PUT /orgs/<org>/teams/ghec-ch07-engineering/repos/<org>/ghec-ch07-frontend -f permission=pull` (repeat for backend/platform).
5. Grant child teams elevated, scoped access:
   - `ghec-ch07-frontend-squad` → Write (`push`) on `ghec-ch07-frontend`.
   - `ghec-ch07-backend-squad` → Write (`push`) on `ghec-ch07-backend`.
   - Neither squad gets Write on `ghec-ch07-platform` (that's a protected, shared repo).
6. Verify effective access: `gh api /orgs/<org>/teams/ghec-ch07-frontend-squad/repos/<org>/ghec-ch07-frontend -H 'Accept: application/vnd.github.v3.repository+json' --jq '.permissions'`. Confirm the squad has push on its own repo but only the inherited pull on others.

### Part C: Predefined repository roles
7. Assign Maintain, not Admin. Create a child team `ghec-ch07-maintainers` and grant it the Maintain predefined role on `ghec-ch07-platform` (`-f permission=maintain`). Document *why* Maintain (manage settings/issues without full admin) fits a tech-lead pattern better than Admin.
8. Demonstrate Triage. Grant a team or member the Triage role somewhere and explain what Triage can do (manage issues/PRs) and cannot (push code). Use the role list reference to back your explanation.
9. Map the five predefined roles (Read / Triage / Write / Maintain / Admin) to one sentence each describing the real-world persona that fits.

### Part D: Custom repository role
10. Start with a built-in role. **Custom repository roles add permissions to a base role; they cannot subtract inherited permissions.** Use built-in Write for a contributor who should push without administrative settings access.
11. If the built-in role lacks a needed permission, select that permission in **Organization settings → Repository roles**. Create the role and assign it to a test team.
12. As a non-owner test member, perform one allowed action and attempt one denied action. First check the member's direct grants and inherited access, including organization base permissions. The highest effective permission wins.

### Part E: Members and access matrix
13. Add a consenting non-owner test member to each tested squad. Confirm membership and test read and write access as those members. An owner account cannot prove the member's access limits.
14. Record each tested repository's team roles and effective member permissions in the existing access record or adoption issue. A separate access document is unnecessary if that record already exists.
15. Diff against the "before" snapshot from setup to prove the org went from flat to modeled.
16. Use an existing enterprise delegation decision or authorized export when available. Do not infer enterprise policy from this organization's settings.

### Organization defaults checklist

Review these settings with the organization owner. Change only approved gaps and keep the before/after API output in the access record:

- Restrict member deletion, transfer, and visibility changes to the intended administrators. Check private/internal forking against the approved contribution route. EMU cannot create public repositories.
- Prefer read-only default Actions permissions. Check `gh api "orgs/$ORG/actions/permissions/workflow"`; set the approved default under **Organization settings → Actions → General**.
- Read the 2FA posture without changing it during an access test. Enabling a requirement can remove members; use the customer's identity rollout for that change.
- Check the default branch for new repositories and reuse the security defaults from the GHAS security-configuration session. A repository setting cannot prove an enterprise policy you cannot inspect.

## Reference links
- [About teams](https://docs.github.com/en/organizations/organizing-members-into-teams/about-teams)
- [Creating a team / adding a parent team](https://docs.github.com/en/organizations/organizing-members-into-teams/creating-a-team)
- [Managing team access to an organization repository](https://docs.github.com/en/organizations/managing-user-access-to-your-organizations-repositories/managing-team-access-to-an-organization-repository)
- [Repository roles for an organization](https://docs.github.com/en/organizations/managing-user-access-to-your-organizations-repositories/managing-repository-roles/repository-roles-for-an-organization)
- [Managing custom repository roles for an organization](https://docs.github.com/en/organizations/managing-peoples-access-to-your-organization-with-roles/managing-custom-repository-roles-for-an-organization)
- [Setting base permissions for an organization](https://docs.github.com/en/organizations/managing-user-access-to-your-organizations-repositories/managing-repository-roles/setting-base-permissions-for-an-organization)
- [Teams REST API](https://docs.github.com/en/rest/teams/teams)
