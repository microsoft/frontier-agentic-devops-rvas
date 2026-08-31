# Activity 3-02: Context Engine

Track: Continuous Intelligence (Advanced)  
Difficulty: 🔴 Advanced  
Estimated time: 30 minutes  
Prerequisites: Track 2, completed ≥3 activities

---

## Background

An agent can only reason from the context it receives. Use gh-aw's `tools:` configuration to give it live data through MCP tools (GitHub labels, repository metrics, service status, and similar). Without repository standards, a PR agent falls back to generic advice; give it the actual conventions and it can check the pull request against them.

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
> Prefer your own repository with real PRs and repo-specific context files (`CONTRIBUTING.md`, `ARCHITECTURE.md`, docs, test conventions). Point the workflow at it everywhere the guide references the sample repo. No candidate repo yet? Use the provided sample repo from setup.

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

## Tips & Troubleshooting

- The `tools: github: toolsets: [...]` array scopes exactly which GitHub APIs the agent can use. Start with `[pull_requests, contents]`.
- Have the agent read `CONTRIBUTING.md`/`ARCHITECTURE.md` explicitly in the prompt — otherwise it defaults to generic advice. Verify the toolset name is correct (`pull_requests`, not `prs`) if reads fail.
- Focus review comments on file patterns, size anomalies, and compliance with *your* standards, not generic code review. Keep the comment to ~200 words.
- Use `checkout: false` since the agent only needs API calls, not a checkout.
- If `add-comment` won't post, check `safe-outputs:` indentation and the workflow logs.

---

## References

- GitHub tool permissions: https://github.github.com/gh-aw/reference/permissions/
- Workflow frontmatter: https://github.github.com/gh-aw/reference/frontmatter/
- PR Analysis Example: https://github.com/github/gh-aw/blob/main/.github/workflows/issue-triage-agent.md (triage agent pattern adapted for PRs)
- Safe Outputs (add-comment): https://github.github.com/gh-aw/reference/safe-outputs/#add-comment
- Workflow Syntax — on.pull_request: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#onpull_request
