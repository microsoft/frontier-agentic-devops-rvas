# Ch04 — GitHub Actions CI Fundamentals

> Deliver a GitHub Actions CI pipeline with triggers, a build matrix, caching, artifacts, environments, and a required merge gate.

| | |
|---|---|
| Track | Developer Flow |
| Difficulty | Intermediate *(per-track ramp)* |
| Duration | ~3 hr, single session |
| Minimum input | An org + an org-owner token. *(All activities are org-scoped — no enterprise owner required.)* |
| App | Provisioned starter repository (created by setup) |
| EMU compatible | yes |

## Prerequisites
- An organization you own (or org-owner rights) on GitHub Enterprise Cloud.
- A token with the scopes listed by `modules/ghec/resources/provisioning/scripts/setup.sh doctor ch04 --org <org>` (least-privilege; for this activity: `repo` + `workflow`).
- Local tooling: `gh >= 2.x`, `git`, `jq`.
- Cost note: Actions on GitHub-hosted runners consumes Actions minutes (free tier on public repos; metered on private). `modules/ghec/resources/provisioning/scripts/setup.sh doctor` warns. Keep matrices small.

## What you will deliver
- Write a workflow from scratch: `on` triggers, `jobs`, `steps`, and `runs-on`.
- Run tests across a build matrix (multiple Node versions / OSes).
- Speed up runs with dependency caching (`actions/cache` or `setup-node` cache).
- Produce and download artifacts (test reports / build output).
- Use job dependencies (`needs`) and conditional steps.
- Gate a `main` merge on a required status check so red CI blocks merges.
- Add an environment with a protection rule and read secrets/variables safely.

## Scenario
A GHEC customer's team merges first and finds out it's broken later — there's no automated gate. You'll give them continuous integration: every push and PR builds and tests the app across supported runtimes, caches dependencies so it's fast, publishes a test report you can download, and — critically — blocks merges to `main` when the build is red.

> [!IMPORTANT]
> Use an approved customer target first. If you have a candidate repository, use it everywhere this guide says `ghec-ch04-actions-ci-fundamentals` and skip Setup. Otherwise use the fallback seeded repo below for testing, then move the validated configuration to an approved customer target.
>
> Record the selected target, adoption owner, and next action.

## Sample test repository or environment
Skip if you brought your own repo.

```bash
# Bash
bash modules/ghec/resources/provisioning/scripts/setup.sh provision ch04 --org <org>
```
```powershell
# PowerShell
modules/ghec/resources/provisioning/scripts/setup.ps1 provision ch04 --org <org>
```

Setup creates these resources (all names use the `ghec-ch04-*` prefix, and teardown is prefix-guarded):
- A seeded repo `ghec-ch04-actions-ci-fundamentals` with a small Node app that has a passing test suite and at least one intentionally failing test behind a flag (so you can demonstrate red→green gating).
- A `package.json` with `test`, `build`, and `lint` scripts.
- A minimal starter workflow (`.github/workflows/ci.yml`) that just echoes — you will replace it with a real pipeline.
- A printed Next steps block telling you where to start.

## Tasks
> `ghec-ch04-actions-ci-fundamentals` is the fallback sample name; substitute your own artifact's name if you brought one.

### Part A — A real CI workflow
1. Replace the starter workflow. Author `.github/workflows/ci.yml` that triggers on `push` to any branch and on `pull_request` targeting `main`. Add a `build-test` job on `ubuntu-latest`.
2. Set up the toolchain step with `actions/setup-node@v6`, install (`npm ci`), then run `npm run lint`, `npm test`, and `npm run build` as separate steps so failures are pinpointable.
3. Confirm it runs. Push a branch, open a PR, and watch the run in the Actions tab (`gh run watch`).

### Part B — Matrix
4. Add a build matrix over `node-version: [20, 22, 24]` (and optionally `os: [ubuntu-latest, windows-latest]`). Use `strategy.matrix` and reference `${{ matrix.node-version }}` in `setup-node`.
5. Add `fail-fast: false` so one failing leg doesn't cancel the others, and observe all legs in the run summary.

### Part C — Caching
6. Enable dependency caching. Use `setup-node`'s built-in `cache: 'npm'` (or `actions/cache@v5` keyed on `hashFiles('/package-lock.json')`). Run twice and confirm the second run reports a cache hit and is faster.

### Part D — Artifacts
7. Produce a test report (e.g., write JUnit/JSON output to `reports/`), then upload it with `actions/upload-artifact@v7`. Download it from the run page and from the CLI (`gh run download`).

### Part E — Job graph & conditionals
8. Add a second job `package` that `needs: build-test` and only runs `if: github.ref == 'refs/heads/main'`. Have it build a distributable and upload it as an artifact.
9. Confirm ordering: `package` waits for `build-test`, and is skipped on feature branches.

### Part F — Environments, secrets & required checks
10. Create an environment named `staging` with a required reviewer protection rule. Add an environment variable and a secret; have the `package` job reference the `staging` environment and echo the variable (never the secret).
11. Make CI required. In branch protection / a ruleset on `main`, mark the `build-test` status check as required. Then flip the seeded failing test on, push, and confirm the PR is blocked from merging. Flip it back to green and confirm the block clears.

### Part G — Verify the effective Actions policy

12. Inspect the effective allowed-Actions policy, default `GITHUB_TOKEN`
    permissions, fork pull-request boundary, and artifact/log retention. Confirm
    the workflow remains compatible with those settings. If an enterprise policy
    is not visible to the org owner, note the limitation without blocking the CI
    activity.

## Reference links
- Understanding GitHub Actions — https://docs.github.com/en/actions/learn-github-actions/understanding-github-actions
- Workflow syntax for GitHub Actions — https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax
- Running variations of jobs in a workflow (matrix) — https://docs.github.com/en/actions/using-jobs/using-a-matrix-for-your-jobs
- Caching dependencies to speed up workflows — https://docs.github.com/en/actions/using-workflows/caching-dependencies-to-speed-up-workflows
- Storing and sharing data with workflow artifacts — https://docs.github.com/en/actions/using-workflows/storing-workflow-data-as-artifacts
- Using environments for deployment — https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment
- Troubleshooting required status checks — https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches#require-status-checks-before-merging
- `gh run` / `gh workflow` CLI manual — https://cli.github.com/manual/gh_run
