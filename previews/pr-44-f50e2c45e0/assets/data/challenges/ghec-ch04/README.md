# Ch04: GitHub Actions CI fundamentals

**Session outcome:** The customer repository runs CI on pull requests. You verify that a failing test blocks merge, then fix it and obtain independent review.

## Prerequisites
- Write access to the Ch02 repository and an administrator to require its CI check.
- A token with the scopes listed by `modules/ghec/resources/provisioning/scripts/setup.sh doctor ch04 --org <org>` (least-privilege; for this activity: `repo` + `workflow`).
- Local tooling: `gh >= 2.x`, `git`, `jq`.
- Cost note: Actions on GitHub-hosted runners consumes Actions minutes (free tier on public repos; metered on private). `modules/ghec/resources/provisioning/scripts/setup.sh doctor` warns. Keep matrices small.

## What you will deliver
- Write a workflow from scratch: `on` triggers, `jobs`, `steps`, and `runs-on`.
- Run the repository's existing tests on one supported runtime.
- Produce and download a test report.
- Gate a `main` merge on a required status check so red CI blocks merges.
- Leave deployment environments to Ch39.

## Scenario
A team discovers failures after merging. Run its existing tests on each PR, save a report, and require the check before merge. Start with one supported runtime.

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
- A minimal starter workflow (`.github/workflows/ci.yml`) that only echoes. You will replace it with a CI pipeline.
- A printed Next steps block telling you where to start.

## Tasks
> `ghec-ch04-actions-ci-fundamentals` is the fallback sample name; substitute your own artifact's name if you brought one.

### Part A: A CI workflow
1. Reuse the Ch02 repository. Write `.github/workflows/ci.yml` with `pull_request` and default-branch `push` triggers. Add a `build-test` job on `ubuntu-latest`. Set `permissions: contents: read` and use an approved version of `actions/checkout`.
2. Set up the repository's supported runtime. For the Node sample, use `actions/setup-node@v6`, install with `npm ci`, then run `npm run lint`, `npm test`, and `npm run build`. Use the existing customer commands when different.
3. Confirm it runs. Push a branch, open a PR, and watch the run in the Actions tab (`gh run watch`).

### Part B: Report and require the result
4. Produce a report with the existing test runner and upload it using `actions/upload-artifact@v7`. Download it with `gh run download` and check it describes this run.
5. After the check has run, require its exact name in the default-branch ruleset. Keep Ch02's independent approval requirement and give contributors no bypass permission.
6. Break one test on a branch and open a PR. Verify that a contributor without bypass permission cannot merge it. Fix the test and obtain human approval before merging. Save both run URLs and the PR.
7. Add caching or a second supported runtime only if the application needs it. Ch39 covers deployment gates.

### Verify the effective Actions policy

8. Inspect the effective allowed-Actions policy, default `GITHUB_TOKEN`
    permissions, fork pull-request boundary, and artifact/log retention. Confirm
    the workflow remains compatible with those settings. If an enterprise policy
    is not visible to the org owner, note the limitation without blocking the CI
    activity.

## Reference links
- [Understanding GitHub Actions](https://docs.github.com/en/actions/learn-github-actions/understanding-github-actions)
- [Workflow syntax for GitHub Actions](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax)
- [Running variations of jobs in a workflow (matrix)](https://docs.github.com/en/actions/using-jobs/using-a-matrix-for-your-jobs)
- [Caching dependencies to speed up workflows](https://docs.github.com/en/actions/using-workflows/caching-dependencies-to-speed-up-workflows)
- [Storing and sharing data with workflow artifacts](https://docs.github.com/en/actions/using-workflows/storing-workflow-data-as-artifacts)
- [Using environments for deployment](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment)
- [Troubleshooting required status checks](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches#require-status-checks-before-merging)
- [`gh run` / `gh workflow` CLI manual](https://cli.github.com/manual/gh_run)
