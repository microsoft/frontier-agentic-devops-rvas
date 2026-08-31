# Ch30 — Copilot & AI Governance

> Inspect enterprise and organization AI controls: effective Copilot policy, access lifecycle, data/code-exposure posture, agent boundaries, and direct evidence.

| | |
|---|---|
| Track | Admin & Governance |
| Difficulty | Advanced |
| Duration | ~4 hrs, multi-session |
| Minimum input | Enterprise owner access, or an authorized export from Enterprise AI Controls; inspect Copilot Business or Enterprise availability |
| App | none |
| EMU compatible | yes — assess features and constraints; no agent execution is required |

## Delivery target

- Delivery target: verified effective inheritance, named owners, review cadence, exceptions, and evidence for the AI-control surfaces below.
- Safety boundary: inspect without changing settings by default. One narrowly scoped policy test is optional and requires customer approval. Do not provision an app, assign a seat, install an agent, configure an MCP server, or start an agent session for this activity.
- Evidence: dated Enterprise AI Controls and organization-policy exports, seat/offboarding evidence, policy and risk decisions, and the MCP configuration inventory.
- Owner: the enterprise AI-controls owner accepts the baseline; identity, legal/privacy, security, procurement, and organization owners accept their assigned decisions and cadence.

## Prerequisites

- An enterprise owner, AI manager, or other authorized party able to export Enterprise AI Controls; an organization-owner policy export is acceptable when enterprise access is unavailable, provided the missing enterprise view is recorded as a limitation.
- Copilot Business or Copilot Enterprise availability must be inspected and recorded. If unavailable, retain the availability evidence and identify which policy surfaces cannot be verified; do not infer availability from a user interface alone.
- A named customer enterprise AI-controls owner, identity/offboarding owner, security/privacy owner, procurement or third-party-risk owner, and organization-policy owner.

> [!IMPORTANT]
> This is an **AI governance** activity, not end-user Copilot training. It does not teach Copilot use, coding-agent use, or MCP use. It inspects policy and proposes controls only.

## Scope boundary

- **Ch30 covers:** seat management, policy delegation, public-code matching, GitHub.com feature/data posture, third-party coding agents, MCP servers, and agentic-activity streaming.
- **Ch19 owns Copilot cloud-agent usage.** Do not run an issue, session, pull request, or cloud-agent pilot here. Record that the cloud agent is unavailable on **EMU-owned repositories** and refer any eligible, approved usage pilot to Ch19.
- Treat third-party coding agents, agent apps, MCP servers, and cloud agent as related but separate decision surfaces. An approval for one does not approve another.
- Check whether `ghec-ch52` (Enterprise Landing Zone & Organization Strategy) has already established this customer's identity model (including EMU and data residency) and enterprise app-registration governance boundary. If so, reuse and cite its register entry as the preferred input for scope and the agent-app authority review in Part A/E instead of re-deriving it. If `ghec-ch52` has not been completed, establish them independently and record that `ghec-ch52` was not available — apply the same rule wherever this activity references `ghec-ch52` below.

## Tasks

### Part A — Establish authority, availability, and the evidence baseline

1. Record the enterprise and organizations in scope, identity model (including EMU and data residency where applicable), named owners, approvers, evidence location, and normal review cadence (see the `ghec-ch52` note above for the identity-model/data-residency source).
2. Inspect the Copilot subscription and availability. Record whether Copilot Business or Copilot Enterprise is available, which organizations are in scope, and any licensing, entitlement, or preview limitation.
3. Obtain a dated, non-secret export or screenshots of Enterprise **AI Controls** and the relevant organization Copilot-policy pages. Record the collector, date, URL/page, and any settings that cannot be viewed.
4. For each AI-control surface in scope, capture the effective value, source level, direct evidence, named owner, cadence, exception/rollback, and next decision.

### Part B — Determine the effective policy and delegation model

5. In Enterprise AI Controls, inspect each relevant Copilot policy and whether the enterprise sets it, enables it for selected organizations, disables it, or delegates the choice to organizations. Export the effective baseline.
6. At each in-scope organization, inspect the resulting policy. Record the winning value and source as `enterprise`, `org`, or delegated; identify conflicts, exceptions, and organizations that must not inherit a broad enablement.
7. Define which policy choices may be made by organization owners, which require enterprise AI-controls approval, who approves exceptions, and how policy drift is reviewed.

### Part C — Govern seats and offboarding

8. Inspect the Copilot access model: eligible populations, enterprise or organization assignment method, team-based grants, inactive/unused-seat reporting, and the joiner/mover/leaver evidence source.
9. Verify the offboarding behavior. **Enterprise-team removal gives immediate Copilot removal; organization-level license revocation is billing-cycle delayed.** Make the identity owner account for that difference, including the compensating action, evidence, and escalation path.
10. Set a named identity owner and a monthly (or customer-approved) seat reconciliation cadence. Retain a dated seat report and one non-secret offboarding or removal evidence sample.

### Part D — Decide code, data, and GitHub.com posture

11. Inspect the public-code matching setting and record the effective value. Decide whether matching public-code suggestions remain disabled or document the approved IP/licensing risk acceptance, owner, expiry, and rollback.
12. Separately inspect which Copilot features on GitHub.com are allowed, what data may be submitted, and the customer posture for product/data feedback. Do not treat this as the same setting as public-code matching.
13. Have legal/privacy and security owners record the rationale, data classification boundary, exception process, and review cadence for both decisions.

### Part E — Separate third-party agent and agent-app governance

14. Inspect the policy and effective availability for **third-party coding agents**. Keep them disabled until enterprise security and third-party-risk review approve a defined organization scope.
15. Assess **agent apps separately**: they are GitHub Apps with an installation, permissions, selected-repository scope, vendor relationship, and app-review lifecycle. Record their installed/approved status and owner separately from the third-party coding-agent policy; neither decision implicitly enables the other. Reuse `ghec-ch52`'s app-registration register when available (see the note above), or assess agent-app authority independently and record the gap.
16. Record vendor data handling, authorization scope, repository targeting, audit/evidence route, renewal cadence, and the condition that would disable or remove an approved agent or app.

### Part F — Assess MCP boundaries without enabling them

17. Inspect the enterprise and organization MCP policy, any applicable registry, and the effective allow/deny/delegated state.
18. Inventory repository-scoped MCP configurations by repository path and revision, server identity, owner, transport/host, exposed tool scope, data classes reachable, authentication/secret handling, and approval status. Do not add or exercise a server.
19. Evaluate third-party-host boundaries independently from server function: outbound data, vendor terms, hosting region, retention, credentials, network access, logging, tool permissions, repository scope, and removal process. Verify whether each discovered configuration is allowed or prohibited by the effective policy.

### Part G — Watch agentic activity streaming; do not make it a pilot requirement

20. Inspect the enterprise monitoring and audit-log options, destination, retention, access, and evidence path. Record the feature's current availability.
21. Treat streaming as **watch-and-decide only**. It is available in public preview for enterprises using EMU or data residency; confirm that the customer's identity and data-residency posture qualifies before proposing it. It is not a mandatory pilot and must not be configured merely to complete this activity.
22. Name the monitoring owner and set a review date for preview availability and destination/retention approval. Configure a test only through a separate customer-approved change.

### Part H — Verify and hand over

23. Reconcile the effective values and inheritance sources with the dated exports. Investigate any mismatch before handover.
24. Hand over the direct evidence, open risks, named owners, review cadence, exception/rollback paths, and next decisions to the enterprise AI-controls owner.

## Reference links

- [Managing policies and features for GitHub Copilot in an organization](https://docs.github.com/en/enterprise-cloud@latest/copilot/how-tos/administer-copilot/manage-for-organization/manage-policies)
- [Managing access to GitHub Copilot](https://docs.github.com/en/enterprise-cloud@latest/copilot/how-tos/administer-copilot/manage-for-organization/manage-access)
- [Managing policies and features for GitHub Copilot in an enterprise](https://docs.github.com/en/enterprise-cloud@latest/copilot/how-tos/administer-copilot/manage-for-enterprise/manage-enterprise-policies)
- [GitHub Copilot policies for enterprises and organizations](https://docs.github.com/en/enterprise-cloud@latest/copilot/concepts/policies)
- [About agent apps](https://docs.github.com/en/enterprise-cloud@latest/copilot/concepts/agents/agent-apps)
- [Model Context Protocol and GitHub Copilot cloud agent](https://docs.github.com/en/enterprise-cloud@latest/copilot/concepts/agents/cloud-agent/mcp-and-cloud-agent)
- [Agent management for enterprises](https://docs.github.com/en/enterprise-cloud@latest/copilot/concepts/agents/enterprise-management)
- [Monitoring agentic activity in your enterprise](https://docs.github.com/en/enterprise-cloud@latest/copilot/how-tos/administer-copilot/manage-for-enterprise/manage-agents/monitor-agentic-activity)
