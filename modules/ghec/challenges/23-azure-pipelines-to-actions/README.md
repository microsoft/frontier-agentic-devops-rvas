# Ch23: Convert Azure Pipelines to GitHub Actions

**Session outcome:** The converted pipeline runs in GitHub and produces the expected tests and artifacts. You confirmed it keeps the source pipeline's CI and deployment-approval requirements.

## Prerequisites

This guide stands alone, but do the repository migration (ch21) first if you can. Ch04 covers Actions CI basics.

Access and tooling:
- A GitHub organization and target repository, ideally the one you migrated in ch21.
- An Azure DevOps organization, project, and at least one Azure Pipeline.
- Docker installed and running. GitHub Actions Importer ships as a Docker container and runs through a GitHub CLI extension.
- GitHub CLI installed and authenticated.
- A GitHub personal access token (classic) with `workflow` scope, so Importer can create PRs.
- An Azure DevOps PAT with read scopes for Agent Pools, Build, Code, Release, Service Connections, Task Groups, and Variable Groups.

## Scenario

GitHub Enterprise Importer and `ado2gh` move repository source, history, and supported metadata, but not Azure Pipelines. Use GitHub Actions Importer to audit your pipelines, estimate Actions usage, and convert one pipeline through a pull request.

> [!IMPORTANT]
> Use an approved Azure DevOps project and pipeline as the source, and an approved repository as the target. If you don't have them, note what blocks you and the next step. Don't migrate an unapproved example.

## Setup

Set variables for the source project and target repository.

```bash
ADO_ORG=<azure-devops-org>
ADO_PROJECT=<azure-devops-project>
PIPELINE_ID=<azure-pipeline-id>
TARGET_REPO=https://github.com/<github-org>/<github-repo>
OUTPUT_DIR=actions-importer-output
```

Install and update the extension.

```bash
gh extension install github/gh-actions-importer
gh actions-importer update
```

Configure credentials.

```bash
gh actions-importer configure
```

When prompted, select Azure DevOps and enter the GitHub token. Accept `https://github.com` unless you use another GitHub instance. Enter the Azure DevOps PAT, accept `https://dev.azure.com`, then enter the Azure DevOps organization and project.

## Tasks

### Part A: Audit Azure DevOps CI/CD

Run an audit against Azure DevOps.

```bash
gh actions-importer audit azure-devops --output-dir "$OUTPUT_DIR/audit"
```

Open `actions-importer-output/audit/audit_summary.md`. Capture:
- How many pipelines were successful, partially successful, unsupported, or failed.
- Unknown or unsupported build steps.
- Secrets, variable groups, self-hosted runners, service connections, or environments that require manual work.
- Actions that the converted workflows would use.

### Optional: Forecast GitHub Actions usage

Estimate Actions usage from your Azure DevOps pipeline history.

```bash
gh actions-importer forecast azure-devops --output-dir "$OUTPUT_DIR/forecast"
```

Review `actions-importer-output/forecast/forecast_report.md`. Note the expected job count, execution time, queue time, concurrency, and any runner queues that affect cost or capacity.

### Part C: Dry-run one pipeline conversion

Convert a build pipeline locally without opening a pull request.

```bash
gh actions-importer dry-run azure-devops pipeline \
  --pipeline-id "$PIPELINE_ID" \
  --output-dir "$OUTPUT_DIR/dry-run"
```

For an Azure DevOps release pipeline, use `release`.

```bash
gh actions-importer dry-run azure-devops release \
  --pipeline-id "$PIPELINE_ID" \
  --output-dir "$OUTPUT_DIR/dry-run"
```

Review the generated workflow YAML under the dry-run output directory. GitHub aims to auto-convert about 80%, with no guarantee of a perfect result. Expect manual cleanup for unsupported or unknown tasks, service connections, secrets, variables, environments, approvals, self-hosted agents, and resource triggers.

### Part D: Migrate by pull request

Convert the same pipeline and let Importer open a pull request on the target repository.

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

Open the pull request URL printed by the command. Read the PR description, especially the Manual steps section, then read `.github/workflows/*.yml` in the Files changed tab.

### Part E: Review and fix the generated workflow

In the pull request branch:
1. Read every generated `.github/workflows/*.yml` file.
2. Replace unsupported or unknown steps with equivalent GitHub Actions, shell commands, reusable workflows, or documented manual steps.
3. Recreate required GitHub repository or organization secrets and variables. Do not commit secret values.
4. Replace Azure DevOps service connections with GitHub-native credentials. Prefer OIDC.
5. Decide whether self-hosted agents become GitHub-hosted runners, larger runners, or self-hosted runners.
6. Write down at least one conversion gap and how you fixed it.

### Part F: Validate in GitHub Actions

Run the reviewed conversion on its PR branch before cutover. If manual dispatch needs the workflow on the default branch, merge only the trigger and setup first, through your normal review.

```bash
gh workflow list --repo <github-org>/<github-repo>
gh workflow run <workflow-file-name.yml> --repo <github-org>/<github-repo> --ref main
gh run watch --repo <github-org>/<github-repo>
```

If the workflow is triggered only by `push` or `pull_request`, push a small docs-only branch or update the PR branch instead of using `workflow_dispatch`.

1. Compare test counts and artifact contents for the same commit in the source pipeline and GitHub run. Download an artifact to inspect it. Compare how each pipeline handles failures too.
2. Fail a test on purpose in the PR and require the matching Actions check. Verify that a contributor without bypass permission can't merge. Then fix the test and rerun.
3. Map any source deployment approval to a protected GitHub environment. Withhold or reject approval and verify the deployment job doesn't run. Then approve a test deployment. If the source has no deployment gate, note that.
4. Get an independent review. Cut over only after the run passes and any approval test is done. Give each unsupported behavior an owner.

## Cleanup

Keep the pull request and reports if the migration plan needs them as evidence. If you used a sample repository, delete the local `actions-importer-output/` directory once you've saved what you need. Remove any test secrets, variables, or workflows you created in GitHub.

## Reference links

- [Automating migration with GitHub Actions Importer](https://docs.github.com/en/actions/tutorials/migrate-to-github-actions/automated-migrations/use-github-actions-importer)
- [Migrating from Azure DevOps with GitHub Actions Importer](https://docs.github.com/en/actions/tutorials/migrate-to-github-actions/automated-migrations/azure-devops-migration)
