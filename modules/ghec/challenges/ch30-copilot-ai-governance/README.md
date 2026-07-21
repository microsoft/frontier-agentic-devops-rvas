# Ch30 — Copilot & AI Governance

> Deliver an enterprise or organization AI-control decision package: effective Copilot policy, access lifecycle, data/code-exposure posture, agent boundaries, accountable owners, review cadence, and register evidence.

| | |
|---|---|
| Track | Admin & Governance |
| Difficulty | Advanced |
| Duration | ~4 hrs, multi-session |
| Minimum input | Enterprise owner access, or an authorized export from Enterprise AI Controls; inspect Copilot Business or Enterprise availability |
| App | none |
| EMU compatible | yes — assess features and constraints; no agent execution is required |

## Customer delivery target

- **Customer objective:** make deliberate, auditable enterprise AI-control decisions rather than enabling Copilot capabilities by default.
- **Customer-tenant target:** a decision package covering the seven controls below, their effective inheritance, named owners, review cadence, exceptions, and evidence in the customer governance register.
- **Approval boundary:** default to **inspect-and-propose**. One narrowly scoped policy pilot is optional and requires customer approval; do not provision an app, assign a seat, install an agent, configure an MCP server, or start an agent session for this activity.
- **Records to keep:** dated Enterprise AI Controls and organization-policy exports, seat/offboarding evidence, policy and risk decisions, approved MCP inventory, and an evidence link for every register row.
- **Handover:** the enterprise AI-controls owner accepts the baseline; identity, legal/privacy, security, procurement, and organization owners accept their assigned decisions and cadence.

## Prerequisites

- An enterprise owner, AI manager, or other authorized party able to export Enterprise AI Controls; an organization-owner policy export is acceptable when enterprise access is unavailable, provided the missing enterprise view is recorded as a limitation.
- Copilot Business or Copilot Enterprise availability must be inspected and recorded. If unavailable, record the affected controls as `not applicable` or `proposed` with the availability evidence; do not infer availability from a user interface alone.
- A named customer enterprise AI-controls owner, identity/offboarding owner, security/privacy owner, procurement or third-party-risk owner, and organization-policy owner.
- The customer-owned governance register, normally copied from `modules/ghec/resources/GOVERNANCE-SETTINGS-REGISTER-TEMPLATE.md`.

> [!IMPORTANT]
> This is an **AI governance** activity, not end-user Copilot training. It does not teach Copilot use, coding-agent use, or MCP use. It inspects policy and proposes controls only.

## Scope boundary

- **Ch30 owns:** `COP-SEAT-MANAGEMENT`, `COP-POLICY-DELEGATION`, `COP-PUBLIC-CODE-MATCHING`, `COP-GITHUB-COM`, `COP-THIRD-PARTY-AGENTS`, `COP-MCP-SERVERS`, and `COP-AGENTIC-STREAMING`.
- **Ch19 owns Copilot cloud-agent usage.** Do not run an issue, session, pull request, or cloud-agent pilot here. Record that the cloud agent is unavailable on **EMU-owned repositories** and refer any eligible, approved usage pilot to Ch19.
- Treat third-party coding agents, agent apps, MCP servers, and cloud agent as related but separate decision surfaces. An approval for one does not approve another.

## Tasks

### Part A — Establish authority, availability, and the evidence baseline

1. Record the enterprise and organizations in scope, identity model (including EMU and data residency where applicable), named owners, approvers, evidence location, and normal review cadence.
2. Inspect the Copilot subscription and availability. Record whether Copilot Business or Copilot Enterprise is available, which organizations are in scope, and any licensing, entitlement, or preview limitation.
3. Obtain a dated, non-secret export or screenshots of Enterprise **AI Controls** and the relevant organization Copilot-policy pages. Record the collector, date, URL/page, and any settings that cannot be viewed.
4. Start seven rows in the existing customer governance register using the control IDs in the scope boundary. For every row, capture the effective value, source level, delivery status, proposed path, evidence, named owner, cadence, exception/rollback, and next decision.

### Part B — Determine the effective policy and delegation model

5. In Enterprise AI Controls, inspect each relevant Copilot policy and whether the enterprise sets it, enables it for selected organizations, disables it, or delegates the choice to organizations. Export the effective baseline.
6. At each in-scope organization, inspect the resulting policy. Record the winning value and source as `enterprise`, `org`, or delegated; identify conflicts, exceptions, and organizations that must not inherit a broad enablement.
7. Define the delegation rule for `COP-POLICY-DELEGATION`: which policy choices may be made by organization owners, which require enterprise AI-controls approval, who approves exceptions, and how policy drift is reviewed.

### Part C — Govern seats and offboarding

8. Inspect the Copilot access model: eligible populations, enterprise or organization assignment method, team-based grants, inactive/unused-seat reporting, and the joiner/mover/leaver evidence source.
9. Document the offboarding control for `COP-SEAT-MANAGEMENT`. **Enterprise-team removal gives immediate Copilot removal; organization-level license revocation is billing-cycle delayed.** Make the identity owner account for that difference, including the compensating action, evidence, and escalation path.
10. Set a named identity owner and a monthly (or customer-approved) seat reconciliation cadence. Retain a dated seat report and one non-secret offboarding or removal evidence sample.

### Part D — Decide code, data, and GitHub.com posture

11. Inspect the public-code matching setting and record the effective value for `COP-PUBLIC-CODE-MATCHING`. Decide whether matching public-code suggestions remain disabled or document the approved IP/licensing risk acceptance, owner, expiry, and rollback.
12. Separately inspect and decide `COP-GITHUB-COM`: which Copilot features on GitHub.com are allowed, what data may be submitted, and the customer posture for product/data feedback. Do not treat this as the same setting as public-code matching.
13. Have legal/privacy and security owners record the rationale, data classification boundary, exception process, and review cadence for both decisions.

### Part E — Separate third-party agent and agent-app governance

14. Inspect the policy and effective availability for **third-party coding agents**. For `COP-THIRD-PARTY-AGENTS`, default to disabled/inspect-and-propose until enterprise security and third-party-risk review approve a defined organization scope.
15. Assess **agent apps separately**: they are GitHub Apps with an installation, permissions, selected-repository scope, vendor relationship, and app-review lifecycle. Record their installed/approved status and owner separately from the third-party coding-agent policy; neither decision implicitly enables the other.
16. Record vendor data handling, authorization scope, repository targeting, audit/evidence route, renewal cadence, and the condition that would disable or remove an approved agent or app.

### Part F — Assess MCP boundaries without enabling them

17. Inspect the enterprise and organization MCP policy, any applicable registry, and the effective allow/deny/delegated state for `COP-MCP-SERVERS`.
18. Inventory repository-scoped MCP configurations by repository path and revision, server identity, owner, transport/host, exposed tool scope, data classes reachable, authentication/secret handling, and approval status. Do not add or exercise a server.
19. Evaluate third-party-host boundaries independently from server function: outbound data, vendor terms, hosting region, retention, credentials, network access, logging, tool permissions, repository scope, and removal process. Produce an approved-server register or a documented prohibition.

### Part G — Watch agentic activity streaming; do not make it a pilot requirement

20. For `COP-AGENTIC-STREAMING`, inspect the enterprise monitoring and audit-log options, destination, retention, access, and evidence path. Record the feature's current availability.
21. Treat streaming as **watch-and-decide only**. It is available in public preview for enterprises using EMU or data residency; confirm that the customer's identity and data-residency posture qualifies before proposing it. It is not a mandatory pilot and must not be configured merely to complete this activity.
22. Name the monitoring owner and set a review date for preview availability, destination/retention approval, and the decision to remain proposed, run a separately approved pilot, or mark it not applicable.

### Part H — Finalize the decision package

23. Reconcile all seven register rows with the exports. Use `approved pilot` only for the one customer-authorized narrow policy change, if any; otherwise use `inspect-and-propose`.
24. Publish a concise decision summary: effective inheritance, allowed/delegated/prohibited boundaries, open risks, named owners, review cadence, exception/rollback path, evidence links, and next decision date.

## Control evidence checklist

| Control ID | Minimum decision and evidence |
|---|---|
| `COP-SEAT-MANAGEMENT` | Access model, seat report, enterprise-team/offboarding evidence, identity owner, reconciliation cadence |
| `COP-POLICY-DELEGATION` | Enterprise AI Controls plus org-policy export, effective source, delegation and exception decision |
| `COP-PUBLIC-CODE-MATCHING` | Effective value, IP/licensing rationale, approver, exception/rollback |
| `COP-GITHUB-COM` | GitHub.com features and data-feedback posture, privacy/security approval |
| `COP-THIRD-PARTY-AGENTS` | Effective agent policy, risk decision, vendor/repository boundary, review owner |
| `COP-MCP-SERVERS` | Policy/registry result, repository configuration inventory, approved-server or prohibition decision, third-party-host assessment |
| `COP-AGENTIC-STREAMING` | Availability check, preview qualification, destination/retention assessment, monitoring owner and review date |

## Validation / Definition of Done

- [ ] Copilot Business or Enterprise availability, enterprise authority or authorized export, scope, identity model, and named owners were recorded.
- [ ] Enterprise AI Controls and organization policies were inspected; every relevant setting records its effective value, inheritance source, and delegation decision.
- [ ] `COP-SEAT-MANAGEMENT` includes a seat/offboarding model, evidence, cadence, and the immediate enterprise-team-removal versus billing-cycle-delayed organization-revocation distinction.
- [ ] `COP-PUBLIC-CODE-MATCHING` and `COP-GITHUB-COM` have separate, approved data/code-exposure decisions.
- [ ] Third-party coding agents and agent apps were assessed separately, with no implied approval between the two.
- [ ] MCP policy, registry, repository configurations, tool/data scope, and third-party-host boundary were inventoried or explicitly prohibited without enabling a server.
- [ ] `COP-AGENTIC-STREAMING` is recorded as a preview availability/watch decision, not a mandatory pilot, with a monitoring owner and review date.
- [ ] The customer register contains all seven control IDs, dated objective evidence, named accountable owners, review cadence, exception/rollback, and next decision.
- [ ] Ch19 cloud-agent usage was not performed; the decision package explicitly states that cloud agent is unavailable on EMU-owned repositories.

## Reference links

- [Managing policies and features for GitHub Copilot in an organization](https://docs.github.com/en/enterprise-cloud@latest/copilot/how-tos/administer-copilot/manage-for-organization/manage-policies)
- [Managing access to GitHub Copilot](https://docs.github.com/en/enterprise-cloud@latest/copilot/how-tos/administer-copilot/manage-for-organization/manage-access)
- [Managing policies and features for GitHub Copilot in an enterprise](https://docs.github.com/en/enterprise-cloud@latest/copilot/how-tos/administer-copilot/manage-for-enterprise/manage-enterprise-policies)
- [GitHub Copilot policies for enterprises and organizations](https://docs.github.com/en/enterprise-cloud@latest/copilot/concepts/policies)
- [About agent apps](https://docs.github.com/en/enterprise-cloud@latest/copilot/concepts/agents/agent-apps)
- [Model Context Protocol and GitHub Copilot cloud agent](https://docs.github.com/en/enterprise-cloud@latest/copilot/concepts/agents/cloud-agent/mcp-and-cloud-agent)
- [Agent management for enterprises](https://docs.github.com/en/enterprise-cloud@latest/copilot/concepts/agents/enterprise-management)
- [Monitoring agentic activity in your enterprise](https://docs.github.com/en/enterprise-cloud@latest/copilot/how-tos/administer-copilot/manage-for-enterprise/manage-agents/monitor-agentic-activity)
