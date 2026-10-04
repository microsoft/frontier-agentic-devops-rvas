# Ch05: Safe auto-merge

**Session outcome:** Auto-merge waits for required CI and independent approval, then merges the approved change. Merge queue is an optional extension.

## Prerequisites
- Repository administration for auto-merge settings and an independent reviewer.
- Approved repository credentials. Organization-wide ruleset permissions are unnecessary.
- Local tooling: `gh >= 2.x`, `git`, `jq`.
- Review the concepts in Ch02 (PRs/CODEOWNERS) and Ch04 (Actions/required checks) first. This activity is independent; its setup creates everything it needs.

## What you will deliver
- Reuse the review and CI gates from Ch02 and Ch04.
- Prove auto-merge waits while either gate is unsatisfied.

## Scenario
A team wants reviewed changes to merge once CI passes. Enable auto-merge without widening bypass or adding housekeeping workflows.

> [!IMPORTANT]
> Use an approved customer target first. If you have a candidate repository, use it everywhere this guide says `ghec-ch05-advanced-pr-automation` and skip Setup. Otherwise use the fallback seeded repo below for testing, then move the validated configuration to an approved customer target.
>
> Record the selected target, adoption owner, and next action.

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
- A printed Next steps block telling you where to start.

## Tasks
> `ghec-ch05-advanced-pr-automation` is the fallback sample name; substitute your own artifact's name if you brought one.

### Part A: Reuse the existing review and CI gates
1. Inspect the existing default-branch ruleset. Create one only if the sample has none. Confirm:
   - Require a pull request before merging (≥1 approval, require review from Code Owners, dismiss stale approvals)
   - Require status checks to pass → add the seeded `build` check
   - Block force pushes
   - Require linear history
2. Set enforcement to Active. Confirm via `gh api repos/<org>/ghec-ch05-advanced-pr-automation/rulesets`.
3. Test enforcement: attempt a direct push to `main` (`git push origin main`) and confirm it's rejected.

### Part B: CODEOWNERS, required reviewers and bypass
4. Map `/src/` and `/docs/` in `CODEOWNERS` to existing teams/users. Create the team(s) if needed. See [about code owners](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners).
5. Reuse protection and CODEOWNERS from Ch02 and Ch04. Leave the bypass list empty so automation must satisfy the same gates as contributors.
6. Open a PR touching `/src/` and confirm the code owner is auto-requested and the PR cannot merge without their approval.

### Part C: Auto-merge
7. Enable auto-merge for the repo (Settings → General → Pull Requests → Allow auto-merge). Learn more: [automatically merging a pull request](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/incorporating-changes-from-a-pull-request/automatically-merging-a-pull-request).
8. Turn on auto-merge for a clean PR (`gh pr merge <n> --auto --squash`). With CI still running and approval pending, watch the PR show "will be merged automatically when requirements are met." Approve + let CI go green, then confirm it merges itself.
9. Contrast with a failing PR: enable auto-merge on the failing-CI PR and confirm it does not merge until the check passes.

### Optional: Merge queue for a busy branch

10. Use a queue only when concurrent merges cause stale CI. Check plan availability and get owner approval before requiring it.
11. Add the `merge_group` trigger to the required CI workflow and configure the merge-queue rule on the test branch.
12. Queue two reviewed PRs and capture the merge-group SHA and CI run. Deliberately fail a test and verify the failing candidate does not merge. Fix it and retry.
13. If the queue cannot run, record it as blocked or omit this extension. Auto-merge alone does not prove a merge queue.

Keep the URLs that show auto-merge waiting for approval and for CI, plus the successful merge. Ch08 covers organization rulesets. This session does not cover path labeling or stale-item automation.

## Reference links
Official documentation links are embedded throughout the tasks above. Additional CLI references:
- [`gh ruleset` / `gh pr merge` manual](https://cli.github.com/manual/gh_pr_merge)
- [`gh ruleset`](https://cli.github.com/manual/gh_ruleset)
