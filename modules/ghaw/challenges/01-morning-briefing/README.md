# Activity 1-01: Morning Briefing

Track: Track 1 — Hello, Agent  
Difficulty: 🟢 Beginner  
Estimated time: 30 minutes  
Prerequisites: Activity 00 — Setup & Hello, Agent

---

## Build

A scheduled workflow that runs every weekday at 9 AM. It reads recent issues and pull requests, then creates a "📋 Morning Briefing" issue that summarizes the past 24 hours.

This can replace the manual status check before standup. Read the generated briefing before deciding whether the team can rely on it.

---

## What you'll practice

1. Write a gh-aw workflow triggered by `on: schedule` (cron syntax)
2. Use the GitHub MCP tool to query recent issues and PRs
3. Tell the agent how to summarize activity
4. Create a structured, dated issue with `safe-outputs: create-issue`
5. Work with time-based automation triggers

---

> [!IMPORTANT]
> Bring your own repo (do this first)
>
> Run the briefing on your own repository if possible. Real issues and pull requests show whether the summary is useful. Use the setup sample only for practice.
>
> - Have a candidate repo? Install or point `morning-briefing.md` at that repo everywhere the guide references the sample repo, and use its real backlog and PR activity as the briefing material.
> - No suitable repo yet? Use the provided sample repo from setup as the safe practice target.
>
> Tell the facilitator which repository you chose.

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
- [ ] Using a project, task, or workflow you own, discuss which daily status update this briefing could replace and what you would trust it to send unsupervised.

---

## Tips & Hints

- Cron syntax: `0 9 * * 1-5` means 9 AM, Monday–Friday. (Explore `crontab.guru` if you need a cheat sheet.)
- Permissions: The GitHub tool needs `read` access to query issues and PRs, but `safe-outputs` handles the write to create the issue.
- Natural language instructions: Write something like: "Summarize the last 24 hours of activity in this repo. Include counts of opened/closed issues, opened/closed PRs, and highlight any high-priority items."
- Workflow dispatch: Add `workflow_dispatch:` to `on:` so you can test manually from the Actions tab without waiting for the cron schedule.
- Tool queries: The GitHub tool returns metadata (issue number, title, state, creation date). Your instructions should tell the agent how to present that to humans.

---

## References

- gh-aw Schedule Triggers: https://github.github.com/gh-aw/reference/triggers/#schedule
- GitHub tool permissions: https://github.github.com/gh-aw/reference/permissions/
- Cron Syntax Guide: https://crontab.guru/
- Safe Outputs — Create Issue: https://github.github.com/gh-aw/reference/safe-outputs/#create-issue
- Related examples: See Category B (Continuous Documentation) in the activity research materials for the `org-health-report.md` and `auto-triage-issues.md` patterns.
- Related Blog: [Peli's Agent Factory Part 9: Metrics & Analytics](https://github.github.com/gh-aw/blog/2026-01-13-meet-the-workflows-metrics-analytics/)

---

## Help

If you're blocked:

1. Check cron syntax on crontab.guru. Day-of-week errors are common.
2. Test with workflow_dispatch: Don't wait for the schedule; manually trigger from the Actions tab to see errors immediately.
3. Read the agent logs: Click your workflow run in the Actions tab and scroll to see what the AI agent actually tried to do.
4. Simplify instructions: If the agent isn't summarizing correctly, give it simpler guidance like "List all issues opened in the last 24 hours" before moving to complex summaries.

Ask your coach if you're blocked for more than 15 minutes.
