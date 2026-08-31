# Activity 3-01: The Relay

Track: Continuous Intelligence (Advanced)  
Difficulty: 🔴 Advanced  
Estimated time: 30 minutes  
Prerequisites: Track 2, completed ≥3 activities

---

## Background

Each workflow normally runs on its own. To coordinate two workflows, the first must leave data that the second can read.

Build a producer that writes structured data to `repo-memory` and a consumer that reads it on its next trigger.

Workflow chaining splits automation into stages with explicit handoffs. You can test each stage separately, reuse producers, and see which stage failed.

---

## What you'll practice

1. Build a producer workflow that writes structured data to `repo-memory`
2. Build a consumer workflow that reads the data and acts on it
3. Configure `tools: repo-memory` and its `file-glob` patterns
4. Pass data between workflows without coupling them directly

---

> [!IMPORTANT]
> Bring your own repo (do this first)
>
> Use your own repository if possible. Exchange real metrics so `repo-memory` contains data the team may keep using. Use the setup sample only for practice.
>
> - Have a candidate repo? Install or point both relay workflows at that repo everywhere the guide references the sample repo, and collect metrics from its real issues, labels, closure history, and Discussions audience.
> - No suitable repo yet? Use the provided sample repo from setup as the safe practice target.
>
> Tell the facilitator which repository and metrics you chose.

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

## Success Criteria

Producer Workflow:
- [ ] Daily trigger works (`on: schedule:`)
- [ ] JSON file written to `repo-memory/metrics/{date}.json` with correct structure
- [ ] Workflow runs without errors (check Actions logs)
- [ ] `safe-outputs: noop` is called

Consumer Workflow:
- [ ] Weekly trigger works
- [ ] Reads from `repo-memory` using `file-glob: metrics/**/*.json`
- [ ] Discussion created with trend analysis
- [ ] Workflow correctly interprets the JSON from the producer

Together:
- [ ] Producer runs, data appears in `repo-memory/`
- [ ] Consumer reads that data and creates a discussion referencing the metrics
- [ ] The two workflows are not directly coupled (consumer doesn't know producer's name)
- [ ] Using a project, task, or workflow you own, identify automation that should be split into a producer and consumer, and choose the checkpoint between them.

---

## Tips & Hints

- `repo-memory` is a branch in your repo (`repo-memory`). You can browse it on GitHub to verify files were written.
- The `file-glob` filter in the `tools: repo-memory:` block silently drops files that do not match. Check the glob carefully.
- For the producer: use simple `gh api` calls or the GitHub MCP tool to fetch issue counts. You don't need to parse the entire repo.
- For the consumer, summarize the JSON trend as "up," "down," or "stable."
- Use `expires:` on the discussion to auto-close old reports (keeps the page clean).
- The simplest producer outputs a 5-10 line JSON file. The consumer reads 7 of them and compares. That's it.

---

## References

- repo-memory Reference: https://github.github.com/gh-aw/reference/repo-memory/
- Metrics Collector Example: https://github.com/github/gh-aw/blob/main/.github/workflows/metrics-collector.md
- Agent Performance Analyzer (Consumer Example): https://github.com/github/gh-aw/blob/main/.github/workflows/agent-performance-analyzer.md
- Safe Outputs Reference: https://github.github.com/gh-aw/reference/safe-outputs/
- Schedule Syntax: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#onschedule

---

## Help

Use these checks if the workflow fails:

- "repo-memory branch not showing up?" → Check the workflow logs. If `noop` or the safe-output succeeded, the branch should exist. Refresh the GitHub repo page.
- "JSON file has the wrong structure?" → Print the JSON in the workflow logs (use `echo` before writing) so you can see what the agent generated.
- "Consumer can't read the files?" → Verify the `file-glob` pattern matches. Run `echo metrics/**/*.json` to test the glob locally.
- "I'm not sure how to compute the trend?" → Read the last N files, compare the first value to the last value. If latest > first, it's "up". Simple as that.

After 20 minutes, ask your coach.
