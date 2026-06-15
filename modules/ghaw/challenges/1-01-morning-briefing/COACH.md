# Coach Guide: Challenge 1-01 — Morning Briefing

---

## Coaching Philosophy

This challenge introduces **scheduled triggers** and the **GitHub MCP tool** for querying repo data. Your role is to guide squads through the mental model: cron schedules fire at fixed times, the GitHub tool reads data, and the agent synthesizes that into human-friendly output.

**Key rule:** This should feel like building on Challenge 00, not a leap. If a squad is stuck on cron syntax or the tool, that's on the system design—give them a cheat sheet and move on.

---

## Common Pitfalls & Coaching Responses

### Pitfall 1: Incorrect cron syntax
**Symptom:** Workflow compiled fine, but it never fires at the expected time. Or it fires at the wrong time.

**Root cause:** Cron expression typo or misunderstanding of day-of-week encoding (0=Sunday, 1-5=Mon-Fri, 6=Saturday).

**Coach response:**
- "Let's check your cron expression. What did you write?"
- Have them verify on crontab.guru — it shows next 5 execution times.
- Common fix: `0 9 * * 1-5` for weekdays at 9 AM UTC
- Remind: GitHub Actions cron runs in UTC; if they want local time, they'll need to adjust.

---

### Pitfall 2: No `workflow_dispatch:` for testing
**Symptom:** Squad can't test because they have to wait for the cron schedule to fire.

**Root cause:** They only added `on: schedule:` but not `on: workflow_dispatch:`

**Coach response:**
- "You can add `workflow_dispatch:` alongside `schedule:` so you can test manually from the Actions tab."
- Show them: in the Actions tab, there's a "Run workflow" button when `workflow_dispatch:` is present.
- This is a best practice for schedulable workflows — always include manual trigger.

---

### Pitfall 3: Trying to call GitHub API directly instead of using the tool
**Symptom:** They use `curl` or `gh api` in the workflow body.

**Root cause:** They're thinking like a GitHub Actions user, not an agentic workflow user.

**Coach response:**
- "I notice you're calling `gh api` directly. That's not wrong, but gh-aw has a better pattern: the GitHub MCP tool."
- Explain: "When you add `tools: github: toolsets: [issues, pull_requests]`, the AI agent can query those without you writing API calls. The agent knows how to ask for 'issues opened in the last 24 hours' and the tool gives it the answer."
- Show the tool reference: https://github.github.com/gh-aw/reference/tools/github/

---

### Pitfall 4: Overly complex summarization instructions
**Symptom:** Agent produces a verbose, repetitive summary or gets confused about what counts as "high-priority".

**Root cause:** Prompt is too ambitious or uses undefined terms ("high-priority" to whom?).

**Coach response:**
- "What do you actually want the agent to tell your team in that briefing?"
- Guide them to: "Tell them the count of opened issues, count of closed issues, count of opened PRs, and a 2-sentence note about any blockers if present."
- Simpler prompts = more reliable results. They can iterate later.

---

### Pitfall 5: Permissions still set to `write-all`
**Symptom:** Workflow has overly permissive permissions when it should be read-only.

**Root cause:** Copy-paste from Challenge 00 or misunderstanding that `safe-outputs` needs permissions too.

**Coach response:**
- "You have `permissions: write-all`. For this workflow, what do you need to write?"
- Guide: "You read issues/PRs (read permission), and `safe-outputs: create-issue:` handles the write. So use `contents: read`."
- Reinforce: "safe-outputs has its own permission model. Your workflow code = minimal permissions. safe-outputs = explicit, bounded writes."

---

### Pitfall 6: Missing the GitHub tool declaration
**Symptom:** Workflow compiles, but the agent has no access to issue/PR data.

**Root cause:** They forgot to add `tools: github: toolsets: [issues, pull_requests]` in frontmatter.

**Coach response:**
- "How is the agent supposed to access issue/PR data?"
- Guide them: "You need to declare which tools the agent can use. Add `tools: github: toolsets: [issues, pull_requests]` in your frontmatter."
- Show them the tool reference and explain toolsets are like a permission model for the agent.

---

## Sample Solution

Here's a working `morning-briefing.md` workflow. Share this only if a squad is stuck after 25+ minutes:

```markdown
---
on:
  schedule:
    - cron: '0 9 * * 1-5'
  workflow_dispatch:

permissions:
  contents: read

safe-outputs:
  create-issue:
    title-prefix: '[Morning Briefing] '

engines:
  - copilot

tools:
  github:
    toolsets:
      - issues
      - pull_requests
---

# Morning Briefing

Query the repository for activity in the last 24 hours:
1. Find all issues opened in the last 24 hours
2. Find all issues closed in the last 24 hours
3. Find all pull requests opened in the last 24 hours
4. Find all pull requests merged/closed in the last 24 hours

Then create a GitHub issue titled "Morning Briefing for [today's date]" with a summary:

**Summary format:**
- Issues Opened: [count]
- Issues Closed: [count]
- PRs Opened: [count]
- PRs Merged: [count]

If there are any issues or PRs with high activity (more than 3 comments), mention the top 2 by title.

Keep the summary concise — 5-7 sentences total.
```

**Why this works:**
- `on: schedule:` with cron + `workflow_dispatch:` for testing
- `permissions: contents: read` — minimal and safe
- `tools: github: toolsets: [issues, pull_requests]` — agent can query data
- `safe-outputs: create-issue:` with title prefix — consistent naming
- Body: clear, structured instructions with specific counts to gather and format
- `engines: [copilot]` — free, reliable default

**Production-ready reference solution:** See `coaches/sample-solutions/track-1/1-01-morning-briefing.md`

---

## Time Management

Suggest this breakdown:

| Phase | Time | What to Do |
|-------|------|-----------|
| Read & orient | 5 min | Discuss cron syntax; test crontab.guru together |
| Write the .md file | 8 min | Create frontmatter + body; check tool declaration |
| Compile & test | 5 min | Run `gh aw compile`, fix any YAML errors |
| Manual trigger | 10 min | Add `workflow_dispatch`, run manually to see results |
| Debug & refine | 2 min | Adjust summary instructions if needed |

**Total: ~30 minutes.**

If they finish early, offer extensions.

---

## Debugging Checklist

If a squad is stuck:

- [ ] Does the cron expression parse correctly? (check crontab.guru)
- [ ] Is `workflow_dispatch:` present so they can test manually?
- [ ] Are `tools: github: toolsets:` declared in frontmatter?
- [ ] Is `permissions: contents: read` or similar (not overpermissioned)?
- [ ] Did `gh aw compile` produce `.lock.yml` without errors?
- [ ] Did they manually trigger via Actions tab? (if yes, check run logs)
- [ ] Do the logs show the agent querying issues/PRs? (indicates tool access works)
- [ ] Was an issue created? (check the Issues tab)
- [ ] Does the issue body have the summary? (indicates agent understood the prompt)

---

## Extension Ideas

If a squad finishes early:

1. **Add time-of-day customization:** Parameterize the cron time (e.g., "9 AM on weekdays" → let them change the `0 9` part and redeploy)
   - Concept: understanding cron flexibility

2. **Add a label to the briefing issue:** Use `safe-outputs: create-issue: labels: [briefing, automated]`
   - Concept: structured safe-outputs configuration

3. **Skip briefing if no activity:** Have the agent decide whether to create the issue (e.g., "only create if there were >0 changes in the last 24h")
   - Concept: conditional safe-output logic in natural language

4. **Include code metrics:** Add `tools: bash: allow: [git log:*, wc:*]` and have the agent count commits/lines changed
   - Concept: multi-tool workflows

5. **Post to Discussions instead of Issues:** Use `safe-outputs: create-discussion:` and make it a weekly (not daily) recurring briefing
   - Concept: different safe-output types, weekly vs daily cadence

---

## Key Takeaways for Coaches

- **Scheduled workflows are foundational:** Once this works, squads understand the heartbeat of automation.
- **Tool queries are AI's superpower:** The GitHub tool frees them from API calls; the agent synthesizes meaning.
- **Test manually first:** Don't let them wait for cron; use `workflow_dispatch` to iterate faster.
- **Celebrate first automation:** When the morning briefing issue appears, that's the win — they just built recurring automation with natural language.
