# Coach Guide: Challenge 2-04 — Stale Patrol

---

## Coaching Philosophy

This challenge teaches **scheduled + conditional logic**, the foundation for maintenance automation. Squads encounter real constraints: "Don't close too fast," "Respect exemptions," "Handle edge cases." Your job: help them see that automation with guardrails is safer than chaotic deletion.

**Key rule:** By minute 25, the squad should understand the 3-phase pattern: warn → wait → close. This restraint is what makes automation trustworthy.

---

## Expected Outcomes

A finished solution has these characteristics:

**File structure:**
- `.github/workflows/stale-patrol.md` — ~40–60 lines (frontmatter + body)
- `.github/workflows/stale-patrol.lock.yml` — auto-generated, ~90–120 lines

**Behavior:**
- Runs daily at scheduled time (visible in Actions tab)
- Queries stale issues (open >60 days, no recent activity)
- Posts warning comment: "This will be closed in 3 days if no activity"
- After 3 runs, closes stale issues with respectful comment
- Skips issues with `keep-alive` or `long-term` labels
- Skips already-closed issues (idempotent)

**Example outcome:**
```
Issue: "Support for NodeJS v16" (opened 90 days ago, last activity 70 days ago)
[Stale Patrol runs — first time]
Comment posted: "This issue hasn't been active in 60+ days. If you're still working on this, please comment. Otherwise, I'll close it in 3 days. Thanks!"
Label: stale (added)

[70 days later, Stale Patrol runs again — still no activity]
Comment posted: "Closing due to inactivity. Please reopen if this is still relevant."
Issue closed.
```

---

## Common Approaches

All valid.

### Approach 1: Warn-Then-Close (Most Common)

Workflow checks:
1. Find stale issues
2. If already has `stale` label + >3 days old: close
3. If no `stale` label: warn and apply `stale` label

**Pros:** Simple, teachable, safe  
**Cons:** Doesn't perfectly track "3 runs" (just uses time-based logic)

### Approach 2: Strict 3-Run Counter

Use `repo-memory` to track when an issue was first marked stale, then close only after 3 runs:

```
Write to repo-memory: {issue_id: marked_stale_on: 2025-01-01}
On subsequent runs, check: is marked_stale_on >3 days old? Then close.
```

**Pros:** Exact, professional  
**Cons:** Requires `tools: repo-memory` (introduces complexity)

### Approach 3: Multiple Exclusions

Expand exempt labels: `keep-alive`, `long-term`, `backlog`, `planned`, `stale/false-positive`

**Pros:** Flexible, team can opt out easily  
**Cons:** More maintenance overhead

---

## Common Pitfalls & Socratic Responses

### Pitfall 1: Workflow Doesn't Run on Schedule

**Symptom:** Scheduled workflow never appears in Actions tab.

**Root cause:** Cron syntax is wrong, or `on: schedule:` is malformed.

**Coach response:**
- "Let's check your cron. Does it look like `0 9 * * *`?"
- Explain: `0 9 * * *` = 9 AM UTC, every day
- Point to cron reference: https://crontab.guru/
- Have them test: manually run workflow with `gh workflow run` to verify it compiles

### Pitfall 2: Closes Issues Too Aggressively

**Symptom:** Issues with `keep-alive` label still get closed, or recent activity is ignored.

**Root cause:** Missing exemption check or age calculation is wrong.

**Coach response:**
- "Before closing, always check: does this issue have `keep-alive`?"
- "Also check: has anyone commented in the last 3 days? If yes, skip."
- Guide: "Your logic should be: is open? no recent activity? no exempt labels? Then warn/close"

### Pitfall 3: Closes Already-Closed Issues

**Symptom:** Workflow tries to close issues that are already closed, causing errors.

**Root cause:** No state check before closing.

**Coach response:**
- "Before updating an issue, always check: `if state == 'closed', do nothing`"
- Emphasize: "This is idempotency—running the workflow twice should be safe"

### Pitfall 4: Query Is Too Broad or Too Narrow

**Symptom:** Workflow finds no stale issues (too narrow) or finds everything (too broad).

**Root cause:** Date filtering is off, or exemption checks too strict.

**Coach response:**
- "Let's test the query. Can you manually query for issues updated before 60 days ago?"
- Suggest: "Use the GitHub Issues API with `updated:<date>` filter"
- Show: "For testing, set the threshold lower: 7 days instead of 60, so you see results faster"

### Pitfall 5: Comment Tone Is Harsh

**Symptom:** Comment feels like a threat ("Your issue is useless and I'm deleting it").

**Root cause:** Squads forget these might be users' important work.

**Coach response:**
- "Rewrite the comment. This is a courtesy notice, not a warning."
- Suggest: "Instead of 'This issue is useless', try: 'This hasn't been active recently. If you're still working on it, please let us know!'"
- Model empathy: "Contributors care about their issues. Your bot should too."

### Pitfall 6: No Test Strategy

**Symptom:** Squad doesn't know how to test (can't wait 60 days for an issue to age).

**Root cause:** Not thinking about testing patterns early.

**Coach response:**
- "For testing, you have options:"
  - Create a fake issue by mocking the date in the agent prompt
  - Use `workflow_dispatch` to run manually, then instruct agent: "Assume this issue was last updated on [date 70 days ago]"
  - Or: adjust the threshold to 0 days temporarily (finds any open issue) to verify the logic works

---

## Sample Solution

This is a complete, working `stale-patrol.md`. Share **only after 20+ min of struggle**; ask them to type it out.

```markdown
---
on:
  schedule:
    - cron: '0 9 * * *'  # 9 AM UTC daily
  workflow_dispatch:

permissions:
  issues: read

safe-outputs:
  add-comment: {}
  update-issue: {}

engines:
  - copilot
---

# Stale Patrol

Every day, find issues that are:
1. Open
2. Created >90 days ago
3. No comments in the last 60 days
4. NOT labeled with `keep-alive` or `long-term`

For each stale issue:
- If it already has the `stale` label and it was labeled >3 days ago: close it with a respectful comment
- If it doesn't have the `stale` label yet: add the label and post a warning comment

**Warning comment:** "This issue hasn't been active in 60+ days. If you're still working on this, please comment. Otherwise, I'll close it in 3 days. Thanks!"

**Closing comment:** "Closing due to inactivity. If this is still relevant, please reopen. Thanks for your understanding!"

Be respectful and helpful. These might be contributors' important work.
```

**Why this works:**
- `on: schedule: - cron: '0 9 * * *'` — runs daily at 9 AM UTC
- `workflow_dispatch` — can be triggered manually for testing
- `permissions: issues: read` — can query issues
- `safe-outputs: update-issue: {}` — can close (which is a form of update)
- Body: clear 3-phase logic (query → warn → close), respectful tone
- `engines: [copilot]` — good at date calculations and respectful copy

---

## Time Management

| Phase | Time | What to Do |
|-------|------|-----------|
| Read & orient | 3 min | Read challenge, understand scheduled triggers |
| Write frontmatter | 4 min | Set up `on: schedule:`, `permissions`, `safe-outputs`, `engines` |
| Write body | 10 min | Draft stale issue query + warn/close logic |
| Compile & test | 9 min | Compile, manually trigger with `workflow_dispatch`, verify logic |
| Refine | 3 min | Adjust dates/exemptions if needed |
| Celebrate | 1 min | Discuss |

**Total: ~30 minutes.**

---

## Extension Ideas (for Fast Squads)

If finished in <20 minutes:

1. **Add a `stale-no-issue` workflow:** Also closes stale PRs
   - **Concept:** Reusing logic across different event types

2. **Escalate before closing:** Post to a maintainer team issue instead of auto-closing
   - **Concept:** `create-issue` + `mention` pattern

3. **Notify author:** Reply to the issue mentioning the original author, giving them a chance to respond
   - **Concept:** `@mention` in comments

4. **Customizable exemptions:** Use `repo-memory` to store a list of exempt issue IDs
   - **Concept:** Dynamic configuration via `repo-memory`

5. **Weekly summary:** Post a discussion summarizing which issues were closed this week
   - **Concept:** Combining `close-issue` with `create-discussion`

---

## Debugging Checklist

If a squad is stuck:

- [ ] Is cron syntax valid? (check crontab.guru)
- [ ] Did they compile?
- [ ] Does `.lock.yml` exist?
- [ ] Did they manually trigger with `workflow_dispatch`?
- [ ] Are there logs in the Actions tab?
- [ ] Is the query finding stale issues? (test with a lower threshold)
- [ ] Are exemption labels being respected?
- [ ] Is the workflow idempotent? (run it twice, no errors?)

---

## Key Takeaways for Coaches

- **Scheduled automation is powerful:** Runs on a clock, no human trigger needed. This scales maintenance.
- **Guardrails matter:** Warn-then-close is better than delete-on-sight. Automation needs to earn trust.
- **Idempotency is key:** Workflows may run twice. Squads should always ask: "Is it safe to run this twice?"
- **Respectful tone:** Automation that feels harsh breaks team trust. Emphasize empathy in bot design.

---

## Reference

**Sample Solution Location:** `coaches/sample-solutions/track-2/2-04-stale-patrol.md`  
**Daily Backlog Burner (Real):** https://github.com/githubnext/agentics/blob/main/workflows/daily-backlog-burner.md  
**Cron Reference:** https://crontab.guru/  
**Schedule Trigger:** https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows#schedule
