# Challenge 1-04: Label Maker

**Track:** Track 1 — Hello, Agent  
**Difficulty:** 🟢 Beginner  
**Estimated time:** 30 minutes  
**Prerequisites:** Challenge 00 — Setup & Hello, Agent, Challenge 1-01 — Morning Briefing

---

## What You'll Build

A workflow triggered by `on: issues: types: [opened]` that automatically categorizes newly opened issues and applies labels based on the issue content. Your agent reads the issue title and body, classifies it (e.g., bug, feature, documentation, question), and applies the appropriate label using `safe-outputs: add-labels:`.

**Why this matters:** Automatic issue classification is foundational for triaging and routing work. In large repositories, an AI triage agent can categorize hundreds of issues, keeping your backlog organized and helping teams find relevant issues faster. This is a real workflow deployed in production repositories.

---

## Goals

By the end of this challenge, your squad will:

1. ✅ Understand `on: issues:` event triggers and issue metadata access
2. ✅ Use issue content (title + body) to make classification decisions
3. ✅ Apply labels using `safe-outputs: add-labels:` with an allowlist
4. ✅ Understand that labels should be pre-defined in the repo
5. ✅ Test by creating issues and watching them get labeled in real-time

---

## Success Criteria

- [ ] Workflow file `.github/workflows/label-maker.md` exists
- [ ] Frontmatter includes `on: issues: types: [opened]`
- [ ] Safe-outputs includes `add-labels:` with an allowlist of 3-5 label names
- [ ] Permissions are scoped minimally (e.g., `contents: read`)
- [ ] `.github/workflows/label-maker.lock.yml` exists after compilation
- [ ] When you open a new issue with clear content (e.g., "Bug: login button not working"), the workflow runs
- [ ] The agent correctly classifies the issue and applies the appropriate label
- [ ] Multiple issues are tested with different classifications
- [ ] Logs show the agent's reasoning (e.g., "This is a bug because...")
- [ ] Coach conversation — how much of your team's issue labelling is guesswork you would hand to an agent, and where would a constrained allowlist stop it from inventing categories you can't trust? Talk it through with your coach and connect it to a real project, task, or workflow you own.

---

## Tips & Hints

- **Label allowlist:** In safe-outputs, specify exactly which labels the agent can apply (e.g., `labels: [bug, feature, documentation, question, help-wanted]`). This prevents the agent from creating random labels.
- **Classification prompt:** Write something like: "Read the issue. If it describes a problem, label it 'bug'. If it's a feature request, label it 'feature'. If it's unclear, label it 'question'."
- **Permissions:** Use `contents: read` + `issues: read` (agent needs to read the issue). Safe-outputs handles the label write.
- **Test with real issues:** Open actual GitHub issues from the web or use `gh issue create`. Watch the workflow run and see labels applied instantly.
- **Add workflow_dispatch:** For testing without opening real issues (though real issues are better for learning).
- **Combine with earlier concepts:** You can add `schedule:` to make this run as a batch job on old unlabeled issues, not just new ones.

---

## References

- **Issues Event Trigger:** https://github.github.com/gh-aw/reference/triggers/#issues
- **Safe Outputs — Add Labels:** https://github.github.com/gh-aw/reference/safe-outputs/#add-labels
- **Label Allowlist Pattern:** https://github.github.com/gh-aw/reference/safe-outputs/#labels
- **GitHub tool permissions:** https://github.github.com/gh-aw/reference/permissions/
- **Dossier Reference:** See Category A (Issue & PR Management) — `issue-triage-agent.md` and `auto-triage-issues.md` patterns
- **Related Blog:** [Peli's Agent Factory Part 7: Issue & PR Management](https://github.github.com/gh-aw/blog/2026-01-13-meet-the-workflows-issue-management/)

---

## Stuck?

If you're blocked for more than **15 minutes**:

1. **Did the workflow trigger?** Check the Actions tab to see if the workflow ran when you opened the issue. If not, check if `on: issues: types: [opened]` is correct.
2. **Check the label allowlist:** Verify your labels are spelled correctly and are defined in the repo (Labels tab on GitHub).
3. **Read the logs:** Look at the workflow logs to see what the agent classified the issue as and why.
4. **Test with clear issue content:** Open an issue with an obvious title like "Bug: login broken" so the agent has clear content to classify.
5. **Simplify the classification:** Start with 2 categories (bug vs feature) before expanding to 5.

Ask your coach.
