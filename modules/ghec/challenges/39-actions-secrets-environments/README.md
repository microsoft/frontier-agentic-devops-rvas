# Ch39: Actions Secrets and Environments

> Govern deployment secrets by moving them behind protected GitHub Actions environments and recording ownership, rotation, and access evidence.

| | |
|---|---|
| Track | Automation & AI |
| Difficulty | Intermediate |
| Duration | ~3 hrs total, multi-session |
| Minimum input | An org + repository admin rights. |
| App | Provisioned starter repository (created by setup) |
| EMU compatible | yes |

## Customer delivery target

- Objective: prevent broad repository secrets from being available to every workflow path.
- Delivery target: one authorized repository with environment-scoped deployment secrets and protection rules.
- Safety boundary: do not read or copy secret values. Change customer secrets and production environment rules only with owner approval.
- Evidence: secret inventory by name, scope, and owner; environment protection settings; workflow evidence; exceptions; and rotation dates.
- Owner: platform security or DevOps.
- Next decision: choose the next repository cohort for secret migration.

## Prerequisites

- An organization and repository where you have repository admin rights.
- A token with scopes listed by `modules/ghec/resources/provisioning/scripts/setup.sh doctor ch39 --org <org>`.
- Local tooling: `gh >= 2.x`, `git`, `jq`.
- Never pass secret values to setup scripts or store them in lesson evidence.

## Scenario

A deployment workflow uses repository-level secrets. Any job that can reference those names can try to use production credentials. Inventory the secrets without exposing values. Move deployment credentials to protected environments, then prove that reviewers and branch rules gate production access.

> [!IMPORTANT]
> Use an approved customer target first. If production changes are not approved, use the fallback sample repository and produce a rollout proposal instead of mutating production controls.

## Sample test repository or environment

```bash
bash modules/ghec/resources/provisioning/scripts/setup.sh provision ch39 --org <org>
```
```powershell
modules/ghec/resources/provisioning/scripts/setup.ps1 provision ch39 -Org <org>
```

Setup creates only namespaced sample artifacts:

- `ghec-ch39-actions-secrets-envs` with a deployment workflow scaffold and governance checklist.
- `ghec-ch39-dev` and `ghec-ch39-prod` repository environments when API permissions allow it.
- No secrets and no credentials.

## Tasks

### Part A — Inventory without exposing values

1. Snapshot repository secret metadata:
   ```bash
   gh secret list --repo <org>/ghec-ch39-actions-secrets-envs
   ```
2. Snapshot environment names and protection settings:
   ```bash
   gh api repos/<org>/ghec-ch39-actions-secrets-envs/environments --jq '.environments[] | {name,protection_rules}'
   ```
3. Record each secret name, scope, consumer workflow, owner, rotation cadence, and whether it should be repository, environment, or organization scoped.

### Part B — Design environment protection

4. Define `dev`, `test`, and `prod` environment requirements: reviewers, wait timer, allowed branches/tags, and exception owner.
5. Keep production environment settings as an explicit participant action; do not delegate broad production changes to setup automation.
6. Record what secrets move to each environment and which jobs are allowed to reference them.

### Part C — Configure environments and secrets

7. Configure protected environments in the repository UI or API.
8. Add environment secrets using `gh secret set --env <environment>` or the UI. Do not print values.
9. Remove or de-scope old repository secrets after workflow migration and approval.

### Part D — Update and validate workflows

10. Update deployment jobs to declare the environment before referencing environment secrets.
11. Run a non-production deployment and capture the workflow URL.
12. Attempt a production deployment from an unauthorized branch or without approval and capture the blocked evidence.

## Operational extensions

- Script a report of repositories with production-like repository secrets.
- Add secret rotation reminders through issues or projects.
- Pair with Ch40 to replace long-lived cloud secrets with OIDC.

## Reference links

- Using secrets in GitHub Actions — https://docs.github.com/en/actions/security-for-github-actions/security-guides/using-secrets-in-github-actions
- Using environments for deployment — https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment
- Actions Secrets REST API — https://docs.github.com/en/rest/actions/secrets
- Environments REST API — https://docs.github.com/en/rest/deployments/environments
