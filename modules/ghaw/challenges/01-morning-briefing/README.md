# Challenge 1-01: Morning Briefing

**Track:** Track 1 — Hello, Agent  
**Difficulty:** 🟢 Beginner  
**Estimated time:** 30 minutes  
**Prerequisites:** Challenge 00 — Setup & Hello, Agent

---

## What You'll Build

A scheduled workflow that runs every weekday morning at 9 AM and creates a GitHub issue summarizing your repo's activity from the past 24 hours. The agent will read recent issues and PRs, generate a natural-language digest, and post it to your repo as an issue titled "📋 Morning Briefing".

**Why this matters:** This is the first step toward real DevOps automation — scheduled reports that keep teams aligned without requiring manual check-ins. In production, morning briefings can surface blockers before standups, making async communication faster and more effective.

---

## Goals

By the end of this challenge, your squad will:

1. ✅ Write a gh-aw workflow triggered by `on: schedule` (cron syntax)
2. ✅ Use the GitHub MCP tool to query recent issues and PRs
3. ✅ Instruct the AI agent to summarize activity in natural language
4. ✅ Create an issue with structured, dated content using `safe-outputs: create-issue`
5. ✅ Understand the time-based trigger pattern for automation

---

> [!IMPORTANT]
> **Bring your own repo (do this first)**
>
> This challenge is most valuable when the briefing runs on **your own repository** with real issues and PRs, so the workflow can keep informing your team after the session. Treat the setup sample as practice, not the default destination.
>
> - **Have a candidate repo?** Install or point `morning-briefing.md` at that repo everywhere the guide references the sample repo, and use its real backlog and PR activity as the briefing material.
> - **No suitable repo yet?** Use the provided sample repo from setup as the safe practice target.
>
> Tell your coach which path you took — bringing your own is the goal; the sample repo is the fallback.

---

## Success Criteria

- [ ] Workflow file `.github/workflows/morning-briefing.md` exists with valid frontmatter
- [ ] Frontmatter includes `on: schedule:` with a cron expression (e.g., `"0 9 * * 1-5"` for weekdays at 9 AM)
- [ ] Workflow uses `tools: github: toolsets: [issues, pull_requests]` to access repo data
- [ ] Safe-outputs includes `create-issue:` with a title prefix like `[Morning Briefing]`
- [ ] Permissions are scoped to `contents: read` (no write access)
- [ ] `.github/workflows/morning-briefing.lock.yml` is generated after compiling
- [ ] At least one issue was created when the workflow ran (or manual trigger via `workflow_dispatch`)
- [ ] Issue body includes a summary of recent activity (issues opened, PRs, etc.)
- [ ] Coach conversation — what daily status update do you or your team assemble by hand today that this scheduled briefing pattern could replace, and what would you trust it to send unsupervised? Talk it through with your coach and connect it to a real project, task, or workflow you own.

---

## Tips & Hints

- **Cron syntax:** `0 9 * * 1-5` means 9 AM, Monday–Friday. (Explore `crontab.guru` if you need a cheat sheet.)
- **Permissions:** The GitHub tool needs `read` access to query issues and PRs, but `safe-outputs` handles the write to create the issue.
- **Natural language instructions:** Write something like: "Summarize the last 24 hours of activity in this repo. Include counts of opened/closed issues, opened/closed PRs, and highlight any high-priority items."
- **Workflow dispatch:** Add `workflow_dispatch:` to `on:` so you can test manually from the Actions tab without waiting for the cron schedule.
- **Tool queries:** The GitHub tool returns metadata (issue number, title, state, creation date). Your instructions should tell the agent how to present that to humans.

---

## References

- **gh-aw Schedule Triggers:** https://github.github.com/gh-aw/reference/triggers/#schedule
- **GitHub tool permissions:** https://github.github.com/gh-aw/reference/permissions/
- **Cron Syntax Guide:** https://crontab.guru/
- **Safe Outputs — Create Issue:** https://github.github.com/gh-aw/reference/safe-outputs/#create-issue
- **Dossier Reference:** See Category B (Continuous Documentation) for `org-health-report.md` and `auto-triage-issues.md` patterns in Challenge Research Dossier
- **Related Blog:** [Peli's Agent Factory Part 9: Metrics & Analytics](https://github.github.com/gh-aw/blog/2026-01-13-meet-the-workflows-metrics-analytics/)

---

## Stuck?

If you're blocked for more than **15 minutes**:

1. **Check cron syntax:** Verify your cron expression on crontab.guru — an off-by-one error in the day-of-week is common.
2. **Test with workflow_dispatch:** Don't wait for the schedule; manually trigger from the Actions tab to see errors immediately.
3. **Read the agent logs:** Click your workflow run in the Actions tab and scroll to see what the AI agent actually tried to do.
4. **Simplify instructions:** If the agent isn't summarizing correctly, give it simpler guidance like "List all issues opened in the last 24 hours" before moving to complex summaries.

Ask your coach if you're blocked for more than 15 minutes.
