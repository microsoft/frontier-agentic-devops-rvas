# Activity 3-02: Context Engine

Track: Continuous Intelligence (Advanced)  
Difficulty: 🔴 Advanced  
Estimated time: 30 minutes  
Prerequisites: Track 2, completed ≥3 activities

---

## Background

An agent can only reason from the context it receives. Use gh-aw's `tools:` configuration to give it live data through MCP tools (Model Context Protocol), such as GitHub labels, repository metrics, or service status.

Without repository standards, a PR agent falls back to generic advice. Give it the actual conventions and it can check the pull request against them.

---

## What you'll practice

1. Configure `tools:` to grant access to multiple MCP toolsets
2. Use external data, not only GitHub APIs, to inform decisions
3. Distinguish `tools: github` scoping from MCP extensions
4. Write instructions that produce repository-specific decisions

---

> [!IMPORTANT]
> Bring your own repo (do this first)
>
> Use your own repository if possible. Give the workflow real pull requests and repository guidance. Use the setup sample only for practice.
>
> - Have a candidate repo? Install or point the workflow at that repo everywhere the guide references the sample repo, and use real PRs plus repo-specific context files such as `CONTRIBUTING.md`, `ARCHITECTURE.md`, docs, or test conventions.
> - No suitable repo yet? Use the provided sample repo from setup as the safe practice target.

---

## Activity

Build a workflow that enriches PR analysis with external context:

### Trigger

Trigger on `pull_request: [opened, synchronize]` (when a PR opens or gets new commits).

### Context sources

Your agent needs to access:

1. Use `tools: github: toolsets: [pull_requests]` for PR metadata such as changed files, line counts, title, and author.
2. Use `tools: github: toolsets: [contents]` for repository guidance such as `.github/CONTRIBUTING.md`.
3. Use the same `contents` toolset for codebase metadata such as `ARCHITECTURE.md`.

### Review decision

Use that context to decide: "What kind of review does this PR need?"

Examples:
- If PR touches `src/auth/**`, suggest "Security review needed"
- If the PR adds tests, comment "Test additions detected. The approver should verify coverage."
- If the PR is large (>500 lines), comment "Large PR. Consider splitting it into smaller changes."
- If CONTRIBUTING.md says "all PRs need docs", and this PR has no docs/, suggest "Please add documentation"

### Comment

Use `safe-outputs: add-comment` to post a structured comment on the PR. The comment should:
- Summarize what you found (3 things: file patterns, size, compliance check)
- Suggest a review focus based on the context
- Include a checklist of items the author should verify

---

## Tips & Hints

- The `tools: github: toolsets: [...]` array lets you specify exactly which GitHub APIs the agent can use. Start with `[pull_requests, contents]` and add others if needed.
- CONTRIBUTING.md and ARCHITECTURE.md are great context sources. Have the agent read them to understand repo conventions.
- Avoid "code review" advice (that's what humans do). Instead, focus on: file patterns, size anomalies, and compliance with *your* specific standards.
- If the repo has no CONTRIBUTING.md, create a short one with the project's rules.
- Use `checkout: false` since the agent only needs API calls, not to check out the code.
- The comment should be ~200 words max. A bulleted list + a focused suggestion is better than paragraphs.

---

## References

- GitHub tool permissions: https://github.github.com/gh-aw/reference/permissions/
- Workflow frontmatter: https://github.github.com/gh-aw/reference/frontmatter/
- PR Analysis Example: https://github.com/github/gh-aw/blob/main/.github/workflows/issue-triage-agent.md (triage agent pattern adapted for PRs)
- Safe Outputs (add-comment): https://github.github.com/gh-aw/reference/safe-outputs/#add-comment
- Workflow Syntax — on.pull_request: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#onpull_request

---

## Help

Use these checks if the workflow fails:

- "Agent can't read CONTRIBUTING.md?" → Check your `tools: github: toolsets: [contents]` is configured. Then verify the file exists at `.github/CONTRIBUTING.md`.
- "Comment won't post?" → Check `safe-outputs: add-comment:` frontmatter is indented correctly. Look at the workflow logs for the exact error.
- "Agent gives generic advice, not specific to our repo?" → You may need to make your CONTRIBUTING.md or ARCHITECTURE.md more explicit. Or your prompt doesn't tell the agent to read them. Try: "Read the CONTRIBUTING.md file first. Then analyze the PR against those rules."
- "Toolsets list not working?" → Verify the toolset names (e.g., `pull_requests`, not `prs`). Reference the docs.
