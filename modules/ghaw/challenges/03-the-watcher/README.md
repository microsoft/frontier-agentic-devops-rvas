# Activity 1-03: The Watcher

Track: Track 1 — Hello, Agent  
Difficulty: 🟢 Beginner  
Estimated time: 30 minutes  
Prerequisites: Activity 00 — Setup & Hello, Agent, Activity 1-01 — Morning Briefing

---

## Build

A workflow triggered by `on: push`. It detects changes in a chosen directory, such as `docs/` or `src/config/`, and comments on the commit with a summary.

`on: push` gives the agent the triggering commit, changed files, and diff. Use it for checks that must react to code as it lands, such as config validation or changelog checks.

---

## What you'll practice

1. Use `on: push:` event triggers
2. Filter triggers with `on: push: paths:`
3. Read commit metadata (changed files, commit message, author)
4. Create a commit comment with `safe-outputs: add-comment:`
5. Test event-driven workflows with local Git operations

---

> [!TIP]
> [Bring your own repo](../../setup.md#bring-your-own-repo): point `the-watcher.md` at a repo you own and watch a real path such as `docs/**`, config, schemas, tests, or release files. No candidate repo yet? Use the setup sample.

---

## Tips & Hints

- Path filters: Use `on: push: paths: ['docs/**']` to only run when files matching that glob are touched. Adjust the path to a meaningful directory in your repo.
- Commit metadata: The agent has access to the commit message, changed files, and author. Use that in your instructions.
- Test locally first: You can test by making a commit to the watched directory, then pushing and watching the Actions tab.
- Safe-outputs: add-comment: This posts a comment on the commit itself (not an issue). Useful for inline feedback.
- Workflow_dispatch for testing: Add it so you can test without actually committing.
- Conditional instructions: You might say: "If the commit changed >5 files in docs/, comment 'Large documentation update detected.' Otherwise, call noop."

---

## References

- Push Event Trigger: https://github.github.com/gh-aw/reference/triggers/#push
- Path Filters: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#onpushpullrequestpaths
- GitHub tool permissions: https://github.github.com/gh-aw/reference/permissions/
- Safe Outputs — Add Comment: https://github.github.com/gh-aw/reference/safe-outputs/#add-comment
- Related Blog: [Peli's Agent Factory Part 2: Continuous Simplicity](https://github.github.com/gh-aw/blog/2026-01-13-meet-the-workflows-continuous-simplicity/)

---

## Help

If you're blocked:

1. Path filters are exact. If the workflow doesn't trigger, confirm you pushed to the watched path (e.g. `docs/**` matches all files under `docs/`) and add `workflow_dispatch:` so you can test without committing.
2. Test with a dummy push: add a `.trigger` file to the watched directory, commit, and push to confirm the workflow runs.
3. Review the commit data in the run logs. If changed files aren't listed, the path filter likely didn't match.
