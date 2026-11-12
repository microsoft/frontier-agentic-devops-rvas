# Ch21: Migrate Azure DevOps Repos with GitHub Enterprise Importer

**Session outcome:** You migrated an approved Azure DevOps Services repository to GitHub Enterprise Cloud with `gh ado2gh` and checked the result. You recorded what didn't migrate and reclaimed mannequins, or assigned them for follow-up.

## Prerequisites

This guide has no activity dependencies.

Access and tools you need:
- GitHub Enterprise Cloud organization with org-owner rights.
- Azure DevOps Services Cloud organization with at least one Git repo containing PR history. TFVC is not supported by GEI; convert TFVC to Git first.
- `gh >= 2.4.0`, `git`, and PowerShell (`pwsh` or Windows PowerShell) installed.
- A classic GitHub PAT. Fine-grained PATs are not supported for GEI. For an org owner, grant `repo`, `admin:org`, and `workflow` scopes.
- An Azure DevOps PAT with `work item (read)`, `code (read)`, and `identity (read)` scopes. Use Full access if you need `inventory-report` to work across all projects.
- If your GitHub org enforces SAML SSO, authorize the GitHub PAT for SSO before running migrations.

## What you'll do
- Install the GitHub Enterprise Importer Azure DevOps extension.
- Set the `GH_PAT` and `ADO_PAT` environment variables without leaking them.
- Inventory your Azure DevOps repos and pick a pilot with real PR history.
- Migrate and check one approved pilot. Generate a bulk script only afterward.
- Check what GEI migrated and list what it doesn't.
- Reclaim mannequins so migrated PR activity maps to GitHub users.
- Log follow-up work for Azure Boards and Azure Pipelines, which GEI doesn't migrate.

> [!IMPORTANT]
> Pick one approved pilot with pull request history and freeze source writes during the migration. **`--queue-only` starts a real migration, so get approval first.** Without approval, stop after the read-only inventory and command review.
>
> Set these before you start:
>
> ```bash
> export ADO_ORG="YOUR_ADO_ORG"
> export ADO_PROJECT="YOUR_ADO_TEAM_PROJECT"
> export ADO_REPO="YOUR_ADO_REPO"
> export GITHUB_ORG="YOUR_GITHUB_ORG"
> export TARGET_REPO="ado-pilot-migrated"
> ```
>
> Next: ch22 covers Azure Boards and ch23 covers Azure Pipelines to GitHub Actions. GEI migrates PR work item links, but not Azure Boards work items or Azure Pipelines definitions.

## Tasks

### Part A: Install the migration extension

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

### Part B: Prepare credentials

3. Create the two PATs outside the terminal, then set them as environment variables in the current shell. Never commit token values or paste them into files.

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

If your GitHub org uses SAML SSO, authorize the classic PAT for it on the PAT settings page. The error `Resource is protected by organization SAML enforcement` means you skipped this.

### Part C: Inventory Azure DevOps repositories

5. Generate an inventory report:

```bash
gh ado2gh inventory-report --ado-org "$ADO_ORG"
```

6. Review the generated `repos.csv`. Pick a low-risk pilot repo with real PRs.

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
- Which repos are Git, and so supported?
- Which repos have many pull requests and should wait for a later wave?
- Which TFVC repos need converting before GEI can migrate them?

### Optional, after Part G: Generate a later migration wave

7. Once the owner accepts the pilot (Parts E through G), generate a script for the next approved repos. `--all` lists every repo in the organization, so remove the unapproved ones before you run it.

```bash
gh ado2gh generate-script \
  --ado-org "$ADO_ORG" \
  --github-org "$GITHUB_ORG" \
  --output migrate-ado-repos.ps1 \
  --all \
  --download-migration-logs
```

8. Read the script before running it. Check target repo names, visibility, and any `--skip-releases` or `--queue-only` flags.

```bash
grep -n "gh ado2gh migrate-repo" migrate-ado-repos.ps1
```

9. Run the script only after the pilot owner accepts the results and approves the next repos. Freeze source writes first:

```bash
pwsh ./migrate-ado-repos.ps1
```

If `pwsh` is unavailable on Windows, run this from PowerShell instead:

```powershell
.\migrate-ado-repos.ps1
```

### Part E: Run a controlled single-repo migration

10. Do this before the optional bulk section. `--queue-only` submits the approved pilot immediately and prints its migration ID.

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

11. Wait for the migration with the ID from the previous command:

```bash
# Paste the RM_... migration ID printed by the queue command.
read -r -p "Migration ID: " MIGRATION_ID
gh ado2gh wait-for-migration --migration-id "$MIGRATION_ID"
```

12. Download the logs within 24 hours, before they expire.

```bash
gh ado2gh download-logs \
  --github-target-org "$GITHUB_ORG" \
  --target-repo "$TARGET_REPO" \
  --migration-log-file "$TARGET_REPO-migration.log"
```

> Azure DevOps migrations don't need your own blob storage. GEI stages the data itself.

### Part F: Validate migrated and non-migrated content

13. Confirm the repo exists and check its visibility. Repos arrive private unless you set otherwise.

```bash
gh repo view "$GITHUB_ORG/$TARGET_REPO" --json name,visibility,url --jq '{name, visibility, url}'
```

14. Check the migrated content:

```bash
gh pr list --repo "$GITHUB_ORG/$TARGET_REPO" --state all --limit 10
gh api repos/$GITHUB_ORG/$TARGET_REPO/pulls?state=all --jq '.[0] | {number,title,state,user:.user.login}'
gh api repos/$GITHUB_ORG/$TARGET_REPO/branches --jq '.[].name'
```

GEI migrates:
- Git source and commit history.
- Pull requests.
- User history for pull requests.
- Work item links on pull requests.
- Pull request attachments.
- Repository branch policies, excluding user-scoped and cross-repo branch policies.

GEI does not migrate:
- TFVC repositories. Convert TFVC to Git in Azure Repos first.
- Azure Pipelines definitions.
- Azure Boards work items. Only PR work item links migrate.
- Git LFS objects. Push LFS objects manually after migration.
- Repository permissions. Recreate teams and access in GitHub.
- User-scoped and cross-repo branch policies.

### Part G: Reclaim mannequins

15. Generate the mannequin mapping CSV:

```bash
gh ado2gh generate-mannequin-csv \
  --github-org "$GITHUB_ORG" \
  --output mannequins.csv
```

16. Edit `mannequins.csv` so each mannequin maps to an existing GitHub organization member. Reclaiming needs an org owner; the migrator role isn't enough. In EMU organizations, use `--skip-invitation`.

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

Commit authorship is separate from mannequins: GitHub attributes a commit by email address when it matches a GitHub account.

Before accepting the pilot:
- Compare branch and tag SHAs between source and destination.
- Check sample PR comments and author mappings.
- Recreate team access. Verify that failing CI or a missing approval blocks a non-owner's first PR.

Keep source writes frozen until the owner accepts cutover, and keep the source read-only as your fallback.

## Reference links

- [About GitHub Enterprise Importer](https://docs.github.com/en/migrations/using-github-enterprise-importer/understanding-github-enterprise-importer/about-github-enterprise-importer)
- [Understand migrations from Azure DevOps](https://docs.github.com/en/migrations/ado/understand-migrations-from-azure-devops-to-github)
- [Manage access for Azure DevOps migrations](https://docs.github.com/en/migrations/ado/manage-access)
- [Prepare for your Azure DevOps migration](https://docs.github.com/en/migrations/ado/prepare-for-your-migration-from-azure-devops-to-github)
- [Migrate repositories from Azure DevOps](https://docs.github.com/en/migrations/ado/migrate-your-repositories-from-azure-devops-to-github)
- [Follow-up tasks for Azure DevOps migrations](https://docs.github.com/en/migrations/ado/follow-up-tasks)
