# Ch02: Branches, pull requests and code review

**Session outcome:** You merge a tested change that fixes a real issue. CODEOWNERS requests the right reviewer, and the required-approval rule blocks the merge until they approve.

## Prerequisites
- Write access to the Ch00 customer repository and an administrator to configure its review rule.
- A token with the scopes listed by `modules/ghec/resources/provisioning/scripts/setup.sh doctor ch02 --org <org>` (least privilege; here: `repo` + `read:org`).
- Local tooling: `gh >= 2.x`, `git`, `jq`.
- An independent human reviewer with repository access. **Blocked** without one: note it in the adoption issue and stop. The session isn't complete.

## Scenario
A GHEC customer's team pushes unreviewed changes straight to `main`, sometimes breaking other work. Require a PR and code owner review for every change.

> [!IMPORTANT]
> Use a customer repository if you have one: use it wherever this guide says `ghec-ch02-pull-requests-code-review` and skip Setup. Otherwise test in the seeded repo below.

## Sample test repository or environment
Skip if you brought your own repo.

```bash
# Bash
bash modules/ghec/resources/provisioning/scripts/setup.sh provision ch02 --org <org>
```
```powershell
# PowerShell
modules/ghec/resources/provisioning/scripts/setup.ps1 provision ch02 --org <org>
```

Setup creates these resources (all names use the `ghec-ch02-*` prefix, and teardown is prefix-guarded):
- A seeded repo `ghec-ch02-pull-requests-code-review` containing a small multi-file app (e.g., `src/`, `docs/`, `.github/`) and a populated `main` branch.
- Two pre-existing feature branches with open pull requests (one clean, one that will conflict).
- A `.github/pull_request_template.md` placeholder.
- A `main` branch with no protection yet (you add it) and a starter directory layout that maps cleanly to `CODEOWNERS` paths.

## Tasks
> `ghec-ch02-pull-requests-code-review` is the fallback sample name; use your own repository's name if you brought one.

### Part A: Branch and open a PR
1. Reuse the Ch00 repository and Ch01 issue. Create `feature/issue-fix`. Use approved Copilot Chat or completions in your IDE to explain the code and propose a small change, or make it by hand. Read the diff and run the existing tests yourself.
2. Open a draft: `gh pr create --draft --base main --head feature/issue-fix --fill`. Link the issue with `Closes #<n>` and include the test result.
3. Mark it ready with `gh pr ready` and request the independent reviewer.

### Part B: Review
4. Have the reviewer leave one useful comment or suggestion.
5. Address it and push the fix. Hold the approval until you've tested the required-review rule below. Authors can't approve their own PRs.

### Part C: CODEOWNERS and branch protection
6. Create `.github/CODEOWNERS` mapping paths to owners, e.g.:
   ```
   *            @<org>/maintainers
   /src/        @<org>/backend-team
   /docs/       @<org>/docs-team
   ```
   Use existing teams with write access. **The last matching line wins**, so put the wildcard first. Merge CODEOWNERS to the base branch before testing review requests.
7. Protect `main`. Add a branch protection rule (or a repo ruleset) requiring: a pull request before merging, at least 1 approving review, and review from Code Owners. Disallow direct pushes to `main`.
8. With a contributor who has no bypass permission, confirm that GitHub requests the right owner and blocks the merge without approval. The owner approves only after tests pass.

### Merge
9. Use the team's merge method, for example squash. Don't enable other merge methods.
10. Merge after independent approval. Check that the linked issue closes and the Ch01 board updates. An unmerged draft doesn't complete the session.

### Optional

- **Merge conflict.** Merge a `main` change that edits the same lines as the second seeded branch, then try to merge that branch. Resolve it locally with `git fetch`, `git rebase origin/main`, fix the markers, and push. See [resolving a merge conflict](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/addressing-merge-conflicts/resolving-a-merge-conflict-using-the-command-line).
- **InnerSource.** Have a contributor outside the owning team submit a small real issue through the same reviewed PR flow. CODEOWNERS requests the owning team, and the contributor can't merge without owner approval.

## Reference links
- [About pull requests](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/about-pull-requests)
- [About code owners](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners)
- [About protected branches](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)
- [About merge methods](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/configuring-pull-request-merges/about-merge-methods-on-github)
- [Reviewing changes in pull requests](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/reviewing-changes-in-pull-requests/about-pull-request-reviews)
- [Resolving a merge conflict](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/addressing-merge-conflicts/resolving-a-merge-conflict-using-the-command-line)
- [`gh pr` CLI manual](https://cli.github.com/manual/gh_pr)
