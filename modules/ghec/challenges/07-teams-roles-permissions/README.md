# Ch07: Organization and team access

**Session outcome:** Two teams hold least-privilege access to their real repositories through team grants. A consenting non-owner member shows one allowed and one denied action.

## Prerequisites
- An organization you own (or org-owner rights) on GitHub Enterprise Cloud.
- Approval to change access on the chosen repositories, and a non-owner member who agrees to test.
- A token with the scopes listed by `modules/ghec/resources/provisioning/scripts/setup.sh doctor ch07 --org <org>` (here: `admin:org` + `repo` + `read:org`).
- `gh >= 2.x`, `git`, `jq`.

## Scenario
A GHEC customer grants repository access directly to individuals. Former employees retain access, and nobody can say who can merge to the payments repo. Move access to teams, then check the result through the API.

> [!IMPORTANT]
> If the customer has a team structure and repositories, use them wherever this guide names `ghec-ch07-*` artifacts, and skip the sample setup. Otherwise use the seeded sample below.

## Sample test repository or environment
Skip if you brought your own teams and repositories.

```bash
# Bash
bash modules/ghec/resources/provisioning/scripts/setup.sh provision ch07 --org <org>
```
```powershell
# PowerShell
modules/ghec/resources/provisioning/scripts/setup.ps1 provision ch07 --org <org>
```

Setup creates three seeded repos (`ghec-ch07-frontend`, `ghec-ch07-backend`, `ghec-ch07-platform`) and a starter team `ghec-ch07-engineering` with one member (you) and no repository access. All names use the `ghec-ch07-*` prefix, and teardown is prefix-guarded.

## Tasks

### Part A: Check base permissions

```bash
export ORG="YOUR-ORG"
gh api "orgs/$ORG" --jq '{default_repository_permission,members_can_delete_repositories,members_can_fork_private_repositories,two_factor_requirement_enabled}'
gh api "orgs/$ORG/members?per_page=100" --paginate --jq '.[].login'
gh api "orgs/$ORG/outside_collaborators?per_page=100" --paginate --jq '.[].login'
```

Base permission combines with direct and team grants, and **the highest wins**. If the base is Write or Admin, team grants can't restrict anyone. With approval, set **Organization settings → Member privileges → Base permissions** to Read or None. Enterprise members can read internal repositories, so use a private repository to test denials.

### Part B: Build two teams and grant access

1. Create two child teams under the parent, for example `ghec-ch07-frontend-squad`:
   ```bash
   gh api -X POST "/orgs/$ORG/teams" -f name='ghec-ch07-frontend-squad' -F parent_team_id=<parent-id>
   ```
   Repeat for `ghec-ch07-backend-squad`. Confirm nesting with `gh api "/orgs/$ORG/teams/ghec-ch07-frontend-squad" --jq '.parent.name'`.
2. Give the parent team `Read` on all three repos. Child teams inherit it:
   ```bash
   gh api -X PUT "/orgs/$ORG/teams/ghec-ch07-engineering/repos/$ORG/ghec-ch07-frontend" -f permission=pull
   ```
   Repeat for backend and platform.
3. Give each squad `push` on its own repo only (frontend squad on `ghec-ch07-frontend`, backend squad on `ghec-ch07-backend`). Neither gets Write on `ghec-ch07-platform`.
4. Check effective access. The squad should have push on its repo and only pull elsewhere:
   ```bash
   gh api "/orgs/$ORG/teams/ghec-ch07-frontend-squad/repos/$ORG/ghec-ch07-frontend" -H 'Accept: application/vnd.github.v3.repository+json' --jq '.permissions'
   ```
5. Create a tech lead team and give it `Maintain`, not Admin, on `ghec-ch07-platform` (`-f permission=maintain`). It can manage settings and issues without full admin rights.

### Part C: Test as a non-owner member

Add the consenting non-owner member to one squad. An owner account can't show a member's limits. First check their direct grants and base permission. Then, as that member:

1. Do one allowed action, such as pushing a branch to the squad's repo.
2. Try one denied action, such as pushing to `ghec-ch07-platform`.

Compare with the setup snapshot to confirm what changed.

### Optional

- **Custom role.** Use a built-in role first. Custom roles only add permissions to a base role. If you need one, create it in **Organization settings → Repository roles**, assign it to a test team, and repeat Part C.
- **Organization defaults.** With the owner, review member deletion and forking limits, default Actions permissions (`gh api "orgs/$ORG/actions/permissions/workflow"`), and the default branch for new repos. Don't change 2FA during an access test, because it can remove members. **Ch36 covers repository creation.**

## Reference links
- [About teams](https://docs.github.com/en/organizations/organizing-members-into-teams/about-teams)
- [Creating a team / adding a parent team](https://docs.github.com/en/organizations/organizing-members-into-teams/creating-a-team)
- [Managing team access to an organization repository](https://docs.github.com/en/organizations/managing-user-access-to-your-organizations-repositories/managing-team-access-to-an-organization-repository)
- [Repository roles for an organization](https://docs.github.com/en/organizations/managing-user-access-to-your-organizations-repositories/managing-repository-roles/repository-roles-for-an-organization)
- [Managing custom repository roles for an organization](https://docs.github.com/en/organizations/managing-peoples-access-to-your-organization-with-roles/managing-custom-repository-roles-for-an-organization)
- [Setting base permissions for an organization](https://docs.github.com/en/organizations/managing-user-access-to-your-organizations-repositories/managing-repository-roles/setting-base-permissions-for-an-organization)
- [Teams REST API](https://docs.github.com/en/rest/teams/teams)
