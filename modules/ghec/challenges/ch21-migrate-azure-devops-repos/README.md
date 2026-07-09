# Ch21 — Migrate Azure DevOps Repos with GitHub Enterprise Importer

> By the end of this challenge you can inventory, queue, run, validate, and clean up a real Azure DevOps Services Git repository migration into GitHub Enterprise Cloud using `gh ado2gh`.

| | |
|---|---|
| **Track** | Migration |
| **Difficulty** | Intermediate *(per-track ramp)* |
| **Duration** | ~4 hrs total, multi-session |
| **Minimum input** | A GitHub org where you are **org owner**, plus an Azure DevOps Services org with a Git repo that has PR history |
| **App** | None |
| **EMU compatible** | yes |

## Prerequisites

**Challenges:** _(none — this challenge is self-contained)_

**Access and tools you need:**
- GitHub Enterprise Cloud organization with **org-owner** rights.
- Azure DevOps Services **Cloud** organization with at least one **Git** repo containing PR history. TFVC is not supported by GEI; convert TFVC to Git first.
- `gh >= 2.4.0`, `git`, and PowerShell (`pwsh` or Windows PowerShell) installed.
- A **classic GitHub PAT**. Fine-grained PATs are not supported for GEI. For an org owner, grant `repo`, `admin:org`, and `workflow` scopes.
- An Azure DevOps PAT with `work item (read)`, `code (read)`, and `identity (read)` scopes. Use **Full access** if you need `inventory-report` to work across all projects.
- If your GitHub org enforces SAML SSO, authorize the GitHub PAT for SSO before running migrations.

## Scenario objectives

By completing this challenge you will:
- Install and verify the GitHub Enterprise Importer Azure DevOps extension.
- Create and store the required `GH_PAT` and `ADO_PAT` environment variables safely.
- Produce an Azure DevOps repository inventory and choose a realistic pilot repo based on PR count.
- Generate and run a bulk migration script, then run or queue a single-repo migration directly.
- Validate what GEI migrated and document what it intentionally does not migrate.
- Reclaim mannequins so migrated PR activity is attributed to GitHub users.
- Build a follow-up backlog for Azure Boards and Azure Pipelines work that GEI does not migrate.

> [!IMPORTANT]
> **Bring your own outcome (do this first)**
>
> Pick a repository that belongs to a real team and has at least one pull request. A small pilot repo is better than a huge monorepo: migration timing is driven mainly by **pull request count**, not Git repository size.
>
> Record these values before you start:
>
> ```bash
> export ADO_ORG="YOUR_ADO_ORG"
> export ADO_PROJECT="YOUR_ADO_TEAM_PROJECT"
> export ADO_REPO="YOUR_ADO_REPO"
> export GITHUB_ORG="YOUR_GITHUB_ORG"
> export TARGET_REPO="ado-pilot-migrated"
> ```
>
> Recommended sequence: after this repo migration, continue with **ch22** for Azure Boards follow-up and **ch23** for Azure Pipelines / GitHub Actions migration. GEI migrates PR work item links, but not Azure Boards work items or Azure Pipelines definitions.

## Tasks

### Part A — Install the migration extension

1. Confirm your local tooling:

```bash
gh --version
git --version
pwsh --version || powershell -NoProfile -Command '$PSVersionTable.PSVersion'
```

2. Install or upgrade the Azure DevOps migration extension:

```bash
gh extension install github/gh-ado2gh || gh extension upgrade github/gh-ado2gh
gh ado2gh --help
```

### Part B — Prepare credentials

3. Create the two PATs outside the terminal, then set them as environment variables for the current shell. Do not commit or paste token values into files.

```bash
read -s -p "GitHub classic PAT: " GH_PAT; echo
export GH_PAT
read -s -p "Azure DevOps PAT: " ADO_PAT; echo
export ADO_PAT
```

PowerShell equivalent:

```powershell
$env:GH_PAT = Read-Host -AsSecureString "GitHub classic PAT" | ConvertFrom-SecureString -AsPlainText
$env:ADO_PAT = Read-Host -AsSecureString "Azure DevOps PAT" | ConvertFrom-SecureString -AsPlainText
```

4. Validate access without printing secrets:

```bash
gh auth status
printf 'GH_PAT set: '; test -n "$GH_PAT" && echo yes || echo no
printf 'ADO_PAT set: '; test -n "$ADO_PAT" && echo yes || echo no
```

If your GitHub org uses SAML SSO, open the PAT settings page and authorize the classic PAT for that organization. A migration error such as `Resource is protected by organization SAML enforcement` means this step was missed.

### Part C — Inventory Azure DevOps repositories

5. Generate an inventory report:

```bash
gh ado2gh inventory-report --ado-org "$ADO_ORG"
```

6. Review the generated `repos.csv`. Prioritize a pilot repo with real PR metadata but low risk.

```bash
python - <<'PY'
import csv, glob
for path in glob.glob('**/repos.csv', recursive=True) or ['repos.csv']:
    try:
        with open(path, newline='', encoding='utf-8-sig') as f:
            rows = list(csv.DictReader(f))
    except FileNotFoundError:
        continue
    print(f'\n{path}')
    for row in rows[:10]:
        print(row)
PY
```

Use the report to answer:
- Which repositories are Git and therefore supported?
- Which repositories have many pull requests and should be scheduled later?
- Are there TFVC repositories that require conversion before GEI can migrate them?

### Part D — Generate and inspect a migration script

7. Generate a PowerShell script for the migration set. Use `--all` for a full org pilot script, or scope the generated script down before running it.

```bash
gh ado2gh generate-script \
  --ado-org "$ADO_ORG" \
  --github-org "$GITHUB_ORG" \
  --output migrate-ado-repos.ps1 \
  --all \
  --download-migration-logs
```

8. Inspect the script before running it. Confirm target repo names, visibility choices, and any `--skip-releases` or `--queue-only` decisions.

```bash
grep -n "gh ado2gh migrate-repo" migrate-ado-repos.ps1
```

9. Run the script in PowerShell when you are satisfied:

```bash
pwsh ./migrate-ado-repos.ps1
```

If `pwsh` is unavailable on Windows, run this from PowerShell instead:

```powershell
.\migrate-ado-repos.ps1
```

### Part E — Run a single-repo migration intentionally

10. For one selected pilot repo, run the direct command. Start with `--queue-only` if you want to inspect the migration ID and wait explicitly.

```bash
gh ado2gh migrate-repo \
  --ado-org "$ADO_ORG" \
  --ado-team-project "$ADO_PROJECT" \
  --ado-repo "$ADO_REPO" \
  --github-org "$GITHUB_ORG" \
  --target-repo "$TARGET_REPO" \
  --queue-only \
  --skip-releases \
  --target-repo-visibility private
```

11. If queued, wait for the migration using the migration ID printed by the previous command:

```bash
# Paste the RM_... migration ID printed by the queue command.
read -r -p "Migration ID: " MIGRATION_ID
gh ado2gh wait-for-migration --migration-id "$MIGRATION_ID"
```

12. Download logs before they expire. Migration logs are available for **24 hours only**.

```bash
gh ado2gh download-logs \
  --github-target-org "$GITHUB_ORG" \
  --target-repo "$TARGET_REPO" \
  --migration-log-file "$TARGET_REPO-migration.log"
```

> Azure DevOps migrations do **not** require you to provide blob storage; GEI stages the migration internally.

### Part F — Validate migrated and non-migrated content

13. Confirm the repository exists and note its visibility. Repositories arrive **private by default** unless you intentionally set visibility.

```bash
gh repo view "$GITHUB_ORG/$TARGET_REPO" --json name,visibility,url --jq '{name, visibility, url}'
```

14. Validate migrated content:

```bash
gh pr list --repo "$GITHUB_ORG/$TARGET_REPO" --state all --limit 10
gh api repos/$GITHUB_ORG/$TARGET_REPO/pulls?state=all --jq '.[0] | {number,title,state,user:.user.login}'
gh api repos/$GITHUB_ORG/$TARGET_REPO/branches --jq '.[].name'
```

GEI migrates:
- Git source and commit history.
- Pull requests.
- User history for pull requests.
- Work item **links** on pull requests.
- Pull request attachments.
- Repository branch policies, excluding user-scoped and cross-repo branch policies.

GEI does **not** migrate:
- TFVC repositories. Convert TFVC to Git in Azure Repos first.
- Azure Pipelines definitions.
- Azure Boards work items. Only PR work item links migrate.
- Git LFS objects. Push LFS objects manually after migration.
- Repository permissions. Recreate teams and access in GitHub.
- User-scoped and cross-repo branch policies.

### Part G — Reclaim mannequins

15. Generate the mannequin mapping CSV:

```bash
gh ado2gh generate-mannequin-csv \
  --github-org "$GITHUB_ORG" \
  --output mannequins.csv
```

16. Edit `mannequins.csv` so each mannequin maps to an existing GitHub organization member. Reclaiming requires an org owner; the migrator role alone is not enough. In EMU organizations, use `--skip-invitation`.

```bash
gh ado2gh reclaim-mannequin \
  --github-org "$GITHUB_ORG" \
  --csv mannequins.csv
```

EMU variant:

```bash
gh ado2gh reclaim-mannequin \
  --github-org "$GITHUB_ORG" \
  --csv mannequins.csv \
  --skip-invitation
```

Commit authorship is separate from mannequin reclaiming: Git commits are attributed by email address when the email matches a GitHub account.

## Validation / Definition of Done

You are done when ALL of the following are true:
- [ ] An Azure DevOps Services Git repository with at least one PR is migrated into your GitHub org.
- [ ] `inventory-report` produced `repos.csv`, and you used PR counts to choose or schedule the pilot.
- [ ] The migrated repo contains Git source history and migrated PR history.
- [ ] At least one migrated PR shows its work item link, or you documented that the source PR had no work item link.
- [ ] The migrated repo visibility is verified as private by default or intentionally set with `--target-repo-visibility`.
- [ ] Migration logs were downloaded within 24 hours or the download command and migration ID are documented.
- [ ] At least one mannequin was reclaimed, or `mannequins.csv` and an org-owner reclaim plan exist.
- [ ] A TFVC repo, if present, was correctly identified as unsupported and the TFVC-to-Git conversion path was documented.
- [ ] Coach conversation — name the real repository, owning team, cutover window, and follow-up backlog for Boards, Pipelines, LFS, permissions, and branch policies.

## Stretch goals

- Run a second migration without `--queue-only` and compare operational control versus direct execution.
- Create a cutover checklist that freezes source writes because GEI does not perform delta migrations.
- Recreate one repository permission model in GitHub teams and document which Azure DevOps access model it replaces.

## Reference links

- About GitHub Enterprise Importer — https://docs.github.com/en/migrations/using-github-enterprise-importer/understanding-github-enterprise-importer/about-github-enterprise-importer
- Understand migrations from Azure DevOps — https://docs.github.com/en/migrations/ado/understand-migrations-from-azure-devops-to-github
- Manage access for Azure DevOps migrations — https://docs.github.com/en/migrations/ado/manage-access
- Prepare for your Azure DevOps migration — https://docs.github.com/en/migrations/ado/prepare-for-your-migration-from-azure-devops-to-github
- Migrate repositories from Azure DevOps — https://docs.github.com/en/migrations/ado/migrate-your-repositories-from-azure-devops-to-github
- Follow-up tasks for Azure DevOps migrations — https://docs.github.com/en/migrations/ado/follow-up-tasks
