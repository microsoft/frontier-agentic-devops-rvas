# Ch25: Migrate from GitLab to GitHub

**Session outcome:** You copied a GitLab repository's source and Git history to GitHub and checked them against the original. You converted its CI pipeline to GitHub Actions and recorded the conversion gaps and the GitLab metadata that didn't come across.

## Migration limits

GitLab isn't a self-serve source for GitHub Enterprise Importer. Migrating GitLab metadata such as Merge Requests and issues through GEI is a GitHub Expert Services engagement.

Here you use Git CLI to migrate source and Git history, then convert GitLab CI separately with GitHub Actions Importer. This pilot doesn't migrate platform metadata.

## Prerequisites

- GitHub organization and repository create rights.
- A GitLab repository on gitlab.com or self-managed GitLab with branches, tags, history, and `.gitlab-ci.yml`.
- `git`, Docker, and GitHub CLI (`gh`) installed.
- A GitLab personal access token with read access to the source repository and CI configuration.
- A GitHub account with the GitLab commit email addresses added and verified in GitHub email settings, so commit authorship resolves.

## Scenario

This pilot mirrors Git history into GitHub, converts the CI definition, and records what the self-serve path loses. Your follow-up plan must cover metadata, LFS, packages, and cutover risk.

> [!IMPORTANT]
> Use an approved GitLab repository as the source, and an approved GitHub target. Mirror and cut over only with an approved owner and a source freeze. Otherwise, stay a pilot. If you don't have an approved repository, note what blocks you and the next step. Don't migrate an unapproved example.

## Tasks

### Part A: Prepare the target repository

1. Authenticate to GitHub CLI.

   ```bash
   gh auth status
   ```

2. Set the repository names for your migration.

   ```bash
   export GITHUB_ORG="your-github-org"
   export GITHUB_REPO="gitlab-migration-pilot"
   export GITLAB_REPO_URL="https://gitlab.example.com/group/repo.git"
   ```

3. Create an empty GitHub repository. Don't add a README, license, or `.gitignore`. The mirror push brings the GitLab refs across.

   ```bash
   gh repo create "$GITHUB_ORG/$GITHUB_REPO" --private --description "Pilot migration from GitLab" --confirm
   ```

### Part B: Mirror GitLab source and history

1. Create a bare clone of the GitLab repository.

   ```bash
   git clone --bare "$GITLAB_REPO_URL"
   ```

2. Before pushing, use the Ch26 checks on the refs and blob sizes, and check author emails. Confirm the destination is empty and approved, because a mirror push can overwrite or delete its refs. Freeze source writes for the final cutover, then push.

   ```bash
   cd repo.git
   git push --mirror "https://github.com/$GITHUB_ORG/$GITHUB_REPO.git"
   cd ..
   rm -rf repo.git
   ```

`--mirror` pushes every ref in the bare clone, including branches and tags, and keeps commit history. GitHub links commit authorship to accounts by commit email, so add the GitLab commit email to the matching GitHub account before or right after migration.

3. Validate the migrated refs.

   ```bash
   gh repo view "$GITHUB_ORG/$GITHUB_REPO" --web
   git ls-remote --heads "https://github.com/$GITHUB_ORG/$GITHUB_REPO.git"
   git ls-remote --tags "https://github.com/$GITHUB_ORG/$GITHUB_REPO.git"
   ```

### Part C: Document what did not migrate

The Git CLI path doesn't migrate GitLab metadata or platform services. Add these to your cutover notes as follow-ups:

- Merge Requests, MR comments, reviews, approvals, and discussions.
- Issues, labels, and milestones.
- GitLab CI/CD pipeline run history.
- Wikis (they're separate repositories in GitLab).
- Packages, container registry data, job artifacts, and release artifacts.
- Git LFS objects, unless you migrate LFS separately.

If the customer must keep Merge Requests, issues, or other metadata intact, engage GitHub Expert Services for the GitLab-to-GHEC path. For GitLab into GitHub Enterprise Server, the expert-led path is `gl-exporter` → `ghe-migrator`.

### Part D: Plan around large repository limits

GitHub blocks individual files above 100 MiB and limits a single push to 2 GiB. If the first mirror push fails with `remote: fatal: pack exceeds maximum allowed size`, push the default branch in batches and finish with a mirror push.

```bash
git clone --bare "$GITLAB_REPO_URL"
cd repo.git
git remote add github "https://github.com/$GITHUB_ORG/$GITHUB_REPO.git"
export BRANCH="main"
step_commits=$(git log --oneline --reverse "refs/heads/$BRANCH" | awk 'NR % 1000 == 0 {print $1}')
for commit in $step_commits; do
  git push github "+$commit:refs/heads/$BRANCH"
done
git push github --mirror
cd ..
rm -rf repo.git
```

Lower `1000` if a batch still exceeds 2 GiB. If a single commit is larger than 2 GiB, split it or deliberately restart history. GitHub can't accept it in one push.

### Part E: Convert GitLab CI to GitHub Actions

Repository migration tools don't carry CI/CD pipelines. Use GitHub Actions Importer to convert `.gitlab-ci.yml` into workflow YAML. It aims to convert about 80% automatically, so review the generated workflow before production use.

1. Clone the migrated GitHub repository.

   ```bash
   gh repo clone "$GITHUB_ORG/$GITHUB_REPO"
   cd "$GITHUB_REPO"
   ```

2. Install and update the extension.

   ```bash
   gh extension install github/gh-actions-importer
   gh actions-importer update
   ```

3. Configure credentials for GitHub and GitLab. The prompts ask for your GitHub token, GitLab token, and GitLab instance URL.

   ```bash
   gh actions-importer configure
   ```

4. Audit, dry-run, and migrate the GitLab CI pipeline.

   ```bash
   mkdir -p migration-work/actions-audit migration-work/actions-dry-run migration-work/actions-migrate
   gh actions-importer audit gitlab --output-dir migration-work/actions-audit
   gh actions-importer dry-run gitlab --output-dir migration-work/actions-dry-run --source-file-path .gitlab-ci.yml
   gh actions-importer migrate gitlab --output-dir migration-work/actions-migrate --target-url "https://github.com/$GITHUB_ORG/$GITHUB_REPO" --source-file-path .gitlab-ci.yml
   ```

5. Review the generated pull request or local YAML under `.github/workflows/`. Fix unsupported steps, and set up secrets and runners before running it.
6. Run the workflow in GitHub. Download its artifact and compare the tests and result with the GitLab pipeline for the same commit.
7. Require the CI check and an independent review. In the first post-migration PR, fail a test on purpose and verify that GitHub blocks the merge. Then fix it and get approval before merging. Use Ch39 to recreate and test any source deployment approval.
8. Compare source and destination branch and tag SHAs. Ask the owner to accept cutover, or keep the source read-only until the gaps are closed. A converted YAML file alone doesn't finish the migration.

## Reference links

- [Migration paths to GitHub](https://docs.github.com/en/migrations/overview/migration-paths-to-github)
- [Importing an external Git repository using the command line](https://docs.github.com/en/migrations/importing-source-code/using-the-command-line-to-import-source-code/importing-an-external-git-repository-using-the-command-line)
- [GitHub Actions Importer](https://docs.github.com/en/actions/tutorials/migrate-to-github-actions/automated-migrations/use-github-actions-importer)
