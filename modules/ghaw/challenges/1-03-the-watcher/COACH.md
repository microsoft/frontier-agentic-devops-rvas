# Coach Guide: Challenge 1-03 — The Watcher

---

## Coaching Philosophy

This is the **event-driven trigger challenge**. The mental model shift: instead of workflows running on a schedule or manually, they react to repository events (pushes, PRs, issues). Your job is to help squads understand that `on: push:` is a powerful and simple trigger.

**Key rule:** Path filters can be tricky. If a squad's workflow isn't firing, the path filter is 90% of the time the culprit.

---

## Common Pitfalls & Coaching Responses

### Pitfall 1: Path filter is too specific or wrong
**Symptom:** Workflow compiles fine, but it never runs when they push changes.

**Root cause:** Path filter doesn't match the actual files they're changing. E.g., they specified `docs/**` but actually pushed to `README.md` in the root.

**Coach response:**
- "Where are you pushing your changes?"
- Have them verify: "If you're pushing to `docs/`, use `docs/**`. If you want any markdown file at any level, use `**/*.md`."
- Show them on github.com: when they push, they can see the file path in the commit. That's what the filter needs to match.
- Quick fix for testing: temporarily use `on: push:` with no paths filter to confirm the workflow runs *at all*. Then add the path filter back.

---

### Pitfall 2: Forgot to include `workflow_dispatch`
**Symptom:** They have to commit and push to test, making iteration slow.

**Root cause:** Only `on: push:` is declared, no manual trigger.

**Coach response:**
- "Add `workflow_dispatch:` to your `on:` block so you can test manually from the Actions tab without committing."
- Show: "This speeds up iteration dramatically — you can refine your prompt without spam-committing."

---

### Pitfall 3: Trying to read commit diff directly instead of using GitHub MCP
**Symptom:** They use `git diff` or call GitHub API directly to inspect changes.

**Root cause:** Thinking like a GitHub Actions user, not an agentic workflow user.

**Coach response:**
- "You can use `tools: bash: allow: [git log:*, git diff:*, git show:*]` to access commit data, OR you can query the GitHub MCP tool for commits. Either works, but the GitHub MCP is often cleaner."
- Show: "With the GitHub MCP, you query: 'What files were changed in the most recent commit?' and the agent handles the API calls."

---

### Pitfall 4: Comment not appearing even though workflow "succeeded"
**Symptom:** Workflow runs, no errors, but no comment on the commit.

**Root cause:** Either (a) agent didn't call the safe-output, or (b) safe-output wasn't declared in frontmatter.

**Coach response:**
- "Check the logs. Does it say 'comment added' or similar?"
- If logs are silent: "You need to declare `safe-outputs: add-comment:` in your frontmatter."
- If logs say the agent tried but nothing happened: "Safe-outputs might be misconfigured. Let's check the title/body format."

---

### Pitfall 5: Agent doesn't have context about what changed
**Symptom:** Agent generates a vague comment like "Changes detected" instead of listing actual files.

**Root cause:** Instructions don't tell the agent to inspect commit metadata.

**Coach response:**
- "What does your workflow body tell the agent to do? Read it out loud."
- Guide: "Add something like: 'Inspect the commit metadata. List the files that were changed. Create a comment summarizing the changes.'"
- Test: "Start with something simple like 'Count how many files were changed' — get that working, then make the comment fancier."

---

### Pitfall 6: Overpermissioning for a read-only workflow
**Symptom:** Frontmatter has `permissions: write-all` when it only needs read + safe-outputs.

**Root cause:** Copy-paste from other examples or misunderstanding the permission model.

**Coach response:**
- "What does this workflow need to write?"
- Guide: "If you're only reading commits and posting a comment, use `contents: read`. Safe-outputs handles the comment write."

---

## Sample Solution

Here's a working `the-watcher.md`:

```markdown
---
on:
  push:
    paths:
      - 'docs/**'
  workflow_dispatch:

permissions:
  contents: read

safe-outputs:
  add-comment:
  noop:

engines:
  - copilot

tools:
  github:
    toolsets:
      - commits
---

# The Watcher

Analyze the current commit and the files that were changed:

1. Look at the commit metadata to see which files were modified
2. Count how many files were changed
3. If 1-3 files: create a comment saying "Docs update: X files changed"
4. If 4+ files: create a comment saying "Bulk docs update: X files changed, please review carefully"
5. If no files were actually changed (edge case), call noop

Keep the comment brief and friendly — it's for the committer to see inline.
```

**Why this works:**
- `on: push: paths: ['docs/**']` — triggers on docs changes only
- `permissions: contents: read` — minimal
- `tools: github: toolsets: [commits]` — agent can query commit data
- `safe-outputs: add-comment:` + `noop:` — two paths
- `workflow_dispatch:` for testing
- Body: clear, measurable conditions based on file count

**Production-ready reference solution:** See `coaches/sample-solutions/track-1/1-03-the-watcher.md`

---

## Time Management

Suggest this breakdown:

| Phase | Time | What to Do |
|-------|------|-----------|
| Read & orient | 5 min | Discuss push triggers and path filters |
| Write the .md file | 8 min | Create frontmatter with path filter, write instructions |
| Compile & test | 5 min | Fix any YAML errors |
| Local commit + push | 10 min | Make a real commit to the watched directory and push |
| Debug | 2 min | Check Actions tab; verify comment appears |

**Total: ~30 minutes.**

---

## Debugging Checklist

If a squad is stuck:

- [ ] Is the `on: push: paths:` filter correct? (Check their actual file paths in the repo)
- [ ] Did they add `workflow_dispatch:` so they can test manually?
- [ ] Does `gh aw compile` succeed?
- [ ] When they push to the watched directory, does the workflow appear in the Actions tab?
- [ ] Do the logs show the agent detecting the commit and files?
- [ ] Is `safe-outputs: add-comment:` declared in frontmatter?
- [ ] Did they declare both `add-comment:` and `noop:` paths?
- [ ] Does the comment appear on the commit? (check the commit's Conversation tab on GitHub.com)
- [ ] If no comment, check logs for error messages about safe-output execution

---

## Extension Ideas

If a squad finishes early:

1. **React to PR comments:** Change to `on: pull_request: types: [opened]` and analyze the PR diff instead of commits
   - Concept: different event types have different data structures

2. **Add a label based on file changes:** Use `tools: github: toolsets: [issues, labels]` + `safe-outputs: add-labels:` to label the related issue
   - Concept: multi-output workflows

3. **Exclude certain paths:** Use `on: push: paths: ['docs/**'] paths-ignore: ['*.md']` to run on non-markdown doc changes
   - Concept: negative filters and path logic

4. **Conditional comment:** Only comment if the commit message contains a keyword (e.g., "BREAKING" or "REVIEW-ME")
   - Concept: multi-signal conditional logic

5. **Create a discussion instead of a comment:** Use `safe-outputs: create-discussion:` to start a discussion thread about the changes (useful for complex changes)
   - Concept: different safe-output types

---

## Key Takeaways for Coaches

- **Event-driven workflows are real automation:** Once this works, squads unlock reactive automation at scale.
- **Path filters are the tricky part:** Spend time debugging them if needed; understanding glob patterns is a valuable skill.
- **Safe-outputs is consistent:** Same model as Challenge 1-02: declare intent, multiple paths, noop as escape hatch.
- **Real git operations test everything:** When they make a real commit and see the workflow run, that's a strong motivational moment.
