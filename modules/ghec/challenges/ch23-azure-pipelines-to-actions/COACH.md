# Ch23 — Convert Azure Pipelines to GitHub Actions — Coach Guide

> Audience: facilitators and graders. Pair with the delivery team member `README.md`.

## Intent

Customer delivery team members learn that repository migration and CI/CD migration are separate workstreams. GitHub Enterprise Importer and `ado2gh` do not migrate Azure Pipelines; GitHub Actions Importer inventories, forecasts, converts, and opens pull requests for CI/CD workflows. The important learning outcome is not blind conversion: it is reviewing generated workflow YAML, identifying the manual gaps, and validating a green GitHub Actions run.

## Timing (reference)

| Phase | Duration |
|---|---:|
| Orientation, credentials, Docker, extension install | ~30 min |
| Audit and forecast | ~35 min |
| Dry-run conversion and YAML review | ~45 min |
| Migrate PR, manual cleanup, and validation run | ~55 min |
| Debrief | ~15 min |
| **Total** | **~180 min** |

## Expected Outputs

When a delivery team member completes this activity successfully, you should see:

- A local `actions-importer-output/audit/audit_summary.md` report.
- A local `actions-importer-output/forecast/forecast_report.md` report.
- A dry-run output directory containing converted GitHub Actions workflow YAML and logs.
- A GitHub pull request opened by `gh actions-importer migrate azure-devops pipeline` or `release`.
- A generated `.github/workflows/*.yml` file reviewed by the delivery team member.
- Written notes identifying at least one manual conversion gap and the fix or owner.
- A successful GitHub Actions run from the migrated workflow.

## Common Pitfalls

### Docker is not running
**Symptom:** `gh actions-importer update`, `audit`, `dry-run`, or `migrate` fails before conversion starts or cannot reach the Actions Importer container.  
**Fix:** Start Docker Desktop or the Docker daemon, then run `docker ps` and `gh actions-importer update` again.

### Azure DevOps PAT lacks required scopes
**Symptom:** Audit reports missing projects or pipelines, or conversion fails with authorization errors.  
**Fix:** Recreate or update the Azure DevOps PAT with read access for Agent Pools, Build, Code, Release, Service Connections, Task Groups, and Variable Groups. Re-run `gh actions-importer configure`.

### GitHub token cannot create workflow PRs
**Symptom:** `migrate` converts locally but fails to open a PR or push `.github/workflows/*`.  
**Fix:** Use a GitHub personal access token (classic) with `workflow` scope and repository access to the target repo.

### Partial conversions need manual fixes
**Symptom:** The generated workflow contains comments, placeholder commands, unknown tasks, or fails on first run.  
**Fix:** Use the audit manual-tasks section and PR description to identify unsupported items. Replace each with a maintained action, a shell equivalent, a reusable workflow, or an explicit manual migration task.

### Secrets and variables are not carried over
**Symptom:** The workflow references secrets or variables that do not exist in GitHub Actions.  
**Fix:** Recreate required secrets and variables at the correct repository, environment, or organization scope. Never copy secret values into YAML or notes.

### Service connections and environments do not translate directly
**Symptom:** Deploy steps that used Azure DevOps service connections, environments, approvals, or gates fail or are omitted.  
**Fix:** Decide the GitHub equivalent: OIDC cloud federation, GitHub environments and reviewers, repository or organization secrets, or a manually rebuilt deployment process. Unsupported gates and some approvals must be redesigned.

## Progressive Hints

Use these in order — give the first hint, wait, then give the next only if the delivery team member is still stuck.

1. **Gentle:** Start with `audit` and `forecast`; do not convert a single pipeline until you know the size, unsupported-task count, secrets, and runner footprint.
2. **Medium:** For a build pipeline, the command shape is `gh actions-importer dry-run azure-devops pipeline --pipeline-id <id> --output-dir <dir>`. Use `release` only for Azure DevOps release pipelines.
3. **Specific:** If the migrated workflow fails, compare three sources: `audit_summary.md`, the PR **Manual steps** section, and the failing Actions log. Most first failures are missing secrets, missing variables, service connection replacements, or self-hosted runner labels.

## Debrief Questions

- Which part of the Azure DevOps pipeline converted cleanly, and which part required human judgment?
- What does the forecast report imply for Actions minutes, runner sizing, or concurrency during cutover?
- Which Azure DevOps secret, variable group, service connection, environment, or approval is highest risk to recreate incorrectly in GitHub?
- How would you sequence repository migration, pipeline migration, validation, and final cutover for a real application team?
- What should be standardized across many pipeline migrations: reusable workflows, approved actions, runner labels, OIDC patterns, or environment names?

## Grading Notes

Give full credit only when the delivery team member can show evidence, not just commands copied into notes. The minimum evidence is an audit report, forecast report, dry-run workflow YAML, migrate PR, documented manual gap, and a green Actions run. For bring-your-own repositories, prefer a real production-adjacent pipeline over a toy pipeline, but accept a safe pilot if access constraints prevent production use.

## Reference Links

- Automating migration with GitHub Actions Importer — https://docs.github.com/en/actions/tutorials/migrate-to-github-actions/automated-migrations/use-github-actions-importer
- Migrating from Azure DevOps with GitHub Actions Importer — https://docs.github.com/en/actions/tutorials/migrate-to-github-actions/automated-migrations/azure-devops-migration
- Research report section 12 and footnote [^3] — `/home/marco/.copilot/session-state/58bb295a-c8c1-42e1-b6f2-898549a9f8b8/research/all-migration-patterns-supported-to-github-enterpr.md`
