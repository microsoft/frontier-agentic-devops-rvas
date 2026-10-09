# Copilot rollout plan for `northwind`

**Plan mode is active. No GitHub settings were changed.**

I could not inspect `northwind.ghe.com`. GitHub CLI has no authenticated account
for that host, and the API connection to `api.northwind.ghe.com` failed. I therefore
left the enterprise, `engineering` organization, inherited AI policies, teams,
subscription, seats, and billing state as unknown. I did not guess.

I saved:

- `assessment.json`: redacted discovery results and unknowns
- `plan.md`: the rollout plan, preview register, billing risks, manual settings,
  approvals, and verification
- `plan.json`: machine-readable batches and blocked operations

The recommended rollout is **team-first seat assignment** for `engineering`, a
small CLI and code-review pilot, server-managed settings in
`engineering/.github-private`, a managed-settings MCP allowlist, and reviewed
enterprise agents sourced from `engineering` if that organization owns the
company-wide agent lifecycle.

The plan calls out these preview items:

- Copilot billing and seat-management REST endpoints
- enterprise custom agents
- Copilot approvals
- custom MCP registry enforcement
- the unresolved release label for organization custom instructions on this host

It also keeps every paid action blocked until we know the unique seat delta,
contract price, proration, code-review AI-credit billing source, budgets, and
billing owner. Copilot CLI and code review policies, organization instructions,
AI-credit budgets, and unsupported AI-control writes remain manual settings unless
current host documentation proves a supported API.

## Next interview question

**May I run `gh auth login --hostname northwind.ghe.com`, then perform narrow
read-only discovery of the active actor, enterprise `northwind`, organization
`engineering`, effective Copilot policies, team names, and the Copilot billing
summary?**

Recommended answer: approve only after confirming the dedicated host and required
network access. Authentication changes local CLI state, so it needs explicit
approval.

The plan was checked against GitHub's current documentation on October 9, 2026,
including Copilot seat assignment, Copilot user-management REST endpoints,
enterprise Copilot policies, Copilot CLI administration, code-review configuration,
enterprise managed settings, MCP management, and enterprise custom agents.
