Track: Production Patterns (Advanced 🟣)
Estimated time: 75 minutes
Tier: Bonus

---

## Background

The Daily Documentation Updater runs on a cron schedule. It compares selected documentation with the codebase and opens pull requests for content that appears out of date.

Source: [`githubnext/agentics/workflows/daily-doc-updater.md`](https://github.com/githubnext/agentics/blob/main/workflows/daily-doc-updater.md)

## Behavior

- Triggers on a daily `schedule: cron`
- Scans a configured docs directory (e.g., `docs/`, `README.md`)
- Identifies content that contradicts or no longer matches the codebase
- Opens PRs with targeted, reviewable corrections

> [!TIP]
> [Bring your own repo](../../setup.md#bring-your-own-repo): point the workflow at a repo you own where `README.md`, `docs/`, API docs, or runbooks drift from the code.

## Steps

1. Install and verify `gh aw` with the [GHAW setup guide](../../setup.md).

2. Pull the production workflow:
   ```bash
   gh aw add-wizard https://github.com/githubnext/agentics/blob/main/workflows/daily-doc-updater.md
   ```

3. Read the [scheduled workflow](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#schedule) cron expression in the frontmatter. Confirm when `schedule: - cron: "0 9 * * *"` runs in UTC.

4. Customise the docs scope and review depth for your repository.

5. Compile:
   ```bash
   gh aw compile daily-doc-updater
   ```

6. Dry-run to see what it would propose:
   ```bash
   gh aw run daily-doc-updater --dry-run
   ```

7. Commit both workflow and `.lock.yml`. Add a stale doc to trigger your first real PR.

## Adapt it

- Change the target path in the prompt body: point at `docs/`, `README.md`, or a subdirectory specific to your project
- Adjust the cron schedule. Use `0 9 * * 1-5` for weekdays or `0 9 * * 1` for Monday morning.
- Tune the review depth: "only check API endpoint docs" vs "review all docs for accuracy"
- Add a PR template or label to the `create-pull-request` output so doc-update PRs are easy to filter

---

<details>
<summary>💡 Hints</summary>

"How do I trigger a scheduled workflow manually for testing?"
→ Add `workflow_dispatch: {}` to your `on:` block. Then use GitHub's [manual workflow run](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/manually-run-a-workflow) flow from the Actions tab.

"The PR diff is too large / changes too many files"
→ Constrain the body: _"Review only `docs/api.md`. Open a single PR per file. Each PR should change no more than 10 lines."_ This keeps the proposed review scope narrow.

"How do I make sure it doesn't overwrite things it shouldn't?"
→ `safe-outputs: create-pull-request` still requires a human to merge. The agent can propose; humans approve.

"The agent keeps proposing the same change every day"
→ Merge the correction so the drift disappears. Also add this check to the prompt: _"Do not open a PR if an identical open PR already exists."_

</details>
