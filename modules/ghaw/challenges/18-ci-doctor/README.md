Track: Production Patterns (Advanced 🟣)
Estimated time: 90 minutes
Tier: Core

---

## Background

CI Doctor runs after a failed workflow. It fetches the logs and opens a diagnostic issue with a likely cause and suggested next step.

Source: [`githubnext/agentics/workflows/ci-doctor.md`](https://github.com/githubnext/agentics/blob/main/workflows/ci-doctor.md)

## Behavior

- Triggers on `on: workflow_run` when a target CI workflow completes with `conclusion: failure`
- Fetches the run logs from the GitHub API
- Reads the logs to identify compile errors, test failures, flaky tests, and other failure patterns
- Opens a `create-issue` with the likely root cause and a suggested fix

> [!TIP]
> [Bring your own repo](../../setup.md#bring-your-own-repo): watch the real CI workflow names, branches, and failure patterns of a repo you own.

## Steps

1. Install and verify `gh aw` with the [GHAW setup guide](../../setup.md).

2. Pull the production workflow:
   ```bash
   gh aw add-wizard https://github.com/githubnext/agentics/blob/main/workflows/ci-doctor.md
   ```

3. Inspect the frontmatter. Note how the [`workflow_run` event](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#workflow_run) names watched workflows and combines `types: [completed]` with a `conclusion` check.

4. Change `workflows:` to list the exact CI workflow names you want to watch, such as `[CI, tests, build]`.

5. Compile:
   ```bash
   gh aw compile ci-doctor
   ```

6. Trigger a test failure (break a test intentionally in a branch, push, let CI fail) and inspect the [workflow run logs](https://docs.github.com/en/actions/how-tos/monitor-workflows/use-workflow-run-logs) as the Doctor fires.

7. Commit both the workflow and its `.lock.yml`.

## Adapt it

- Change the `workflows:` list to name exactly the CI workflows you want to monitor (use the exact workflow name from your `.github/workflows/` files)
- Tune the diagnostic prompt: add repo-specific context like "this repo uses Node 20" or "tests run with vitest"
- Adjust the issue template by adding labels, assignees, or project board routing to `create-issue`
- Set `branches: [main]` if you only want to watch failures on main (not every branch)

---

<details>
<summary>💡 Hints</summary>

"How does workflow_run know which run failed?"
→ `github.event.workflow_run.conclusion` is `"failure"` on failures. Include a check in your body: _"Only investigate if the triggering workflow concluded with failure."_

"How do I fetch the logs?"
→ The `tools: github: toolsets: [actions]` toolset gives the agent access to run logs. Alternatively, include explicit log fetching instructions pointing to `github.event.workflow_run.logs_url`.

"My CI doesn't fail often — how do I test this?"
→ Add a temporary step to a test workflow: `run: exit 1`. Push to a branch, let it fail, then revert.

"The issue body is too long / too noisy"
→ Constrain the prompt: _"Keep the issue body to 3 sections: 1) What failed, 2) Likely cause, 3) Suggested fix. Max 200 words."_

</details>
