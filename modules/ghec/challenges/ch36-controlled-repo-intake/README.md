# Ch36 — Controlled Repository Intake

> Deliver a governed repository request path: custom issue form, maintainer approval label, and GitHub Actions provisioning with auditable evidence.

| | |
|---|---|
| Track | Admin/Governance |
| Difficulty | Advanced |
| Duration | ~4 hrs total, multi-session |
| Minimum input | An org + an org-owner token. *(All activities are org-scoped — no enterprise owner required.)* |
| App | Provisioned intake repository (created by setup) |
| EMU compatible | yes |

## Customer delivery target

- Customer objective: stop unmanaged repository sprawl while preserving a fast, reviewable request path.
- Customer-tenant target: organization member-creation policy and a repository intake workflow.
- Approval and safety boundary: disabling member repository creation is an org-wide governance change; apply it only with explicit org-owner approval. If not approved, produce a signed rollout proposal and prove the sample workflow instead.
- Records to keep: retain policy snapshots, issue-form schema, workflow identity, approval label evidence, created repository URL, and failure handling evidence.
- Adoption owner / handover: the platform governance owner accepts the intake process and operational runbook.
- Next action and owner: approve production rollout, add repository baseline controls, or onboard the first real requester cohort.

## Prerequisites

- An organization you own (or org-owner rights) on GitHub Enterprise Cloud.
- A token with the scopes listed by `modules/ghec/resources/provisioning/scripts/setup.sh doctor ch36 --org <org>` (least-privilege; for this activity: `admin:org` + `repo` + `read:org`).
- Local tooling: `gh >= 2.x`, `git`, `jq` (run `modules/ghec/resources/provisioning/scripts/setup.sh doctor` to verify).
- A workflow credential for provisioning:
  - Preferred: GitHub App installation token with narrowly scoped repository administration and contents permissions.
  - Workshop fallback: fine-grained PAT stored as an Actions secret named `REPO_PROVISIONER_TOKEN`.
- No secret should ever be committed to the repository.

## Customer delivery objectives

This delivery engagement establishes:

- Inspect and document the current repository-creation policy.
- Restrict direct repository creation by members, or capture an approved rollout proposal when the production org cannot be changed during the session.
- Create an intake repository with a custom issue form for repository requests.
- Use a maintainer-applied approval label as the provisioning trigger.
- Provision a repository through GitHub Actions using a scoped workflow identity.
- Comment back to the request with success or failure evidence and preserve an auditable trail.

## Scenario

A customer wants fewer shadow repositories and more consistent repository baselines. Today, anyone can create a repo, skip required metadata, forget ownership, and miss baseline settings. Your job is to replace that with a governed path: people request a repo through an issue form, maintainers approve with a label, and automation provisions the repo with an agreed baseline.

> [!IMPORTANT]
> Use an approved customer target (do this first)
>
> Default to an authorised customer intake repository and org policy decision. Complete the work on that artifact and retain the evidence, guardrails, or automation.
>
> - Have a candidate? Use the customer's real intake repository and policy target wherever this guide names `ghec-ch36-repo-intake`. Skip the Setup step below entirely.
> - No suitable one? Use the fallback below: a seeded intake repository with labels, issue form, workflow scaffold, and sample request.
>
> Record the selected target, policy owner, workflow owner, approval label, and next action. Use the sample only for testing; move the validated intake flow to an approved customer target.

## Sample test repository or environment (when tenant delivery is constrained)

Skip this if you brought your own intake target. Otherwise run the provisioning entrypoint (Bash or PowerShell — both supported).

```bash
# Bash
bash modules/ghec/resources/provisioning/scripts/setup.sh provision ch36 --org <org>
```
```powershell
# PowerShell
modules/ghec/resources/provisioning/scripts/setup.ps1 provision ch36 --org <org>
```

What setup creates (all artifacts namespaced `ghec-ch36-*`, idempotent, prefix-guarded teardown):

- `ghec-ch36-repo-intake` with a repository-request issue form.
- Intake labels including `repo-intake: approved`, `repo-intake: provisioned`, and `repo-intake: failed`.
- `.github/workflows/provision-repository.yml`, a fail-closed workflow scaffold triggered by the approval label.
- A sample repository request issue.
- A printed organization repository-creation policy snapshot.

## Tasks

> Throughout, `ghec-ch36-repo-intake` is the fallback sample. If you brought your own artifact, substitute its name in every command and use your real history, teams, settings, or data as the material to work from.

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
10. Record the credential owner, rotation date, and permissions in the governance register. Do not paste or store the secret value in the register.

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

## Validation / Definition of Done

You are done when ALL of the following are true:

- [ ] Members cannot create repositories directly, or an approved rollout proposal records why the production setting was not changed during the session.
- [ ] The intake repository has a working repository-request issue form.
- [ ] A maintainer-applied `repo-intake: approved` label triggers the provisioning workflow.
- [ ] The workflow creates a requested repository with approved baseline settings and fails closed for invalid requests.
- [ ] The intake issue is updated with provisioning evidence and a final provisioned or failed label.
- [ ] Governance evidence records owner, approval route, workflow identity, baseline controls, audit evidence, and next review.
- [ ] Real-outcome check — if you brought your own intake repo, a real team can request repos through it; if you used the sample, you can name the production intake repo or org policy decision to roll out next.
- [ ] Adoption handover — name the intake process owner, credential owner, next repository baseline improvement, and review date.

> Coaches verify these via the automated hints in `COACH.md`.

## Operational extensions

- Replace the fallback PAT with a GitHub App token minted inside the workflow.
- Add repository custom properties from Ch08 during provisioning.
- Add rulesets, default branch policy, team permissions, and Actions default permissions to the created repo.
- Add a scheduled audit that finds repos not linked to an approved intake issue.

## Reference links

- Restricting repository creation in your organization — https://docs.github.com/en/organizations/managing-organization-settings/restricting-repository-creation-in-your-organization
- Configuring issue templates — https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/configuring-issue-templates-for-your-repository
- Using secrets in GitHub Actions — https://docs.github.com/en/actions/security-for-github-actions/security-guides/using-secrets-in-github-actions
- Authenticating as a GitHub App installation — https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/authenticating-as-a-github-app-installation
- Repositories REST API — https://docs.github.com/en/rest/repos/repos
