# Challenge 2-01: Triage Bot

**Track:** Repo Concierge (Intermediate 🟡)  
**Estimated time:** 30 minutes  
**Prerequisites:** Complete at least 2 challenges from Track 1

---

## What You'll Build

A workflow that automatically categorizes new issues as they arrive. When someone opens an issue in your repo, your Triage Bot springs into action: it analyzes the issue title and body, assigns one of several labels (e.g., `bug`, `feature-request`, `documentation`, `question`), and posts a friendly comment explaining the categorization and next steps.

**Why this matters:** Open source maintainers spend enormous time on issue triage. A Triage Bot handles the first pass instantly, reducing friction and letting humans focus on decisions that need judgment. This challenge teaches you event-driven automation — the most common pattern in gh-aw workflows.

---

## Goals

By the end, your squad will:

1. ✅ Build a workflow triggered by `on: issues: types: [opened]`
2. ✅ Use the GitHub API toolset to read issue details
3. ✅ Implement AI-powered classification logic (no hardcoded rules)
4. ✅ Apply labels via `safe-outputs: add-labels` with an allowlist
5. ✅ Post a structured comment explaining the classification

---

## Challenge

Create a gh-aw workflow named `triage-bot.md` in `.github/workflows/` that:

- **Triggers on:** New issues (when someone clicks "Open an issue")
- **Analyzes:** Issue title and body
- **Classifies** the issue into one of these categories:
  - `bug` — Something is broken or doesn't work as expected
  - `feature-request` — A new capability or enhancement
  - `documentation` — Docs need clarification, examples, or fixes
  - `question` — User asking for help or information
  - `duplicate` — Looks like an existing issue (include why in the comment)
- **Applies a label** from the allowlist using `safe-outputs: add-labels`
- **Posts a comment** with:
  - The assigned category (e.g., "This looks like a **bug** report")
  - A brief explanation of why (1 sentence)
  - Next steps or encouragement (e.g., "Thanks for the report! A maintainer will review soon")

---

## Success Criteria

- [ ] `.github/workflows/triage-bot.md` exists with valid gh-aw frontmatter
- [ ] Frontmatter includes: `on: issues:`, `permissions`, `safe-outputs:`, `engines`
- [ ] Safe-outputs has an allowlist limiting labels to: `bug`, `feature-request`, `documentation`, `question`, `duplicate`
- [ ] `.github/workflows/triage-bot.lock.yml` compiles without errors
- [ ] You manually test by creating a test issue in your repo
- [ ] The workflow triggers automatically (watch the Actions tab)
- [ ] The correct label appears on the test issue
- [ ] A comment is posted with the category and explanation
- [ ] The comment is friendly and encouraging (not robotic)

---

## Tips & Hints

- **Event trigger:** Use `on: issues: types: [opened]` to fire when new issues arrive
- **Permissions:** Keep them minimal — the agent only reads; `safe-outputs` handles writes
- **Allowlist is strict:** Only labels you explicitly list in the frontmatter can be applied. This is a safety guardrail; use it
- **AI reasoning:** You don't hardcode "if title contains 'error' → bug." Instead, write natural instructions to the AI: "Read the issue and decide which category fits best"
- **Comment template:** Use markdown formatting (bold, lists, links) to make the comment readable
- **Watch for duplicates:** Your AI might spot that a new issue is very similar to an existing one. If so, suggest the `duplicate` label
- **Tone matters:** The comment represents your repo's personality. Be welcoming

---

## References

- **gh-aw Frontmatter Docs:** https://github.github.com/gh-aw/reference/frontmatter/
- **Safe Outputs (add-labels, add-comment):** https://github.github.com/gh-aw/reference/safe-outputs/
- **GitHub API Toolset:** https://github.github.com/gh-aw/reference/tools/github/
- **Real-world example:** `issue-triage-agent.md` at https://github.com/github/gh-aw/blob/main/.github/workflows/issue-triage-agent.md

---

## Stuck?

- **"Workflow triggered but no label applied?"** → Check the Actions tab logs. Look for errors in the safe-outputs section or permission issues
- **"Label not in my allowlist?"** → Labels in the frontmatter allowlist are case-sensitive; double-check spelling
- **"Comment is generic/robotic?"** → Rewrite the body to include personality. Try: "Thanks for opening this issue! We've categorized it as a **{category}**..."
- **"Not sure how to analyze the issue?"** → Write out what you'd look for: "If the title mentions 'broken' or 'crash' it's likely a bug. If it asks 'how do I...' it's a question."

Raise your hand — your coach is here.
