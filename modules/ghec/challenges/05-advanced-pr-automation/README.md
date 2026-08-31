# Ch05 — Advanced PR Automation & Rulesets

> Deliver a governed merge pipeline with repository and organisation rulesets, required checks and reviewers, auto-merge, `CODEOWNERS`, and PR automation.

| | |
|---|---|
| Track | Developer Flow |
| Difficulty | Advanced *(per-track ramp)* |
| Duration | ~5–6 hrs total, multi-session |
| Minimum input | An org + an org-owner token. *(All activities are org-scoped — no enterprise owner required.)* |
| App | Provisioned starter repository (created by setup) |
| EMU compatible | yes |

## Delivery target

- Delivery target: a repository or organisation ruleset, `CODEOWNERS`, PR template, and PR-automation workflows.
- Safety boundary: activate rulesets and bypass settings only with the accountable owner's approval; the seeded repository is a sample for proposed policy.
- Evidence: the ruleset export, bypass rationale, workflow files, and validation PR history.
- Owner: the repository and platform owners accept the automation and the bypass governance.
- Next decision: the owner authorises activation in the selected repository or records a rollout decision.

## Prerequisites
- An organization you own (or org-owner rights) on GitHub Enterprise Cloud.
- A token with the scopes listed by `modules/ghec/resources/provisioning/scripts/setup.sh doctor ch05 --org <org>` (least-privilege; for this activity: `repo` + `workflow` + `admin:org` for org rulesets).
- Local tooling: `gh >= 2.x`, `git`, `jq`.
- Recommended: you've done the *concepts* in Ch02 (PRs/CODEOWNERS) and Ch04 (Actions/required checks) — but this activity is independent and its setup creates everything it needs.

## What you will deliver
- Define repository rulesets and an organization ruleset and understand how they layer with classic branch protection.
- Require status checks, pull requests, linear history, and signed commits via rules.
- Configure CODEOWNERS + required reviewers and bypass actors correctly.
- Enable and use auto-merge so a PR merges itself the moment all gates go green.
- Use draft PRs and a PR template to control when review starts.
- Automate PR housekeeping with Actions: auto-label by path, auto-assign reviewers, and mark/close stale PRs.

## Scenario
A GHEC platform team is drowning in manual merge babysitting: pinging reviewers, re-checking CI, merging PRs by hand at odd hours, and chasing stale branches. You'll replace all of that with policy and automation: rulesets that enforce quality at the org and repo level, auto-merge that ships the moment gates pass, and workflows that label, route, and tidy PRs without a human. The result is a merge pipeline that runs itself — safely.

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
- No rulesets yet — you create them.
- A printed Next steps block telling you where to start.

## Tasks
> `ghec-ch05-advanced-pr-automation` is the fallback sample name; substitute your own artifact's name if you brought one.

### Part A — Repository ruleset (replace classic protection)
1. Create a repository ruleset targeting `main` (Settings → Rules → Rulesets → New branch ruleset). Name it `ghec-ch05-main`. Learn more about [repository rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/creating-rulesets-for-a-repository). Enable rules:
   - Require a pull request before merging (≥1 approval, require review from Code Owners, dismiss stale approvals)
   - Require status checks to pass → add the seeded `build` check
   - Block force pushes
   - Require linear history
2. Set enforcement to Active. Confirm via `gh api repos/<org>/ghec-ch05-advanced-pr-automation/rulesets`.
3. Prove it bites: attempt a direct push to `main` (`git push origin main`) and confirm it's rejected.

### Part B — CODEOWNERS + required reviewers + bypass
4. Flesh out `CODEOWNERS` mapping `/src/` and `/docs/` to teams/users that exist. Create the team(s) if needed. See [about code owners](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners).
5. Configure a bypass actor. Add an explicit bypass for org admins (or a named integration) in the ruleset, and document *why* limited bypass exists. Confirm a non-bypass user is fully gated.
6. Open a PR touching `/src/` and confirm the code owner is auto-requested and the PR cannot merge without their approval.

### Part C — Auto-merge
7. Enable auto-merge for the repo (Settings → General → Pull Requests → Allow auto-merge). Learn more: [automatically merging a pull request](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/incorporating-changes-from-a-pull-request/automatically-merging-a-pull-request).
8. Turn on auto-merge for a clean PR (`gh pr merge <n> --auto --squash`). With CI still running and approval pending, watch the PR show "will be merged automatically when requirements are met." Approve + let CI go green, then confirm it merges itself.
9. Contrast with a failing PR: enable auto-merge on the failing-CI PR and confirm it does not merge until the check passes.

### Part D — Draft PRs & template
10. Improve the PR template (`.github/pull_request_template.md`) with a checklist, a "type of change" section, and a testing section. See [creating a pull request template](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/creating-a-pull-request-template-for-your-repository) for best practices. Open a new PR and confirm it pre-fills.
11. Demonstrate draft gating: open a PR as draft, confirm reviewers aren't auto-requested and auto-merge can't be armed, then `gh pr ready` and watch the gates engage.

### Part E — Actions-driven PR housekeeping
12. Auto-label by path. Add `.github/labeler.yml` and a workflow using [`actions/labeler@v6`](https://github.com/actions/labeler) (triggered on `pull_request_target`) so PRs touching `/src/` get `area: backend` and `/docs/` get `area: docs`. Open PRs to prove both.
13. Auto-assign reviewers via a workflow (or the CODEOWNERS path you already built) and add a step that comments a checklist when a PR opens.
14. Stale PR automation. Add [`actions/stale@v10`](https://github.com/actions/stale) on a schedule to mark PRs with no activity in N days `status: stale` and close them after a grace period. Trigger it manually with `workflow_dispatch` and confirm it labels/comments the right PRs.

### Part F — Organization ruleset
15. Create an org-level ruleset (Org Settings → Repository → Rulesets) named `ghec-ch05-org` targeting repos matching `ghec-ch05-*`, requiring a PR + the `build` check across all matching repos. See [managing rulesets for organizations](https://docs.github.com/en/organizations/managing-organization-settings/creating-rulesets-for-repositories-in-your-organization). Confirm it layers on top of the repo ruleset (the stricter wins) and verify via `gh api /orgs/<org>/rulesets`.

## Reference links
Official documentation links are embedded throughout the tasks above. Additional CLI references:
- `gh ruleset` / `gh pr merge` manual — https://cli.github.com/manual/gh_pr_merge
- `gh ruleset` — https://cli.github.com/manual/gh_ruleset
