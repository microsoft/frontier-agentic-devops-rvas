# Coach Guide: Challenge 3-02 — Context Engine

---

## Coaching Philosophy for This Challenge

This is the **MCP tools intro**. Squads have used GitHub APIs passively (reading), but now you're teaching them to think about *data sources* and *context injection*.

Your job: Help them see that an agent without context is like a human reviewer without the codebase—it gives mediocre advice. But an agent that reads CONTRIBUTING.md and ARCHITECTURE.md? That agent writes insightful, specific feedback.

**Key rule:** Push back on generic advice. "You wrote a comment that could apply to any repo" → "How do we make it specific to *ours*?"

---

## Expected Outcomes

A finished solution has:

**Workflow (`context-aware-pr-reviewer.md`)**
- ~35-45 lines (frontmatter + body)
- Trigger: `on: pull_request: types: [opened, synchronize]`
- Frontmatter includes: `tools: github: toolsets: [pull_requests, contents]`
- Optional: `checkout: false` (agent doesn't need the code)
- Uses `safe-outputs: add-comment`

**PR Comment (Example):**
```
## Review Focus

**Files changed:** 4 files in src/auth/ and 1 in docs/

**Patterns detected:**
- Security-sensitive code (src/auth/**) — recommend security review
- Documentation updated — good!

**Checklist for author:**
- [ ] If adding new auth features, include unit tests
- [ ] If docs changed, verify links work
- [ ] PR is 120 lines — size is good, not too big

**Next step:** Assign to a security reviewer for the auth changes.
```

---

## Common Approaches

Squads will differ in complexity. All are valid:

### Approach 1: "Simple Heuristics" (most common)
- Check file patterns (e.g., `src/auth/**` → security review)
- Check size (>500 lines → suggest breaking up)
- Check for specific labels (docs, test coverage)

**Pros:** Fast, clear pattern matching, easy to get right
**Cons:** Doesn't use full context reading capability

### Approach 2: "Full Context Reader"
- Agent reads CONTRIBUTING.md, ARCHITECTURE.md, and compares PR against those rules
- More sophisticated analysis

**Pros:** More context-aware, closer to the "engine" concept
**Cons:** Requires repo to have these files, more complex prompt

### Approach 3: "MCP Toolset Maximizer"
- Uses 4-5 different toolsets (pull_requests, contents, repos, issues)
- Might query related issues or PRs for context

**Pros:** Showcases MCP flexibility
**Cons:** More moving parts, more things to go wrong

**Coach guidance:** Approach 1 or 2 is ideal for this challenge. Approach 3 is ambitious but not required.

---

## Common Pitfalls & Socratic Responses

### Pitfall 1: Toolsets not configured correctly
**Symptom:** Workflow logs show "API not found" or agent says "I can't read pull_requests".

**Root cause:** Typo in `tools: github: toolsets: [...]` or tool name doesn't exist.

**Coach response:**
- "What toolsets did you specify?"
- Have them check against the MCP reference. Common typos: `pull_request` (singular) vs `pull_requests` (plural).
- "Let's verify the tool name: is it `pull_requests` or `prs`?"

### Pitfall 2: Agent gives generic advice, not context-specific
**Symptom:** Workflow runs, comment posts, but it says things like "Consider adding tests" without referencing the actual repo's policies.

**Root cause:** Agent wasn't told to read CONTRIBUTING.md or repo standards.

**Coach response:**
- "Your comment could apply to any repo. How do we make it specific to ours?"
- "Did you tell the agent to read CONTRIBUTING.md? Add something like: 'First, read the CONTRIBUTING.md file. Then analyze the PR against those rules.'"
- "What makes *your* repo unique? Is there a style guide? An architecture? Tell the agent about it."

### Pitfall 3: CONTRIBUTING.md doesn't exist
**Symptom:** Agent tries to read the file, gets a 404, and doesn't know what to do.

**Root cause:** File doesn't exist, or agent didn't handle the missing file gracefully.

**Coach response:**
- "Either create a simple CONTRIBUTING.md file, or tell the agent: 'If CONTRIBUTING.md doesn't exist, just analyze the PR based on standard practices.'"
- Have them create `.github/CONTRIBUTING.md` with 5-10 bullet points about repo standards (e.g., "All PRs need tests", "Docs required for API changes").

### Pitfall 4: `add-comment` safe-output not configured
**Symptom:** Workflow runs, but no comment appears on the PR. Logs show "No safe-output called".

**Root cause:** Missing `safe-outputs: add-comment:` in frontmatter, or agent didn't use it.

**Coach response:**
- "Every gh-aw workflow must call a safe-output. For a PR comment, that's `safe-outputs: add-comment:`."
- Have them check the frontmatter indentation. Common mistake: `add-comment:` not aligned under `safe-outputs:`.
- Remind them: "The agent should end with: 'I'll post this comment to the PR.' Then the safe-output runs."

### Pitfall 5: Comment is too long or too vague
**Symptom:** Comment posts but it's rambling (1000+ words) or doesn't give actionable feedback.

**Root cause:** Agent wasn't told to be concise, or the prompt didn't specify what kind of feedback to give.

**Coach response:**
- "Your comment is 800 words. GitHub comments should be 200-300 max. Can you tighten it?"
- "What's the *one thing* this PR needs to know? Start with that, then add 2-3 supporting details."
- "I see vague phrases like 'consider testing.' Instead, give a specific checklist: 'Verify that X, Y, Z.'"

### Pitfall 6: Toolset scoping too permissive
**Symptom:** Workflow works but agent has access to too many APIs (e.g., can delete repositories).

**Root cause:** Used `tools: github: mode: full` or didn't scope toolsets.

**Coach response:**
- This is a nice "security thinking" moment.
- "You gave the agent access to everything. For this workflow, does it really need repos+contents+pull_requests+issues? Probably just pull_requests+contents."
- "Scoping toolsets is a security practice—principle of least privilege."

### Pitfall 7: Agent reads files but doesn't use them in analysis
**Symptom:** Logs show agent fetched CONTRIBUTING.md, but comment doesn't mention it.

**Root cause:** Agent wasn't explicitly told to apply the rules from the files.

**Coach response:**
- "I see you read CONTRIBUTING.md, but the comment doesn't reference it. Try: 'Compare the PR against the rules in CONTRIBUTING.md. Highlight which rules apply.'"
- Make the connection explicit in the prompt.

---

## Coaching Questions

1. **"What toolsets did you configure?"** → Have them read the frontmatter
2. **"Did you tell the agent to read CONTRIBUTING.md?"** → Check the workflow body
3. **"Is your comment specific to your repo, or could it apply to any project?"** → Read the comment out loud
4. **"What's the one most important thing the PR author should know?"** → If they struggle, their prompt might be unfocused
5. **"Did you test it? Does the comment actually appear on a PR?"** → Verification step
6. **"What would make this comment more helpful?"** → Push for refinement

---

## Sample Solution

Share this **only if stuck >20 minutes**. Have them type it.

**`context-aware-pr-reviewer.md`:**

```markdown
---
on:
  pull_request:
    types: [opened, synchronize]

permissions:
  contents: read
  pull_requests: read

safe-outputs:
  add-comment:

tools:
  github:
    toolsets: [pull_requests, contents]

engines:
  - copilot

checkout: false
---

# Context-Aware PR Reviewer

Analyze incoming PRs using repository context to provide specific, actionable feedback.

1. Read the PR metadata: files changed, size, title, author.
2. Read `.github/CONTRIBUTING.md` to understand repo standards (if it exists).
3. Analyze the PR against those standards.
4. Post a comment with three things:
   - What patterns/areas did the PR touch? (e.g., auth, docs, tests)
   - Specific checklist items for the author (based on CONTRIBUTING.md)
   - One recommendation for the reviewer

Keep the comment under 250 words. Use markdown formatting: headers, bullets, checkboxes.

Example output:
```
## Review Focus

**Files changed:** src/auth/, docs/

**Checklist for author:**
- [ ] Security review for auth changes
- [ ] Doc links validated

**For reviewer:** This PR touches auth—recommend security team approval.
```
```

---

## Why This Works

- **Frontmatter:** Minimal permissions, specific toolsets, `checkout: false`
- **Context reading:** Agent fetches CONTRIBUTING.md to understand repo rules
- **Specific feedback:** Instead of generic advice, the agent compares PR to repo standards
- **Output:** `add-comment` is clear and actionable
- **Philosophy:** This is the "context engine" pattern—decisions based on informed data

---

## Time Management

| Phase | Time | What to Do |
|-------|------|-----------|
| Read & orient | 5 min | Understand MCP toolsets, context injection concept |
| Create/update CONTRIBUTING.md | 5 min | If not present, create simple repo guidelines |
| Write workflow | 12 min | Build frontmatter with toolsets, write agent prompt |
| Test on a PR | 6 min | Open a PR, trigger the workflow, verify comment appears |
| Iterate on comment quality | 2 min | If generic, refine the prompt for specificity |

**Total: ~30 minutes.**

---

## Extension Ideas

1. **Add a pre-agent step:** Use bash to compute PR statistics (churn rate, authors, test count) before the agent runs.
2. **Query related issues:** Use `tools: github: toolsets: [issues]` to see if this PR closes any issues, and mention them in the comment.
3. **Multi-language guidance:** If the repo has multiple languages, give context-specific advice per language (e.g., "Python PRs need docstrings").
4. **Bot exception handling:** Detect if PR author is a bot, skip the comment (prevent comment spam).

---

## Debugging Checklist

- [ ] Toolsets configured in frontmatter? (`tools: github: toolsets: [pull_requests, contents]`)
- [ ] Toolset names correct? (e.g., `pull_requests`, not `prs`)
- [ ] CONTRIBUTING.md exists (or agent handles missing file gracefully)?
- [ ] Agent instructions mention reading CONTRIBUTING.md?
- [ ] `safe-outputs: add-comment:` in frontmatter?
- [ ] Workflow triggered on a PR? (Open a test PR if needed)
- [ ] Comment appears on PR within 2 minutes?
- [ ] Comment is context-specific (not generic)?

---

## Key Takeaways

- **Context transforms agents:** A context-aware agent is 10× better than one flying blind.
- **MCP toolsets are about scoping:** Don't grant every tool; grant what the agent needs.
- **Repository conventions matter:** The agent should read your repo's standards, not invent its own.
- **Specific feedback > generic advice:** Your comment should reference *your* repo, not any repo.

Celebrate when the comment is specific and useful. That's the signal the context injection worked.
