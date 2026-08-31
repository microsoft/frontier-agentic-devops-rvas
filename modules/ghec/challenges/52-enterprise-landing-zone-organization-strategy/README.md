# Ch52 — Enterprise Landing Zone & Organization Strategy

> Inspect the enterprise topology and propose a justified organization-boundary strategy: organization count, charter and intake/retirement process, enterprise roles/teams model, delegation/inheritance matrix, and a populated governance settings register. Do not create organizations, teams, or repositories.

| | |
|---|---|
| Track | Admin/Governance |
| Difficulty | Advanced |
| Duration | ~5 hrs, multi-session |
| Minimum input | Enterprise owner access **or** authorized enterprise-policy export |
| App | none |
| EMU compatible | yes |

## Delivery target

- Delivery target: a topology map, a boundary decision, an org charter and intake/retirement process, a delegation/inheritance matrix, and a populated Governance Settings Register — not a new organization, migration, or production rollout.
- Safety boundary: inspect and propose. Change nothing in production by default; a bounded pilot (for example, a single test-organization setting) proceeds only with explicit customer authorization. Setup creates no organizations, teams, repositories, or custom properties.

## Scope boundary

This activity sets the enterprise-wide landing zone decision that other chapters implement in depth. Ch06 configures a single organization's member-privilege baseline; Ch07 models organization teams and repository roles; Ch10 operates billing and cost centers; Ch14 configures organization SAML/SCIM; Ch28 inspects enterprise identity, network, SSH CA, and enterprise-role controls; Ch44 detects repository-level policy drift. None of those activities decide **how many organizations the enterprise should have, why, or who owns the boundary** — that decision, and the register that tracks it, belongs here. Reuse their evidence where it exists; record the enterprise-wide decision and routing in this activity.

## Prerequisites

- Enterprise owner access **or** an authorized, current export of enterprise organization, identity, billing, and policy settings.
- A named executive sponsor and enterprise governance owner who can approve the boundary decision and charter.
- Local tooling: `gh >= 2.x` and `jq` for API inspection (no write scopes are required for the default inspect-and-propose path).
- Customer approval before any pilot change. Enterprise-owner access is required for a settings change; an export-only session remains inspection-only.

## What you will deliver

- An enterprise topology map: every organization (or an authorized representative subset), its purpose, membership size, sensitivity, and the enterprise hosting/data-residency context inherited by it.
- A justified organization count and a boundary decision naming the primary rationale and at least one rejected alternative.
- An org charter template and an intake/retirement process for creating or decommissioning an organization.
- An enterprise roles/teams model and a delegation/inheritance matrix covering identity, teams, lifecycle, offboarding, email, metadata/custom properties, data residency, app registrations, cost centers, Projects/Sponsors, and policy domains.
- A populated Governance Settings Register (shared resource) and a follow-on activity map that routes open findings to the chapter that will implement them.

## Scenario

A GHEC customer has grown an enterprise account by accretion: organizations were created ad hoc for pilots, acquisitions, and individual teams, nobody can say why there are as many as there are, enterprise-owner assignment has crept past the people who actually need it, and no one owns the decision to create or retire an organization. You will inspect the current topology, propose (not impose) a justified boundary, define the charter and lifecycle process, model enterprise roles/teams and their delegation limits, and populate the shared governance register so the customer's next organization decision is deliberate instead of accidental.

> [!IMPORTANT]
> Inspect-and-propose by default
>
> The default path is inspection and a written proposal. Do not create, merge, rename, or retire an organization; do not change enterprise-owner assignment, cost-center membership, custom properties, or data residency during this activity.
>
> - Have enterprise-owner access? Inspect live settings via the UI and API.
> - No owner access? Use a current, dated export of enterprise organization, identity, billing, and policy settings, and record its source and date.
> - If the customer authorizes a single bounded pilot (for example, one test-organization custom property or one charter dry run), record scope, owner, and rollback before acting.

## No sample resources are created

This activity provisions nothing. There is no `setup.sh provision ch52` step, no sample organization, team, or repository, and no seeded register. Copy `modules/ghec/resources/GOVERNANCE-SETTINGS-REGISTER-TEMPLATE.md` to a customer-owned evidence location and populate that copy; do not write customer evidence into the curriculum template.

## Tasks

### Part A — Map the enterprise topology and identity baseline

1. Enumerate every organization the enterprise owns (or an authorized representative subset for a very large enterprise), recording purpose, member count, visibility posture, and business owner:
   ```bash
   gh api /enterprises/<enterprise>/organizations --paginate --jq '.[] | {login, description}'
   ```
   or use the authorized policy export if API/UI access is unavailable.
2. Record the enterprise identity model: Enterprise Managed Users (EMU) or unmanaged/personal accounts; the IdP and supported SAML or OIDC protocol with its constraints; whether SSO/SCIM is enforced at the enterprise or per-organization level; the authoritative provisioning/offboarding path; and the effective 2FA requirement. For EMU, identify the enterprise SCIM owner and evidence source without attempting user provisioning. For non-EMU, record the 2FA rollout and member-removal risk without enabling enforcement in this activity.
3. Inventory existing enterprise teams (if any), their purpose, membership source (manual or IdP-synced), and the organizations each can access.
4. Record the enterprise hostname and hosting model (GitHub.com or GHE.com with data residency), the selected region where applicable, and the feature constraints inherited by its organizations. Do not imply that organizations inside one enterprise independently select different residency regions.

### Part B — Decide the organization boundary

5. List the candidate boundary drivers for this enterprise: related applications or services, compliance/regulatory isolation, security/blast-radius isolation, data residency, M&A or divestiture planning, external collaboration, and public/open-source work. Mark which apply and which do not. Treat billing or licensing alone as insufficient justification for another organization; use cost centers, teams, and license assignment instead.
6. Propose a justified organization count and structure (for example, "one org per regulated business unit plus one shared-services org") and name the primary rationale.
7. Name at least one rejected alternative (for example, "one org for the whole enterprise" or "one org per team") and record why it was rejected.
8. Record the accountable approver for the boundary decision and the review cadence for revisiting it (for example, annually or at each M&A event).

### Part C — Define the org charter and intake/retirement process

9. Draft an org charter template: required fields (owner, business justification, boundary driver, initial cost center, initial data-residency choice, initial custom properties, initial restricted-email/domain policy).
10. Inspect who is currently allowed to create organizations, then define the intake process: who requests a new organization, who approves and creates it, what baseline settings it inherits, and what evidence is captured.
11. Define the retirement/offboarding process: how an organization is decommissioned, how its unaffiliated members are identified and removed or transferred, and how repositories, teams, and cost-center assignments are retired or migrated.
12. Record the restricted-email/verified-domain decision: whether enterprise-level email-notification restriction is enforced, which domains are verified or approved, and any per-organization exception.

### Part D — Model enterprise roles, teams, and delegation

13. Export the enterprise People/role view (or the authorized export) and name every enterprise-owner holder, delegated enterprise role holder (billing manager, security manager, etc.), and their purpose. Minimize enterprise-owner assignment; name a target state if current assignment is broader than needed.
14. Define or confirm the enterprise-teams model: which teams exist or should exist, their IdP sync source, and which organizations/roles each is granted.
15. Build the delegation/inheritance matrix: for each governed domain (identity, network, repository policy, Actions policy, security defaults, packages, Pages, Copilot/AI policy, vendor/outside-collaborator access, custom properties, cost centers), record the effective enterprise-level setting, whether an organization may add a stricter/additive setting, and the accountable delegate.
16. Record the enterprise's custom-properties strategy (which properties are enterprise-mandated versus organization-optional), enterprise app-registration and installation authority, and cost-center structure (how organizations, repositories, enterprise teams, and users are assigned).
17. Record the applicability of enterprise-level Projects and GitHub Sponsors: whether either is in scope for this enterprise's landing zone, who owns the decision, and any policy constraint.

### Part E — Populate the register and hand over

18. Open `modules/ghec/resources/GOVERNANCE-CONTROL-CATALOGUE.md`, copy `modules/ghec/resources/GOVERNANCE-SETTINGS-REGISTER-TEMPLATE.md` to the customer-owned evidence location, and populate that copy for every applicable control ID with the current value or effective source, decision, accountable owner, and review/expiry date.
19. Build the follow-on activity map: for every open finding or deferred decision, name the existing chapter that will implement or deepen it (for example, route base-permission tuning to Ch06, the access matrix to Ch07, billing budgets to Ch10, SAML/SCIM to Ch14, enterprise identity/network detail to Ch28, drift detection to Ch44, packages policy to Ch45, Pages policy to Ch46, or vendor lifecycle to Ch48).
20. Present the topology map, boundary decision, charter/lifecycle process, roles/teams model, delegation matrix, and populated register to the executive sponsor and enterprise governance owner. Record the next decision: accept the boundary, pilot one organization or setting, schedule a phased rollout, or accept/document a named risk.

## Reference links

- [Enterprise accounts](https://docs.github.com/en/enterprise-cloud@latest/admin/concepts/enterprise-fundamentals/enterprise-accounts)
- [Roles in an enterprise](https://docs.github.com/en/enterprise-cloud@latest/admin/concepts/enterprise-fundamentals/roles-in-an-enterprise)
- [Teams in an enterprise](https://docs.github.com/en/enterprise-cloud@latest/admin/concepts/enterprise-fundamentals/teams-in-an-enterprise)
- [About Enterprise Managed Users](https://docs.github.com/en/enterprise-cloud@latest/admin/concepts/identity-and-access-management/enterprise-managed-users)
- [Adding organizations to your enterprise](https://docs.github.com/en/enterprise-cloud@latest/admin/managing-accounts-and-repositories/managing-organizations-in-your-enterprise/adding-organizations-to-your-enterprise)
- [Removing organizations from your enterprise](https://docs.github.com/en/enterprise-cloud@latest/admin/managing-accounts-and-repositories/managing-organizations-in-your-enterprise/removing-organizations-from-your-enterprise)
- [Controlling user offboarding](https://docs.github.com/en/enterprise-cloud@latest/admin/enforcing-policies/enforcing-policies-for-your-enterprise/control-offboarding)
- [Restricting email notifications for your enterprise](https://docs.github.com/en/enterprise-cloud@latest/admin/enforcing-policies/enforcing-policies-for-your-enterprise/restricting-email-notifications-for-your-enterprise)
- [Verifying or approving a domain for your organization](https://docs.github.com/en/organizations/managing-organization-settings/verifying-or-approving-a-domain-for-your-organization)
- [Custom properties](https://docs.github.com/en/enterprise-cloud@latest/admin/managing-accounts-and-repositories/managing-organizations-in-your-enterprise/custom-properties)
- [About GitHub Enterprise Cloud with data residency](https://docs.github.com/en/enterprise-cloud@latest/admin/data-residency/about-github-enterprise-cloud-with-data-residency)
- [Installing a GitHub App on your enterprise](https://docs.github.com/en/enterprise-cloud@latest/apps/using-github-apps/installing-a-github-app-on-your-enterprise)
- [Limiting OAuth app and GitHub App access requests and installations](https://docs.github.com/en/organizations/managing-programmatic-access-to-your-organization/limiting-oauth-app-and-github-app-access-requests-and-installations)
- [Cost centers](https://docs.github.com/en/billing/concepts/cost-centers)
- [Using cost centers to allocate costs to business units](https://docs.github.com/en/billing/how-tos/products/use-cost-centers)
- [About Projects](https://docs.github.com/en/issues/planning-and-tracking-with-projects/learning-about-projects/about-projects)
- [About GitHub Sponsors](https://docs.github.com/en/sponsors/getting-started-with-github-sponsors/about-github-sponsors)
- [Enforcing policies for your enterprise](https://docs.github.com/en/enterprise-cloud@latest/admin/enforcing-policies/enforcing-policies-for-your-enterprise)
