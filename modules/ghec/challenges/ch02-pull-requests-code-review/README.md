# Ch02 — Branches, Pull Requests & Code Review

> By the end of this activity you can drive a professional pull-request lifecycle — feature branches, reviews, `CODEOWNERS`, required reviewers, merge-conflict resolution, and the three merge strategies — entirely from an org-owner token.

| | |
|---|---|
| **Track** | Developer Flow |
| **Difficulty** | Foundational *(per-track ramp)* |
| **Duration** | ~3–4 hrs total, multi-session |
| **Minimum input** | An **org** + an **org-owner token**. *(All activities are org-scoped — no enterprise owner required.)* |
| **App** | Provisioned starter repository (created by setup) |
| **EMU compatible** | yes |

## Prerequisites
- An organization you own (or org-owner rights) on GitHub Enterprise Cloud.
- A token with the scopes listed by `modules/ghec/resources/provisioning/scripts/setup.sh doctor ch02 --org <org>` (least-privilege; for this activity: `repo` + `read:org`).
- Local tooling: `gh >= 2.x`, `git`, `jq` (run `modules/ghec/resources/provisioning/scripts/setup.sh doctor` to verify).
- A second account or teammate helps demonstrate *real* review approvals, but the activity is completable solo (the coach guide explains the self-review caveat).

## Scenario objectives
By completing this activity you will:
- Use a clean **branch-per-change** workflow and open **pull requests** from the CLI and UI.
- Run a **code review**: line comments, review threads, suggested changes, approve / request-changes.
- Define ownership with a **`CODEOWNERS`** file and require owner review through branch protection.
- Deliberately create and **resolve a merge conflict**.
- Compare the three merge strategies — **merge commit**, **squash**, **rebase** — and pick the right one.
- Use **draft PRs**, linked issues (`Closes #n`), and PR templates to streamline collaboration.

## Scenario
A GHEC customer's team keeps pushing straight to `main`, breaking each other's work, and shipping un-reviewed changes. You've been asked to introduce a real review culture: every change goes through a PR, the right people are required to review the code they own, and merges are clean and traceable. You'll build that workflow on a seeded service repo and prove it end-to-end.

> [!IMPORTANT]
> **Bring your own outcome (do this first)**
>
> This activity is most valuable when the result *outlives the delivery session*. Pick a real repository with a pull-request review flow you can improve and complete every task on **that** artifact. You leave with evidence, guardrails, or automation genuinely standing up on something you care about.
>
> - **Have a candidate?** Use it everywhere this guide says `ghec-ch02-pull-requests-code-review`. Skip the Setup step below entirely.
> - **No suitable one?** Use the fallback below: a seeded sample repo with PRs and review settings to configure.
>
> Tell your coach which path you took. "Bring your own" is the goal; the sample is the fallback.

## Setup (fallback sample)
Skip this if you brought your own repo. Otherwise run the provisioning entrypoint (Bash or PowerShell — both supported).

```bash
# Bash
bash modules/ghec/resources/provisioning/scripts/setup.sh provision ch02 --org <org>
```
```powershell
# PowerShell
modules/ghec/resources/provisioning/scripts/setup.ps1 provision ch02 --org <org>
```

**What setup creates** (all artifacts namespaced `ghec-ch02-*`, idempotent, prefix-guarded teardown):
- A seeded repo **`ghec-ch02-pull-requests-code-review`** containing a small multi-file app (e.g., `src/`, `docs/`, `.github/`) and a populated `main` branch.
- **Two pre-existing feature branches** with **open pull requests** that need review (one clean, one that will conflict).
- A **`.github/pull_request_template.md`** placeholder you will improve.
- A `main` branch with **no protection yet** (you add it) and a starter directory layout that maps cleanly to `CODEOWNERS` paths.
- A printed **Next steps** block telling you where to start.


## Tasks
> Throughout, **`ghec-ch02-pull-requests-code-review` is the fallback sample**. If you brought your own artifact, substitute its name in every command and use your real history, teams, settings, or data as the material to work from.

### Part A — Branch & open a PR
1. **Clone and branch.** `gh repo clone <org>/ghec-ch02-pull-requests-code-review`, then create `feature/add-healthcheck` and add a small, real change (e.g., a `/health` endpoint or a new function + doc line).
2. **Open a PR from the CLI.** `gh pr create --base main --head feature/add-healthcheck --fill`. In the body, link an issue with `Closes #<n>` (create a tracking issue first if none exists).
3. **Open it as a draft first**, then mark it **Ready for review** (`gh pr ready`). Note how draft PRs cannot be merged and don't request reviewers automatically.

### Part B — Code review mechanics
4. **Review the seeded clean PR.** Add at least **two line comments**, one **multi-line review thread**, and one **suggested change** (the `\`\`\`suggestion` block). Submit the review as **Comment**, then iterate.
5. **Request changes** on something real, have the author (you or a teammate) push a fix commit, and confirm the **review thread resolves**.
6. **Approve** the PR once it's clean. (If solo: the coach guide covers the self-approval caveat — branch protection blocks self-approval, so you'll demonstrate the *required-review* gate rather than approving your own PR.)

### Part C — CODEOWNERS + branch protection
7. **Author a `CODEOWNERS`** file (`.github/CODEOWNERS`) mapping paths to owners, e.g.:
   ```
   /src/        @<org>/backend-team
   /docs/       @<your-username>
   *            @<your-username>
   ```
   Create the referenced team(s) if needed (`gh api orgs/<org>/teams -f name='backend-team'`).
8. **Protect `main`.** Add a **branch protection rule** (or a repo **ruleset**) requiring: a pull request before merging, **at least 1 approving review**, and **review from Code Owners**. Disallow direct pushes to `main`.
9. **Prove ownership routing.** Open a PR that touches `/src/` and confirm GitHub **auto-requests the code owner**.

### Part D — Merge conflict
10. **Trigger the conflict.** The second seeded branch edits the same lines as a change you'll make on `main` (via another PR). Merge your `main` change first, then attempt to merge the seeded branch — GitHub reports a conflict.
11. **Resolve it** locally: `git fetch`, `git rebase origin/main` (or merge), fix the conflict markers, push, and watch the PR go mergeable.

### Part E — Merge strategies
12. **Configure allowed merges.** In repo settings, enable all three: **merge commit**, **squash**, **rebase**. Then merge three different PRs using a *different* strategy each, and inspect the resulting history with `git log --oneline --graph`.
13. **Write a one-paragraph note** in the repo (`docs/merge-strategy.md`) stating which strategy the team should default to and why (hint: squash for clean linear history is a common GHEC recommendation).

## Validation / Definition of Done
You are done when ALL of the following are true:
- [ ] At least **three pull requests** were opened against `main` (CLI or UI), one started as a **draft**.
- [ ] A review contains **line comments, a thread, and a `suggestion` block**; at least one PR shows a **request-changes → fix → resolve** cycle.
- [ ] A valid **`.github/CODEOWNERS`** exists and a PR touching an owned path **auto-requested the owner**.
- [ ] **`main` is protected**: PR required, ≥1 approval, **require Code Owner review**, no direct pushes.
- [ ] A **merge conflict was resolved** and that branch merged cleanly afterward.
- [ ] **All three merge strategies are enabled** and each was used at least once (verifiable from commit history).
- [ ] `docs/merge-strategy.md` documents the chosen default.
- [ ] Real-outcome check — if you brought your own repo, its PR template, review rules, and branch protections now improve a live review flow; if you used the sample, you can name the real repo you will harden next.
- [ ] Coach conversation — think about the last pull request that sat open too long or had a painful review cycle on your team: which of the branch protection rules, required reviewers, or PR templates you just configured would have shortened it, and what's still missing? Talk it through with your coach and connect it to a real project, task, or workflow you own.

> Coaches verify these via the automated hints in `COACH.md`.

## Stretch goals
- Add a **PR template** with a checklist and a "screenshots" section; confirm new PRs pre-fill it.
- Add **auto-request** of a whole team via `CODEOWNERS` and require **2** approvals for `/src/`.
- Enable **"require linear history"** on `main` and observe how it forbids merge commits — reconcile that with your strategy choice.

## Reference links
- About pull requests — https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/about-pull-requests
- About code owners — https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners
- About protected branches — https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches
- About merge methods — https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/configuring-pull-request-merges/about-merge-methods-on-github
- Reviewing changes in pull requests — https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/reviewing-changes-in-pull-requests/about-pull-request-reviews
- Resolving a merge conflict — https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/addressing-merge-conflicts/resolving-a-merge-conflict-using-the-command-line
- `gh pr` CLI manual — https://cli.github.com/manual/gh_pr
