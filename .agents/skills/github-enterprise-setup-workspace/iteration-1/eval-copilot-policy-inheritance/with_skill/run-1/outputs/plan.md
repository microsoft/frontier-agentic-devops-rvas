# GitHub Enterprise Copilot rollout plan

## Outcome

Prepare a **Plan-mode** rollout for enterprise `northwind` on `northwind.ghe.com`.
Start with organization `engineering`. Assign paid seats through teams when the
identity model supports it. Include Copilot CLI, code review, managed instructions,
MCP controls, and enterprise custom agents.

No GitHub setting was changed.

## Target and authority

The live assessment is blocked:

- `gh auth status --active --hostname northwind.ghe.com --json hosts` found no
  authenticated account.
- A read of `/user` could not connect to `api.northwind.ghe.com`.
- The enterprise, organization, actor, roles, subscription, teams, billing state,
  and inherited AI policies remain **unverified**.

The next read needs an authenticated account on the named host and network access
to its API. The command that would start authentication is:

```bash
gh auth login --hostname northwind.ghe.com
```

This command was not run. After authentication, recheck the actor before requesting
any extra scope. Do not assume enterprise-owner, AI-manager, billing-manager, or
organization-owner authority from a successful login.

## Confirmed capability checklist

The request selects these areas:

- identity model and operator authority;
- enterprise policy inheritance;
- `engineering` organization and teams;
- Copilot subscription, seat mode, assignments, and billing;
- Copilot CLI and code review;
- organization instructions and enterprise managed settings;
- MCP policy and server allowlist;
- enterprise custom agents and their source organization;
- rollout evidence, audit events, and usage metrics.

Discovery should stay narrow: the enterprise, `engineering`, its teams, Copilot
billing summary, effective AI controls, and the `.github-private` repository. A
seat roster is sensitive and potentially large, so list it only after showing the
count and getting approval.

## Current effective state

No effective policy value is known. This matters because an organization setting
can look configurable while an enterprise policy still controls the result.

For each Copilot control, record:

| Control | Enterprise value | Organization value | Effective value | Effective source |
|---|---:|---:|---:|---|
| Copilot plan and seat mode | Unknown | Unknown | Unknown | Unknown |
| Copilot CLI | Unknown | Unknown | Unknown | Unknown |
| Copilot code review | Unknown | Unknown | Unknown | Unknown |
| Copilot approvals | Unknown | Unknown | Unknown | Unknown |
| Public-code matching | Unknown | Unknown | Unknown | Unknown |
| Preview feature opt-in | Unknown | Unknown | Unknown | Unknown |
| MCP servers in Copilot | Unknown | Unknown | Unknown | Unknown |
| MCP allowlist | Unknown | Unknown | Unknown | Unknown |
| Organization instructions | N/A or inherited constraint | Unknown | Unknown | Unknown |
| Managed settings | Unknown | Team override unknown | Unknown | Unknown |
| Custom-agent rules | Unknown | Unknown | Unknown | Unknown |
| Custom-agent source organization | Unknown | N/A | Unknown | Unknown |

Do not plan an override until discovery proves that the actor can change the
effective source.

## Decisions

Use these provisional choices once live state confirms they fit:

1. **Pilot boundary:** `engineering` only.
2. **Seat assignment:** assign organization teams first. Use enterprise teams when
   identity ownership and cross-organization use make them a better fit. Direct
   assignments are exceptions with an owner and expiry or review date.
3. **Code review:** enable reviews for the pilot. Keep Copilot approvals disabled
   at first because approvals can satisfy required-review rules and remain in
   public preview.
4. **Managed settings:** prefer server-managed settings in
   `engineering/.github-private` at `copilot/managed-settings.json`. Use a pull
   request and protected ownership. Use MDM or `/etc/github-copilot/managed-settings.json`
   only for controls that must survive a server-policy outage.
5. **MCP:** use the generally available `managed-settings.json` allowlist. Do not
   start with the preview custom-registry restriction.
6. **Enterprise custom agents:** use `engineering` as the source organization only
   if it owns the company-wide agent lifecycle. Store enterprise agents in
   `.github-private/agents/*.md` and protect those paths.
7. **Instructions:** keep organization instructions short. Put build, test, and
   repository-specific rules in repository instruction files. Confirm what the
   requester means by “managed instructions” before applying either form.

## Proposed batches

### Batch 0: Restore read access

**Risk:** manual prerequisite  
**Targets:** `northwind.ghe.com`, active operator  
**Actions:** authenticate after approval, confirm DNS or network access, then read
the actor and visible enterprises.  
**Acceptance:** the actor is identified without exposing a token, and GraphQL
returns enterprise slug `northwind`.  
**Recovery:** no GitHub change. Switch back to the prior CLI account if needed.

### Batch 1: Discover effective policy and billing state

**Risk:** read-only  
**Targets:** enterprise `northwind`, organization `engineering`  
**Actions:** verify stable IDs, roles, identity model, plan type, seat mode, billing
owner, AI-credit budgets, and the effective source of each selected AI policy.
Inspect team names and counts. Do not collect all seat usernames yet.  
**Acceptance:** every selected control has a value, source, timestamp, and permission
classification.

Candidate reads, pinned to API version `2026-03-10`:

```bash
GH_HOST=northwind.ghe.com gh api --hostname northwind.ghe.com user \
  -H 'X-GitHub-Api-Version: 2026-03-10' --jq '{login,id,type}'

GH_HOST=northwind.ghe.com gh api --hostname northwind.ghe.com graphql \
  -F slug=northwind -f query='
    query($slug:String!) {
      enterprise(slug:$slug) {
        id slug name
        organizations(first:100) { nodes { id login name } }
      }
    }'

GH_HOST=northwind.ghe.com gh api --hostname northwind.ghe.com \
  /orgs/engineering/copilot/billing \
  -H 'X-GitHub-Api-Version: 2026-03-10'

GH_HOST=northwind.ghe.com gh api --hostname northwind.ghe.com \
  --paginate /orgs/engineering/teams?per_page=100 \
  -H 'X-GitHub-Api-Version: 2026-03-10'

GH_HOST=northwind.ghe.com gh api --hostname northwind.ghe.com \
  /enterprises/northwind/copilot/custom-agents/source \
  -H 'X-GitHub-Api-Version: 2026-03-10'
```

The Copilot billing and seat-management API is **public preview**. Treat its schema
and token rules as unstable.

### Batch 2: Define team-based seat recipients

**Risk:** planning only until the recipient set and cost are known  
**Targets:** named `engineering` teams  
**Actions:** choose teams whose membership source is authoritative. Calculate the
unique new-seat delta, including users who already receive a seat from another
organization or enterprise team. Record direct-assignment exceptions separately.  
**Acceptance:** named teams, member counts, duplicate-seat handling, billing owner,
and estimated seat delta are documented.

### Batch 3: Assign Copilot seats

**Risk:** **high impact and recurring cost**  
**Targets:** approved team slugs only  
**API:** `POST /orgs/engineering/copilot/billing/selected_teams`  
**Preview:** yes, the Copilot user-management endpoints are public preview.  
**Preconditions:** Copilot Business or Enterprise subscription, selected assignment
mode, configured suggestion-matching policy, organization-owner authority, supported
token, exact team list, current billing read, and written billing-owner approval.  
**Acceptance:** the response reports expected seats, a separate read shows the
members assigned through the intended teams, and no unexpected direct recipients
appear.  
**Recovery:** removing a team sets affected seats to pending cancellation. Treat
removal as a separate high-impact batch.

No write command is ready because team slugs, seat delta, and billing approval are
unknown.

### Batch 4: Enable CLI and code review

**Risk:** high impact  
**Targets:** `engineering` through enterprise AI controls  
**Actions:**

- set Copilot CLI to the approved effective value;
- enable Copilot code review for `engineering`;
- leave Copilot approvals disabled during the pilot;
- decide whether reviews use the requester's entitlement or organization-paid AI
  credits;
- set an AI-credit budget or spending limit before automatic review at scale;
- add an enterprise ruleset for automatic review only after a small manual pilot.

**Manual setting:** use **Enterprise → AI controls → Copilot** for feature policies
unless current official documentation exposes a supported write endpoint for the
exact control. Do not automate an undocumented UI setting.

**Acceptance:** one consenting licensed user can use CLI, one pilot pull request
gets a review, an unauthorized path is blocked, and audit events identify the
policy change.

Copilot code review is generally available. **Copilot approvals are public preview.**
If `/delegate` from CLI is wanted, both the CLI and Copilot cloud-agent policies
must be enabled.

### Batch 5: Add instructions and managed settings

**Risk:** high impact because settings can govern agent permissions and tools  
**Targets:** `engineering/.github-private` and organization Copilot settings  
**Actions:**

- create or adopt a private `.github-private` repository;
- protect `copilot/managed-settings.json`, `/agents/*.md`, and
  `/.github/agents/*.md`;
- add `copilot/managed-settings.json` through a pull request;
- add organization custom instructions in
  **Organization → Settings → Copilot → Custom instructions**;
- add repository instructions through ordinary repository pull requests.

**Manual settings:** organization custom instructions are configured in the web
settings. MDM delivery and file-based delivery are handled by the endpoint-management
owner, outside GitHub.

**Acceptance:** a supported client loads the intended managed settings, precedence
is documented, and instruction tests cover GitHub.com code review plus the selected
developer clients.

GitHub's current docs have changed the labeling of organization instructions over
time. Treat their release status as **unverified on this host** until the UI and
current host documentation confirm it.

### Batch 6: Apply MCP controls

**Risk:** high impact  
**Recommended path:** define the approved MCP servers in enterprise
`managed-settings.json`. This is GitHub's generally available, recommended control.
Also set the “MCP servers in Copilot” policy at the effective enterprise scope.

**Preview alternative:** hosting a custom MCP registry and restricting clients to
“Registry only” is **public preview**. It also needs a separately operated HTTPS
registry. Use it only when it solves a requirement that managed settings cannot.

**Manual settings:** policy selection in enterprise AI controls, registry hosting,
TLS, service ownership, incident response, and any credentials used by MCP servers.
Never store MCP credentials in the plan or agent definitions.

**Acceptance:** approved servers run in Copilot CLI, an unapproved server is denied,
and a client cannot bypass the managed policy.

### Batch 7: Publish enterprise custom agents

**Risk:** high impact and preview feature  
**Targets:** `engineering/.github-private`, enterprise `northwind`  
**Actions:**

- add reviewed agent profiles under `/agents/*.md`;
- test them before company-wide release;
- set `engineering` as the enterprise custom-agent source;
- create or verify a ruleset protecting agent definition files;
- confirm the tools and MCP servers each agent may use.

**API candidate:** `PUT /enterprises/northwind/copilot/custom-agents/source` with
the verified numeric organization ID. The custom-agent feature is **public preview**,
so recheck the endpoint, API version, permissions, token type, and response schema
immediately before planning the write.

**Manual setting:** agent ownership, security review, release approval, and incident
response. The source organization decision needs an enterprise owner.

**Acceptance:** the enterprise endpoint reports `engineering` as the source, the
expected agents are listed, a pilot user can invoke one in CLI, and a changed agent
must pass the protected review path.

### Batch 8: Verify rollout and control cost

**Risk:** read-only plus manual evidence  
**Actions:** confirm effective policies, team-derived seat assignments, CLI access,
code-review behavior, managed-settings precedence, MCP denial tests, custom-agent
availability, audit events, and usage metrics. Review inactive seats after an agreed
window.  
**Acceptance:** each planned item is `verified`, `partially_verified`,
`manual_evidence_required`, or `blocked`.

## High-impact changes

Separate typed approvals are required for:

- paid seat assignment to named teams;
- enterprise or organization AI policy changes;
- automatic Copilot code-review rulesets;
- any setting that lets Copilot approvals satisfy branch requirements;
- managed settings that change agent permissions or tool access;
- MCP policy or allowlist changes;
- selecting the enterprise custom-agent source;
- seat removal or feature disablement.

Each approval must name the batch and targets. A generic “yes” is not enough.

## Billing and licenses

The following amounts are unknown and must not be represented as zero:

- current Copilot plan and contracted seat price;
- prorated seat charges;
- unique users added by each team;
- duplicate assignments across organizations or enterprise teams;
- users whose personal Copilot plan would be replaced;
- code-review AI-credit billing source;
- budgets, cost centers, and enterprise spending limits;
- extra AI-credit use from automatic reviews or agentic features;
- taxes, contract discounts, and data-residency terms.

GitHub bills a unique user once within an enterprise when multiple organizations
or enterprise teams assign that user, but the billing attribution can move between
assigning organizations. Confirm the current contract and API result before using
that behavior in a cost estimate.

## Preview register

| Item | Status to plan against | Guardrail |
|---|---|---|
| Organization and enterprise Copilot billing, seat listing, and seat assignment REST endpoints | Public preview | Pin API version `2026-03-10`; verify token type, schema, and permissions before each use |
| Enterprise custom agents | Public preview | Pilot first; protect source files; recheck source API |
| Copilot approvals | Public preview | Keep disabled in the first wave |
| MCP custom registry and “Registry only” restriction | Public preview | Prefer the generally available managed-settings allowlist |
| Organization custom instructions | Release label differs across current and older GitHub docs | Confirm the label and support matrix on `northwind.ghe.com` |

Copilot CLI itself and Copilot code review are not marked preview in the current
documentation reviewed for this plan. Optional CLI cloud sandboxes and computer-use
features are preview, but they are outside this rollout unless added later.

## Manual handoffs

1. **Network owner:** make `api.northwind.ghe.com` reachable and confirm the correct
   dedicated enterprise hostname.
2. **GitHub operator:** authenticate CLI after approval and prove the active actor.
3. **Enterprise owner or AI manager:** confirm effective AI policies and inherited
   values in Enterprise AI controls.
4. **Billing owner:** approve the named team list, seat delta, code-review billing
   source, budgets, and spending limits.
5. **Organization owner:** approve organization instructions and the
   `.github-private` repository workflow.
6. **Endpoint-management owner:** deploy MDM or file-based managed settings if used.
7. **MCP service owner:** operate any registry and review server authentication.
8. **Agent owner and security reviewer:** approve enterprise agent profiles and
   their tool permissions.

## Verification

After access is restored, rerun discovery and replace every unknown with timestamped
evidence. Before any write, refresh the actor, target IDs, policy source, recipient
set, billing estimate, and prerequisites.

The smallest useful pilot is one approved team, one repository, one CLI user, one
manual Copilot review, one denied MCP server, and one enterprise custom agent.

## Resume command

Resume in Plan mode with this output directory:

```text
Resume the GitHub Enterprise setup plan in .agents/skills/github-enterprise-setup-workspace/iteration-1/eval-copilot-policy-inheritance/with_skill/outputs/. Recheck northwind.ghe.com, the active actor, enterprise northwind, organization engineering, all inherited AI policies, and billing before changing the plan.
```
