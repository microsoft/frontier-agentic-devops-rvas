# Ch05: Safe auto-merge

**Session outcome:** Auto-merge waits for required CI and independent approval, then merges. Merge queue is optional.

## Prerequisites
- Repository administration for auto-merge settings and an independent reviewer.
- Approved repository credentials. You don't need organization-wide ruleset permissions.
- Local tooling: `gh >= 2.x`, `git`, `jq`.
- Know the concepts from Ch02 (PRs, CODEOWNERS) and Ch04 (Actions, required checks). This activity doesn't depend on them; its setup creates what it needs.

## Scenario
A team wants reviewed changes to merge once CI passes. Enable auto-merge without widening bypass permissions or adding housekeeping workflows.

> [!IMPORTANT]
> Use a customer repository if you have one: use it wherever this guide says `ghec-ch05-advanced-pr-automation` and skip Setup. Otherwise test in the seeded repo below, then apply the configuration to a customer repository.
>
> Record the target, who adopts it, and the next action.

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

### Part A: Reuse the existing review and CI gates
1. Check the default-branch ruleset. Create one only if the sample has none. Confirm it has:
   - Require a pull request before merging (≥1 approval, require review from Code Owners, dismiss stale approvals)
   - Require status checks to pass → add the seeded `build` check
   - Block force pushes
   - Require linear history
2. Set enforcement to Active. Confirm with `gh api repos/<org>/ghec-ch05-advanced-pr-automation/rulesets`.
3. Test it: push directly to `main` (`git push origin main`) and confirm GitHub rejects it.

### Part B: CODEOWNERS, required reviewers and bypass
4. Map `/src/` and `/docs/` in `CODEOWNERS` to existing teams or users. Create teams if needed. See [about code owners](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners).
5. Reuse the protection and CODEOWNERS from Ch02 and Ch04. Leave the bypass list empty so automation passes the same gates as contributors.
6. Open a PR touching `/src/` and confirm GitHub requests the code owner and the PR can't merge without their approval.

### Part C: Auto-merge
7. Enable auto-merge for the repo (Settings → General → Pull Requests → Allow auto-merge). See [automatically merging a pull request](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/incorporating-changes-from-a-pull-request/automatically-merging-a-pull-request).
8. Turn on auto-merge for a clean PR (`gh pr merge <n> --auto --squash`). With CI still running and approval pending, watch the PR show "will be merged automatically when requirements are met." Have the independent reviewer approve it and wait for CI to pass, then confirm it merges automatically.
9. Compare with a failing PR: enable auto-merge on the failing-CI PR and confirm it doesn't merge until the check passes.

### Optional: Merge queue for a busy branch

10. Use a queue only if concurrent merges cause stale CI. Check that your plan supports it and get owner approval before requiring it.
11. Add the `merge_group` trigger to the required CI workflow and configure the merge-queue rule on the test branch.
12. Queue two reviewed PRs and capture the merge-group SHA and CI run. Fail a test on purpose and check that the failing candidate doesn't merge. Fix it and retry.
13. If the queue can't run, record it as blocked or skip this extension. Testing auto-merge alone doesn't test the queue.

Keep the URLs that show auto-merge waiting for approval and for CI, plus the successful merge. Ch08 covers organization rulesets. This session doesn't cover path labeling or stale-item automation.

## Reference links
Documentation links are in the tasks above. More CLI references:
- [`gh ruleset` / `gh pr merge` manual](https://cli.github.com/manual/gh_pr_merge)
- [`gh ruleset`](https://cli.github.com/manual/gh_ruleset)
