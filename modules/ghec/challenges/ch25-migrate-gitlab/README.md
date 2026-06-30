# Ch25 — Migrate from GitLab to GitHub

> Migrate a GitLab repository's source and Git history to GitHub with Git CLI, then convert its GitLab CI pipeline to GitHub Actions with GitHub Actions Importer.

| | |
|---|---|
| **Track** | Migration |
| **Difficulty** | Intermediate |
| **Duration** | ~3 hrs |
| **Minimum input** | A GitLab repository and an empty GitHub repository target |
| **App** | None |
| **EMU compatible** | yes |

## Critical framing

GitLab is **not** a self-serve source for GitHub Enterprise Importer. A full GitLab migration that preserves metadata such as Merge Requests and issues through GEI is a **GitHub Expert Services** engagement.

This hands-on challenge uses the self-serve path that is available to any Git repository: **source + Git history** via Git CLI. You will then convert GitLab CI separately with GitHub Actions Importer. Treat this as a pilot cutover pattern, not a full metadata migration.

## Prerequisites

- GitHub organization and repository create rights.
- A GitLab repository on gitlab.com or self-managed GitLab with branches, tags, history, and `.gitlab-ci.yml`.
- `git`, Docker, and GitHub CLI (`gh`) installed.
- A GitLab personal access token with read access to the source repository and CI configuration.
- A GitHub account that has the GitLab commit email addresses added and verified under GitHub email settings, so commit authorship can resolve correctly.

## Scenario

Your team is piloting a GitLab-to-GitHub move. The business wants fast cutover evidence, but also an honest inventory of what the self-serve path does **not** preserve. You will mirror Git history into GitHub, convert the CI definition, and document follow-up work for metadata, LFS, packages, and cutover risk.

## Tasks

### Part A — Prepare the target repository

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

3. Create an empty GitHub repository. Do not initialize it with a README, license, or `.gitignore`; the mirror push should bring the GitLab refs across.

   ```bash
   gh repo create "$GITHUB_ORG/$GITHUB_REPO" --private --description "Pilot migration from GitLab" --confirm
   ```

### Part B — Mirror GitLab source and history

1. Create a bare clone of the GitLab repository.

   ```bash
   git clone --bare "$GITLAB_REPO_URL"
   ```

2. Push every Git ref to GitHub.

   ```bash
   cd repo.git
   git push --mirror "https://github.com/$GITHUB_ORG/$GITHUB_REPO.git"
   cd ..
   rm -rf repo.git
   ```

`--mirror` pushes all refs in the bare clone, including branches, tags, and other refs. It preserves Git commit history. Commit authorship is linked to GitHub accounts by commit email, so add the GitLab commit email to the matching GitHub account before or immediately after migration.

3. Validate the migrated refs.

   ```bash
   gh repo view "$GITHUB_ORG/$GITHUB_REPO" --web
   git ls-remote --heads "https://github.com/$GITHUB_ORG/$GITHUB_REPO.git"
   git ls-remote --tags "https://github.com/$GITHUB_ORG/$GITHUB_REPO.git"
   ```

### Part C — Document what did not migrate

The Git CLI path does **not** migrate GitLab metadata or platform services. Record these as explicit follow-up items in your cutover notes:

- Merge Requests, MR comments, reviews, approvals, and discussions.
- Issues, labels, and milestones.
- GitLab CI/CD pipeline run history.
- Wikis, because GitLab wikis are separate repositories.
- Packages, container registry data, job artifacts, and release artifacts.
- Git LFS objects, unless you migrate LFS separately.

If the customer requires Merge Request, issue, or other metadata fidelity, engage **GitHub Expert Services** for the GitLab-to-GHEC path. For GitLab into GitHub Enterprise Server, the expert-led path is `gl-exporter` → `ghe-migrator`.

### Part D — Plan around large repository limits

GitHub blocks individual files above **100 MiB** and limits a single push to **2 GiB**. If the first mirror push fails with `remote: fatal: pack exceeds maximum allowed size`, push the default branch in batches and finish with a mirror push.

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

Reduce `1000` if any batch still exceeds 2 GiB. If a single commit is larger than 2 GiB, split that commit or restart history intentionally; GitHub cannot accept it in one push.

### Part E — Convert GitLab CI to GitHub Actions

Repository migration tools do not carry CI/CD pipelines. Use GitHub Actions Importer to convert `.gitlab-ci.yml` into GitHub Actions workflow YAML. The importer targets about 80% automatic conversion, so always review the generated workflow before production use.

1. Clone the migrated GitHub repository as a working tree.

   ```bash
   gh repo clone "$GITHUB_ORG/$GITHUB_REPO"
   cd "$GITHUB_REPO"
   ```

2. Install and update the importer extension.

   ```bash
   gh extension install github/gh-actions-importer
   gh actions-importer update
   ```

3. Configure credentials for GitHub and GitLab. Use the interactive prompts to provide your GitHub token, GitLab token, and GitLab instance URL.

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

5. Review the generated pull request or local YAML under `.github/workflows/`. Fix unsupported syntax, secrets, runner labels, container assumptions, caches, services, and environment variables before enabling the workflow as a required gate.

## Validation / Definition of Done

You are done when all of the following are true:

- [ ] An empty GitHub repository was created as the target.
- [ ] The GitLab repository's branch and tag history was mirror-pushed to GitHub.
- [ ] At least one migrated commit links to the expected GitHub user through a matching commit email.
- [ ] You documented the GitLab data that did not migrate in this self-serve path.
- [ ] GitHub Actions Importer produced a dry-run workflow or opened a PR that adds `.github/workflows/*.yml`.
- [ ] You identified manual fixes required before the converted workflow can run reliably.
- [ ] Coach conversation — explain why GitLab metadata migration requires Expert Services, when `gl-exporter` → `ghe-migrator` applies, and what cutover risks remain for your pilot.

## Reference links

- Migration paths to GitHub — https://docs.github.com/en/migrations/overview/migration-paths-to-github
- Importing an external Git repository using the command line — https://docs.github.com/en/migrations/importing-source-code/using-the-command-line-to-import-source-code/importing-an-external-git-repository-using-the-command-line
- GitHub Actions Importer — https://docs.github.com/en/actions/tutorials/migrate-to-github-actions/automated-migrations/use-github-actions-importer
