# Ch23 — Convert Azure Pipelines to GitHub Actions — Delivery Assurance Guide
> **Customer authorization and rollout boundary:** Apply changes in a customer-owned tenant or repository only after the named customer owner authorizes the scope. A fallback is a sample test repository or environment, not the destination: record its evidence, risks and controls, accountable owner, handover, and the explicit tenant adoption, cutover, or rollout decision.


> Audience: delivery assurance leads and authorized customer implementation owners. Pair with the corresponding customer implementation `README.md`.

## Intent

Treat repository migration and CI/CD migration as separate customer implementation workstreams. GitHub Enterprise Importer and `ado2gh` do not migrate Azure Pipelines; GitHub Actions Importer inventories, forecasts, converts, and opens pull requests for CI/CD workflows. The required outcome is not blind conversion: it is customer-owned review evidence for generated workflow YAML, identified manual gaps with owners, and a validated green GitHub Actions run that supports a rollout decision.

## Timing (reference)

| Phase | Duration |
|---|---:|
| Authorized scope, credentials, Docker, extension install | ~30 min |
| Audit and forecast | ~35 min |
| Dry-run conversion and customer YAML review | ~45 min |
| Migrate PR, owned manual remediation, and validation run | ~55 min |
| Adoption decision and handover | ~15 min |
| **Total** | **~180 min** |

## Expected Outputs

For delivery assurance, collect the following customer-owned evidence:

- A local `actions-importer-output/audit/audit_summary.md` report.
- A local `actions-importer-output/forecast/forecast_report.md` report.
- A dry-run output directory containing converted GitHub Actions workflow YAML and logs.
- A GitHub pull request opened by `gh actions-importer migrate azure-devops pipeline` or `release`.
- A generated `.github/workflows/*.yml` file reviewed by the customer implementation owner.
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

## Implementation troubleshooting prompts

Use these progressively to resolve an implementation blocker while preserving customer ownership and the rollout boundary.

1. **Gentle:** Start with `audit` and `forecast`; do not convert a single pipeline until you know the size, unsupported-task count, secrets, and runner footprint.
2. **Medium:** For a build pipeline, the command shape is `gh actions-importer dry-run azure-devops pipeline --pipeline-id <id> --output-dir <dir>`. Use `release` only for Azure DevOps release pipelines.
3. **Specific:** If the migrated workflow fails, compare three sources: `audit_summary.md`, the PR **Manual steps** section, and the failing Actions log. Most first failures are missing secrets, missing variables, service connection replacements, or self-hosted runner labels.

## Customer adoption decision

- Which part of the Azure DevOps pipeline converted cleanly, and which part required human judgment?
- What does the forecast report imply for Actions minutes, runner sizing, or concurrency during cutover?
- Which Azure DevOps secret, variable group, service connection, environment, or approval is highest risk to recreate incorrectly in GitHub?
- How would you sequence repository migration, pipeline migration, validation, and final cutover for a real application team?
- What should be standardized across many pipeline migrations: reusable workflows, approved actions, runner labels, OIDC patterns, or environment names?

## Delivery assurance evidence

Accept implementation readiness only when the customer owner can show evidence, not just commands copied into notes. The minimum evidence is an audit report, forecast report, dry-run workflow YAML, migrate PR, documented manual gap, and a green Actions run. Prefer an authorized production-adjacent pipeline; a safe pilot is acceptable when access constraints prevent production use, provided it records the target tenant, owner, controls, and cutover or rollout decision.

## Reference Links

- Automating migration with GitHub Actions Importer — https://docs.github.com/en/actions/tutorials/migrate-to-github-actions/automated-migrations/use-github-actions-importer
- Migrating from Azure DevOps with GitHub Actions Importer — https://docs.github.com/en/actions/tutorials/migrate-to-github-actions/automated-migrations/azure-devops-migration
- Research report section 12 and footnote [^3] — `/home/marco/.copilot/session-state/58bb295a-c8c1-42e1-b6f2-898549a9f8b8/research/all-migration-patterns-supported-to-github-enterpr.md`
