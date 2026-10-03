# Activity 1-01: Morning briefing

## Build

Build a scheduled workflow that runs every weekday at 9 AM. It reads recent issues and pull requests, then creates a "Morning Briefing" issue that summarizes the past 24 hours.

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
> [Bring your own repo](../../setup.md#bring-your-own-repo): point `morning-briefing.md` at a repo you own and use its real backlog and PR activity.

---

## Tips and troubleshooting

- `0 9 * * 1-5` means 9 AM, Monday through Friday. Use `crontab.guru` to check cron syntax.
- The GitHub tool needs `read` access to query issues and PRs. `safe-outputs` handles the write to create the issue.
- Write instructions such as: "Summarize the last 24 hours of activity in this repo. Include counts of opened/closed issues and PRs. Highlight any high-priority items."
- Add `workflow_dispatch:` to `on:` so you can test manually from the Actions tab without waiting for the cron schedule.
- The GitHub tool returns metadata such as issue number, title, state, and creation date. Tell the agent how to present it.
- If the agent does not follow your instructions, read the run log in the Actions tab to see what it tried to do.
- If the summary is wrong, simplify the instruction first ("List all issues opened in the last 24 hours"), then build back up.

---

## References

- gh-aw Schedule Triggers: https://github.github.com/gh-aw/reference/triggers/#schedule
- GitHub tool permissions: https://github.github.com/gh-aw/reference/permissions/
- Cron Syntax Guide: https://crontab.guru/
- Safe outputs, create-issue: https://github.github.com/gh-aw/reference/safe-outputs/#create-issue
- Related Blog: [Peli's Agent Factory Part 9: Metrics & Analytics](https://github.github.com/gh-aw/blog/2026-01-13-meet-the-workflows-metrics-analytics/)
