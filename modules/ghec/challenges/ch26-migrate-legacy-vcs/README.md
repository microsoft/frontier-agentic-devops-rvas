# Ch26 — Migrate Legacy VCS (SVN, Mercurial, TFVC, Perforce) to GitHub

> Convert legacy source-control history into Git, then push the converted repository to GitHub with author mapping, large-file checks, and cutover evidence.

| | |
|---|---|
| **Track** | Migration |
| **Difficulty** | Advanced |
| **Duration** | ~4 hrs |
| **Minimum input** | A GitHub org or repo destination plus at least one legacy VCS source |
| **App** | None |
| **EMU compatible** | yes |

## Prerequisites

**Challenges:** none. This challenge is self-contained. For Azure Repos Git migration after TFVC conversion, ch21 is a useful cross-reference but not required.

**Access and tooling:**
- GitHub organization with repository create rights.
- GitHub CLI authenticated with permission to create and push repositories.
- `git` installed.
- For SVN: `git svn` and a reachable Subversion repository.
- For Mercurial: `hg`, Python, and `hg-fast-export`.
- For TFVC: Azure DevOps organization with Azure Repos access.
- For Perforce: `git-p4` and access to the source depot.

## Scenario

Your migration team has legacy source systems that GitHub Enterprise Importer does not migrate directly. You need a reliable source-and-history path for Subversion, Mercurial, TFVC, and Perforce repositories.

The GitHub Importer web tool is now **Git-only**, imports code and commit history only, works on **GitHub.com only**, and does not import LFS, issues, pull requests, or other metadata. SVN, Mercurial, TFVC, and Perforce must be converted to Git with CLI tooling first, then pushed to GitHub.

> Hands-on scope: complete SVN plus at least one of Mercurial, TFVC, or Perforce if you have source access. For systems you cannot access in the workshop, document the exact commands, source URL shape, identity map, and blocker so a real migration owner can execute it later.

## Setup

Set shared destination variables.

```bash
GITHUB_ORG=<github-org>
DEST_REPO=<new-github-repo>
VISIBILITY=private
```

Create the destination repository only after you know which converted Git directory you will push.

```bash
gh repo create "$GITHUB_ORG/$DEST_REPO" --$VISIBILITY
```

## Tasks

### Part A — Subversion: extract authors and convert with `git svn`

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

5. Push the converted repository to GitHub.

```bash
gh repo create "$GITHUB_ORG/$DEST_REPO" --private
git remote add origin "https://github.com/$GITHUB_ORG/$DEST_REPO.git"
git push --mirror origin
```

### Part B — Mercurial: convert with `hg-fast-export`

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

4. Inspect the converted refs and push to GitHub.

```bash
git log --oneline --decorate --graph --all | head -50
gh repo create "$GITHUB_ORG/$DEST_REPO" --private
git remote add origin "https://github.com/$GITHUB_ORG/$DEST_REPO.git"
git push --mirror origin
```

### Part C — TFVC: convert to Azure Repos Git first, then push to GitHub

TFVC has no direct `git svn` equivalent in GitHub's migration tooling. Convert TFVC to Git inside Azure Repos first by using Azure DevOps **Repos > Import repository > TFVC** or the organization's approved TFVC-to-Git import process. After the Azure Repos Git repository exists, treat it as a Git source.

```bash
ADO_ORG=<azure-devops-org>
ADO_PROJECT=<azure-devops-project>
ADO_GIT_REPO=<azure-repos-git-repo>
DEST_REPO=<github-repo>

git clone --mirror "https://dev.azure.com/$ADO_ORG/$ADO_PROJECT/_git/$ADO_GIT_REPO" tfvc-git-mirror
cd tfvc-git-mirror
gh repo create "$GITHUB_ORG/$DEST_REPO" --private
git remote set-url origin "https://github.com/$GITHUB_ORG/$DEST_REPO.git"
git push --mirror origin
```

If you need Azure Repos Git repository migration patterns with metadata, use the Azure DevOps Git migration challenge (ch21). This challenge covers the legacy TFVC-to-Git prerequisite and the source-and-history Git push path.

### Part D — Perforce: convert with `git-p4`

1. Authenticate to Perforce and clone the depot path.

```bash
export P4PORT=perforce.example.com:1666
export P4USER=<perforce-user>
p4 login

git p4 clone //depot/path@all p4-converted
cd p4-converted
```

2. Review the converted history and push to GitHub.

```bash
git log --oneline --decorate --graph --all | head -50
gh repo create "$GITHUB_ORG/$DEST_REPO" --private
git remote add origin "https://github.com/$GITHUB_ORG/$DEST_REPO.git"
git push --mirror origin
```

For very large depots, migrate one depot path at a time and agree on branch mapping before cutover.

### Part E — Cross-cutting migration checks

Run these checks in each converted Git repository before the final push.

1. Confirm author identities are useful.

```bash
git log --all --format='%aN <%aE>' | sort -u | less
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
git lfs migrate import --include='*.zip,*.jar,*.bin,*.psd'
git lfs push --all origin
```

3. Plan around the 2 GiB single-push limit. For very large first imports, push history in batches, then finish with the full ref push.

```bash
BRANCH=main
git rev-list --reverse "$BRANCH" | awk 'NR % 1000 == 0' | \
  while read commit; do git push origin "+$commit:refs/heads/$BRANCH"; done

git push origin "$BRANCH"
git push --tags origin
```

Repeat branch-by-branch if needed, or reduce the batch size for unusually large commits. If you need every ref exactly mirrored after successful batching, run `git push --mirror origin` only after the large history is already present on GitHub.

4. Document metadata gaps. These CLI conversions preserve source and commit history, but not issues, pull requests, reviews, permissions, CI/CD runs, work items, shelves, labels, or other collaboration metadata.

## Validation / Definition of Done

You are done when the applicable evidence is true:

- [ ] An SVN repository's trunk, branches, and tags history was converted to Git with an authors map and pushed to GitHub, or the exact source-specific blocker was documented.
- [ ] A Mercurial repository was converted through `hg-fast-export` with an author map and pushed to GitHub with history intact, or the exact source-specific blocker was documented.
- [ ] The TFVC to Azure Repos Git to GitHub path was executed or documented end-to-end, including the handoff to ch21 for Azure Repos Git migration patterns.
- [ ] A Perforce depot path was converted through `git-p4` and pushed to GitHub, or the exact source-specific blocker was documented.
- [ ] Author identities in converted commits resolve to real names and emails instead of `unknown` or raw source usernames.
- [ ] Large-file and large-push risks were checked, including 100 MiB file blocks, Git LFS candidates, and the 2 GiB single-push limit.
- [ ] At least one converted repository exists in GitHub with branches, tags, and expected commit history visible.
- [ ] Coach conversation — explain which legacy VCS source you would migrate first in a real program, which metadata will not come across, and how you would reduce cutover risk.

## Cleanup

Delete only workshop-created GitHub repositories and local conversion directories when you no longer need the evidence.

```bash
gh repo delete "$GITHUB_ORG/$DEST_REPO" --yes
```

Do not delete or rewrite the original legacy source system during the workshop.

## Reference links

- About source code imports using the command line — https://docs.github.com/en/migrations/importing-source-code/using-the-command-line-to-import-source-code/about-source-code-imports-using-the-command-line
- Importing an external Git repository using the command line — https://docs.github.com/en/migrations/importing-source-code/using-the-command-line-to-import-source-code/importing-an-external-git-repository-using-the-command-line
- Importing a Subversion repository — https://docs.github.com/en/migrations/importing-source-code/using-the-command-line-to-import-source-code/importing-a-subversion-repository
- About GitHub Importer — https://docs.github.com/en/migrations/importing-source-code/using-github-importer/about-github-importer
- About large files on GitHub — https://docs.github.com/en/repositories/working-with-files/managing-large-files/about-large-files-on-github
- Troubleshooting the 2 GB push limit — https://docs.github.com/en/get-started/using-git/troubleshooting-the-2-gb-push-limit
