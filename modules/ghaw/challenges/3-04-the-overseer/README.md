# Challenge 3-04: The Overseer

**Track:** Continuous Intelligence (Advanced)  
**Difficulty:** 🔴 Advanced  
**Estimated time:** 30 minutes  
**Prerequisites:** Track 2, completed ≥3 challenges

---

## Background

When you have multiple workflows running, who watches the watchers?

**The Overseer** is about **meta-workflows**—agents that monitor, audit, and report on other agents. Imagine a supervisor workflow that checks:
- *Are my other workflows running successfully?*
- *How many tokens did each workflow burn?*
- *Which workflows are failing repeatedly?*
- *Should I alert someone?*

This is the **observability layer**. Production automation doesn't just execute—it observes itself and reacts to what it finds.

**Why this matters:** As your automation system grows (5, 10, 20 workflows), you need built-in health monitoring. An Overseer catches problems early, alerts the team, and helps you optimize before costs spiral.

---

## Goals

By the end of this challenge, your squad will:

1. ✅ Use the `agentic-workflows` MCP tool to query all workflow runs
2. ✅ Understand `max-effective-tokens` for large-scale analysis
3. ✅ Build a meta-workflow that creates health/alert issues
4. ✅ See how agents can introspect their own ecosystem

---

## Challenge

Build a **workflow health monitor** that runs weekly and reports on all agentic workflows:

### The Data Collection

Use the `agentic-workflows` MCP tool to gather:
- **Last 7 days** of workflow run summaries (name, success/failure, tokens, cost)
- **Failure rate** per workflow (# failed / # total)
- **Token efficiency** per workflow (avg tokens per run)

### The Analysis

Identify:
1. **Top 3 most expensive workflows** (by total tokens burned in the past 7 days)
2. **Top 3 failing workflows** (highest failure rate)
3. **Unexpected spikes** (a workflow that was stable but suddenly started failing or using 10× tokens)

### The Output

Create an **issue** with:
- A summary table: Workflow name, success rate, avg tokens, trend
- Alerts for any workflow with >20% failure rate
- Recommendations (e.g., "workflow X is burning tokens—consider optimizing the prompt")

Use `safe-outputs: create-issue: expires: 7d, max: 1, close-older-issues: true` to keep one active health report per week.

### The Trick

Use **`max-effective-tokens: 5000000`** (or similar high value) because analyzing all workflow data requires headroom. Document in your solution *why* you set that value.

---

## Success Criteria

- [ ] Workflow triggers weekly (`on: schedule:`)
- [ ] Uses `agentic-workflows` MCP tool to fetch run data
- [ ] Frontmatter includes `max-effective-tokens: XXXXX` with a comment explaining the value
- [ ] Analysis identifies: top expensive, top failing, unexpected spikes
- [ ] Issue created with structured data (table + alerts)
- [ ] Old issues auto-close (via `close-older-issues: true`)
- [ ] At least one alert or recommendation is triggered

---

## Tips & Hints

- The `agentic-workflows` MCP tool is special—it only works in gh-aw workflows and gives you read-only access to all workflow runs in *this* repo.
- `max-effective-tokens` is about **cost-normalized tokens**—set it high enough that the agent won't get cut off mid-analysis, but not so high that costs spiral. A good starting value is 5,000,000–10,000,000.
- Failure rate: If a workflow ran 5 times and failed 1 time, that's 20% failure rate. Use a threshold (e.g., >20% triggers an alert).
- Token efficiency: If a workflow's latest run used 2× more tokens than average, flag it. Could be a prompt regression or a real data spike.
- Use `tracker-id: workflow-health-monitor` in frontmatter—this helps other workflows correlate issues back to this specific monitor.
- Keep the issue body to ~200 lines. Use markdown tables for easy reading.

---

## References

- **agentic-workflows MCP Reference:** https://github.github.com/gh-aw/reference/mcp-tools/#agentic-workflows
- **max-effective-tokens Guide:** https://github.github.com/gh-aw/reference/frontmatter/#max-effective-tokens
- **Audit Workflows Example:** https://github.com/github/gh-aw/blob/main/.github/workflows/audit-workflows.md
- **Workflow Health Manager Example:** https://github.com/github/gh-aw/blob/main/.github/workflows/workflow-health-manager.md
- **Safe Outputs (create-issue):** https://github.github.com/gh-aw/reference/safe-outputs/#create-issue

---

## Help

Stuck? Here's how to escalate:

- **"agentic-workflows tool not found?"** → Check your `tools: agentic-workflows` in frontmatter. Verify the tool is configured.
- **"Max-effective-tokens—how high is too high?"** → Start with 5M. If the agent gets cut off mid-analysis, increase to 10M.
- **"How do I compute failure rate?"** → # failed runs / # total runs. Simple division.
- **"How do I detect unexpected spikes?"** → Compare latest run tokens to average of previous 5 runs. If >2× average, flag it.
- **"The issue is too long?"** → Use a table instead of prose. Tables are compact and scannable.

Still stuck after 20 minutes? Raise your hand for your coach.
