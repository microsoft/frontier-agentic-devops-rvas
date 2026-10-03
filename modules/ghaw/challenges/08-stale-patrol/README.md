# Activity 2-04: Stale patrol

## Build

Build a daily workflow that finds issues open for more than 60 days with no recent activity. It warns maintainers, then closes an issue if it remains stale for three more days.

The warning gives maintainers time to intervene before the workflow closes an issue.

---

## What you'll practice

1. Build a daily workflow with `on: schedule:`
2. Query stale issues with `tools: github:`
3. Decide whether an issue is stale and how old it is
4. Post a warning before closing
5. Close the issue with an explanation
6. Leave already-closed issues alone

---

> [!TIP]
> [Bring your own repo](../../setup.md#bring-your-own-repo): point `stale-patrol.md` at a repo you own and use its real exemption labels (e.g. `keep-alive`), grace period, and closure language.

---

## Activity

Create a gh-aw workflow named `stale-patrol.md` in `.github/workflows/` that:

- Runs daily using `on: schedule:`, for example at 9 AM UTC
- Scans for issues that meet all these criteria:
  - Open (state: "open")
  - Not labeled `keep-alive` or `long-term` (so you can exempt important issues)
  - No activity (no comments) for >60 days
  - Created more than 90 days ago
- For each stale issue:
  - Post a comment: "This issue hasn't been active in 60+ days. If it's still relevant, please comment. Otherwise, I'll close it in 3 days."
  - Add a label: `stale` (optional but helpful)
- After the workflow has run 3+ times on an issue with `stale` label and still no activity, close it with comment: "Closing due to inactivity. Please reopen if this is still relevant."

---

## Tips and troubleshooting

- Use `on: schedule: - cron: '0 9 * * *'` for 9 AM UTC daily.
- Tell the agent how to calculate inactivity: "Consider an issue stale if last comment was >60 days ago."
- Check for exemption labels such as `keep-alive`, `long-term`, and `backlog` before closing.
- Test without waiting 60 days by mocking the date: "Assume this issue was last updated on [date 70 days ago]."
- Check the issue's state first so you do not close an already-closed issue.
- Keep the closing comment respectful and offer to reopen the issue if needed.
- Query stale issues through the GitHub API search syntax: `state:open updated:<2024-01-01`.
- No stale issues found is the correct result in a young repo. Mock a date to test the path.
- If closing produces a permission error, set `permissions: issues: write` or let safe-outputs handle the write.

---

## References

- Schedule Syntax: https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#schedule
- GitHub tool permissions: https://github.github.com/gh-aw/reference/permissions/
- Safe Outputs (update-issue): https://github.github.com/gh-aw/reference/safe-outputs/
- Real-world example: the GitHub Next Agentics examples at https://github.com/githubnext/agentics
