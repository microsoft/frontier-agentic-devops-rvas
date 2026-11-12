# Ch02: Branches, pull requests and code review

**Session outcome:** You merge a small change after independent review. CODEOWNERS requests the right reviewer, and the review rule blocks a merge without approval.

## Prerequisites
- Write access to the Ch00 customer repository and an administrator to configure its review rule.
- A token with the scopes listed by `modules/ghec/resources/provisioning/scripts/setup.sh doctor ch02 --org <org>` (least privilege; here: `repo` + `read:org`).
- Local tooling: `gh >= 2.x`, `git`, `jq` (run `modules/ghec/resources/provisioning/scripts/setup.sh doctor` to verify).
- An independent human reviewer with repository access. Without one, stop after you confirm the review rule blocks a merge.

## What you will deliver
- Use a branch-per-change workflow and open pull requests from the CLI and UI.
- Review code: line comments, threads, suggested changes, approve or request changes.
- Define ownership with a `CODEOWNERS` file and require owner review through branch protection.
- Merge with the team's one approved merge method.
- Optionally practice a merge conflict after the reviewed change.
- Use draft PRs, linked issues (`Closes #n`), and PR templates.

## Scenario
A GHEC customer's team pushes unreviewed changes straight to `main`, sometimes breaking other work. Require a PR and code owner review for every change.

> [!IMPORTANT]
> Use a customer repository if you have one: use it wherever this guide says `ghec-ch02-pull-requests-code-review` and skip Setup. Otherwise test in the seeded repo below, then apply the configuration to a customer repository.
>
> Record the target, who adopts it, and the next action.

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
- Two pre-existing feature branches with open pull requests that need review (one clean, one that will conflict).
- A `.github/pull_request_template.md` placeholder you will improve.
- A `main` branch with no protection yet (you add it) and a starter directory layout that maps cleanly to `CODEOWNERS` paths.

## Tasks
> `ghec-ch02-pull-requests-code-review` is the fallback sample name; use your own repository's name if you brought one.

### Part A: Branch and open a PR
1. Reuse the Ch00 repository and Ch01 issue. Create `feature/issue-fix`. In the team's IDE, use approved Copilot Chat or completions to explain the relevant code and propose a small change. Read the diff and run the existing tests yourself. If Copilot is unavailable, make the change by hand and record that the Copilot step was blocked.
2. Open a draft: `gh pr create --draft --base main --head feature/issue-fix --fill`. Link the Ch01 issue with `Closes #<n>` and include the test result.
3. Mark it ready with `gh pr ready` and request the independent reviewer.

### Part B: Code review mechanics
4. Have the reviewer inspect the change and leave one useful comment or suggestion.
5. Address it and push the fix. The reviewer checks the new diff and test result.
6. Hold the approval until you've tested the required-review rule below. Authors can't approve their own PRs.

### Part C: CODEOWNERS and branch protection
7. Create a `CODEOWNERS` file (`.github/CODEOWNERS`) mapping paths to owners, e.g.:
   ```
   *            @<org>/maintainers
   /src/        @<org>/backend-team
   /docs/       @<org>/docs-team
   ```
   Use existing teams with write access. **The last matching line wins**, so put the wildcard first. Merge CODEOWNERS to the base branch before testing review requests.
8. Protect `main`. Add a branch protection rule (or a repo ruleset) requiring: a pull request before merging, at least 1 approving review, and review from Code Owners. Disallow direct pushes to `main`.
9. With a contributor who has no bypass permission, confirm that GitHub requests the right owner and blocks the merge without approval. The owner approves only after tests pass.

### Optional: Merge conflict
10. Trigger the conflict. The second seeded branch edits the same lines as a change you'll make on `main` through another PR. Merge your `main` change first, then try to merge the seeded branch. GitHub reports a conflict.
11. Resolve it locally: `git fetch`, `git rebase origin/main` (or merge), fix the conflict markers, push, and confirm the PR is mergeable.

### Finish the change
12. Use the team's merge method, for example squash. Don't enable other merge methods.
13. Merge after independent approval. Check that the linked issue closes and the Ch01 board updates. Keep the PR and test URLs as [completion evidence](../../../README.md#completion-evidence). An unmerged draft counts as practice only.

### Optional: Contribute across teams

Use this path when the customer wants InnerSource adoption. Pick a contributor outside the repository's owning team and a maintainer to review their work.

1. Choose a small real issue. Check that README and CONTRIBUTING explain the build, tests, and review route. Fix only the gaps that block this contribution.
2. Confirm the contributor can read the repository and propose a branch or approved fork. Grant only approved access, and leave the owner-review and CI rules as they are.
3. Complete the reviewed PR steps above with that contributor. CODEOWNERS should request the owning team; the contributor must not merge without independent owner approval.
4. After the merge, check the change on the default branch and close the issue. Ask what slowed the contributor down and fix it.

Keep the issue and reviewed PR, and name the cross-team contributor. If you have none, record the blocker. Don't claim a cross-team contribution.

## Reference links
- [About pull requests](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/about-pull-requests)
- [About code owners](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners)
- [About protected branches](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)
- [About merge methods](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/configuring-pull-request-merges/about-merge-methods-on-github)
- [Reviewing changes in pull requests](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/reviewing-changes-in-pull-requests/about-pull-request-reviews)
- [Resolving a merge conflict](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/addressing-merge-conflicts/resolving-a-merge-conflict-using-the-command-line)
- [`gh pr` CLI manual](https://cli.github.com/manual/gh_pr)
