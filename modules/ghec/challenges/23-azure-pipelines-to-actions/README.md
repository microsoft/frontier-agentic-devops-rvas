# Ch23 — Convert Azure Pipelines to GitHub Actions

> Convert an approved Azure DevOps Pipeline into a GitHub Actions workflow with GitHub Actions Importer, then review, remediate, validate, and hand it over.

| | |
|---|---|
| Track | Migration |
| Difficulty | Intermediate |
| Duration | 150 min |
| Minimum input | A GitHub repo + an Azure DevOps project with at least one Pipeline |
| App | None |
| EMU compatible | yes |

## Prerequisites

Dependencies: none. This guide is independent, but it is recommended after the Azure DevOps repository migration guide (ch21) and complements ch04 Actions CI fundamentals.

Access and tooling:
- A GitHub organization and target repository, ideally the repository migrated from Azure DevOps in ch21.
- An Azure DevOps organization, project, and at least one Azure Pipeline.
- Docker installed and running. GitHub Actions Importer is distributed as a Docker container and driven through a GitHub CLI extension.
- GitHub CLI installed and authenticated.
- A GitHub personal access token (classic) with `workflow` scope for Importer PR creation.
- An Azure DevOps PAT with read scopes for Agent Pools, Build, Code, Release, Service Connections, Task Groups, and Variable Groups.

## Scenario

GitHub Enterprise Importer and `ado2gh` move repository source, history, and supported metadata, but not Azure Pipelines. Use GitHub Actions Importer to inventory the CI/CD footprint, estimate Actions usage, convert one pipeline, open a pull request, and validate the migrated workflow.

> [!IMPORTANT]
> Use an approved Azure DevOps project and pipeline as the source and target throughout this guide. Without a suitable source and target, record the access constraint and next action instead of migrating an unapproved example.

## Setup

Set variables for the source Azure DevOps project and target GitHub repository.

```bash
ADO_ORG=<azure-devops-org>
ADO_PROJECT=<azure-devops-project>
PIPELINE_ID=<azure-pipeline-id>
TARGET_REPO=https://github.com/<github-org>/<github-repo>
OUTPUT_DIR=actions-importer-output
```

Install and update the GitHub Actions Importer extension.

```bash
gh extension install github/gh-actions-importer
gh actions-importer update
```

Configure credentials for the Azure DevOps source and GitHub target.

```bash
gh actions-importer configure
```

When prompted, select Azure DevOps, enter the GitHub token, accept `https://github.com` unless you use another GitHub instance, enter the Azure DevOps PAT, accept `https://dev.azure.com`, then enter the Azure DevOps organization and project.

## Tasks

### Part A — Audit the Azure DevOps CI/CD footprint

Run an audit against Azure DevOps.

```bash
gh actions-importer audit azure-devops --output-dir "$OUTPUT_DIR/audit"
```

Open `actions-importer-output/audit/audit_summary.md`. Capture:
- How many pipelines were successful, partially successful, unsupported, or failed.
- Unknown or unsupported build steps.
- Secrets, variable groups, self-hosted runners, service connections, or environments that require manual work.
- Actions that the converted workflows would use.

### Part B — Forecast GitHub Actions usage

Estimate future GitHub Actions usage from Azure DevOps pipeline history.

```bash
gh actions-importer forecast azure-devops --output-dir "$OUTPUT_DIR/forecast"
```

Review `actions-importer-output/forecast/forecast_report.md`. Note expected job count, execution time, queue time, concurrency, and any runner queues that affect cost or capacity planning.

### Part C — Dry-run one pipeline conversion

Convert a build pipeline locally without opening a pull request.

```bash
gh actions-importer dry-run azure-devops pipeline \
  --pipeline-id "$PIPELINE_ID" \
  --output-dir "$OUTPUT_DIR/dry-run"
```

If you are converting an Azure DevOps release pipeline instead, use `release`.

```bash
gh actions-importer dry-run azure-devops release \
  --pipeline-id "$PIPELINE_ID" \
  --output-dir "$OUTPUT_DIR/dry-run"
```

Review the generated workflow YAML under the dry-run output directory. GitHub documents an approximately 80% auto-conversion target, not a perfect conversion guarantee. Expect manual cleanup for unsupported tasks, unknown tasks, service connections, secrets, variables, environments, approvals, self-hosted agents, or resource triggers.

### Part D — Migrate by pull request

Convert the same pipeline and have Importer open a pull request against the target GitHub repository.

```bash
gh actions-importer migrate azure-devops pipeline \
  --pipeline-id "$PIPELINE_ID" \
  --target-url "$TARGET_REPO" \
  --output-dir "$OUTPUT_DIR/migrate"
```

For a release pipeline, use `release`.

```bash
gh actions-importer migrate azure-devops release \
  --pipeline-id "$PIPELINE_ID" \
  --target-url "$TARGET_REPO" \
  --output-dir "$OUTPUT_DIR/migrate"
```

Open the pull request URL printed by the command. Inspect the PR description, especially the Manual steps section, then inspect `.github/workflows/*.yml` in the Files changed tab.

### Part E — Review and fix the generated workflow

In the pull request branch:
1. Read every generated `.github/workflows/*.yml` file.
2. Replace unsupported or unknown steps with equivalent GitHub Actions, shell commands, reusable workflows, or documented manual steps.
3. Recreate required GitHub repository or organization secrets and variables. Do not commit secret values.
4. Map Azure DevOps service connections to GitHub-native credentials, preferably OIDC where possible.
5. Decide whether Azure DevOps self-hosted agents become GitHub-hosted runners, larger runners, or GitHub self-hosted runners.
6. Document at least one conversion gap and how you fixed it.

### Part F — Validate in GitHub Actions

Merge or update the PR when the workflow is safe to run, then trigger the migrated workflow.

```bash
gh workflow list --repo <github-org>/<github-repo>
gh workflow run <workflow-file-name.yml> --repo <github-org>/<github-repo> --ref main
gh run watch --repo <github-org>/<github-repo>
```

If the workflow is triggered only by `push` or `pull_request`, push a small documentation-only branch or update the PR branch instead of using `workflow_dispatch`.

## Cleanup

Keep the pull request and reports if they are evidence for the migration plan. If you used a sample test repository, delete the local `actions-importer-output/` directory after capturing required evidence. Remove any test-only secrets, variables, or workflows created in GitHub.

## Reference links

- Automating migration with GitHub Actions Importer — https://docs.github.com/en/actions/tutorials/migrate-to-github-actions/automated-migrations/use-github-actions-importer
- Migrating from Azure DevOps with GitHub Actions Importer — https://docs.github.com/en/actions/tutorials/migrate-to-github-actions/automated-migrations/azure-devops-migration
