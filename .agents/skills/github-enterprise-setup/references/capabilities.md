# Capability map

Use this map to turn an outcome into discovery, interview, and plan areas. Select
only what the confirmed outcome needs.

## Outcome starters

| Outcome | Start with | Common dependencies |
|---|---|---|
| Enterprise baseline | identity, enterprise policy, audit, applications, billing | organizations, Actions, security, Copilot |
| New organization landing zone | organization, ownership, teams, repositories | Actions, security, Copilot |
| Existing organization alignment | organization policy, access, repositories | enterprise policy source |
| Team access model | members, teams, repository grants | identity source, base permissions |
| Repository factory | templates, properties, rulesets, standard files | teams, Actions, security |
| Copilot rollout | subscription, seat model, policies, instructions, agents | identity, teams, repositories, billing |
| Security enablement | entitlements, security configurations, repository coverage | Actions, teams, rollout plan |
| Actions platform | policy, workflow permissions, runners, environments | repositories, identity, billing |

## Capability areas

### Identity and authority

Assess:

- personal accounts with SAML or Enterprise Managed Users;
- enterprise owners and delegated enterprise roles;
- organization owners and custom organization roles;
- identity-provider and SCIM ownership;
- enterprise teams and IdP-linked groups;
- two-factor authentication requirements;
- outside-collaborator and guest paths.

Treat IdP, SAML, SCIM, recovery codes, and secret-bearing identity setup as manual
work unless a supported API gives a complete and safe path.

### Enterprise governance

Assess:

- organization creation and ownership model;
- repository creation and visibility policy;
- Actions policy and workflow-token defaults;
- rulesets and custom properties;
- personal access token and application policy;
- audit-log access and streaming;
- network allow-list posture;
- billing ownership and cost centers.

Record whether the enterprise locks, limits, or delegates each control.

Before recommending organization boundaries or delegated administration, read
[enterprise organization practices](https://docs.github.com/en/enterprise-cloud%40latest/admin/concepts/enterprise-best-practices/organize-work).
Compare the guidance with the customer's governance boundaries.

### Organizations

Assess:

- purpose and ownership;
- base repository permission;
- member repository creation;
- repository visibility and deletion controls;
- team creation;
- outside-collaborator invitations;
- two-factor state;
- default branch and repository defaults;
- inherited enterprise constraints.

For a new organization, confirm its owner, purpose, identity boundary, expected
repository visibility, and lifecycle owner before creation.

Before recommending owners or team membership management, read
[organization best practices](https://docs.github.com/en/enterprise-cloud%40latest/organizations/collaborating-with-groups-in-organizations/best-practices-for-organizations).
Check ownership continuity, including GitHub's recommendation for at least two
organization owners. Explain any customer-approved exception.

### Teams and repository access

Assess:

- enterprise teams versus organization teams;
- IdP-linked membership;
- parent and child team structure;
- privacy and notification settings;
- base permissions;
- direct collaborators;
- outside collaborators;
- team repository grants;
- custom repository roles.

Calculate effective access from enterprise membership, organization base
permission, team inheritance, direct grants, outside-collaborator grants, and
repository visibility. The highest applicable repository permission wins, but an
enterprise policy may still block the action.

Choose supported team operations from the
[Teams REST reference](https://docs.github.com/en/rest/teams).
Confirm whether each selected team is enterprise-managed or organization-managed
before selecting its endpoint.

### Repositories and templates

Assess:

- new versus adopted repositories;
- template source and ownership;
- visibility;
- default branch;
- merge methods;
- branch deletion;
- issues, discussions, wiki, and Projects;
- labels and CODEOWNERS;
- custom properties;
- repository and organization rulesets;
- standard workflows and instruction files;
- archival and transfer ownership.

Do not push generated content directly to an adopted production repository unless
the approved plan names that write path. Prefer a branch and pull request.

When planning template creation or repository settings, use the
[Repositories REST reference](https://docs.github.com/en/rest/repos)
to check the exact operation and payload.

### Actions and developer platform

Assess:

- enterprise and organization Actions permissions;
- selected-action allowlists;
- SHA pinning;
- default workflow-token permissions;
- fork workflow policy;
- reusable workflows;
- environments and reviewers;
- hosted and self-hosted runner strategy;
- runner groups and repository access;
- OIDC and cloud trust handoffs;
- retention, cache, and cost controls;
- Codespaces policy when selected.

Treat runner network access, OIDC trust, and external cloud provisioning as
separate security boundaries.

Before recommending workflow or runner controls, read the
[Actions secure use reference](https://docs.github.com/en/actions/reference/security/secure-use).
Use the [Actions REST reference](https://docs.github.com/en/rest/actions)
for supported policy and runner operations. Keep cloud-side trust work in its
own handoff.

### Code security and secret protection

Assess:

- product entitlements;
- security configurations;
- dependency graph and Dependabot;
- CodeQL default or advanced setup;
- secret scanning and push protection;
- delegated bypass;
- private vulnerability reporting;
- ruleset integration;
- current repository coverage;
- rollout waves and exception owners.

Do not claim coverage until the configuration is attached and the expected
analysis or scanning result exists.

For security-configuration operations, use the
[Code security REST reference](https://docs.github.com/en/rest/code-security).
Check both attachment state and the analysis or scanning evidence required by
the selected control.

### Copilot

Assess:

- enterprise or organization subscription;
- seat-management mode;
- organization teams, enterprise teams, and direct assignments;
- billing and inactive seats;
- GitHub.com, IDE, CLI, code review, and cloud-agent availability;
- model policies;
- public-code matching policy;
- content exclusion;
- MCP policy;
- custom instructions;
- custom agents and source organization;
- cloud-agent repository access and runners;
- metrics access and rollout evidence.

Copilot seat assignment can create recurring cost. Keep it in a separate batch
with named recipients, current assignments, estimated seat delta, and billing
owner approval.

For seats or usage data, select the endpoint from the
[Copilot REST reference](https://docs.github.com/en/rest/copilot).
For agent controls, read
[enterprise agent management](https://docs.github.com/en/enterprise-cloud%40latest/copilot/concepts/enterprise/agent-management)
and follow its policy-inheritance guidance. Distinguish documented API operations
from settings that need a manual handoff.

## Transparent profiles

Profiles seed recommendations. Expand them into explicit values and compare each
value with live state.

### Balanced

- Read base permission where the customer accepts broad internal discovery.
- Private and internal repository creation, with public creation owner-controlled.
- Read-only workflow tokens by default.
- Selected Actions policy with reviewed exceptions.
- Team-first repository access.
- Private repositories by default.
- Copilot enabled through scoped rollout groups.

### Regulated

- None base permission unless internal visibility is required.
- Central repository creation.
- Narrow Actions allowlist and stronger pinning requirements.
- Team or IdP-group access only.
- Security controls rolled out in measured waves with named exceptions.
- High-impact policy changes require change-owner approval and rollback evidence.

### InnerSource

- Internal repositories where the enterprise identity model permits them.
- Read access for enterprise members, with contribution through teams and pull
  requests.
- Visible ownership and contribution files.
- Reusable templates and discovery properties.
- Rules protect sensitive branches without blocking ordinary contribution.

### EMU controlled collaboration

- Treat the IdP as the identity and membership source.
- Do not invite personal accounts into managed-user organizations.
- Keep repositories private unless the collaboration model needs internal access.
- Use IdP groups or enterprise teams for access.
- Separate vendor access and expiry from employee access.
- Skip controls that do not apply to managed users, such as enterprise 2FA
  enforcement for personal accounts.
