# Challenge 2-04: Stale Patrol

**Track:** Repo Concierge (Intermediate 🟡)  
**Estimated time:** 30 minutes  
**Prerequisites:** Complete at least 2 challenges from Track 1

---

## What You'll Build

A workflow that patrols your repo for stale issues and closes them automatically. Daily, it scans for issues open >60 days with no recent activity, warns the maintainers with a comment, and closes them if still stale 3 days later. This teaches you **scheduled automation + conditional logic**—the foundation for maintenance workflows.

**Why this matters:** Stale issues clutter backlogs and confuse new contributors. Automated cleanup keeps repos healthy. But you need judgment: warn first, close only after confirmation. This mirrors real team practices.

---

## Goals

By the end, your squad will:

1. ✅ Build a workflow triggered daily on a schedule (`on: schedule:`)
2. ✅ Use `tools: github:` to query stale issues
3. ✅ Implement conditional logic (is an issue stale? how old is it?)
4. ✅ Post a warning comment if stale
5. ✅ Close the issue with a comment explaining why
6. ✅ Avoid re-closing already-closed issues

---

## Challenge

Create a gh-aw workflow named `stale-patrol.md` in `.github/workflows/` that:

- **Triggers:** Daily (early morning, e.g., 9 AM UTC) using `on: schedule:`
- **Scans for issues** that meet ALL criteria:
  - Open (state: "open")
  - Not labeled `keep-alive` or `long-term` (so you can exempt important issues)
  - No activity (no comments) for >60 days
  - Created before the last 90 days (old enough to be truly stale)
- **For each stale issue:**
  - Post a comment: "This issue hasn't been active in 60+ days. If it's still relevant, please comment. Otherwise, I'll close it in 3 days."
  - Add a label: `stale` (optional but helpful)
- **After the workflow has run 3+ times on an issue** with `stale` label and still no activity, close it with comment: "Closing due to inactivity. Please reopen if this is still relevant."

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

---

## Tips & Hints

- **Schedule syntax:** Use `on: schedule: - cron: '0 9 * * *'` for 9 AM UTC daily
- **Age calculation:** The agent can calculate days since last activity. Provide: "Consider an issue stale if last comment was >60 days ago"
- **Exemptions:** Always check for labels like `keep-alive`, `long-term`, `backlog` before closing
- **Testing:** Since the workflow runs on a 60-day clock, you can mock this: "Assume this issue was last updated on [date 70 days ago]"
- **Idempotency:** Don't close an already-closed issue. Check state first
- **Tone in closing comment:** Friendly and respectful, not harsh. Offer reopening if needed

---

## References

- **Schedule Syntax:** https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows#schedule
- **GitHub API Issues Querying:** https://github.github.com/gh-aw/reference/tools/github/
- **Safe Outputs (update-issue):** https://github.github.com/gh-aw/reference/safe-outputs/
- **Real-world example:** `daily-backlog-burner.md` at https://github.com/githubnext/agentics/blob/main/workflows/daily-backlog-burner.md

---

## Stuck?

- **"How do I query for stale issues?"** → Use the GitHub API to search: `state:open updated:<2024-01-01` (dates in the past)
- **"How do I avoid closing already-closed issues?"** → Before updating, check the issue state: "If state is already 'closed', do nothing"
- **"Workflow runs but doesn't find any stale issues?"** → This is correct if your repo is young! Add a mock: "For testing, assume this issue was last updated on [old date]"
- **"Permission error when trying to close?"** → Ensure `permissions: issues: write` is set (or safe-outputs handles it)

Ask your coach.
