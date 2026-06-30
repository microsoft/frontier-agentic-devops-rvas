# Ch04 — GitHub Actions CI Fundamentals

> By the end of this challenge you can build a real CI pipeline with GitHub Actions — triggers, jobs, a build matrix, dependency caching, artifacts, environments, and a required status check that gates merges — using an org and an org-owner token.

| | |
|---|---|
| **Track** | Developer Flow |
| **Difficulty** | Intermediate *(per-track ramp)* |
| **Duration** | ~4–5 hrs total, multi-session |
| **Minimum input** | An **org** + an **org-owner token**. *(All challenges are org-scoped — no enterprise owner required.)* |
| **App** | Provisioned starter repository (created by setup) |
| **EMU compatible** | yes |

## Prerequisites
- An organization you own (or org-owner rights) on GitHub Enterprise Cloud.
- A token with the scopes listed by `modules/ghec/resources/provisioning/scripts/setup.sh doctor ch04 --org <org>` (least-privilege; for this challenge: `repo` + `workflow`).
- Local tooling: `gh >= 2.x`, `git`, `jq`.
- **Cost note:** Actions on GitHub-hosted runners consumes **Actions minutes** (free tier on public repos; metered on private). `modules/ghec/resources/provisioning/scripts/setup.sh doctor` warns. Keep matrices small.

## Scenario objectives
By completing this challenge you will:
- Write a **workflow** from scratch: `on` triggers, `jobs`, `steps`, and `runs-on`.
- Run tests across a **build matrix** (multiple Node versions / OSes).
- Speed up runs with **dependency caching** (`actions/cache` or `setup-node` cache).
- Produce and download **artifacts** (test reports / build output).
- Use **job dependencies** (`needs`) and **conditional** steps.
- Gate a `main` merge on a **required status check** so red CI blocks merges.
- Add an **environment** with a protection rule and read **secrets/variables** safely.

## Scenario
A GHEC customer's team merges first and finds out it's broken later — there's no automated gate. You'll give them continuous integration: every push and PR builds and tests the app across supported runtimes, caches dependencies so it's fast, publishes a test report you can download, and — critically — blocks merges to `main` when the build is red.

## Bring your own outcome (do this first)
This challenge is most valuable when the result *outlives the hackathon*. Pick a real repository with a build, test, or validation step that should run automatically and complete every task on **that** artifact. You leave with evidence, guardrails, or automation genuinely standing up on something you care about.

- **Have a candidate?** Use it everywhere this guide says `wth-ch04-actions-ci-fundamentals`. Skip the Setup step below entirely.
- **No suitable one?** Use the fallback below: a seeded sample repo with code ready for a first CI workflow.

> Tell your coach which path you took. "Bring your own" is the goal; the sample is the fallback.

## Setup (fallback sample)
Skip this if you brought your own repo. Otherwise run the provisioning entrypoint (Bash or PowerShell — both supported).

```bash
# Bash
bash modules/ghec/resources/provisioning/scripts/setup.sh provision ch04 --org <org>
```
```powershell
# PowerShell
modules/ghec/resources/provisioning/scripts/setup.ps1 provision ch04 --org <org>
```

**What setup creates** (all artifacts namespaced `wth-ch04-*`, idempotent, prefix-guarded teardown):
- A seeded repo **`wth-ch04-actions-ci-fundamentals`** with a small **Node** app that has a **passing test suite** and at least one **intentionally failing test behind a flag** (so you can demonstrate red→green gating).
- A `package.json` with `test`, `build`, and `lint` scripts.
- A **minimal starter workflow** (`.github/workflows/ci.yml`) that just echoes — you will replace it with a real pipeline.
- A printed **Next steps** block telling you where to start.


## Tasks
> Throughout, **`wth-ch04-actions-ci-fundamentals` is the fallback sample**. If you brought your own artifact, substitute its name in every command and use your real history, teams, settings, or data as the material to work from.

### Part A — A real CI workflow
1. **Replace the starter workflow.** Author `.github/workflows/ci.yml` that triggers on `push` to any branch and on `pull_request` targeting `main`. Add a `build-test` job on `ubuntu-latest`.
2. **Set up the toolchain step** with `actions/setup-node@v6`, install (`npm ci`), then run `npm run lint`, `npm test`, and `npm run build` as separate steps so failures are pinpointable.
3. **Confirm it runs.** Push a branch, open a PR, and watch the run in the **Actions** tab (`gh run watch`).

### Part B — Matrix
4. **Add a build matrix** over `node-version: [20, 22, 24]` (and optionally `os: [ubuntu-latest, windows-latest]`). Use `strategy.matrix` and reference `${{ matrix.node-version }}` in `setup-node`.
5. **Add `fail-fast: false`** so one failing leg doesn't cancel the others, and observe all legs in the run summary.

### Part C — Caching
6. **Enable dependency caching.** Use `setup-node`'s built-in `cache: 'npm'` (or `actions/cache@v5` keyed on `hashFiles('**/package-lock.json')`). Run twice and confirm the second run reports a **cache hit** and is faster.

### Part D — Artifacts
7. **Produce a test report** (e.g., write JUnit/JSON output to `reports/`), then upload it with `actions/upload-artifact@v7`. Download it from the run page and from the CLI (`gh run download`).

### Part E — Job graph & conditionals
8. **Add a second job** `package` that `needs: build-test` and only runs `if: github.ref == 'refs/heads/main'`. Have it build a distributable and upload it as an artifact.
9. **Confirm ordering:** `package` waits for `build-test`, and is skipped on feature branches.

### Part F — Environments, secrets & required checks
10. **Create an environment** named `staging` with a **required reviewer** protection rule. Add an environment **variable** and a **secret**; have the `package` job reference the `staging` environment and echo the variable (never the secret).
11. **Make CI required.** In branch protection / a ruleset on `main`, mark the **`build-test` status check as required**. Then flip the seeded failing test on, push, and confirm the PR is **blocked** from merging. Flip it back to green and confirm the block clears.

## Validation / Definition of Done
You are done when ALL of the following are true:
- [ ] `.github/workflows/ci.yml` triggers on **push and pull_request** and runs lint + test + build as distinct steps.
- [ ] A **matrix** runs across ≥3 Node versions with `fail-fast: false`.
- [ ] **Caching** is enabled and a run shows a **cache hit** on the second execution.
- [ ] A **test-report artifact** is uploaded and downloadable (UI + `gh run download`).
- [ ] A second job uses **`needs`** and a **conditional** so it only runs on `main`.
- [ ] An **environment** `staging` exists with a protection rule and a variable + secret wired into a job.
- [ ] The **`build-test` check is required** on `main`; a red run **blocks merge**, a green run unblocks it.
- [ ] Real-outcome check — if you brought your own repo, CI now runs against a real build or test path; if you used the sample, you can name the workflow you will automate next.
- [ ] Coach conversation — pick one test suite or build process from your actual work that runs manually or inconsistently: what would an always-on, branch-triggered Actions workflow catch in the next two weeks that human discipline alone has missed? Talk it through with your coach and connect it to a real project, task, or workflow you own.

> Coaches verify these via the automated hints in `COACH.md`.

## Stretch goals
- Extract the test job into a **reusable workflow** (`workflow_call`) and call it from `ci.yml`.
- Add a **concurrency** group so superseded runs on the same branch cancel automatically.
- Add **OIDC**-based cloud auth (no long-lived secret) to a deploy job (document, even if the cloud side is mocked).

## Reference links
- Understanding GitHub Actions — https://docs.github.com/en/actions/learn-github-actions/understanding-github-actions
- Workflow syntax for GitHub Actions — https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions
- Running variations of jobs in a workflow (matrix) — https://docs.github.com/en/actions/using-jobs/using-a-matrix-for-your-jobs
- Caching dependencies to speed up workflows — https://docs.github.com/en/actions/using-workflows/caching-dependencies-to-speed-up-workflows
- Storing and sharing data with workflow artifacts — https://docs.github.com/en/actions/using-workflows/storing-workflow-data-as-artifacts
- Using environments for deployment — https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment
- Troubleshooting required status checks — https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches#require-status-checks-before-merging
- `gh run` / `gh workflow` CLI manual — https://cli.github.com/manual/gh_run
