# Activity 3-04: The Overseer

Track: Continuous Intelligence (Advanced)  
Difficulty: 🔴 Advanced  
Estimated time: 75 minutes  
Prerequisites: Track 2, completed ≥3 activities

---

## Background

The Overseer monitors other agentic workflows: are they running successfully, how many tokens are they burning, which ones fail repeatedly, and should someone be alerted? The team gets one place to see repeated failures, token spikes, and stale workflows.

---

## What you'll practice

1. Query workflow runs with the `agentic-workflows` MCP tool
2. Set `max-effective-tokens` for the expected analysis
3. Build a meta-workflow that creates health or alert issues
4. Monitor agentic workflows from another workflow

---

> [!TIP]
> [Bring your own repo](../../setup.md#bring-your-own-repo): point the health monitor at a repo you own whose agentic workflow runs, failure patterns, and token history matter to the team.

## Activity

Build a workflow health monitor that runs weekly and reports on all agentic workflows:

### Collect run data

Use the `agentic-workflows` MCP tool to gather:
- Last 7 days of workflow run summaries (name, success/failure, tokens, cost)
- Failure rate per workflow (# failed / # total)
- Token efficiency per workflow (avg tokens per run)

### Analyze the runs

Identify:
1. Top 3 most expensive workflows (by total tokens burned in the past 7 days)
2. Top 3 failing workflows (highest failure rate)
3. Unexpected spikes (a workflow that was stable but suddenly started failing or using 10× tokens)

### Create the report

Create an issue with:
- A summary table: Workflow name, success rate, avg tokens, trend
- Alerts for workflows above the failure-rate threshold your team chose
- Recommendations tied to evidence, such as pagination fixes for API timeouts or prompt splitting when token use doubles after a new scan is added

Use `safe-outputs: create-issue: expires: 7d, max: 1, close-older-issues: true` to keep one active health report per week.

### Set the token budget

Use a concrete `max-effective-tokens` value because analyzing workflow history requires enough token budget to complete. Document in your solution *why* that value fits the number of runs you expect to analyze.

---

## Tips & Troubleshooting

- The `agentic-workflows` MCP tool gives read-only access to workflow runs in *this* repo only; if it's not found, check `tools: agentic-workflows` in frontmatter.
- Failure rate = failed runs / total runs. Flag a workflow as spiking if its latest run used >2× the average tokens of the previous 5 runs.
- Set `max-effective-tokens` high enough for the expected analysis, and document why that value fits the run count. If analysis stops early, reduce scope before raising the budget.
- Use `tracker-id: workflow-health-monitor` so other workflows can associate issues with this monitor, and keep the issue body to a compact markdown table (~200 lines max).

---

## References

- Workflow frontmatter: https://github.github.com/gh-aw/reference/frontmatter/
- max-effective-tokens Guide: https://github.github.com/gh-aw/reference/frontmatter/#max-effective-tokens
- Audit Workflows Example: https://github.com/github/gh-aw/blob/main/.github/workflows/audit-workflows.md
- Workflow Health Manager Example: https://github.com/github/gh-aw/blob/main/.github/workflows/workflow-health-manager.md
- Safe Outputs (create-issue): https://github.github.com/gh-aw/reference/safe-outputs/#create-issue
