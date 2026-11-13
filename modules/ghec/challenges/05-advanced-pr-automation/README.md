# Ch05: Safe auto-merge

**Session outcome:** Auto-merge merges a passing PR only after required CI and independent approval, and never merges a failing one.

## Prerequisites
- Repository administration for auto-merge settings and an independent reviewer.
- Local tooling: `gh >= 2.x`, `git`, `jq`.
- Working review and CI gates from Ch02 and Ch04. The sample setup creates equivalents if you skip those sessions.

## Scenario
A team wants reviewed changes to merge once CI passes. Enable auto-merge without widening bypass permissions or adding housekeeping workflows.

> [!IMPORTANT]
> Use a customer repository if you have one: use it wherever this guide says `ghec-ch05-advanced-pr-automation` and skip Setup. Otherwise test in the seeded repo below.

## Sample test repository or environment
Skip if you brought your own repo.

```bash
# Bash
bash modules/ghec/resources/provisioning/scripts/setup.sh provision ch05 --org <org>
```
```powershell
# PowerShell
modules/ghec/resources/provisioning/scripts/setup.ps1 provision ch05 --org <org>
```

Setup creates these resources (all names use the `ghec-ch05-*` prefix, and teardown is prefix-guarded):
- A seeded repo `ghec-ch05-advanced-pr-automation` with a small app, a working CI workflow that emits a `build` status check, a populated `main`, and a `src/` + `docs/` layout for CODEOWNERS paths.
- Several open PRs in different states (clean, failing-CI, draft, missing-owner-review) so every rule has something to act on.
- A starter `.github/CODEOWNERS` and a placeholder `.github/pull_request_template.md`.
- No rulesets yet. You create them.

## Tasks
> `ghec-ch05-advanced-pr-automation` is the fallback sample name; use your own repository's name if you brought one.

### Part A: Start from the working Ch02 gates
1. Check the default-branch ruleset. Create one only if the sample has none. Confirm it has:
   - Require a pull request before merging (≥1 approval, require review from Code Owners, dismiss stale approvals)
   - Require status checks to pass → add the seeded `build` check
   - Block force pushes
   - Require linear history
2. Set enforcement to Active. Confirm with `gh api repos/<org>/ghec-ch05-advanced-pr-automation/rulesets`.
3. Test it: commit a harmless change on a throwaway local branch, then try to push it straight to `main` (`git push origin HEAD:main`). Confirm GitHub rejects it.

### Part B: Check CODEOWNERS and bypass
4. Map `/src/` and `/docs/` in `CODEOWNERS` to existing teams or users. See [about code owners](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners).
5. Leave the bypass list empty so automation passes the same gates as contributors.
6. Open a PR touching `/src/` and confirm GitHub requests the code owner and the PR can't merge without their approval.

### Part C: Auto-merge
7. Enable auto-merge for the repo (Settings → General → Pull Requests → Allow auto-merge). See [automatically merging a pull request](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/incorporating-changes-from-a-pull-request/automatically-merging-a-pull-request).
8. **Passing PR.** Turn on auto-merge for a clean PR (`gh pr merge <n> --auto --squash`). With CI running and approval pending, the PR shows "will be merged automatically when requirements are met." Have the independent reviewer approve it and wait for CI. Confirm it merges automatically.
9. **Failing PR.** Enable auto-merge on the failing-CI PR and confirm it doesn't merge, even if approved, until the check passes.

### Optional: Merge queue

Use a queue only if concurrent merges cause stale CI and your plan supports it. Add the `merge_group` trigger to the required CI workflow, configure the merge-queue rule on a test branch, and queue two reviewed PRs. See [managing a merge queue](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/configuring-pull-request-merges/managing-a-merge-queue).

Ch08 covers organization rulesets.

## Reference links
Documentation links are in the tasks above. More CLI references:
- [`gh ruleset` / `gh pr merge` manual](https://cli.github.com/manual/gh_pr_merge)
- [`gh ruleset`](https://cli.github.com/manual/gh_ruleset)
