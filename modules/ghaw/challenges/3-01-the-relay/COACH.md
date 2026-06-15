# Coach Guide: Challenge 3-01 — The Relay

---

## Coaching Philosophy for This Challenge

This is the **first Advanced challenge**. Squads coming from Track 2 have seen event triggers, safe-outputs variety, and basic AI integration. Now you're asking them to think in **systems**—multiple workflows talking to each other.

Your job: Build confidence that workflow chaining is not magic, it's just data + contracts. One workflow writes JSON, another reads it. They don't know about each other, but they work together.

**Key rule:** Celebrate the "aha moment" when the consumer reads the producer's data. That's the win.

---

## Expected Outcomes

A finished solution has:

**Producer Workflow (`daily-metrics-collector.md`)**
- ~25-35 lines (frontmatter + body)
- Runs daily via `on: schedule: cron: "0 9 * * *"` (or similar)
- Uses `tools: github: toolsets: [issues]` to fetch counts
- Writes JSON to `repo-memory/metrics/YYYY-MM-DD.json` with structure: `{ "open_count": N, "closed_last_7d": N, "avg_days_to_close": X, "top_labels": [...] }`
- Calls `safe-outputs: noop`
- Logs confirm: "Wrote snapshot to repo-memory"

**Consumer Workflow (`weekly-metrics-report.md`)**
- ~30-40 lines
- Runs weekly via `on: schedule: cron: "0 10 * * 1"` (Monday at 10 AM)
- Uses `tools: repo-memory: file-glob: metrics/**/*.json`
- Reads 7 JSON files, computes trend (first vs last value)
- Creates discussion with: "This week we closed {X} issues. Trend: {up|down|stable}."
- Uses `safe-outputs: create-discussion: expires: 7d`

**Example output (Discussion):**
```
Title: Weekly Metrics Report
Category: Reports

Body:
Metrics for the week ending 2026-05-28:
- Open issues: 47 (trend: up from 43)
- Avg time-to-close: 3.2 days (trend: stable)
- Top labels: bug, enhancement, documentation

This week we closed 18 issues and opened 22. Good momentum!
```

---

## Common Approaches

Squads will vary in how they compute metrics. All of these are fine:

### Approach 1: "Simple Count" (most common)
Producer: Just counts open issues, doesn't compute time-to-close. Consumer: Shows open-count trend.

**Pros:** Fast, easy to understand, focuses on the pattern not the sophistication
**Cons:** Doesn't showcase the full potential (but that's OK for an intro challenge)

### Approach 2: "Full Analytics"
Producer: Computes multiple metrics including time-to-close, label distribution, etc. Consumer: Multi-chart analysis.

**Pros:** Richer data, better demo
**Cons:** More complexity, but not wrong

### Approach 3: "CSV Instead of JSON"
Producer writes a single CSV file instead of per-day JSON files.

**Pros:** Still demonstrates repo-memory persistence
**Cons:** Harder to trend (less idiomatic for gh-aw)

**Coach guidance:** Prefer JSON over CSV, but don't penalize CSV if they get it working.

---

## Common Pitfalls & Socratic Responses

### Pitfall 1: `repo-memory` branch doesn't show up
**Symptom:** Producer runs successfully (logs say "noop called"), but no `repo-memory/` branch appears in GitHub.

**Root cause:** `safe-outputs: noop` was called, but no `create-*` output wrote data, or the file glob filtered it out.

**Coach response:**
- "Let's check: did your workflow actually write the JSON file before calling noop?"
- Have them add a `echo $JSON_DATA` to the logs so we can see what was written
- "Does the file path match your `file-glob` pattern? Show me the pattern in the frontmatter."

### Pitfall 2: File glob filter silently drops files
**Symptom:** Producer is writing files to `repo-memory/`, but consumer can't read them. Logs show "No files matched glob."

**Root cause:** The `file-glob` in `tools: repo-memory:` doesn't match the file paths the producer is writing.

**Coach response:**
- This is the "critical gotcha" in the dossier. Point it out explicitly.
- "repo-memory has a glob filter. If your file path doesn't match, it gets silently dropped—no error, no warning. Classic silent failure."
- Have them verify: "What path did the producer write? What glob did you specify?"
- Example fix: Producer writes to `repo-memory/metrics/2026-05-28.json`, consumer uses `file-glob: metrics/**/*.json`

### Pitfall 3: Consumer can't parse the JSON
**Symptom:** Consumer workflow runs, but agent errors with "Invalid JSON" or "Can't read files".

**Root cause:** Producer generated malformed JSON, or consumer's instructions didn't tell it how to read the files.

**Coach response:**
- "Let's look at what the producer wrote. Can you manually check a file in the repo-memory branch?"
- If malformed: "Have the agent print the first 50 lines of each file before parsing."
- If consumer isn't looking for files: "Your instructions need to tell the agent: 'Read all JSON files from repo-memory and compare the values.' Be explicit."

### Pitfall 4: Trend analysis is vague
**Symptom:** Consumer creates a discussion but the trend is confused or missing.

**Root cause:** Agent wasn't given clear instructions on how to compute trend (compare first to last, look at slope, etc.).

**Coach response:**
- "What does 'trend' mean to your agent? Is it clear in the prompt?"
- Suggest: "If the latest value is higher than the first, write 'up'. Lower = 'down'. Same ±10% = 'stable'."
- Simple heuristics work great here.

### Pitfall 5: Forgot to use `noop` on producer
**Symptom:** Producer workflow fails with "No output generated" error.

**Root cause:** Agent produced no safe-output. Even data-collection workflows **must** call a safe-output (usually `noop`).

**Coach response:**
- "Every gh-aw workflow must call a safe-output before exiting. For a data-collection workflow, that's `noop`."
- Show the sample solution (below): `safe-outputs: noop:` in frontmatter, and the agent should end with "Task complete. Calling noop."

### Pitfall 6: Multiple instances of consumer conflict
**Symptom:** Two weekly runs start at the same time and create duplicate discussions.

**Root cause:** No `lock-for-agent` protection, and `close-older-discussions: false`.

**Coach response:**
- "This is a scheduling issue. If the consumer runs twice simultaneously, it creates duplicate reports."
- "Use `safe-outputs: create-discussion: max: 1, close-older-discussions: true` to ensure only one active report."
- "Or add `lock-for-agent: true` to the trigger (though for a scheduled workflow, max/close-older is better)."

### Pitfall 7: Hardcoded assumptions about 7 days of data
**Symptom:** Consumer assumes exactly 7 files exist, crashes if there are fewer (e.g., first week running).

**Root cause:** No defensive check for available data.

**Coach response:**
- "What if this is the first week and there's only 1 data file?"
- Guide: "Your agent should check how many files exist and adjust. E.g., 'If fewer than 3 files, say "Not enough data yet"'."
- This is good defensive programming.

---

## Coaching Questions (Use These if Squad is Stuck)

1. **"Have you verified the producer wrote any files?"** → Check the Actions logs for the echo/print statement
2. **"What's the file path the producer is writing?"** → Have them show the code
3. **"What glob pattern did you use?"** → Have them show the frontmatter
4. **"Does the glob match the path?"** → Walk through the pattern matching (e.g., `metrics/**/*.json` matches `metrics/2026-05-28.json`? Yes.)
5. **"Did you call `safe-outputs: noop:` on the producer?"** → Check for the mandatory output
6. **"Can you manually browse the `repo-memory` branch and see the files?"** → GitHub UI verification
7. **"What does your agent instruction say about reading the JSON?"** → Read their prompt out loud; it often reveals vague instructions

---

## Sample Solution

Share this **only if a squad is stuck for >20 minutes**. Have them type it, not copy-paste.

**Producer: `daily-metrics-collector.md`**

```markdown
---
on:
  schedule:
    - cron: '0 9 * * *'

permissions:
  contents: read
  issues: read

safe-outputs:
  noop:

tools:
  github:
    toolsets: [issues]
  repo-memory:
    file-glob: 'metrics/**/*.json'

engines:
  - copilot
---

# Daily Metrics Collector

Collect issue statistics and persist to repo-memory.

Use the GitHub API to fetch:
1. Current count of open issues
2. Count of issues closed in the last 7 days
3. List of the top 5 most common labels

Format the data as a JSON object:
```json
{
  "date": "2026-05-28",
  "open_count": 47,
  "closed_last_7d": 18,
  "top_labels": ["bug", "enhancement", "documentation", "question", "help-wanted"]
}
```

Write this to a file in repo-memory at `metrics/{date}.json` where {date} is today's date in YYYY-MM-DD format.

After writing the file, call the noop safe-output to complete the workflow.
```

**Consumer: `weekly-metrics-report.md`**

```markdown
---
on:
  schedule:
    - cron: '0 10 * * 1'
  workflow_dispatch:

permissions:
  contents: read

safe-outputs:
  create-discussion:
    category: reports
    expires: 7d

tools:
  repo-memory:
    file-glob: 'metrics/**/*.json'

engines:
  - copilot
---

# Weekly Metrics Report

Read the last 7 JSON metric snapshots from repo-memory and create a weekly report.

Load all JSON files from repo-memory/metrics/. Sort by date (newest first).

If fewer than 3 files exist, create a discussion saying "Not enough data yet."

If 3+ files exist:
1. Take the oldest and newest values
2. Compare: if newest_open_count > oldest_open_count, trend is "up". Lower = "down". ±10% = "stable".
3. Create a discussion titled "Weekly Metrics Report" with:
   - The date range (oldest date to newest date)
   - Open issue count and trend
   - Top labels from the latest snapshot
   - A short summary comment

Keep the body to 5-10 sentences. Use bullet points for readability.
```

---

## Why This Works

- **Producer frontmatter:** Minimal permissions (read-only), clear `tools: repo-memory`, `safe-outputs: noop`
- **Consumer frontmatter:** Also read-only, matches the producer's `file-glob`, creates a discussion with `expires: 7d`
- **Architecture:** Producer writes daily, consumer reads weekly—no coupling, they don't know about each other
- **Pattern:** This is the "infrastructure agent" pattern—write once, read many times

---

## Time Management

Suggest this breakdown:

| Phase | Time | What to Do |
|-------|------|-----------|
| Read & orient | 5 min | Understand producer-consumer pattern; ask q's |
| Plan the design | 5 min | Sketch: What data? What format? Daily/Weekly schedule? |
| Write producer | 10 min | Build and test the data-collection workflow |
| Write consumer | 8 min | Build and test the reading+analysis workflow |
| Verify end-to-end | 2 min | Run producer, wait for data, run consumer, check discussion |

**Total: ~30 minutes.**

If done early: offer extensions (see below).

---

## Extension Ideas (for Fast Squads)

1. **Add a `pre-agent-step` that computes statistics:** Use Python + pandas in a pre-step to generate charts (matplotlib) before the agent even runs.

2. **Deploy a 3-workflow chain:** Add a third workflow that reads the consumer's discussion and sends a Slack message (simulated with an issue).

3. **Experiment with different `max-effective-tokens`:** The consumer reads multiple files; see how the model responds with 5000 vs 20000 tokens.

4. **Add confidence scoring:** Have the consumer note how confident it is in the trend ("Trend: UP with 90% confidence based on 7 data points").

5. **Cross-repo metrics:** If they're ambitious, have the producer fetch metrics from 2-3 other repos and aggregate them into a single snapshot.

---

## Debugging Checklist

If a squad is truly stuck:

- [ ] Producer has `on: schedule:` trigger? (`gh workflow list`)
- [ ] Producer has `safe-outputs: noop:`?
- [ ] Producer has `tools: repo-memory: file-glob:` matching the path it writes?
- [ ] Does the `repo-memory` branch exist in GitHub? (Settings → Branches)
- [ ] Can you manually check one JSON file on the `repo-memory` branch?
- [ ] Is the JSON valid? (Can you copy it and validate with `jq` locally?)
- [ ] Consumer has `tools: repo-memory: file-glob:` matching producer's output?
- [ ] Consumer has `on: schedule:` trigger for weekly?
- [ ] Consumer creates the discussion? (Check GitHub Discussions tab)

---

## Key Takeaways for Coaches

- **The "aha moment":** When the consumer reads the producer's data and creates a report, the squad will get it. That's the win.
- **Silent failures are the enemy:** The `repo-memory` glob filter is the biggest gotcha—it silently drops files. Point it out explicitly.
- **Simplicity wins:** A squad that writes 5 JSON fields and reads them correctly is better than one that tries to be fancy and fails. Celebrate the simple wins.
- **This is the foundation:** Producer-consumer patterns unlock everything ahead — meta-workflows, orchestration, state machines. Build confidence here.
