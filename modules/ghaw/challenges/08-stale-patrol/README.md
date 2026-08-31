# Activity 2-04: Stale Patrol

Track: Repo Concierge (Intermediate 🟡)  
Estimated time: 30 minutes  
Prerequisites: Complete at least 2 activities from Track 1

---

## Build

A daily workflow that finds issues open for more than 60 days with no recent activity. It warns maintainers, then closes an issue if it remains stale for three more days.

Stale issues make backlogs harder to trust. The workflow warns before closing so maintainers have time to intervene.

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
> [Bring your own repo](../../setup.md#bring-your-own-repo): point `stale-patrol.md` at a repo you own and use its real exemption labels (e.g. `keep-alive`), grace period, and closure language. No candidate repo yet? Use the setup sample.

---

## Activity

Create a gh-aw workflow named `stale-patrol.md` in `.github/workflows/` that:

- Triggers: Daily (early morning, e.g., 9 AM UTC) using `on: schedule:`
- Scans for issues that meet ALL criteria:
  - Open (state: "open")
  - Not labeled `keep-alive` or `long-term` (so you can exempt important issues)
  - No activity (no comments) for >60 days
  - Created before the last 90 days (old enough to be truly stale)
- For each stale issue:
  - Post a comment: "This issue hasn't been active in 60+ days. If it's still relevant, please comment. Otherwise, I'll close it in 3 days."
  - Add a label: `stale` (optional but helpful)
- After the workflow has run 3+ times on an issue with `stale` label and still no activity, close it with comment: "Closing due to inactivity. Please reopen if this is still relevant."

---

## Tips & Hints

- Schedule syntax: Use `on: schedule: - cron: '0 9 * * *'` for 9 AM UTC daily
- Age calculation: The agent can calculate days since last activity. Provide: "Consider an issue stale if last comment was >60 days ago"
- Exemptions: Always check for labels like `keep-alive`, `long-term`, `backlog` before closing
- Testing: Since the workflow runs on a 60-day clock, you can mock this: "Assume this issue was last updated on [date 70 days ago]"
- Idempotency: Don't close an already-closed issue. Check state first
- Tone in closing comment: Friendly and respectful, not harsh. Offer reopening if needed

---

## References

- Schedule Syntax: https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#schedule
- GitHub tool permissions: https://github.github.com/gh-aw/reference/permissions/
- Safe Outputs (update-issue): https://github.github.com/gh-aw/reference/safe-outputs/
- Real-world example: the GitHub Next Agentics examples at https://github.com/githubnext/agentics

---

## Help

- "How do I query for stale issues?" → Use the GitHub API to search: `state:open updated:<2024-01-01` (dates in the past)
- "Workflow runs but doesn't find any stale issues?" → This is correct if your repo is young! Mock it: "For testing, assume this issue was last updated on [old date]"
- "Permission error when trying to close?" → Ensure `permissions: issues: write` is set (or safe-outputs handles it)
