# Challenge 1-03: The Watcher

**Track:** Track 1 — Hello, Agent  
**Difficulty:** 🟢 Beginner  
**Estimated time:** 30 minutes  
**Prerequisites:** Challenge 00 — Setup & Hello, Agent, Challenge 1-01 — Morning Briefing

---

## What You'll Build

A workflow triggered by `on: push` that detects when files in a specific directory (e.g., `docs/` or `src/config/`) are modified and creates a comment on the commit summarizing what changed. This teaches you how to react to repository events in real-time.

**Why this matters:** Event-driven automation is the backbone of DevOps. When code changes, you might want to run tests, validate schemas, or notify teams. Learning `on: push` and working with commit data unlocks a whole category of reactive workflows.

---

## Goals

By the end of this challenge, your squad will:

1. ✅ Understand `on: push:` event triggers and how they fire
2. ✅ Use `on: push: paths:` to filter which files trigger the workflow
3. ✅ Access commit metadata (files changed, commit message, author)
4. ✅ Create a commit comment using `safe-outputs: add-comment:`
5. ✅ Test event-driven workflows using local git operations

---

## Success Criteria

- [ ] Workflow file `.github/workflows/the-watcher.md` exists
- [ ] Frontmatter includes `on: push: paths: ['docs/**']` (or similar path filter for a meaningful directory)
- [ ] Permissions are scoped appropriately (read-only for the agent, safe-outputs handles write)
- [ ] Safe-outputs includes `add-comment:` to post comments on the commit
- [ ] `.github/workflows/the-watcher.lock.yml` exists after compilation
- [ ] When you push changes to the watched directory, the workflow runs
- [ ] A comment appears on the commit summarizing the changes (e.g., "Modified 3 files in docs/")
- [ ] Logs show the agent detected which files were changed
- [ ] Coach conversation — which repository events do you currently notice only after the fact, and what would change if a push-triggered agent flagged risky file changes the moment they land? Talk it through with your coach and connect it to a real project, task, or workflow you own.

---

## Tips & Hints

- **Path filters:** Use `on: push: paths: ['docs/**']` to only run when files matching that glob are touched. Adjust the path to a meaningful directory in your repo.
- **Commit metadata:** The agent has access to the commit message, changed files, and author. Use that in your instructions.
- **Test locally first:** You can test by making a commit to the watched directory, then pushing and watching the Actions tab.
- **Safe-outputs: add-comment:** This posts a comment on the commit itself (not an issue). Useful for inline feedback.
- **Workflow_dispatch for testing:** Add it so you can test without actually committing.
- **Conditional instructions:** You might say: "If the commit changed >5 files in docs/, comment 'Large documentation update detected.' Otherwise, call noop."

---

## References

- **Push Event Trigger:** https://github.github.com/gh-aw/reference/triggers/#push
- **Path Filters:** https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions#onpushpullrequestpaths
- **GitHub tool permissions:** https://github.github.com/gh-aw/reference/permissions/
- **Safe Outputs — Add Comment:** https://github.github.com/gh-aw/reference/safe-outputs/#add-comment
- **Dossier Reference:** See Category C (Continuous Improvement) — `breaking-change-checker.md` pattern for `bash` tool + git inspection
- **Related Blog:** [Peli's Agent Factory Part 2: Continuous Simplicity](https://github.github.com/gh-aw/blog/2026-01-13-meet-the-workflows-continuous-simplicity/)

---

## Stuck?

If you're blocked for more than **15 minutes**:

1. **Did you push to the watched directory?** Path filters are exact; if your directory path is wrong, the workflow won't trigger.
2. **Check path filter syntax:** Use `docs/**` for "all files in docs directory" or `*.md` for markdown files.
3. **Test with a dummy push:** Add a `.trigger` file to your watched directory, commit, push, and see if the workflow runs.
4. **Review the commit data:** In the logs, you should see what files changed. If you don't, the path filter may not have matched.
5. **Add workflow_dispatch:** So you can test without actually committing. Then focus on the logic.

Ask your coach.
