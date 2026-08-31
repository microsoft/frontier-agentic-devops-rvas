Track: Production Patterns (Advanced 🟣)
Estimated time: 30 minutes
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

> [!IMPORTANT]
> Bring your own repo (do this first)
>
> Use a repository in an organization you control. Choose one where `README.md`, `docs/`, API docs, or runbooks tend to drift from the code.
>
> - Have a candidate repo? Use it everywhere this guide references the sample repo, and point the workflow at that repo's real docs and code paths so proposed PRs fix production documentation drift.
> - No suitable repo yet? Use the provided sample repo from setup as the safe practice target.
>
> Tell the facilitator which repository and documentation paths you chose.

## Steps

1. Install [`gh aw`](https://github.com/github/gh-aw) (if not already done):
   ```bash
   curl -sL https://raw.githubusercontent.com/github/gh-aw/main/install-gh-aw.sh | bash
   ```

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

## Success Criteria

- [ ] `.github/workflows/daily-doc-updater.md` exists with valid gh-aw frontmatter
- [ ] Trigger is `schedule: cron` (valid cron expression)
- [ ] Target doc directory is configured to something real in your repo
- [ ] `safe-outputs: create-pull-request` is declared
- [ ] `.github/workflows/daily-doc-updater.lock.yml` compiles without errors
- [ ] Dry-run produces at least one proposed doc change
- [ ] A manually triggered run opens a real PR with a focused, accurate diff
- [ ] Using a project, task, or workflow you own, identify docs that drift from the code and define what an agent PR must show before you would merge it.

---

<details>
<summary>💡 Hints</summary>

"How do I trigger a scheduled workflow manually for testing?"
→ Add `workflow_dispatch: {}` to your `on:` block. Then use GitHub's [manual workflow run](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/manually-run-a-workflow) flow from the Actions tab.

"The PR diff is too large / changes too many files"
→ Constrain the body: _"Review only `docs/api.md`. Open a single PR per file. Each PR should change no more than 10 lines."_ This keeps the proposed review scope narrow.

"How do I make sure it doesn't overwrite things it shouldn't?"
→ `safe-outputs: create-pull-request` still requires a human to merge. The agent can propose; humans approve.

"What cron syntax do I use?"
→ GitHub Actions uses UTC. `0 9 * * *` = 9am UTC daily. Use https://crontab.guru to validate your expression.

"The agent keeps proposing the same change every day"
→ Merge the correction so the drift disappears. Also add this check to the prompt: _"Do not open a PR if an identical open PR already exists."_

</details>
