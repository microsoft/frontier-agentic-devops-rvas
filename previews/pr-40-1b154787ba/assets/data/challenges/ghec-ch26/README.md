# Ch26: Convert one legacy VCS repository

**Session outcome:** You have converted the selected legacy VCS repository to Git and pushed it to GitHub. You have checked the history and author mapping, and recorded large-file issues and cutover limitations.

## Prerequisites

This guide is independent. Ch21 covers Azure Repos Git migration after TFVC conversion.

Access and tooling:
- GitHub organization with repository create rights.
- GitHub CLI authenticated with permission to create and push repositories.
- `git` installed.
- For SVN: `git svn` and a reachable Subversion repository.
- For Mercurial: `hg`, Python, and `hg-fast-export`.
- For TFVC: Azure DevOps organization with Azure Repos access.
- For Perforce: `git-p4` and access to the source depot.

## Scenario

GitHub Enterprise Importer does not directly migrate Subversion, Mercurial, TFVC, or Perforce repositories. Convert them to Git with CLI tooling, then push the converted history to GitHub.

The GitHub Importer web tool accepts Git sources only, works on GitHub.com only, and imports code and commit history without LFS, issues, pull requests, or other metadata.

> [!IMPORTANT]
> Use an approved legacy-VCS source (SVN, Mercurial, TFVC, or Perforce) as the source and target throughout this guide. Without one, record the access constraint and next action instead of migrating an unapproved example.

## Setup

Set shared destination variables.

```bash
GITHUB_ORG=<github-org>
DEST_REPO=<new-github-repo>
VISIBILITY=private
```

Create the destination once, in Part E, after validating the converted history.

## Tasks

Choose one converter, then complete Part E before any push. Ask the source owner to approve a write freeze for final export and cutover. Keep the original source read-only for recovery.

### Part A: Subversion: extract authors and convert with `git svn`

1. Export unique SVN usernames into an author map file.

```bash
SVN_URL=https://svn.example.com/project
svn log -q "$SVN_URL" | awk -F'|' '/^r/ {gsub(/^ +| +$/, "", $2); print $2" = "$2" <"$2"@example.com>"}' | sort -u > authors.txt
```

2. Edit `authors.txt` so every source username maps to a real identity.

```text
svnuser = Full Name <email@example.com>
jdoe = Jane Doe <jane.doe@example.com>
```

3. Convert the standard SVN layout (`trunk`, `branches`, `tags`) to Git.

```bash
git svn clone -s "$SVN_URL" svn-converted --authors-file authors.txt
cd svn-converted
```

If the repository does not use the standard layout, replace `-s` with explicit paths, for example:

```bash
git svn clone "$SVN_URL" svn-converted \
  --trunk=mainline --branches=release-branches --tags=labels \
  --authors-file authors.txt
```

4. Convert SVN remote branches and tags into normal Git branches and tags before pushing.

```bash
git for-each-ref --format='%(refname:short)' refs/remotes/origin | \
  grep -v '^origin/tags/' | grep -v '^origin/trunk$' | \
  while read ref; do git branch "${ref#origin/}" "refs/remotes/$ref"; done

git for-each-ref --format='%(refname:short)' refs/remotes/origin/tags | \
  while read ref; do git tag "${ref#origin/tags/}" "refs/remotes/$ref"; done
```

5. Continue to Part E with the local conversion. Do not push yet.

### Part B: Mercurial: convert with `hg-fast-export`

1. Clone the Mercurial source and the converter.

```bash
HG_URL=https://hg.example.com/team/project
hg clone "$HG_URL" hg-source
git clone https://github.com/frej/fast-export.git hg-fast-export
```

2. Create an author map. Use the Mercurial username exactly as it appears in commits.

```text
legacyuser=Full Name <email@example.com>
Jane Doe <jane@old.example>=Jane Doe <jane.doe@example.com>
```

3. Run `hg-fast-export` into a fresh Git repository.

```bash
mkdir hg-git-converted
cd hg-git-converted
git init
../hg-fast-export/hg-fast-export.sh -r ../hg-source -A ../authors.txt
git checkout HEAD
```

4. Inspect the converted refs, then continue to Part E before pushing.

```bash
git log --oneline --decorate --graph --all | head -50
```

### Part C: TFVC: convert to Azure Repos Git first, then push to GitHub

TFVC has no direct `git svn` equivalent in GitHub's migration tooling. Convert TFVC to Git inside Azure Repos first by using Azure DevOps Repos > Import repository > TFVC or the organization's approved TFVC-to-Git import process. After the Azure Repos Git repository exists, treat it as a Git source.

```bash
ADO_ORG=<azure-devops-org>
ADO_PROJECT=<azure-devops-project>
ADO_GIT_REPO=<azure-repos-git-repo>
DEST_REPO=<github-repo>

git clone --mirror "https://dev.azure.com/$ADO_ORG/$ADO_PROJECT/_git/$ADO_GIT_REPO" tfvc-git-mirror
cd tfvc-git-mirror
```

If you need Azure Repos Git repository migration patterns with metadata, use the Azure DevOps Git migration activity (ch21). This activity covers the legacy TFVC-to-Git prerequisite and the source-and-history Git push path.

### Part D: Perforce: convert with `git-p4`

1. Authenticate to Perforce and clone the depot path.

```bash
export P4PORT=perforce.example.com:1666
export P4USER=<perforce-user>
p4 login

git p4 clone //depot/path@all p4-converted
cd p4-converted
```

2. Review the converted history, then continue to Part E.

```bash
git log --oneline --decorate --graph --all | head -50
```

For very large depots, migrate one depot path at a time and agree on branch mapping before cutover.

### Part E: Common migration checks

Run these checks in each converted Git repository before the final push.

1. Confirm author identities map to the intended people.

```bash
git log --all --format='%aN <%aE>' | sort -u
```

Fix bad identities in the source-specific author map and reconvert rather than accepting `unknown`, raw usernames, or fake email domains.

2. Find large files before GitHub rejects the push.

```bash
git rev-list --objects --all | \
  git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' | \
  awk '$1 == "blob" && $3 >= 50000000 {printf "%.1f MiB %s\n", $3/1048576, $4}' | \
  sort -nr | head -50
```

GitHub warns at 50 MiB and blocks files over 100 MiB. Move large binaries to Git LFS before the migration when they must remain versioned.

```bash
git lfs install
git lfs migrate import --everything --include='*.zip,*.jar,*.bin,*.psd'
```

3. Compare the converted branches and tags with the source, including the default branch. Record any converter limitations and review its tracking refs before mirroring them. After the owner accepts the result, create the empty destination once and add a separate remote:

```bash
gh repo create "$GITHUB_ORG/$DEST_REPO" --private
git remote add github "https://github.com/$GITHUB_ORG/$DEST_REPO.git"
git push github --all
git push github --tags
# Only if the chosen conversion uses LFS:
git lfs push --all github
```

For repositories that exceed the 2 GiB single-push limit, plan approved batches before executing those pushes:

```bash
BRANCH=main
git rev-list --reverse "$BRANCH" | awk 'NR % 1000 == 0' | \
  while read commit; do git push github "$commit:refs/heads/$BRANCH"; done

git push github "$BRANCH"
git push --tags github
```

Repeat for other required branches if needed. Compare the approved local branch and tag SHAs with `git ls-remote --heads --tags github`. Make a fresh clone and run the source project's tests. If LFS conversion rewrites history, get approval for the resulting refs.

4. Document metadata gaps. These CLI conversions preserve source and commit history, but not issues, pull requests, reviews, permissions, CI/CD runs, work items, shelves, labels, or other collaboration metadata.

## Cleanup

Remove only approved local conversion files after verification. Retain the GitHub destination and original source until the owner accepts cutover and its recovery plan.

Do not delete or rewrite the original legacy source system during controlled validation.

## Reference links

- [About source code imports using the command line](https://docs.github.com/en/migrations/importing-source-code/using-the-command-line-to-import-source-code/about-source-code-imports-using-the-command-line)
- [Importing an external Git repository using the command line](https://docs.github.com/en/migrations/importing-source-code/using-the-command-line-to-import-source-code/importing-an-external-git-repository-using-the-command-line)
- [Importing a Subversion repository](https://docs.github.com/en/migrations/importing-source-code/using-the-command-line-to-import-source-code/importing-a-subversion-repository)
- [About GitHub Importer](https://docs.github.com/en/migrations/importing-source-code/using-github-importer/about-github-importer)
- [About large files on GitHub](https://docs.github.com/en/repositories/working-with-files/managing-large-files/about-large-files-on-github)
- [Troubleshooting the 2 GB push limit](https://docs.github.com/en/get-started/using-git/troubleshooting-the-2-gb-push-limit)
