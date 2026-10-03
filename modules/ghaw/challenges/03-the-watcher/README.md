# Activity 1-03: The watcher

**Session outcome:** A push to your chosen repository path triggers a workflow that comments on the commit with a change summary. Your test push confirms the path filter and comment work.

## Build

Build a workflow triggered by `on: push`. It detects changes in a chosen directory, such as `docs/` or `src/config/`, and comments on the commit with a summary.

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
> [Bring your own repo](../../setup.md#bring-your-own-repo): point `the-watcher.md` at a repo you own and watch a real path such as `docs/**`, config, schemas, tests, or release files.

---

## Tips and troubleshooting

- Use `on: push: paths: ['docs/**']` to run only when files matching that glob change. Set the path to the directory you want to watch.
- The agent can read the commit message, changed files, and author. Refer to those fields in your instructions.
- `safe-outputs: add-comment:` posts a comment on the commit itself, not an issue.
- Add `workflow_dispatch` so you can test without committing.
- Write conditional instructions such as: "If the commit changed >5 files in docs/, comment 'Large documentation update detected.' Otherwise, call noop."
- Path filters are exact. If the workflow doesn't trigger, confirm you pushed to the watched path, then test with a throwaway `.trigger` file.
- Review the commit data in the run logs. If changed files aren't listed, the path filter didn't match.

---

## References

- Push Event Trigger: https://github.github.com/gh-aw/reference/triggers/#push
- Path Filters: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#onpushpullrequestpaths
- GitHub tool permissions: https://github.github.com/gh-aw/reference/permissions/
- Safe outputs, add-comment: https://github.github.com/gh-aw/reference/safe-outputs/#add-comment
- Related Blog: [Peli's Agent Factory Part 2: Continuous Simplicity](https://github.github.com/gh-aw/blog/2026-01-13-meet-the-workflows-continuous-simplicity/)
