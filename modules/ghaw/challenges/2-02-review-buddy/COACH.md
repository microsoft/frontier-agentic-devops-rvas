# Coach Guide: Challenge 2-02 — Review Buddy

---

## Coaching Philosophy

This challenge deepens the event-driven pattern from 2-01 while teaching **PR-specific context access**. Squads move from issue analysis to pull request diff analysis—a natural progression. Your role: help them see that analyzing *metadata* (file count, line changes) is easier and cheaper than analyzing code semantics.

**Key rule:** By minute 25, every squad should see a comment on a test PR. The comment should feel like a helpful colleague, not a bot.

---

## Expected Outcomes

A finished solution has these characteristics:

**File structure:**
- `.github/workflows/review-buddy.md` — ~30–40 lines (frontmatter + body)
- `.github/workflows/review-buddy.lock.yml` — auto-generated, ~70–90 lines

**Behavior:**
- Workflow runs on PR open (visible in Actions tab)
- A comment appears on the PR within 30 seconds
- Comment includes:
  - Greeting + thank you
  - Summary of changes (e.g., "5 files, 200 additions, 50 deletions")
  - 2–3 observations (scope, test coverage, description quality)
  - Encouragement

**Example outcome:**
```
Thanks for opening this PR! Here's what I see:

📊 **Changes:** 3 files modified, 145 additions, 32 deletions

✅ **Observations:**
- Good scope — these changes are focused on one feature
- Tests included — the test file has been updated
- Description is clear and actionable

Looking forward to reviewing this! 🚀
```

---

## Common Approaches

All valid.

### Approach 1: Metadata-Only Analysis (Most Common)

Body provides metadata (file count, line count) and asks AI to comment:

```
This PR has {file_count} files changed, {additions} additions, {deletions} deletions.
Write a friendly review comment. Include observations about:
- Whether this is a focused or large change
- Whether test files are included
- Whether the description is clear
```

**Pros:** Simple, predictable, teaches metadata extraction  
**Cons:** Less sophisticated reasoning

### Approach 2: Guided Observations

Body lists specific things to look for:

```
Look at this PR and note:
1. Is this a small/medium/large change?
2. Are tests included?
3. Is the description complete and clear?

Then write a friendly comment with these observations.
```

**Pros:** Clear, structured, good learning  
**Cons:** Slightly prescriptive

### Approach 3: Diff Deep-Dive

Squad checks out the repo and analyzes actual code:

```
on:
  pull_request:
    types: [opened]

checkout: true  # instead of false
```

Then agent reads files and analyzes code quality.

**Pros:** More sophisticated (educational for Track 3)  
**Cons:** Slower (30–60s checkout overhead); overkill for 2-02

---

## Common Pitfalls & Socratic Responses

### Pitfall 1: Workflow Doesn't Trigger on PR

**Symptom:** Squad creates test PR; nothing happens.

**Root cause:** Used `on: issues:` instead of `on: pull_request:`, or typo in trigger.

**Coach response:**
- "You used `on: issues:` — but we're working with PRs now. Should be `on: pull_request:`"
- Show difference: `issues` (for GitHub Issues), `pull_request` (for PRs)
- Have them recompile and create a fresh test PR

### Pitfall 2: Comment Is Generic ("Good PR")

**Symptom:** Comment appears, but it's vague or robotic.

**Root cause:** Squad didn't include specific observations.

**Coach response:**
- "Read the comment. Would you find this useful as a PR author?"
- "Instead of 'Good PR', try: 'This is well-scoped — 3 files, clear intent'"
- Ask: "What did you notice about this PR? Tell me three things."

### Pitfall 3: Agent Can't Access PR Stats

**Symptom:** Comment doesn't mention file count or line changes.

**Root cause:** Squad doesn't know how to access `github.event.pull_request.*` context.

**Coach response:**
- "The PR metadata is available in the GitHub context. In your instructions, reference `{files_changed}`, `{additions}`, `{deletions}`"
- Point to: https://docs.github.com/en/actions/learn-github-actions/contexts#github-context
- Suggest starting sentence: "This PR modifies {N} files..."

### Pitfall 4: Checkout is Enabled but Not Needed

**Symptom:** Workflow is slow (>60 seconds) or fails with permission errors.

**Root cause:** `checkout: true` is set unnecessarily (agent only needs metadata).

**Coach response:**
- "Do you need to read the actual code files?"
- If no: "Set `checkout: false`. It saves time and reduces permissions needed."
- Emphasize: "Most PR analysis can happen with metadata alone"

### Pitfall 5: Multiple Comments Posted

**Symptom:** Several copies of the same comment appear on the PR.

**Root cause:** Workflow ran multiple times (unlikely in practice), or body says "post a comment" multiple times.

**Coach response:**
- "Check the Actions tab — did the workflow run more than once?"
- Usually: "This is a known edge case. For now, you can manually delete duplicate comments. In production, workflows have concurrency controls."

### Pitfall 6: Overly Critical Tone

**Symptom:** Comment reads harsh or discouraging (e.g., "This is too big" without balance).

**Root cause:** Squads forget this is a *buddy*, not a gatekeeper.

**Coach response:**
- "You're being helpful, not judging. Rewrite tone to be collaborative."
- Instead of: "This is too big", try: "This is a significant change — reviewers may take a bit longer, but it looks well-organized"

---

## Sample Solution

This is a complete, working `review-buddy.md`. Share **only after 20+ min of struggle**; ask them to type it out.

```markdown
---
on:
  pull_request:
    types: [opened]

permissions:
  pull-requests: read

safe-outputs:
  add-comment: {}

engines:
  - copilot
---

# Review Buddy

Welcome a new pull request with a friendly comment. 

Analyze the PR and provide observations about:
1. The scope (how many files, how many lines changed — is it focused or large?)
2. Test coverage (are test files included or modified?)
3. Description quality (is it complete and clear, or does it need more detail?)

Write a warm, encouraging comment that:
- Thanks the author
- Summarizes the change (e.g., "{X} files, {Y} additions, {Z} deletions")
- Shares 2-3 observations
- Encourages the author

Tone: helpful colleague, not gatekeeper.
```

**Why this works:**
- `on: pull_request: types: [opened]` — fires when new PR created
- `permissions: pull-requests: read` — can read PR metadata
- `checkout: false` (implicit) — doesn't need code, saves time
- `safe-outputs: add-comment: {}` — can post a single comment
- Body: natural language, clear observations, emphasizes warmth
- `engines: [copilot]` — free, reliable

---

## Time Management

| Phase | Time | What to Do |
|-------|------|-----------|
| Read & orient | 3 min | Read challenge, understand PR triggers |
| Write frontmatter | 4 min | Set up `on: pull_request:`, `permissions`, `safe-outputs`, `engines` |
| Write body | 6 min | Draft observations + comment template |
| Compile & test | 8 min | Compile, create test PR, watch Actions tab |
| Refine tone | 6 min | Read comment, improve warmth/specificity |
| Celebrate | 3 min | Discuss learnings |

**Total: ~30 minutes.**

---

## Extension Ideas (for Fast Squads)

If finished in <20 minutes:

1. **Add a label by PR size:** Use `safe-outputs: add-labels:` to tag PR with `size/small`, `size/medium`, `size/large`
   - **Concept:** Combining event triggers with labeling

2. **Check for test files:** If test files aren't touched, suggest adding tests
   - **Concept:** Conditional suggestions based on analysis

3. **Draft message to commit:** Use `safe-outputs: create-comment:` on a PR commit directly (vs. the PR itself)
   - **Concept:** Different safe-outputs targets

4. **Schedule a follow-up review:** Have the workflow post a second comment 48h later asking "Any feedback from reviewers yet?"
   - **Concept:** Combining `on: pull_request:` with `on: schedule:` in the same workflow

5. **Port to issues:** Create a parallel workflow for issue descriptions (e.g., "Is this issue well-described?")
   - **Concept:** Same logic, different event type

---

## Debugging Checklist

If a squad is stuck:

- [ ] Is trigger `on: pull_request: types: [opened]`? (not `on: issues:`)
- [ ] Did they compile? (`gh aw compile review-buddy.md`)
- [ ] Does `.lock.yml` exist?
- [ ] Did they create a fresh test PR *after* compiling?
- [ ] Is there a workflow run in the Actions tab?
- [ ] Is the comment appearing (even if generic)?
- [ ] Are the permission scopes correct? (`pull-requests: read` minimum)
- [ ] Is the comment text meaningful or generic?

---

## Key Takeaways for Coaches

- **Event variety:** Squads are now building for multiple GitHub events (`issues` vs `pull_request`). This is the foundation for Track 2's depth.
- **Metadata > code:** Analyzing PR metadata (file count, line count) is fast and safe. Parsing code is for later.
- **Personality in automation:** A friendly bot is more useful than a harsh one. Emphasize tone.
- **PR as communication:** PRs tell stories (scope, intent, effort). The bot should read that story and reflect it back warmly.

---

## Reference

**Sample Solution Location:** `coaches/sample-solutions/track-2/2-02-review-buddy.md`  
**PR Fix Workflow (Real):** https://github.com/githubnext/agentics/blob/main/workflows/pr-fix.md  
**Pull Request Context:** https://docs.github.com/en/actions/learn-github-actions/contexts#github-context
