# Northwind Copilot rollout plan

**Mode:** Plan only. I made no changes to `northwind.ghe.com` and ran no GitHub mutation commands.

**Plan date:** October 9, 2026.

## Recommended design

Start with the `engineering` organization and assign seats to **selected organization teams**, ideally teams synchronized from Northwind's identity provider. This keeps onboarding and offboarding tied to team membership.

Use organization-scoped assignment because direct assignment to **enterprise teams supports Copilot Business only**. If Northwind wants Copilot Enterprise for `engineering`, enable that plan for the organization, then assign its seats through organization teams.

Do not replace inherited enterprise policies blindly. First record each effective enterprise and organization setting as **Enabled**, **Disabled**, **Let organizations decide**, or **Unconfigured**. Then change only the settings required for the pilot.

## Phase 0 — Read-only assessment

An enterprise owner or AI manager should capture the following before rollout:

1. **Contract and plan**
   - Confirm whether Northwind already has Copilot Business or Copilot Enterprise.
   - Confirm the contracted seat price, billing entity, billing cycle, and any GHE.com or data-residency terms.
   - Confirm whether `engineering` is already enabled and which plan it uses.

2. **Seat state**
   - Export enterprise and `engineering` seat assignments.
   - Identify duplicate assignments from other organizations or enterprise teams.
   - List active, pending-cancellation, and inactive seats.
   - Inventory `engineering` teams and their IdP synchronization status.

3. **Inherited AI controls**
   - Review enterprise **AI controls** for features, clients, models, agents, MCP, content exclusion, and paid AI-credit usage.
   - Review the separate **Policies for enterprise-assigned users** setting. It does not govern users licensed through `engineering`, but it matters if direct enterprise assignment is later introduced.
   - Review `engineering` → **Settings → Copilot** and note which controls are locked by the enterprise.
   - Check users who receive seats from multiple organizations. The least restrictive policy usually applies within one enterprise, with documented exceptions.

4. **Upcoming default-policy change**
   - The **Default policy for new features** is configured but does not become active until **October 22, 2026**. It is enabled by default. Unless Northwind wants unconfigured GA features enabled automatically, disable it before October 22 or explicitly configure every eligible policy.

5. **Existing governance assets**
   - Check whether `engineering/.github-private` exists.
   - Check whether an organization is already selected as the enterprise source for managed settings and custom agents.
   - Inventory existing `copilot/managed-settings.json`, team overrides, enterprise agents, organization instructions, repository instructions, rulesets, MCP registries, and MCP allowlists.

### Optional read-only API checks

These examples are **not executed**. They require an authorized account and must target the dedicated API host.

```bash
gh api --hostname northwind.ghe.com \
  -H 'X-GitHub-Api-Version: 2026-03-10' \
  /enterprises/northwind/copilot/billing/seats

gh api --hostname northwind.ghe.com \
  -H 'X-GitHub-Api-Version: 2026-03-10' \
  /orgs/engineering/copilot/billing

gh api --hostname northwind.ghe.com \
  -H 'X-GitHub-Api-Version: 2026-03-10' \
  /enterprises/northwind/copilot/custom-agents/source

gh api --hostname northwind.ghe.com \
  -H 'X-GitHub-Api-Version: 2026-03-10' \
  /enterprises/northwind/copilot/custom-agents
```

**Preview warning:** all Copilot user-management REST endpoints, including the two billing and seat reads above, are in public preview and may change. The custom-agent REST page does not currently label its endpoints as preview, although the custom-agent feature itself is in public preview.

## Phase 1 — Billing guardrails

Before assigning a seat:

1. Choose the plan for `engineering`:
   - **Copilot Business:** published list price is $19 USD per user/month and includes 1,900 AI credits per user/month.
   - **Copilot Enterprise:** published list price is $39 USD per user/month and includes 3,900 AI credits per user/month.
2. Confirm Northwind's contract. GHE.com purchases may require GitHub Sales, and contracted pricing can differ from published pricing.
3. Confirm whether data-resident Copilot requests receive the documented **10% model multiplier increase**.
4. Decide whether paid AI-credit usage is allowed. It is enabled by default for organizations and enterprises unless an administrator disables it.
5. Set a universal user budget and an enterprise or `engineering` budget with a hard stop before the pilot.
6. Decide how Copilot code review is billed:
   - **Member:** uses the licensed member's entitlement; the review fails if that allowance is exhausted.
   - **Organization:** bills `engineering`; this requires AI-credit paid usage to be enabled for the organization.

**Recommended pilot setting:** use organization billing for automatic reviews only if `engineering` has a strict hard-stop budget. Otherwise, begin with member billing and manual reviews.

### Billing uncertainties to resolve

- Contracted Business or Enterprise seat rate.
- Exact pilot team membership and resulting unique seat count.
- Proration for seats added during the current cycle and possible proration of included AI credits.
- Whether Northwind's GHE.com configuration incurs the data-residency model multiplier.
- Review volume, selected review depth, model mix, CLI usage, and agent-session length.
- GitHub Actions minutes used by code review; Balanced reviews may use more AI credits and marginally more Actions minutes.
- Additional AI-credit spend after the pooled allowance is exhausted. The published rate is $0.01 USD per credit.
- Duplicate seats. A person licensed by multiple organizations in the same enterprise is billed once, but GitHub may choose the billed organization each cycle. Avoid duplicates to keep budgets predictable.
- Seat removal takes effect for billing at the end of the cycle; no refund is issued for unused time.

## Phase 2 — Enable `engineering` and assign seats

### Manual settings

1. In enterprise **Billing and licensing → Licensing → Copilot**, enable Copilot for selected organizations.
2. Assign `engineering` the approved plan.
3. In `engineering` → **Settings → Copilot → Access**, choose selected members or teams rather than all members.
4. Set the public-code-suggestions policy before using seat-assignment APIs; GitHub requires it for team assignment.
5. Synchronize pilot IdP groups to GitHub teams where possible.
6. Assign seats to the pilot teams. Use individual seats only for documented exceptions.
7. Record the initial unique seat count and estimated monthly license cost.

### API alternative — public preview

The mutation below is a **plan example only** and must not be run until the team slugs, plan, budget, and approval are confirmed:

```bash
gh api --hostname northwind.ghe.com \
  --method POST \
  -H 'X-GitHub-Api-Version: 2026-03-10' \
  /orgs/engineering/copilot/billing/selected_teams \
  --input approved-teams.json
```

`approved-teams.json` would contain only approved team slugs:

```json
{
  "selected_teams": ["TEAM-SLUG-1", "TEAM-SLUG-2"]
}
```

**Preview warning:** the Copilot team-seat assignment API is in public preview. Prefer the web UI for the first rollout. Do not use direct enterprise-team assignment if `engineering` requires Copilot Enterprise; direct enterprise assignment currently grants Copilot Business licenses only.

## Phase 3 — Policy configuration

Use the enterprise layer for non-negotiable controls. Use **Let organizations decide** only where `engineering` needs a pilot-specific choice. Explicitly configure inherited or unconfigured settings instead of relying on defaults.

**Manual:** enable **Copilot in GitHub.com** for `engineering` if code review, organization instructions, or cloud-agent workflows need it. Review the separate **Opt in to preview features** setting before enabling it. That switch can expose previews beyond the custom-agent pilot, so enable it only if the required feature is unavailable without it and record the accepted preview scope.

### Copilot CLI

- **Manual:** enable the Copilot CLI policy for `engineering` through enterprise and organization AI controls.
- Keep Copilot cloud agent disabled unless Northwind also wants CLI `/delegate`; both policies must be enabled for delegation.
- Require developers to authenticate their IDE and command-line environment against `northwind.ghe.com`. This is a client-side onboarding step.
- Apply content exclusions; enterprise, organization, and repository exclusions also apply to CLI.
- Note a control gap: users can provide their own local LLM keys to Copilot CLI, and enterprise Copilot policies do not control those keys.

### Managed settings

Create or reuse `engineering/.github-private` and select `engineering` as the enterprise governance source. Store:

```text
copilot/managed-settings.json
copilot/team-mappings.json
copilot/teams/*.json
agents/*.agent.md
```

Start with a reviewed `managed-settings.json` that:

- disables bypass or allow-all permission mode;
- requires approval for sensitive operations;
- denies dangerous commands and sensitive paths;
- defines approved and denied MCP servers;
- sets an approved default model or `auto`;
- enables sandboxing where supported;
- restricts sandbox network hosts where required.

Use enterprise-team overrides only for a clear operational need. Server-managed settings may take about an hour to refresh; client restart or sign-in can force a refresh. For controls that must survive a server outage, also deploy MDM-managed settings because MDM takes precedence and server-managed settings may be unavailable when no cached policy exists.

### Managed instructions

Use two layers because organization instructions do not cover every client:

1. **Manual organization setting:** `engineering` → **Settings → Copilot → Custom instructions**. Keep these instructions short and broadly applicable. They currently apply to Copilot Chat, code review, and cloud agent on GitHub, not Copilot CLI or IDE chat.
2. **Repository files:** add `.github/copilot-instructions.md` to pilot repositories. Add path-specific `.github/instructions/*.instructions.md`, `AGENTS.md`, or `REVIEW.md` only where needed. These cover more development surfaces, including CLI.

Repository instructions override organization instructions when they conflict. Review the instruction text for contradictions before rollout.

### MCP controls

- **Manual:** enable **MCP servers in Copilot** for `engineering`.
- Use `allowedMcpServers` and `deniedMcpServers` in `copilot/managed-settings.json` as the enforcement source.
- Begin deny-by-default and approve servers by exact URL, package command, and version where practical.
- Keep secrets out of agent profiles and repositories. Use approved secret storage and narrow credentials.
- The Copilot MCP policy does **not** govern the GitHub MCP server used from unrelated third-party host applications. Govern those clients separately.

Do not use registry-only enforcement for this rollout. **Restricting MCP access to a custom registry is in public preview, and GitHub currently recommends the generally available managed-settings allowlist instead.** A registry can still be used for discovery after security review.

## Phase 4 — Copilot code review

1. **Manual:** enterprise **AI controls → Available Agents → Copilot code review**. Enable it for `engineering` or let the organization decide, depending on the inherited setting.
2. Start with manual review requests on a small repository set.
3. Choose Lite or Balanced review depth after measuring quality and credit usage.
4. Enable **Only allow Copilot code review to be triggered by authorized users** to prevent external licenses from charging or invoking reviews in Northwind repositories.
5. Keep **Copilot approvals disabled** during the pilot.
6. After validation, create an enterprise-level branch ruleset targeting selected `engineering` repositories and enable **Automatically request Copilot code review**. Do not review drafts or every push initially; both options can add noise and cost.
7. Add repository or organization instructions that define Northwind's review priorities, security rules, and test expectations.

**Preview warning:** allowing Copilot approvals to count toward merge requirements is in public preview. The rollout should leave it off.

## Phase 5 — Enterprise custom agents

1. Use `engineering/.github-private` as the designated enterprise source.
2. **Manual:** select that source under enterprise **AI controls → Agents**.
3. Protect `agents/**`, `.github/agents/**`, and `copilot/**` with a ruleset. Require pull requests and designated reviewers from platform engineering and security.
4. Test agents privately under `.github/agents/` in the governance repository.
5. Release approved agents by moving their profiles to `/agents` on the default branch.
6. Give each agent the smallest useful tool set. Avoid broad write tools unless the use case requires them.
7. Add `include-custom-instructions: true` only when a subagent must consume repository instructions.
8. Validate the agents in Copilot CLI and on GitHub. Monitor enterprise audit logs for agent activity.

**Preview warning:** Copilot custom agents are in public preview and subject to change. Their support is also preview in some IDEs. Treat agent profiles as versioned code and keep a rollback commit.

## Preview and manual-setting register

| Item | Status on October 9, 2026 | Rollout decision |
|---|---|---|
| Copilot user-management REST APIs, including seat reads and team assignment | **Public preview API** | UI first; API only after approval and validation |
| Enterprise custom agents | **Public preview feature** | Limited pilot; protected source and rollback |
| Custom-agent REST endpoints | Current REST page does **not** label the endpoints preview; underlying feature is preview | Read-only validation acceptable; prefer UI for source changes |
| MCP registry-only restriction | **Public preview**, not GitHub's recommended enforcement method | Do not use; use managed-settings allowlist |
| Copilot approvals counting toward merge requirements | **Public preview** | Keep disabled |
| Model access assigned through enterprise teams | **Opt-in preview** | Out of scope; do not enable |
| Organization custom instructions | Manual UI setting with limited surface support | Enable for `engineering`; add repository files for CLI/IDE coverage |
| Copilot plan and organization enablement | Manual billing setting | Enterprise owner action |
| Paid AI-credit usage and budgets | Manual billing settings | Configure before seats |
| CLI, MCP, code review, models, preview opt-in, and inherited policies | Manual AI-control settings | Record effective state, then change narrowly |
| Governance source and protective ruleset | Manual AI-control/repository settings | Configure before releasing agents or settings |
| Automatic code review | Manual enterprise ruleset | Add only after the manual-review pilot |
| GHE.com client authentication | Manual endpoint configuration on developer machines | Include in onboarding |
| Default policy for new GA features | Manual enterprise/org policy; activates October 22, 2026 | Disable or explicitly configure before activation |

## Pilot exit criteria

Proceed beyond the pilot only when:

- every licensed user belongs to an approved team or documented exception;
- inherited enterprise and organization policies match the approved control matrix;
- no unexpected organization can assign seats;
- paid usage and hard-stop budgets behave as intended;
- CLI users can authenticate to `northwind.ghe.com` and receive managed settings;
- unapproved MCP servers are blocked;
- code review follows Northwind instructions and stays within the budget;
- custom agents load from the designated source and cannot bypass protected controls;
- audit logs show expected seat, policy, review, MCP, and agent activity;
- the October 22 default-feature-policy change has been addressed.

## Rollback

- Remove pilot teams from Copilot access. Team-assigned seats enter pending cancellation unless users retain access elsewhere.
- Disable CLI, MCP, code review, and custom agents at the narrowest effective scope.
- Revert governance-repository changes to the last approved commit.
- Disable automatic-review rulesets.
- Preserve exported seat, usage, policy, and audit data for the review.
- Remember that removing seats does not refund the current cycle, and access or billing timing depends on whether access is unassigned, revoked, or the plan is disabled.

## Primary GitHub documentation consulted

- GitHub Copilot policies for enterprises and organizations
- Feature availability when GitHub Copilot policies conflict in organizations
- Granting users access to GitHub Copilot in your enterprise
- REST API endpoints for Copilot user management, API version `2026-03-10`
- Administering Copilot CLI for your enterprise
- Getting started with enterprise-managed settings
- Enterprise managed settings
- Configuring an MCP server allowlist for your enterprise
- Restrict MCP server access to a custom registry
- Configuring code review by GitHub Copilot
- Adding organization custom instructions for GitHub Copilot
- Support for different types of custom instructions
- Preparing to use custom agents in your enterprise
- Testing and releasing custom agents in your organization or enterprise
- REST API endpoints for Copilot custom agents, API version `2026-03-10`
- Usage-based billing for organizations and enterprises
- GitHub Copilot seats and billing cycles for organizations and enterprises
