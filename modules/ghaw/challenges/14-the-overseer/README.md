# Activity 3-04: The Overseer

Track: Continuous Intelligence (Advanced)  
Difficulty: 🔴 Advanced  
Estimated time: 30 minutes  
Prerequisites: Track 2, completed ≥3 activities

---

## Background

The Overseer monitors and reports on other agentic workflows. It checks:
- *Are my other workflows running successfully?*
- *How many tokens did each workflow burn?*
- *Which workflows are failing repeatedly?*
- *Should I alert someone?*

The team gets one place to see repeated failures, token spikes, and stale workflows.

---

## What you'll practice

1. Query workflow runs with the `agentic-workflows` MCP tool
2. Set `max-effective-tokens` for the expected analysis
3. Build a meta-workflow that creates health or alert issues
4. Monitor agentic workflows from another workflow

---

> [!IMPORTANT]
> Bring your own repo (do this first)
>
> Use a repository in an organization you control. It should have, or soon have, several agentic workflows whose failures and token use matter to the team.
>
> - Have a candidate repo? Use it everywhere this guide references the sample repo, and point the health monitor at that repo's real agentic workflow runs, failure patterns, and token history.
> - No suitable repo yet? Use the provided sample repo from setup as the safe practice target.

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

## Tips & Hints

- The `agentic-workflows` MCP tool works only in gh-aw workflows. It gives read-only access to workflow runs in *this* repo.
- `max-effective-tokens` limits the tokens available to the workflow. Set it high enough for the expected analysis, and document how the expected run count informed the limit.
- Failure rate: If a workflow ran 5 times and failed 1 time, that's 20% failure rate. Choose the alert threshold before the run so the report is not tuned after seeing the data.
- Token efficiency: If a workflow's latest run used 2× more tokens than average, flag it. Could be a prompt regression or a real data spike.
- Use `tracker-id: workflow-health-monitor` in frontmatter so other workflows can associate issues with this monitor.
- Keep the issue body to ~200 lines. Use markdown tables for easy reading.

---

## References

- Workflow frontmatter: https://github.github.com/gh-aw/reference/frontmatter/
- max-effective-tokens Guide: https://github.github.com/gh-aw/reference/frontmatter/#max-effective-tokens
- Audit Workflows Example: https://github.com/github/gh-aw/blob/main/.github/workflows/audit-workflows.md
- Workflow Health Manager Example: https://github.com/github/gh-aw/blob/main/.github/workflows/workflow-health-manager.md
- Safe Outputs (create-issue): https://github.github.com/gh-aw/reference/safe-outputs/#create-issue

---

## Help

Use these checks if the workflow fails:

- "agentic-workflows tool not found?" → Check your `tools: agentic-workflows` in frontmatter. Verify the tool is configured.
- **The token budget is too low:** Estimate the number of runs and fields the agent must inspect. If analysis stops early, reduce the scope first. Raise the budget only when you can explain why.
- "How do I compute failure rate?" → # failed runs / # total runs. Simple division.
- "How do I detect unexpected spikes?" → Compare latest run tokens to average of previous 5 runs. If >2× average, flag it.
- "The issue is too long?" → Use a table instead of prose. Tables are compact and scannable.
