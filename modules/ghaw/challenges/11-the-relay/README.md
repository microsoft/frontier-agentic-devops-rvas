# Challenge 3-01: The Relay

**Track:** Continuous Intelligence (Advanced)  
**Difficulty:** 🔴 Advanced  
**Estimated time:** 30 minutes  
**Prerequisites:** Track 2, completed ≥3 challenges

---

## Background

By default, each workflow runs independently — it triggers, does its work, and exits. If you need two workflows to coordinate, one has to leave something behind for the other to pick up.

**The Relay** is about **workflow chaining**. You'll build two workflows: a **producer** (collects data, writes to `repo-memory`) and a **consumer** (reads that data, takes action). The producer runs first and writes a structured file; the consumer reads it on its next trigger.

**Why this matters:** Workflow chaining lets you break complex automation into stages with clear hand-off points — each stage reads what the previous one wrote, validates it, and adds its own output. Debugging is easier (one stage at a time), reuse is cleaner (a producer used by two consumers), and failures are isolated to the stage that actually broke.

---

## Goals

By the end of this challenge, your squad will:

1. ✅ Build a **producer workflow** that writes structured data to `repo-memory`
2. ✅ Build a **consumer workflow** that reads from `repo-memory` and takes action
3. ✅ Understand the `tools: repo-memory` configuration and its `file-glob` patterns
4. ✅ See how workflows can communicate without direct coupling

---

> [!IMPORTANT]
> **Bring your own repo (do this first)**
>
> This challenge is most valuable when the producer and consumer workflows exchange **your own repository's** real metrics, so `repo-memory` becomes a durable signal your team can keep using after the session. Treat the setup sample as practice, not the default destination.
>
> - **Have a candidate repo?** Install or point both relay workflows at that repo everywhere the guide references the sample repo, and collect metrics from its real issues, labels, closure history, and Discussions audience.
> - **No suitable repo yet?** Use the provided sample repo from setup as the safe practice target.
>
> Tell your coach which path you took — bringing your own is the goal; the sample repo is the fallback.

---

## Challenge

Build two workflows that work together:

### Producer Workflow: `daily-metrics-collector.md`

Triggers **daily** and collects issue metrics:
- Current open issue count
- Average time-to-close for recently closed issues (last 7 days)
- Distribution of labels (top 5)

Write this data as a JSON snapshot to `repo-memory` with a timestamped filename (e.g., `repo-memory/metrics/2026-05-28.json`).

Use `safe-outputs: noop` (this is a data-collection workflow—no user-facing output, just persistence).

**Success:** File appears in `repo-memory/` branch with correct JSON structure.

### Consumer Workflow: `weekly-metrics-report.md`

Triggers **weekly** (or manually via `workflow_dispatch`) and:
1. Reads the last 7 JSON snapshots from `repo-memory/metrics/`
2. Analyzes the trend (is issue volume trending up or down?)
3. Creates a **discussion** with a summary: "This week, we closed {X} issues. Average time-to-close is {Y} days, trending {direction}."

Use `safe-outputs: create-discussion`.

**Success:** Discussion appears with the trend analysis.

---

## Success Criteria

**Producer Workflow:**
- [ ] Daily trigger works (`on: schedule:`)
- [ ] JSON file written to `repo-memory/metrics/{date}.json` with correct structure
- [ ] Workflow runs without errors (check Actions logs)
- [ ] `safe-outputs: noop` is called

**Consumer Workflow:**
- [ ] Weekly trigger works
- [ ] Reads from `repo-memory` using `file-glob: metrics/**/*.json`
- [ ] Discussion created with trend analysis
- [ ] Workflow correctly interprets the JSON from the producer

**Together:**
- [ ] Producer runs, data appears in `repo-memory/`
- [ ] Consumer reads that data and creates a discussion referencing the metrics
- [ ] The two workflows are not directly coupled (consumer doesn't know producer's name)
- [ ] Coach conversation — what complex automation are you tempted to build as one giant agent that would be safer split into a producer and a consumer passing state, and where would you put the checkpoint between them? Talk it through with your coach and connect it to a real project, task, or workflow you own.

---

## Tips & Hints

- `repo-memory` is a branch in your repo (`repo-memory`). You can browse it on GitHub to verify files were written.
- The `file-glob` filter in the `tools: repo-memory:` block **silently drops** files that don't match—always double-check your glob pattern.
- For the producer: use simple `gh api` calls or the GitHub MCP tool to fetch issue counts. You don't need to parse the entire repo.
- For the consumer: the agent reads JSON and should summarize the trend in plain language. Don't overthink the analysis—"up", "down", or "stable" is enough.
- Use `expires:` on the discussion to auto-close old reports (keeps the page clean).
- The simplest producer outputs a 5-10 line JSON file. The consumer reads 7 of them and compares. That's it.

---

## References

- **repo-memory Reference:** https://github.github.com/gh-aw/reference/repo-memory/
- **Metrics Collector Example:** https://github.com/github/gh-aw/blob/main/.github/workflows/metrics-collector.md
- **Agent Performance Analyzer (Consumer Example):** https://github.com/github/gh-aw/blob/main/.github/workflows/agent-performance-analyzer.md
- **Safe Outputs Reference:** https://github.github.com/gh-aw/reference/safe-outputs/
- **Schedule Syntax:** https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions#onschedule

---

## Help

Stuck? Here's how to escalate:

- **"repo-memory branch not showing up?"** → Check the workflow logs. If `noop` or the safe-output succeeded, the branch should exist. Refresh the GitHub repo page.
- **"JSON file has the wrong structure?"** → Print the JSON in the workflow logs (use `echo` before writing) so you can see what the agent generated.
- **"Consumer can't read the files?"** → Verify the `file-glob` pattern matches. Run `echo metrics/**/*.json` to test the glob locally.
- **"I'm not sure how to compute the trend?"** → Read the last N files, compare the first value to the last value. If latest > first, it's "up". Simple as that.

Still stuck after 20 minutes? Raise your hand for your coach.
