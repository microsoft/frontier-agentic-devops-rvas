# Activity 3-01: The Relay

Track: Continuous Intelligence (Advanced)  
Difficulty: 🔴 Advanced  
Estimated time: 90 minutes  
Prerequisites: Track 2, completed ≥3 activities

---

## Background

Workflows normally run in isolation. To coordinate two of them, the first must leave data the second can read. Build a producer that writes structured data to `repo-memory` and a consumer that reads it on its next trigger — splitting automation into stages with explicit, testable handoffs.

---

## What you'll practice

1. Build a producer workflow that writes structured data to `repo-memory`
2. Build a consumer workflow that reads the data and acts on it
3. Configure `tools: repo-memory` and its `file-glob` patterns
4. Pass data between workflows without coupling them directly

---

> [!TIP]
> [Bring your own repo](../../setup.md#bring-your-own-repo): point both relay workflows at a repo you own so `repo-memory` holds real issue and label metrics the team can keep using.

---

## Activity

Build two workflows that work together:

### Producer Workflow: `daily-metrics-collector.md`

Triggers daily and collects issue metrics:
- Current open issue count
- Average time-to-close for recently closed issues (last 7 days)
- Distribution of labels (top 5)

Write this data as a JSON snapshot to `repo-memory` with a timestamped filename (e.g., `repo-memory/metrics/2026-05-28.json`).

Use `safe-outputs: noop`. This workflow stores data and produces no user-facing output.

Success: File appears in `repo-memory/` branch with correct JSON structure.

### Consumer Workflow: `weekly-metrics-report.md`

Triggers weekly (or manually via `workflow_dispatch`) and:
1. Reads the last 7 JSON snapshots from `repo-memory/metrics/`
2. Analyzes the trend (is issue volume trending up or down?)
3. Creates a discussion with a summary: "This week, we closed {X} issues. Average time-to-close is {Y} days, trending {direction}."

Use `safe-outputs: create-discussion`.

Success: Discussion appears with the trend analysis.

---

## Tips & Troubleshooting

- `repo-memory` is a real branch — browse it on GitHub to confirm files were written. If it's missing, check the workflow logs first.
- The `file-glob` filter in `tools: repo-memory:` silently drops non-matching files; test the glob (e.g. `echo metrics/**/*.json`) if the consumer can't read anything.
- Use simple `gh api` calls for the producer's issue counts — no need to parse the whole repo.
- Compute the trend by comparing the first and last of the last 7 snapshots ("up"/"down"/"stable").
- Use `expires:` on the discussion to auto-close old reports.

---

## References

- repo-memory Reference: https://github.github.com/gh-aw/reference/repo-memory/
- Metrics Collector Example: https://github.com/github/gh-aw/blob/main/.github/workflows/metrics-collector.md
- Agent Performance Analyzer (Consumer Example): https://github.com/github/gh-aw/blob/main/.github/workflows/agent-performance-analyzer.md
- Safe Outputs Reference: https://github.github.com/gh-aw/reference/safe-outputs/
- Schedule Syntax: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#onschedule
