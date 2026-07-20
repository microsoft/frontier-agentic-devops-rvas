# Ch05 — Advanced PR Automation & Rulesets

> By the end of this activity you can run a hands-off, governed merge pipeline — repo & org **rulesets**, required status checks + required reviewers, **auto-merge**, **CODEOWNERS**, draft-PR gating, and Actions-driven PR automation (labeling, assignment, stale handling) — all from an org and an org-owner token.

| | |
|---|---|
| **Track** | Developer Flow |
| **Difficulty** | Advanced *(per-track ramp)* |
| **Duration** | ~5–6 hrs total, multi-session |
| **Minimum input** | An **org** + an **org-owner token**. *(All activities are org-scoped — no enterprise owner required.)* |
| **App** | Provisioned starter repository (created by setup) |
| **EMU compatible** | yes |

## Prerequisites
- An organization you own (or org-owner rights) on GitHub Enterprise Cloud.
- A token with the scopes listed by `modules/ghec/resources/provisioning/scripts/setup.sh doctor ch05 --org <org>` (least-privilege; for this activity: `repo` + `workflow` + `admin:org` for org rulesets).
- Local tooling: `gh >= 2.x`, `git`, `jq`.
- Recommended: you've done the *concepts* in Ch02 (PRs/CODEOWNERS) and Ch04 (Actions/required checks) — but this activity is **independent** and its setup creates everything it needs.

## Scenario objectives
By completing this activity you will:
- Define **repository rulesets** and an **organization ruleset** and understand how they layer with classic branch protection.
- Require **status checks**, **pull requests**, **linear history**, and **signed commits** via rules.
- Configure **CODEOWNERS** + **required reviewers** and **bypass actors** correctly.
- Enable and use **auto-merge** so a PR merges itself the moment all gates go green.
- Use **draft PRs** and a **PR template** to control when review starts.
- Automate PR housekeeping with **Actions**: auto-label by path, auto-assign reviewers, and mark/close **stale** PRs.

## Scenario
A GHEC platform team is drowning in manual merge babysitting: pinging reviewers, re-checking CI, merging PRs by hand at odd hours, and chasing stale branches. You'll replace all of that with policy and automation: rulesets that enforce quality at the org and repo level, auto-merge that ships the moment gates pass, and workflows that label, route, and tidy PRs without a human. The result is a merge pipeline that runs itself — safely.

> [!IMPORTANT]
> **Bring your own outcome (do this first)**
>
> This activity is most valuable when the result *outlives the delivery session*. Pick a real repository where PR automation would remove review toil and complete every task on **that** artifact. You leave with evidence, guardrails, or automation genuinely standing up on something you care about.
>
> - **Have a candidate?** Use it everywhere this guide says `ghec-ch05-advanced-pr-automation`. Skip the Setup step below entirely.
> - **No suitable one?** Use the fallback below: a seeded sample repo with PR automation hooks to build on.
>
> Tell your coach which path you took. "Bring your own" is the goal; the sample is the fallback.

## Setup (fallback sample)
Skip this if you brought your own repo. Otherwise run the provisioning entrypoint (Bash or PowerShell — both supported).

```bash
# Bash
bash modules/ghec/resources/provisioning/scripts/setup.sh provision ch05 --org <org>
```
```powershell
# PowerShell
modules/ghec/resources/provisioning/scripts/setup.ps1 provision ch05 --org <org>
```

**What setup creates** (all artifacts namespaced `ghec-ch05-*`, idempotent, prefix-guarded teardown):
- A seeded repo **`ghec-ch05-advanced-pr-automation`** with a small app, a working **CI workflow** that emits a `build` status check, a populated `main`, and a `src/` + `docs/` layout for CODEOWNERS paths.
- **Several open PRs** in different states (clean, failing-CI, draft, missing-owner-review) so every rule has something to act on.
- A **starter `.github/CODEOWNERS`** and a placeholder **`.github/pull_request_template.md`**.
- **No rulesets yet** — you create them.
- A printed **Next steps** block telling you where to start.


## Tasks
> Throughout, **`ghec-ch05-advanced-pr-automation` is the fallback sample**. If you brought your own artifact, substitute its name in every command and use your real history, teams, settings, or data as the material to work from.

### Part A — Repository ruleset (replace classic protection)
1. **Create a repository ruleset** targeting `main` (Settings → Rules → Rulesets → New branch ruleset). Name it `ghec-ch05-main`. Learn more about [repository rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/creating-rulesets-for-a-repository). Enable rules:
   - **Require a pull request before merging** (≥1 approval, **require review from Code Owners**, dismiss stale approvals)
   - **Require status checks to pass** → add the seeded `build` check
   - **Block force pushes**
   - **Require linear history**
2. **Set enforcement to Active.** Confirm via `gh api repos/<org>/ghec-ch05-advanced-pr-automation/rulesets`.
3. **Prove it bites:** attempt a direct push to `main` (`git push origin main`) and confirm it's rejected.

### Part B — CODEOWNERS + required reviewers + bypass
4. **Flesh out `CODEOWNERS`** mapping `/src/` and `/docs/` to teams/users that exist. Create the team(s) if needed. See [about code owners](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners).
5. **Configure a bypass actor.** Add an explicit **bypass** for org admins (or a named integration) in the ruleset, and document *why* limited bypass exists. Confirm a non-bypass user is fully gated.
6. **Open a PR touching `/src/`** and confirm the code owner is **auto-requested** and the PR cannot merge without their approval.

### Part C — Auto-merge
7. **Enable auto-merge** for the repo (Settings → General → Pull Requests → Allow auto-merge). Learn more: [automatically merging a pull request](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/incorporating-changes-from-a-pull-request/automatically-merging-a-pull-request).
8. **Turn on auto-merge for a clean PR** (`gh pr merge <n> --auto --squash`). With CI still running and approval pending, watch the PR show "**will be merged automatically when requirements are met**." Approve + let CI go green, then confirm it **merges itself**.
9. **Contrast with a failing PR:** enable auto-merge on the failing-CI PR and confirm it **does not** merge until the check passes.

### Part D — Draft PRs & template
10. **Improve the PR template** (`.github/pull_request_template.md`) with a checklist, a "type of change" section, and a testing section. See [creating a pull request template](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/creating-a-pull-request-template-for-your-repository) for best practices. Open a new PR and confirm it pre-fills.
11. **Demonstrate draft gating:** open a PR as **draft**, confirm reviewers aren't auto-requested and auto-merge can't be armed, then `gh pr ready` and watch the gates engage.

### Part E — Actions-driven PR housekeeping
12. **Auto-label by path.** Add `.github/labeler.yml` and a workflow using [`actions/labeler@v6`](https://github.com/actions/labeler) (triggered on `pull_request_target`) so PRs touching `/src/` get `area: backend` and `/docs/` get `area: docs`. Open PRs to prove both.
13. **Auto-assign reviewers** via a workflow (or the CODEOWNERS path you already built) and add a step that **comments** a checklist when a PR opens.
14. **Stale PR automation.** Add [`actions/stale@v10`](https://github.com/actions/stale) on a schedule to mark PRs with no activity in N days `status: stale` and close them after a grace period. Trigger it manually with `workflow_dispatch` and confirm it labels/comments the right PRs.

### Part F — Organization ruleset
15. **Create an org-level ruleset** (Org Settings → Repository → Rulesets) named `ghec-ch05-org` targeting repos matching `ghec-ch05-*`, requiring a PR + the `build` check across all matching repos. See [managing rulesets for organizations](https://docs.github.com/en/organizations/managing-organization-settings/creating-rulesets-for-repositories-in-your-organization). Confirm it **layers on top** of the repo ruleset (the stricter wins) and verify via `gh api /orgs/<org>/rulesets`.

## Validation / Definition of Done
You are done when ALL of the following are true:
- [ ] An **active repository ruleset** on `main` requires PR + ≥1 approval + **code-owner review** + the **`build` status check** + linear history, and **blocks direct pushes** (demonstrated).
- [ ] **CODEOWNERS** is valid; a `/src/` PR **auto-requests** the owner; a **bypass actor** is configured and documented.
- [ ] **Auto-merge** is enabled and a clean PR **merged itself** once gates passed; a failing PR did **not**.
- [ ] A **PR template** pre-fills new PRs; a **draft** PR demonstrably blocks auto-merge/reviewers until marked ready.
- [ ] **Auto-labeling** assigns `area:` labels by path; an **open-PR comment** workflow fires; a **stale** workflow labels/closes inactive PRs.
- [ ] An **organization ruleset** targeting `ghec-ch05-*` is active and layers with the repo ruleset.
- [ ] Real-outcome check — if you brought your own repo, PR automation now removes a real review chore; if you used the sample, you can name the team repo where you will install it next.
- [ ] Coach conversation — which repetitive PR task on your current team (auto-labeling, reviewer assignment, size checks, changelog enforcement) costs the most human time per week, and what could a composite action or reusable workflow replace? Talk it through with your coach and connect it to a real project, task, or workflow you own.

> Coaches verify these via the automated hints in `COACH.md`.

## Stretch goals
- Add **required signed commits** to the ruleset and demonstrate a rejected unsigned push, then a passing signed one.
- Add a **merge queue** for `main` and route auto-merge through it.
- Write a small **GitHub Script** (`actions/github-script`) step that posts a PR size label (`size: S/M/L`) computed from the diff.

## Reference links
Official documentation links are embedded throughout the tasks above. Additional CLI references:
- `gh ruleset` / `gh pr merge` manual — https://cli.github.com/manual/gh_pr_merge
- `gh ruleset` — https://cli.github.com/manual/gh_ruleset
