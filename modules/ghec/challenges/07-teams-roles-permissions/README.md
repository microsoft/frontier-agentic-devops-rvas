# Ch07: Organization and team access

**Session outcome:** Base permissions and team grants give members the access their work needs. Tests with non-owner members confirm what they can and can't do.

## Prerequisites
- Approval to test the chosen teams and repositories, and non-owner members who agree to take part. Reuse existing organization-boundary decisions.
- An organization you own (or org-owner rights) on GitHub Enterprise Cloud.
- A token with the scopes listed by `modules/ghec/resources/provisioning/scripts/setup.sh doctor ch07 --org <org>` (least privilege; here: `admin:org` + `repo` + `read:org`).
- Local tooling: `gh >= 2.x`, `git`, `jq` (run `modules/ghec/resources/provisioning/scripts/setup.sh doctor` to verify).
- No GHAS, Codespaces, or enterprise-owner features needed. GHEC orgs support custom repository roles.

## What you will deliver
- Create a team hierarchy (parent and child teams) and see how child teams inherit the parent's access.
- Grant teams access to repositories at the right predefined repository role (Read / Triage / Write / Maintain / Admin).
- See how organization base permissions combine with team grants: the highest permission wins.
- Create and assign a custom repository role for a permission set no predefined role matches.
- Add members to teams and check their effective permissions through the API.
- Map an org chart to a least-privilege access model and document it.

## Scenario
A GHEC customer grants repository access directly to individuals. Former employees retain access, and the team cannot identify who can merge to the payments repo. Create a parent team for the department and child teams for squads. Grant repository access through teams, and add a custom contractor role where predefined roles don't fit. Check the result through the API.

> [!IMPORTANT]
> Use a customer team structure and access model if you have one: use it wherever this guide names `ghec-ch07-frontend` or the other `ghec-ch07-*` artifacts, and skip Setup. Otherwise test with the seeded repos and starter team below, then apply the access model to the customer organisation.
>
> Record the target, the access owner, and the next action.

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
- An API snapshot of current teams and repository grants for comparison after the changes.

## Tasks

### Part A: Build the team hierarchy
Before creating teams, confirm the organization boundary with its owner. Reuse the existing organization unless there is an approved need for isolation or separate ownership. Billing allocation alone doesn't need another organization. Organizations in one enterprise can't pick different data-residency regions.

Snapshot base permissions and membership:

```bash
export ORG="YOUR-ORG"
gh api "orgs/$ORG" --jq '{default_repository_permission,members_can_delete_repositories,members_can_fork_private_repositories,two_factor_requirement_enabled}'
gh api "orgs/$ORG/members?per_page=100" --paginate --jq '.[].login'
gh api "orgs/$ORG/outside_collaborators?per_page=100" --paginate --jq '.[].login'
```

With approval, set **Organization settings → Member privileges → Base permissions** to Read or None, to match the customer's access model. Base permission combines with direct and team grants, and the highest wins. Outside collaborators have repository-level access, not organization membership.

Use a non-owner member, with their consent, who has no direct or team grant on a private test repository. Base Read should allow reading but not pushing. Base None should deny reading. Enterprise members can read internal repositories, so those can't prove a denial.

**Ch36 covers repository creation.** Keep its App exception and active repository policy. Don't disable creation with a blanket setting here.

1. Create a parent team `ghec-ch07-engineering` (reuse the seeded one) and two child teams under it: `ghec-ch07-frontend-squad` and `ghec-ch07-backend-squad`. Create children with the parent set, e.g. `gh api -X POST /orgs/<org>/teams -f name='ghec-ch07-frontend-squad' -F parent_team_id=<parent-id>`.
2. Confirm nesting via `gh api /orgs/<org>/teams/ghec-ch07-frontend-squad --jq '.parent.name'` (should print the parent).
3. You'll check inheritance in Part B: both child teams inherit repository access granted to the parent.

### Part B: Grant repository access via teams
4. Grant the parent team `Read` on all three repos (so the whole department can see everything): `gh api -X PUT /orgs/<org>/teams/ghec-ch07-engineering/repos/<org>/ghec-ch07-frontend -f permission=pull` (repeat for backend/platform).
5. Grant child teams elevated, scoped access:
   - `ghec-ch07-frontend-squad` → Write (`push`) on `ghec-ch07-frontend`.
   - `ghec-ch07-backend-squad` → Write (`push`) on `ghec-ch07-backend`.
   - Neither squad gets Write on `ghec-ch07-platform` (that's a protected, shared repo).
6. Check effective access: `gh api /orgs/<org>/teams/ghec-ch07-frontend-squad/repos/<org>/ghec-ch07-frontend -H 'Accept: application/vnd.github.v3.repository+json' --jq '.permissions'`. Confirm the squad has push on its own repo but only the inherited pull on others.

### Part C: Predefined repository roles
7. Assign Maintain, not Admin. Create a child team `ghec-ch07-maintainers` and grant it the Maintain role on `ghec-ch07-platform` (`-f permission=maintain`). Explain why a tech lead can manage settings and issues without full admin access.
8. Try Triage. Grant a team or member the Triage role somewhere and explain what it can do (manage issues and PRs) and can't do (push code). Check the role reference.
9. For each of the five predefined roles (Read / Triage / Write / Maintain / Admin), write one sentence describing who would use it.

### Part D: Custom repository role
10. Start with a built-in role. **Custom repository roles add permissions to a base role; they cannot subtract inherited permissions.** Use built-in Write for a contributor who should push without access to admin settings.
11. If the built-in role lacks a needed permission, select that permission in **Organization settings → Repository roles**. Create the role and assign it to a test team.
12. As a non-owner test member, do one allowed action and try one denied action. First check the member's direct grants and inherited access, including organization base permissions. The highest effective permission wins.

### Part E: Members and access matrix
13. Add a non-owner test member, with their consent, to each squad you test. Confirm membership and test read and write access as that member. An owner account can't show a member's limits.
14. Record each tested repository's team roles and effective member permissions in the existing access record or adoption issue. Don't start a separate document if one exists.
15. Compare with the "before" snapshot from setup to show what changed in the team hierarchy and repository grants.
16. Use an existing enterprise delegation decision or authorized export if you have one. Don't infer enterprise policy from this organization's settings.

### Organization defaults checklist

Review these settings with the organization owner. Change only approved gaps, and keep the before and after API output in the access record:

- Restrict member deletion, transfer, and visibility changes to the intended administrators. Check private and internal forking against the approved contribution route. EMU cannot create public repositories.
- Prefer read-only default Actions permissions. Check `gh api "orgs/$ORG/actions/permissions/workflow"`; set the approved default under **Organization settings → Actions → General**.
- Read the 2FA setting but don't change it during an access test. Requiring 2FA can remove members, so make that change through the customer's identity rollout.
- Check the default branch for new repositories and reuse the security defaults from the GHAS security-configuration session. A repository setting can't prove an enterprise policy you can't inspect.

## Reference links
- [About teams](https://docs.github.com/en/organizations/organizing-members-into-teams/about-teams)
- [Creating a team / adding a parent team](https://docs.github.com/en/organizations/organizing-members-into-teams/creating-a-team)
- [Managing team access to an organization repository](https://docs.github.com/en/organizations/managing-user-access-to-your-organizations-repositories/managing-team-access-to-an-organization-repository)
- [Repository roles for an organization](https://docs.github.com/en/organizations/managing-user-access-to-your-organizations-repositories/managing-repository-roles/repository-roles-for-an-organization)
- [Managing custom repository roles for an organization](https://docs.github.com/en/organizations/managing-peoples-access-to-your-organization-with-roles/managing-custom-repository-roles-for-an-organization)
- [Setting base permissions for an organization](https://docs.github.com/en/organizations/managing-user-access-to-your-organizations-repositories/managing-repository-roles/setting-base-permissions-for-an-organization)
- [Teams REST API](https://docs.github.com/en/rest/teams/teams)
