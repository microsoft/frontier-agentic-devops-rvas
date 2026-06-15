# Coach Guide: Challenge 3-04 — The Overseer

---

## Coaching Philosophy for This Challenge

This is the **meta-workflow intro**. Squads have built workflows that do things. Now teach them to build workflows that *watch other workflows*.

Your job: Build the insight that observability is not optional—it's foundational. An unmonitored automation system is a liability. An agent watching all the other agents? That's professional.

**Key rule:** Celebrate when they get their first workflow health alert working. That's the "aha moment" of meta-thinking.

---

## Expected Outcomes

A finished solution has:

**Workflow (`workflow-health-monitor.md`)**
- ~40-50 lines (frontmatter + body)
- Trigger: `on: schedule: cron: "0 10 * * 1"` (weekly)
- Frontmatter includes: `tools: agentic-workflows`, `max-effective-tokens: 5000000` (or similar)
- Uses `safe-outputs: create-issue` with `max: 1, close-older-issues: true`
- Optional: `tracker-id: workflow-health-monitor`

**Weekly Issue (Example):**
```
Title: Workflow Health Report — Week of 2026-05-28

## Summary

Last 7 days: 42 workflow runs, 38 succeeded (90% success rate)

## Top Expensive Workflows

| Workflow | Total Tokens | Avg/Run | Status |
|----------|-------------|---------|--------|
| schema-consistency-checker | 8.2M | 2.7M | ⚠️ HIGH |
| audit-workflows | 4.1M | 1.4M | OK |
| agentic-token-audit | 3.2M | 1.6M | OK |

## Failures

| Workflow | Failures | Rate | Last Error |
|----------|----------|------|------------|
| metrics-collector | 0 | 0% | None |
| weekly-reporter | 1 | 20% | Timeout on org scan |

## Alerts

🔴 **weekly-reporter** has 20% failure rate. Latest run timed out querying repos.
→ Recommendation: Increase timeout or add rate limiting to queries.

⚠️ **schema-consistency-checker** spiked to 2.7M tokens (2× normal).
→ Recommendation: Check if the codebase grew or if the prompt is too verbose.

## Next Steps

- Consider disabling failing workflows until fixed
- Optimize schema-checker prompt to reduce token usage
- Monitor weekly-reporter for recurring timeouts
```

---

## Common Approaches

Squads will vary in sophistication:

### Approach 1: "Simple Table" (most common)
Agent fetches workflow summaries, creates a basic table with: workflow name, success rate, latest token count.

**Pros:** Fast, clear, sufficient for learning
**Cons:** Doesn't compute trends or detect spikes

### Approach 2: "Full Analysis"
Compares current week to previous week, flags spikes, computes failure rates, includes recommendations.

**Pros:** Production-grade, genuinely useful
**Cons:** More complex prompt, requires more tokens

### Approach 3: "Minimal Output"
Workflow runs but only creates an issue if something is broken (no issue if all is well).

**Cons:** Misses the learning—participants should see the full report. Not ideal.

**Coach guidance:** Prefer Approach 1 or 2. Encourage at least a basic summary table.

---

## Common Pitfalls & Socratic Responses

### Pitfall 1: agentic-workflows tool not configured
**Symptom:** Workflow logs show "Tool not found" or "agentic-workflows is not available".

**Root cause:** Missing `tools: agentic-workflows` in frontmatter, or tool name typo.

**Coach response:**
- "What's in your `tools:` section?"
- "It should be `tools: agentic-workflows:` (yes, it's not a `toolsets` like GitHub—it's its own tool)."
- Check the reference docs.

### Pitfall 2: No data returned
**Symptom:** Workflow runs but agent says "No workflows found" or "Empty summary".

**Root cause:** `agentic-workflows` didn't return data (maybe no workflows exist, or the query was wrong).

**Coach response:**
- "First: do you have other workflows in this repo that have run in the past 7 days?"
- "If yes, check the agent's instructions. Did it ask for a 7-day window? Try: 'Query the last 7 days of workflow runs using the agentic-workflows MCP tool.'"
- This is a data-pipeline debugging moment.

### Pitfall 3: max-effective-tokens set too low
**Symptom:** Issue is incomplete or agent says "Token budget exceeded".

**Root cause:** `max-effective-tokens` was too small for the analysis.

**Coach response:**
- "How big is your data? 42 runs × 10 metrics per run = 420 data points. That's a lot for a small token budget."
- "Try starting with 5,000,000 tokens. If the agent still gets cut off, increase to 10,000,000."
- "Why do you think we need a high budget here?" → Guide them to understand: analyzing many workflows requires more reasoning tokens than a single task.

### Pitfall 4: Issue never closes
**Symptom:** Multiple old health reports pile up in Issues.

**Root cause:** Missing `close-older-issues: true` or `max: 1` in safe-outputs.

**Coach response:**
- "Check your `safe-outputs: create-issue:` section. Include: `max: 1, close-older-issues: true`."
- "This ensures only one active health report exists—when a new one is created, the old one auto-closes."
- This is a "production safety" moment.

### Pitfall 5: No alerts or insights
**Symptom:** Issue is just a table, no actual problems flagged or recommendations made.

**Root cause:** Agent wasn't told to analyze, just report.

**Coach response:**
- "A good health report spots problems. If all your workflows are perfect, great! But if not, the report should highlight them."
- "Your prompt should include: 'Identify workflows with >20% failure rate, or those that spiked in token usage.'"
- Guide them to add decision logic.

### Pitfall 6: Confused about failure rate calculation
**Symptom:** Agent calculates failure rate wrong (e.g., "failed 3 times" but doesn't divide by total runs).

**Root cause:** Agent wasn't given clear instructions.

**Coach response:**
- "Failure rate = (# failed runs) / (# total runs). If a workflow ran 10 times and failed 2, rate is 2/10 = 20%."
- "Your prompt should be explicit: 'Calculate the failure rate as: number of failed runs divided by total runs.'"

### Pitfall 7: No workflows to monitor
**Symptom:** Overseer runs but says "No workflows found" because this is the first week and no other workflows exist.

**Root cause:** Squad is running challenges in isolation, no other workflows exist.

**Coach response:**
- "That's OK! The challenge is to build the *Overseer*, not to have a full farm of workflows to monitor."
- "For testing, have them manually trigger the Overseer a few times to generate some run history. Then the Overseer has data to analyze."
- Or: "If you want, create a dummy workflow that runs weekly and produces some data. Then the Overseer can monitor it."

---

## Coaching Questions

1. **"What MCP tool are you using to get workflow data?"** → Should be `agentic-workflows`
2. **"How high did you set `max-effective-tokens` and why?"** → Tests reasoning about token budgeting
3. **"What counts as 'failure' in your monitor?"** → Did they define success criteria?
4. **"Show me the issue. What problem does it surface?"** → Verification of output quality
5. **"If all workflows are running great, what does your issue say?"** → Does it handle the happy path?
6. **"How does the old issue auto-close?"** → Check for understanding of `close-older-issues: true`

---

## Sample Solution

Share **only if stuck >20 minutes**. Have them type it.

**`workflow-health-monitor.md`:**

```markdown
---
on:
  schedule:
    - cron: '0 10 * * 1'
  workflow_dispatch:

permissions:
  contents: read

safe-outputs:
  create-issue:
    max: 1
    close-older-issues: true
    expires: 7d

tools:
  agentic-workflows:

max-effective-tokens: 5000000

engines:
  - claude

checkout: false

tracker-id: workflow-health-monitor
---

# Workflow Health Monitor

Analyze all agentic workflow runs from the past 7 days. Create a health report.

Use the agentic-workflows MCP tool to fetch:
1. All workflow run summaries from the last 7 days
2. For each workflow: name, total runs, successful runs, failed runs, total tokens used, average tokens per run

Calculate:
- Success rate = successful runs / total runs
- Failure rate = failed runs / total runs
- Identify workflows with >20% failure rate (red flag)
- Identify workflows that used >2M tokens (expensive flag)
- Compare current week's token usage to previous week (spike detection)

Create an issue with:
1. Summary header: "X runs, Y% success rate"
2. Table: Workflow | Runs | Success % | Avg Tokens | Status
3. Alerts section: List any workflows with high failure or high cost
4. Recommendations: Suggest actions (e.g., "Optimize prompt", "Increase timeout")

Format: Markdown tables, bullets, checkboxes. Keep under 250 lines.

If all workflows are healthy, still create the issue with a "✅ All systems green" note.
```

---

## Why This Works

- **Frontmatter:** High `max-effective-tokens` allows deep analysis. `agentic-workflows` MCP tool configured. `close-older-issues: true` prevents report spam.
- **Meta-pattern:** The agent queries its own ecosystem—meta-thinking.
- **Observability:** Production automation needs this layer.
- **Decision-making:** Not just data, but insights and recommendations.

---

## Time Management

| Phase | Time | What to Do |
|-------|------|-----------|
| Orient | 3 min | Understand meta-workflows, agentic-workflows tool |
| Plan | 3 min | Sketch: What data to collect? What alerts to surface? |
| Write frontmatter | 5 min | Configure tools, max-effective-tokens, safe-outputs |
| Write agent prompt | 12 min | Explain analysis logic and issue format |
| Test | 5 min | Run and verify issue is created |
| Refine | 2 min | If needed, adjust the analysis or formatting |

**Total: ~30 minutes.**

---

## Extension Ideas

1. **Slack notifications:** Mock sending alerts to a Slack channel (via a placeholder issue comment).
2. **Multi-week trending:** Compare health metrics across 4 weeks—is the system getting better or worse?
3. **Correlation analysis:** Detect if failures in workflow A cause failures in workflow B (dependency detection).
4. **Cost predictions:** Estimate weekly cost based on 7-day trends; alert if predicted cost exceeds budget.
5. **Per-engine metrics:** Break down tokens and failures by engine (Copilot vs Claude vs Codex).

---

## Debugging Checklist

- [ ] `tools: agentic-workflows` configured?
- [ ] `max-effective-tokens` set to a reasonable value (5M+)?
- [ ] Workflow triggered at least once?
- [ ] Issue created? (check Issues tab)
- [ ] Issue includes a table or structured data?
- [ ] At least one alert or insight flagged?
- [ ] `close-older-issues: true` working? (old reports auto-close)

---

## Key Takeaways

- **Meta-workflows are powerful:** An agent watching other agents is the observability layer.
- **Token budgets are real:** Analyzing many workflows requires planning headroom.
- **Insights > raw data:** A good health report surfaces problems and recommends actions.
- **Production mindset:** Real teams have automated monitoring. You now do too.
