# Activity 3-02: Context engine

**Session outcome:** Your pull-request assistant reads live GitHub context and repository standards, then posts a review comment. Each observation refers to the relevant changes or standards.

## Background

Use gh-aw's `tools:` configuration to give the agent live data through MCP tools, such as GitHub labels, repository metrics, or service status. Supply the repository's standards so it can check pull requests against them instead of giving generic advice.

---

## What you'll practice

1. Configure `tools:` to grant access to multiple MCP toolsets
2. Use external data, not only GitHub APIs, to inform decisions
3. Distinguish `tools: github` scoping from MCP extensions
4. Write instructions that produce repository-specific decisions

---

> [!TIP]
> [Bring your own repo](../../setup.md#bring-your-own-repo): point the workflow at a repo you own with real PRs and context files (`CONTRIBUTING.md`, `ARCHITECTURE.md`, docs, test conventions).

---

## Activity

Build a workflow that uses repository guidance to review pull requests:

### Trigger

Trigger on `pull_request: [opened, synchronize]` (when a PR opens or gets new commits).

### Context sources

Configure these context sources:

1. Use `tools: github: toolsets: [pull_requests]` for PR metadata such as changed files, line counts, title, and author.
2. Use `tools: github: toolsets: [contents]` for repository guidance such as `.github/CONTRIBUTING.md`.
3. Use the same `contents` toolset for codebase metadata such as `ARCHITECTURE.md`.

### Review decision

Use that context to recommend the review the PR needs.

Examples:
- If PR touches `src/auth/**`, suggest "Security review needed"
- If the PR adds tests, comment "Test additions detected. The approver should verify coverage."
- If the PR is large (>500 lines), comment "Large PR. Consider splitting it into smaller changes."
- If CONTRIBUTING.md says "all PRs need docs", and this PR has no docs/, suggest "Please add documentation"

### Comment

Use `safe-outputs: add-comment` to post a structured comment on the PR. The comment should:
- Summarize the file patterns, change size, and compliance check
- Suggest a review focus based on the context
- Include a checklist of items the author should verify

---

## Tips and troubleshooting

- The `tools: github: toolsets: [...]` array scopes exactly which GitHub APIs the agent can use. Start with `[pull_requests, contents]`.
- Tell the agent to read `CONTRIBUTING.md`/`ARCHITECTURE.md` in the prompt. Verify the toolset name is correct (`pull_requests`, not `prs`) if reads fail.
- Focus review comments on file patterns, size anomalies, and compliance with your repository's standards. Keep the comment to ~200 words.
- Use `checkout: false` because the agent only needs API calls.
- If `add-comment` won't post, check `safe-outputs:` indentation and the workflow logs.

---

## References

- GitHub tool permissions: https://github.github.com/gh-aw/reference/permissions/
- Workflow frontmatter: https://github.github.com/gh-aw/reference/frontmatter/
- PR Analysis Example: https://github.com/github/gh-aw/blob/main/.github/workflows/issue-triage-agent.md (triage agent pattern adapted for PRs)
- Safe Outputs (add-comment): https://github.github.com/gh-aw/reference/safe-outputs/#add-comment
- Workflow syntax, on.pull_request: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#onpull_request
