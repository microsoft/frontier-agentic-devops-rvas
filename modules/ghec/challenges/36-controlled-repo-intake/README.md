# Ch36: Controlled Repository Intake

> Deliver a governed repository request path: custom issue form, maintainer approval label, and GitHub Actions provisioning with auditable evidence.

| | |
|---|---|
| Track | Admin/Governance |
| Difficulty | Advanced |
| Duration | 165 min |
| Minimum input | An org + an org-owner token. *(All activities are org-scoped — no enterprise owner required.)* |
| App | Provisioned intake repository (created by setup) |
| EMU compatible | yes |

## Prerequisites

- An organization you own (or org-owner rights) on GitHub Enterprise Cloud.
- A token with the scopes listed by `modules/ghec/resources/provisioning/scripts/setup.sh doctor ch36 --org <org>` (least-privilege; for this activity: `admin:org` + `repo` + `read:org`).
- Local tooling: `gh >= 2.x`, `git`, `jq` (run `modules/ghec/resources/provisioning/scripts/setup.sh doctor` to verify).
- A workflow credential for provisioning:
  - Preferred: GitHub App installation token with narrowly scoped repository administration and contents permissions.
  - Workshop fallback: fine-grained PAT stored as an Actions secret named `REPO_PROVISIONER_TOKEN`.
- No secret should ever be committed to the repository.

## Customer delivery objectives

You will:

- Inspect and document the current repository-creation policy.
- Restrict direct repository creation by members, or capture an approved rollout proposal when the production org cannot be changed during the session.
- Create an intake repository with a custom issue form for repository requests.
- Use a maintainer-applied approval label as the provisioning trigger.
- Provision a repository through GitHub Actions using a scoped workflow identity.
- Comment back to the request with success or failure evidence and preserve an auditable trail.

## Scenario

A customer wants fewer shadow repositories and more consistent baselines. Today, members can create a repository without required metadata, an owner, or standard settings. Replace that path with an issue form, maintainer approval, and an automated build that applies the agreed baseline.

> [!IMPORTANT]
> Choose the target before setup. If you have an authorised intake repository and organization policy decision, use it wherever this guide names `ghec-ch36-repo-intake` and skip Setup. Otherwise use the seeded intake repository below, then move the validated intake flow to an approved customer target.
>
> Record the selected target, policy owner, workflow owner, approval label, and next action.

## Sample test repository or environment

Skip if you brought your own intake target.

```bash
# Bash
bash modules/ghec/resources/provisioning/scripts/setup.sh provision ch36 --org <org>
```
```powershell
# PowerShell
modules/ghec/resources/provisioning/scripts/setup.ps1 provision ch36 --org <org>
```

Setup is idempotent and creates only these namespaced artifacts. Teardown accepts only the `ghec-ch36-*` prefix.

- `ghec-ch36-repo-intake` with a repository-request issue form.
- Intake labels including `repo-intake: approved`, `repo-intake: provisioned`, and `repo-intake: failed`.
- `.github/workflows/provision-repository.yml`, a fail-closed workflow scaffold triggered by the approval label.
- A sample repository request issue.
- A printed organization repository-creation policy snapshot.

## Tasks

### Part A — Inspect and decide the policy

1. Snapshot the current repository-creation policy:
   ```bash
   gh api /orgs/<org> --jq '{members_can_create_repositories, members_can_create_public_repositories, members_can_create_private_repositories, members_can_create_internal_repositories}'
   ```
2. Record the risk decision: direct member creation remains temporarily allowed, or direct member creation will be disabled and replaced by intake.
3. If authorized, disable member repository creation in Organization settings → Member privileges → Repository creation. Verify via the API:
   ```bash
   gh api /orgs/<org> --jq '{members_can_create_repositories, members_can_create_public_repositories, members_can_create_private_repositories, members_can_create_internal_repositories}'
   ```
4. If not authorized, write the rollout proposal with approver, risk, timing, and fallback path. This still counts for the policy part; do not change production settings without approval.

### Part B — Configure the intake repository

5. Review `.github/ISSUE_TEMPLATE/repository-request.yml` in `ghec-ch36-repo-intake`.
6. Open a new repository request and confirm the form captures:
   - requested repository name
   - owner/team
   - business purpose
   - visibility
   - data classification
   - baseline requirements
7. Confirm the intake labels exist:
   ```bash
   gh label list --repo <org>/ghec-ch36-repo-intake --limit 100
   ```

### Part C — Configure workflow identity

8. Preferred: create or select a GitHub App with narrowly scoped permissions for repository administration and contents, then provide the workflow an installation token through a secret or token-minting step.
9. Workshop fallback: create a fine-grained PAT with only the needed organization/repository permissions and store it as an Actions secret named `REPO_PROVISIONER_TOKEN` on the intake repo.
10. Confirm the credential owner, rotation date, and permissions in the approved secret-management or workflow operating evidence. Never record the secret value.

### Part D — Approve and provision

11. Open the sample request issue and verify the requested repo name uses the safe prefix `ghec-ch36-`.
12. As a maintainer, apply the approval label:
    ```bash
    gh issue edit <issue-number> --repo <org>/ghec-ch36-repo-intake --add-label 'repo-intake: approved'
    ```
13. Watch the workflow run. It should parse the issue form, validate the request, create the repository, seed a README, add labels, and comment back to the issue.
14. Confirm the issue has a final label:
    - `repo-intake: provisioned` on success
    - `repo-intake: failed` on validation or provisioning failure

### Part E — Verify the created repository baseline

15. Inspect the created repository:
    ```bash
    gh repo view <org>/<requested-repo> --json name,visibility,description
    gh label list --repo <org>/<requested-repo> --limit 100
    ```
16. Confirm the repo has the approved baseline: description, visibility, README, expected labels, and owner evidence in the request issue.
17. Record the audit trail: request issue, approving actor, workflow run, created repo, and any exception.

## Reference links

- Restricting repository creation in your organization — https://docs.github.com/en/organizations/managing-organization-settings/restricting-repository-creation-in-your-organization
- Configuring issue templates — https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/configuring-issue-templates-for-your-repository
- Using secrets in GitHub Actions — https://docs.github.com/en/actions/security-for-github-actions/security-guides/using-secrets-in-github-actions
- Authenticating as a GitHub App installation — https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/authenticating-as-a-github-app-installation
- Repositories REST API — https://docs.github.com/en/rest/repos/repos
