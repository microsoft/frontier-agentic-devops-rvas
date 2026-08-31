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

> [!IMPORTANT]
> Bring your own repo (do this first)
>
> Run Stale Patrol on your own repository if possible. Use the team's real exemption labels and grace period. Use the setup sample only for practice.
>
> - Have a candidate repo? Install or point `stale-patrol.md` at that repo everywhere the guide references the sample repo, and use real stale issues, labels such as `keep-alive`, and your team's closure language.
> - No suitable repo yet? Use the provided sample repo from setup as the safe practice target.
>
> Tell the facilitator which repository and policy you chose.

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

## Success Criteria

- [ ] `.github/workflows/stale-patrol.md` exists with valid gh-aw frontmatter
- [ ] Trigger is `on: schedule:` with a cron expression (daily around 9 AM UTC)
- [ ] Safe-outputs includes `add-comment` and optionally `update-issue` (to close)
- [ ] `.github/workflows/stale-patrol.lock.yml` compiles without errors
- [ ] Manual test: 
  - Create a test issue dated 70+ days ago (or mock it in the agent prompt)
  - Run workflow manually via `workflow_dispatch`
  - Verify: warning comment appears
  - Verify: `stale` label is applied
- [ ] A second run (simulated 3 days later) closes the issue
- [ ] Issues labeled `keep-alive` are skipped (not closed)
- [ ] No errors if repo has no stale issues
- [ ] Using a project, task, or workflow you own, define when an agent may warn about or close stale work and what grace period you would require.

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
- "How do I avoid closing already-closed issues?" → Before updating, check the issue state: "If state is already 'closed', do nothing"
- "Workflow runs but doesn't find any stale issues?" → This is correct if your repo is young! Add a mock: "For testing, assume this issue was last updated on [old date]"
- "Permission error when trying to close?" → Ensure `permissions: issues: write` is set (or safe-outputs handles it)

Ask your coach.
