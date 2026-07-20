# Activity 3-02: Context Engine

**Track:** Continuous Intelligence (Advanced)  
**Difficulty:** 🔴 Advanced  
**Estimated time:** 30 minutes  
**Prerequisites:** Track 2, completed ≥3 activities

---

## Background

Without external data, an agent can only reason about what's already in the prompt. **Context Engine** is about closing that gap with **MCP tools** (Model Context Protocol). You'll connect the agent to external data sources — GitHub labels, repository metrics, upstream service status — using gh-aw's `tools:` configuration, so its decisions are grounded in real state rather than inferred from incomplete context.

**Why this matters:** Ask an agent to review a PR without giving it your repo's coding standards and it will apply generic heuristics. Give it a `repo-memory` file with your actual conventions and it applies those instead. This activity teaches you to identify what information an agent needs before it can make a useful decision, and how to supply that information through `tools:` configuration.

---

## Goals

By the end of this activity, your squad will:

1. ✅ Configure `tools:` section to grant an agent access to multiple MCP toolsets
2. ✅ Build a workflow that uses external data (not just GitHub APIs) to enrich decisions
3. ✅ Understand the difference between `tools: github` scoping and MCP extensions
4. ✅ Write an agent that makes context-aware decisions (not generic AI)

---

> [!IMPORTANT]
> **Bring your own repo (do this first)**
>
> This activity is most valuable when the context engine reads **your own repository's** real PRs, CONTRIBUTING guidance, architecture notes, docs, and tests, so its review-focus comments stay useful after the session. Treat the setup sample as practice, not the default destination.
>
> - **Have a candidate repo?** Install or point the workflow at that repo everywhere the guide references the sample repo, and use real PRs plus repo-specific context files such as `CONTRIBUTING.md`, `ARCHITECTURE.md`, docs, or test conventions.
> - **No suitable repo yet?** Use the provided sample repo from setup as the safe practice target.
>
> Tell your coach which path you took — bringing your own is the goal; the sample repo is the fallback.

---

## Activity

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
- [ ] Discuss what context an agent on your team needs before it can make a decision you would trust, and where it flies blind without that data today. Connect it to a project, task, or workflow you own.

---

## Tips & Hints

- The `tools: github: toolsets: [...]` array lets you specify exactly which GitHub APIs the agent can use. Start with `[pull_requests, contents]` and add others if needed.
- CONTRIBUTING.md and ARCHITECTURE.md are great context sources. Have the agent read them to understand repo conventions.
- Avoid "code review" advice (that's what humans do). Instead, focus on: file patterns, size anomalies, and compliance with *your* specific standards.
- If your repo doesn't have CONTRIBUTING.md, create a simple one during the activity—just a few bullet points about your project's rules.
- Use `checkout: false` since the agent only needs API calls, not to check out the code.
- The comment should be ~200 words max. A bulleted list + a focused suggestion is better than paragraphs.

---

## References

- **GitHub tool permissions:** https://github.github.com/gh-aw/reference/permissions/
- **Workflow frontmatter:** https://github.github.com/gh-aw/reference/frontmatter/
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
