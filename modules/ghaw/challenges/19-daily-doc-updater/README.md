**Track:** Production Patterns (Advanced 🟣)
**Estimated time:** 30 minutes
**Tier:** Bonus

---

## Background

Code evolves. Docs don't — not unless someone makes them a first-class concern. The Daily Documentation Updater runs on a cron schedule, reviews your docs directory against the actual codebase, and opens PRs for content that has drifted out of sync.

The production version in `githubnext/agentics` achieved roughly a **96% merge rate** (57 of 59 proposed PRs merged, as a point-in-time sample). When the agent proposes a doc fix, maintainers almost always agree with it.

Source: [`githubnext/agentics/workflows/daily-doc-updater.md`](https://github.com/githubnext/agentics/blob/main/workflows/daily-doc-updater.md)

## What It Does

- Triggers on a daily `schedule: cron`
- Scans a configured docs directory (e.g., `docs/`, `README.md`)
- Identifies content that contradicts or no longer matches the codebase
- Opens PRs with targeted, reviewable corrections

> [!IMPORTANT]
> **Bring your own repo (do this first)**
>
> This challenge is most valuable when the updater reviews docs that can keep serving your users after the session. Pick a repository in an org you control where `README.md`, `docs/`, API docs, or runbooks drift as the code changes.
>
> - **Have a candidate repo?** Use it everywhere this guide references the sample repo, and point the workflow at that repo's real docs and code paths so proposed PRs fix production documentation drift.
> - **No suitable repo yet?** Use the provided sample repo from setup as the safe practice target.
>
> Tell your coach which path you took — bringing your own is the goal; the sample repo is the fallback.

## What You'll Do

1. **Install [`gh aw`](https://github.com/github/gh-aw)** (if not already done):
   ```bash
   curl -sL https://raw.githubusercontent.com/github/gh-aw/main/install-gh-aw.sh | bash
   ```

2. **Pull the production workflow**:
   ```bash
   gh aw add-wizard https://github.com/githubnext/agentics/blob/main/workflows/daily-doc-updater.md
   ```

3. **Read the [scheduled workflow](https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows#schedule) cron expression** in the frontmatter — understand how `schedule: - cron: "0 9 * * *"` works and what time it fires in UTC.

4. **Customise** the docs scope and review depth for your repository.

5. **Compile**:
   ```bash
   gh aw compile daily-doc-updater
   ```

6. **Dry-run** to see what it would propose:
   ```bash
   gh aw run daily-doc-updater --dry-run
   ```

7. Commit both workflow and `.lock.yml`. Add a stale doc to trigger your first real PR.

## Customize It

- Change the target path in the prompt body: point at `docs/`, `README.md`, or a subdirectory specific to your project
- Adjust the cron schedule — `0 9 * * 1-5` for weekdays only, or `0 9 * * 1` for Monday morning only
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
- [ ] Coach conversation — which docs in your projects silently rot as the code evolves, and what would it take for you to trust an agent's documentation PRs enough to review and merge them regularly? Talk it through with your coach and connect it to a real project, task, or workflow you own.

---

<details>
<summary>💡 Hints</summary>

**"How do I trigger a scheduled workflow manually for testing?"**
→ Add `workflow_dispatch: {}` to your `on:` block. Then use GitHub's [manual workflow run](https://docs.github.com/en/actions/using-workflows/manually-running-a-workflow) flow from the Actions tab.

**"The PR diff is too large / changes too many files"**
→ Constrain the body: _"Review only `docs/api.md`. Open a single PR per file. Each PR should change no more than 10 lines."_ Smaller PRs get merged faster.

**"How do I make sure it doesn't overwrite things it shouldn't?"**
→ `safe-outputs: create-pull-request` still requires a human to merge. The agent can propose; humans approve.

**"What cron syntax do I use?"**
→ GitHub Actions uses UTC. `0 9 * * *` = 9am UTC daily. Use https://crontab.guru to validate your expression.

**"The agent keeps proposing the same change every day"**
→ The PR merging is the fix. Once merged, the drift disappears. Add a check in the prompt: _"Do not open a PR if an identical open PR already exists."_

</details>

