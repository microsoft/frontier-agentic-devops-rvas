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

> [!IMPORTANT]
> Bring your own repo (do this first)
>
> Run the watcher on your own repository if possible. Track a directory that matters to the team. Use the setup sample only for practice.
>
> - Have a candidate repo? Install or point `the-watcher.md` at that repo everywhere the guide references the sample repo, and watch real paths such as `docs/**`, config, schemas, tests, or release files.
> - No suitable repo yet? Use the provided sample repo from setup as the safe practice target.

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
- Related example: See the Category C (Continuous Improvement) `breaking-change-checker.md` pattern for using the `bash` tool and inspecting Git history.
- Related Blog: [Peli's Agent Factory Part 2: Continuous Simplicity](https://github.github.com/gh-aw/blog/2026-01-13-meet-the-workflows-continuous-simplicity/)

---

## Help

If you're blocked:

1. Did you push to the watched directory? Path filters are exact; if your directory path is wrong, the workflow won't trigger.
2. Check path filter syntax: Use `docs/**` for "all files in docs directory" or `*.md` for markdown files.
3. Test with a dummy push: Add a `.trigger` file to your watched directory, commit, push, and see if the workflow runs.
4. Review the commit data: In the logs, you should see what files changed. If you don't, the path filter may not have matched.
5. Add workflow_dispatch: So you can test without actually committing. Then focus on the logic.
