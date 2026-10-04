# Ch02: Branches, pull requests and code review

**Session outcome:** You merge a small IDE change after independent review. CODEOWNERS requests the correct reviewer, and the review rule blocks an unapproved merge.

## Prerequisites
- Write access to the Ch00 customer repository and an administrator to configure its review rule.
- A token with the scopes listed by `modules/ghec/resources/provisioning/scripts/setup.sh doctor ch02 --org <org>` (least-privilege; for this activity: `repo` + `read:org`).
- Local tooling: `gh >= 2.x`, `git`, `jq` (run `modules/ghec/resources/provisioning/scripts/setup.sh doctor` to verify).
- An independent human reviewer with repository access. Without one, stop after testing that the review rule blocks a merge.

## What you will deliver
- Use a branch-per-change workflow and open pull requests from the CLI and UI.
- Run a code review: line comments, review threads, suggested changes, approve / request-changes.
- Define ownership with a `CODEOWNERS` file and require owner review through branch protection.
- Optionally practice a merge conflict after completing the reviewed change.
- Use the team's one approved merge method.
- Use draft PRs, linked issues (`Closes #n`), and PR templates.

## Scenario
A GHEC customer's team pushes unreviewed changes straight to `main`, sometimes breaking other work. Configure a workflow that requires a PR for every change and review by the code owners. Test it on a seeded service repo.

> [!IMPORTANT]
> Use an approved customer target first. If you have a candidate repository, use it everywhere this guide says `ghec-ch02-pull-requests-code-review` and skip Setup. Otherwise use the fallback seeded repo below for testing, then move the validated configuration to an approved customer target.
>
> Record the selected target, adoption owner, and next action.

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
- A printed Next steps block telling you where to start.

## Tasks
> `ghec-ch02-pull-requests-code-review` is the fallback sample name; substitute your own artifact's name if you brought one.

### Part A: Branch and open a PR
1. Reuse the Ch00 repository and Ch01 issue. Create `feature/issue-fix`. In the team's IDE, use approved Copilot Chat or completions to explain the relevant code and propose a small change. Read the diff and run the existing tests yourself. If Copilot is unavailable, make the same change manually and record that the assisted step was blocked.
2. Open a draft: `gh pr create --draft --base main --head feature/issue-fix --fill`. Link the Ch01 issue with `Closes #<n>` and include the test result.
3. Mark it ready with `gh pr ready` and request the independent reviewer.

### Part B: Code review mechanics
4. Have the reviewer inspect the change and leave one useful comment or suggestion.
5. Address it and push the fix. The reviewer checks the new diff and test result.
6. Keep approval pending until you have tested the required-review gate below. The author cannot approve their own PR.

### Part C: CODEOWNERS and branch protection
7. Author a `CODEOWNERS` file (`.github/CODEOWNERS`) mapping paths to owners, e.g.:
   ```
   *            @<org>/maintainers
   /src/        @<org>/backend-team
   /docs/       @<org>/docs-team
   ```
   Use existing teams with write access. **The last matching line wins**, so put the wildcard first. Merge CODEOWNERS to the base branch before testing review routing.
8. Protect `main`. Add a branch protection rule (or a repo ruleset) requiring: a pull request before merging, at least 1 approving review, and review from Code Owners. Disallow direct pushes to `main`.
9. Use a contributor without bypass permission to confirm that GitHub requests the expected owner and blocks merging without approval. The independent owner approves only after the tests pass.

### Optional: Merge conflict
10. Trigger the conflict. The second seeded branch edits the same lines as a change you'll make on `main` (via another PR). Merge your `main` change first, then attempt to merge the seeded branch. GitHub reports a conflict.
11. Resolve it locally: `git fetch`, `git rebase origin/main` (or merge), fix the conflict markers, push, and watch the PR go mergeable.

### Finish the change
12. Use the team's approved merge method, for example squash. Do not enable extra merge modes for this exercise.
13. Merge after independent approval. Verify the linked issue closes and the Ch01 board updates. Keep the PR and test URLs as [completion evidence](../../../README.md#completion-evidence). An unmerged draft is practice.

### Optional: Contribute across teams

Use this path instead of a separate contribution exercise when the customer needs InnerSource adoption. Select a contributor outside the repository's owning team and a maintainer who will review their work.

1. Choose a small real issue. Check README and CONTRIBUTING explain the build, tests, and review route; fix only gaps that block this contribution.
2. Confirm the contributor can read the repository and propose a branch or approved fork. Grant only approved access. Keep the owner-review and CI rules unchanged.
3. Complete the reviewed PR steps above with that contributor. CODEOWNERS should request the owning team; the contributor must not merge without independent owner approval.
4. After merge, verify the default-branch change and close the issue. Ask which instruction or access step slowed the contributor down and fix that gap.

Keep the issue and reviewed PR, and identify the cross-team contributor. If none is available, record the blocker instead of claiming a cross-team contribution.

## Reference links
- [About pull requests](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/about-pull-requests)
- [About code owners](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners)
- [About protected branches](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)
- [About merge methods](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/configuring-pull-request-merges/about-merge-methods-on-github)
- [Reviewing changes in pull requests](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/reviewing-changes-in-pull-requests/about-pull-request-reviews)
- [Resolving a merge conflict](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/addressing-merge-conflicts/resolving-a-merge-conflict-using-the-command-line)
- [`gh pr` CLI manual](https://cli.github.com/manual/gh_pr)
