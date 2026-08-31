# Ch02 — Branches, Pull Requests & Code Review

> Deliver a governed pull-request lifecycle: feature branches, reviews, `CODEOWNERS`, required reviewers, conflict resolution, and merge-strategy controls.

| | |
|---|---|
| Track | Developer Flow |
| Difficulty | Foundational *(per-track ramp)* |
| Duration | ~3–4 hrs total, multi-session |
| Minimum input | An org + an org-owner token. *(All activities are org-scoped — no enterprise owner required.)* |
| App | Provisioned starter repository (created by setup) |
| EMU compatible | yes |

## Delivery target

- Delivery target: the repository's PR template, `CODEOWNERS`, review rules, and branch/ruleset configuration.
- Safety boundary: apply controls only when the repository owner authorises them; use the seeded repository only to validate a proposed change.
- Evidence: the approved policy, validation PRs, and merge-strategy decision.
- Owner: the repository maintainer owns the controls and accepts the documented merge policy.
- Next decision: the maintainer schedules rollout or approves the validated proposal.

## Prerequisites
- An organization you own (or org-owner rights) on GitHub Enterprise Cloud.
- A token with the scopes listed by `modules/ghec/resources/provisioning/scripts/setup.sh doctor ch02 --org <org>` (least-privilege; for this activity: `repo` + `read:org`).
- Local tooling: `gh >= 2.x`, `git`, `jq` (run `modules/ghec/resources/provisioning/scripts/setup.sh doctor` to verify).
- A second account or teammate helps demonstrate *real* review approvals, but the activity is completable solo.

## What you will deliver
- Use a clean branch-per-change workflow and open pull requests from the CLI and UI.
- Run a code review: line comments, review threads, suggested changes, approve / request-changes.
- Define ownership with a `CODEOWNERS` file and require owner review through branch protection.
- Deliberately create and resolve a merge conflict.
- Compare the three merge strategies — merge commit, squash, rebase — and pick the right one.
- Use draft PRs, linked issues (`Closes #n`), and PR templates to streamline collaboration.

## Scenario
A GHEC customer's team keeps pushing straight to `main`, breaking each other's work, and shipping un-reviewed changes. You've been asked to introduce a real review culture: every change goes through a PR, the right people are required to review the code they own, and merges are clean and traceable. You'll build that workflow on a seeded service repo and prove it end-to-end.

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

### Part A — Branch & open a PR
1. Clone and branch. `gh repo clone <org>/ghec-ch02-pull-requests-code-review`, then create `feature/add-healthcheck` and add a small, real change (e.g., a `/health` endpoint or a new function + doc line).
2. Open a PR from the CLI. `gh pr create --base main --head feature/add-healthcheck --fill`. In the body, link an issue with `Closes #<n>` (create a tracking issue first if none exists).
3. Open it as a draft first, then mark it Ready for review (`gh pr ready`). Note how draft PRs cannot be merged and don't request reviewers automatically.

### Part B — Code review mechanics
4. Review the seeded clean PR. Add at least two line comments, one multi-line review thread, and one suggested change (the `\`\`\`suggestion` block). Submit the review as Comment, then iterate.
5. Request changes on something real, have the author (you or a teammate) push a fix commit, and confirm the review thread resolves.
6. Approve the PR once it's clean. (If solo: branch protection blocks self-approval, so you'll demonstrate the *required-review* gate rather than approving your own PR.)

### Part C — CODEOWNERS + branch protection
7. Author a `CODEOWNERS` file (`.github/CODEOWNERS`) mapping paths to owners, e.g.:
   ```
   /src/        @<org>/backend-team
   /docs/       @<your-username>
   *            @<your-username>
   ```
   Create the referenced team(s) if needed (`gh api orgs/<org>/teams -f name='backend-team'`).
8. Protect `main`. Add a branch protection rule (or a repo ruleset) requiring: a pull request before merging, at least 1 approving review, and review from Code Owners. Disallow direct pushes to `main`.
9. Prove ownership routing. Open a PR that touches `/src/` and confirm GitHub auto-requests the code owner.

### Part D — Merge conflict
10. Trigger the conflict. The second seeded branch edits the same lines as a change you'll make on `main` (via another PR). Merge your `main` change first, then attempt to merge the seeded branch — GitHub reports a conflict.
11. Resolve it locally: `git fetch`, `git rebase origin/main` (or merge), fix the conflict markers, push, and watch the PR go mergeable.

### Part E — Merge strategies
12. Configure allowed merges. In repo settings, enable all three: merge commit, squash, rebase. Then merge three different PRs using a *different* strategy each, and inspect the resulting history with `git log --oneline --graph`.
13. Write a one-paragraph note in the repo (`docs/merge-strategy.md`) stating which strategy the team should default to and why (hint: squash for clean linear history is a common GHEC recommendation).

## Reference links
- About pull requests — https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/about-pull-requests
- About code owners — https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners
- About protected branches — https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches
- About merge methods — https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/configuring-pull-request-merges/about-merge-methods-on-github
- Reviewing changes in pull requests — https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/reviewing-changes-in-pull-requests/about-pull-request-reviews
- Resolving a merge conflict — https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/addressing-merge-conflicts/resolving-a-merge-conflict-using-the-command-line
- `gh pr` CLI manual — https://cli.github.com/manual/gh_pr
