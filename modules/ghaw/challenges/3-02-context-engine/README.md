# Challenge 3-02: Context Engine

**Track:** Continuous Intelligence (Advanced)  
**Difficulty:** 🔴 Advanced  
**Estimated time:** 30 minutes  
**Prerequisites:** Track 2, completed ≥3 challenges

---

## Background

Imagine an AI agent that doesn't just run in isolation—it has **context**. External data sources feed it real-time information: GitHub labels, repository metrics, upstream service status, even data from outside GitHub.

**Context Engine** is about **MCP tools** (Model Context Protocol). Instead of your agent working with only what's in the repo, you'll connect it to external data sources using gh-aw's `tools:` configuration. The agent reads enriched context and makes better decisions.

This is where agentic workflows become truly powerful. An agent that understands your repo's recent trends, architectural constraints, or external system status makes decisions 10× better than one flying blind.

**Why this matters:** Most production automation fails because it lacks context. This challenge teaches you to think about *what information your agent needs to make good decisions*, and how to supply it cleanly.

---

## Goals

By the end of this challenge, your squad will:

1. ✅ Configure `tools:` section to grant an agent access to multiple MCP toolsets
2. ✅ Build a workflow that uses external data (not just GitHub APIs) to enrich decisions
3. ✅ Understand the difference between `tools: github` scoping and MCP extensions
4. ✅ Write an agent that makes context-aware decisions (not generic AI)

---

## Challenge

Build a workflow that **enriches PR analysis with external context**:

### The Setup

Trigger on **`pull_request: [opened, synchronize]`** (when a PR opens or gets new commits).

### The Context Sources

Your agent needs to access:

1. **PR metadata** (files changed, lines added/removed, title, author) — use `tools: github: toolsets: [pull_requests]`
2. **Issue templates or style guide** stored in the repo (e.g., a `.github/CONTRIBUTING.md`) — use `tools: github: toolsets: [contents]`
3. **Codebase metadata** (e.g., a `ARCHITECTURE.md` file describing project structure) — again, `tools: github: toolsets: [contents]`

### The Decision

Use that context to decide: **"What kind of review does this PR need?"**

Examples:
- If PR touches `src/auth/**`, suggest "Security review needed"
- If PR adds tests, comment "Test additions detected—approver should verify coverage"
- If PR is large (>500 lines), comment "Large PR—consider breaking into smaller chunks"
- If CONTRIBUTING.md says "all PRs need docs", and this PR has no docs/, suggest "Please add documentation"

### The Output

Use **`safe-outputs: add-comment`** to post a structured comment on the PR. The comment should:
- Summarize what you found (3 things: file patterns, size, compliance check)
- Suggest a review focus based on the context
- Include a checklist of items the author should verify

---

## Success Criteria

- [ ] Workflow triggers on PR open/push
- [ ] Agent reads PR diff (GitHub toolset)
- [ ] Agent reads repo files (CONTRIBUTING.md, ARCHITECTURE.md) to understand repo context
- [ ] Agent produces a structured comment with context-aware insights
- [ ] Comment appears on the PR
- [ ] Comment avoids generic advice—it's specific to *this* repo's standards
- [ ] `safe-outputs: add-comment` is used correctly

---

## Tips & Hints

- The `tools: github: toolsets: [...]` array lets you specify exactly which GitHub APIs the agent can use. Start with `[pull_requests, contents]` and add others if needed.
- CONTRIBUTING.md and ARCHITECTURE.md are great context sources. Have the agent read them to understand repo conventions.
- Avoid "code review" advice (that's what humans do). Instead, focus on: file patterns, size anomalies, and compliance with *your* specific standards.
- If your repo doesn't have CONTRIBUTING.md, create a simple one during the challenge—just a few bullet points about your project's rules.
- Use `checkout: false` since the agent only needs API calls, not to check out the code.
- The comment should be ~200 words max. A bulleted list + a focused suggestion is better than paragraphs.

---

## References

- **MCP Tools Reference:** https://github.github.com/gh-aw/reference/mcp-tools/
- **GitHub Toolsets:** https://github.github.com/gh-aw/reference/mcp-tools/#github
- **PR Analysis Example:** https://github.com/github/gh-aw/blob/main/.github/workflows/issue-triage-agent.md (triage agent pattern adapted for PRs)
- **Safe Outputs (add-comment):** https://github.github.com/gh-aw/reference/safe-outputs/#add-comment
- **Workflow Syntax — on.pull_request:** https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions#onpull_request

---

## Help

Stuck? Here's how to escalate:

- **"Agent can't read CONTRIBUTING.md?"** → Check your `tools: github: toolsets: [contents]` is configured. Then verify the file exists at `.github/CONTRIBUTING.md`.
- **"Comment won't post?"** → Check `safe-outputs: add-comment:` frontmatter is indented correctly. Look at the workflow logs for the exact error.
- **"Agent gives generic advice, not specific to our repo?"** → You may need to make your CONTRIBUTING.md or ARCHITECTURE.md more explicit. Or your prompt doesn't tell the agent to read them. Try: "Read the CONTRIBUTING.md file first. Then analyze the PR against those rules."
- **"Toolsets list not working?"** → Verify the toolset names (e.g., `pull_requests`, not `prs`). Reference the docs.

Still stuck after 20 minutes? Raise your hand for your coach.
