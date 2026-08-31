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

> [!TIP]
> [Bring your own repo](../../setup.md#bring-your-own-repo): point `morning-briefing.md` at a repo you own and use its real backlog and PR activity. No candidate repo yet? Use the setup sample.

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
- Related Blog: [Peli's Agent Factory Part 9: Metrics & Analytics](https://github.github.com/gh-aw/blog/2026-01-13-meet-the-workflows-metrics-analytics/)

---

## Help

If you're blocked:

1. Check cron syntax on crontab.guru. Day-of-week errors are common.
2. Test with workflow_dispatch: Don't wait for the schedule; manually trigger from the Actions tab to see errors immediately.
3. Read the agent logs: Click your workflow run in the Actions tab and scroll to see what the AI agent actually tried to do.
4. Simplify instructions: If the agent isn't summarizing correctly, give it simpler guidance like "List all issues opened in the last 24 hours" before moving to complex summaries.
