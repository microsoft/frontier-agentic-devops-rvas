# Ch52 — Enterprise Landing Zone & Organization Strategy

> Map the enterprise and recommend an organization strategy: how many organizations it needs, what each one is for, how organizations are created or retired, who holds enterprise roles, and which settings the enterprise or each organization owns. Complete the governance settings register. Do not create organizations, teams, or repositories.

## Scope boundary

This activity makes the enterprise-wide organization decision that the other chapters build on. Ch06 sets a single organization's member-privilege baseline. Ch07 covers organization teams and repository roles. Ch10 covers billing and cost centers. Ch14 configures SAML/SCIM. Ch28 examines enterprise identity, network, SSH CA, and enterprise-role controls. Ch44 finds repository policy drift.

Those activities do not decide **how many organizations the enterprise needs, why they exist, or who can approve their boundaries**. Make that decision here, then record it in the governance settings register. Reuse evidence from the other chapters when it is available.

## Prerequisites

- Enterprise owner access **or** an authorized, current export of enterprise organization, identity, billing, and policy settings.
- A named executive sponsor and enterprise governance owner who can approve the organization strategy and charter.
- Local tooling: `gh >= 2.x` and `jq` for API inspection (no write scopes are required for the default inspect-and-propose path).
- Customer approval before any pilot change. Enterprise-owner access is required for a settings change; an export-only session remains inspection-only.

## Deliverables

- A topology map for every organization, or an approved representative subset. Include purpose, member count, sensitivity, and the hosting or data-residency context inherited from the enterprise.
- A recommendation for the number of organizations, its main reason, and at least one rejected option.
- An organization charter template, plus processes for creating and retiring organizations.
- An enterprise role and team model, plus a matrix that shows who owns settings across identity, teams, lifecycle, offboarding, email, custom properties, data residency, app registrations, cost centers, Projects, Sponsors, and policy.
- A completed Governance Settings Register and a map that sends open work to the chapter that owns it.

## Scenario

A GHEC customer added organizations for pilots, acquisitions, and individual teams. Years later, nobody can explain why the enterprise has this many organizations. Too many people hold the enterprise-owner role. Nobody owns the decision to create or retire an organization.

Inspect the topology. Recommend a boundary without changing it. Define the charter, lifecycle process, enterprise roles and team model, and delegation limits. Then update the shared governance register so the next organization decision has an owner and a record.

> [!IMPORTANT]
> Inspect-and-propose by default
>
> Start with inspection and a written proposal. Do not create, merge, rename, or retire an organization. Do not change enterprise-owner assignments, cost-center membership, custom properties, or data residency in this activity.
>
> - Have enterprise-owner access? Inspect live settings via the UI and API.
> - No owner access? Use a current, dated export of enterprise organization, identity, billing, and policy settings, and record its source and date.
> - If the customer authorizes one limited pilot, such as a test-organization custom property or a charter dry run, record its scope, owner, and rollback plan before you start.

## No sample resources are created

This activity creates nothing. There is no `setup.sh provision ch52` command, sample organization, team, repository, or prefilled register. Copy `modules/ghec/resources/GOVERNANCE-SETTINGS-REGISTER-TEMPLATE.md` to a customer-owned evidence location, then complete that copy. Keep customer evidence out of the curriculum template.

## Tasks

### Part A — Map the enterprise and identity baseline

1. List every organization in the enterprise, or an approved representative subset for a very large enterprise. Record its purpose, member count, visibility posture, and business owner:
   ```bash
   gh api /enterprises/<enterprise>/organizations --paginate --jq '.[] | {login, description}'
   ```
   Use the approved policy export when you cannot access the API or UI.
2. Record the identity model: Enterprise Managed Users (EMU) or unmanaged/personal accounts; the IdP; the SAML or OIDC protocol and its limits; where SSO/SCIM is enforced; the source of truth for provisioning and offboarding; and the effective 2FA requirement. For EMU, identify the enterprise SCIM owner and the evidence source. Do not provision users. For non-EMU, record the 2FA rollout and member-removal risk without enforcing either one.
3. List existing enterprise teams, if any. Record their purpose, membership source (manual or IdP-synced), and which organizations they can access.
4. Record the enterprise hostname and hosting model (GitHub.com or GHE.com with data residency), its selected region when relevant, and feature limits inherited by its organizations. Organizations in one enterprise cannot choose separate data-residency regions.

### Part B — Decide the organization boundary

5. Consider boundary drivers: related applications or services, regulatory isolation, security or blast-radius isolation, data residency, M&A or divestiture planning, external collaboration, and public or open-source work. Mark which apply. Billing or licensing alone does not justify another organization. Use cost centers, teams, and license assignment for those needs.
6. Recommend an organization count and structure. For example: one organization per regulated business unit, plus one for shared services. Name the main reason for the recommendation.
7. Record at least one rejected option, such as one organization for the whole enterprise or one per team, and explain why it does not fit.
8. Name the person who approves the organization strategy and set a review cadence, such as annually or at each M&A event.

### Part C — Define the org charter and intake/retirement process

9. Draft an organization charter template with the owner, business justification, boundary driver, initial cost center, initial data-residency choice, initial custom properties, and initial restricted-email or domain policy.
10. Check who can create organizations now. Define who requests one, who approves and creates it, its baseline settings, and the evidence to capture.
11. Define the retirement process. Cover decommissioning the organization, identifying and removing or transferring unaffiliated members, and retiring or moving repositories, teams, and cost-center assignments.
12. Record the restricted-email and verified-domain decision: whether the enterprise enforces email-notification restrictions, which domains are verified or approved, and any organization-level exception.

### Part D — Model enterprise roles, teams, and delegation

13. Export the enterprise People and role view, or use the approved export. Name each enterprise owner and delegated role holder (billing manager, security manager, and similar), along with their purpose. Keep enterprise-owner membership small. If too many people have it today, describe the target state.
14. Confirm or define the enterprise team model: which teams exist or should exist, their IdP sync source, and the organizations or roles granted to each one.
15. Build a delegation and inheritance matrix. For identity, network, repository policy, Actions policy, security defaults, packages, Pages, Copilot/AI policy, vendor or outside-collaborator access, custom properties, and cost centers, record the effective enterprise setting, whether an organization may make it stricter or add to it, and who is accountable.
16. Record the custom-property strategy: which properties the enterprise requires and which are optional for organizations. Also record who can register or install enterprise apps and how cost centers assign organizations, repositories, enterprise teams, and users.
17. Record whether enterprise-level Projects or GitHub Sponsors belong in this organization strategy. Name the decision owner and any policy limit.

### Part E — Populate the register and hand over

18. Open `modules/ghec/resources/GOVERNANCE-CONTROL-CATALOGUE.md`. Copy `modules/ghec/resources/GOVERNANCE-SETTINGS-REGISTER-TEMPLATE.md` to the customer-owned evidence location. For each relevant control ID, record the current value or effective source, decision, accountable owner, and review or expiry date.
19. Map each open finding or deferred decision to the chapter that will handle it. For example, send base-permission tuning to Ch06, the access matrix to Ch07, billing budgets to Ch10, SAML/SCIM to Ch14, enterprise identity or network detail to Ch28, drift detection to Ch44, packages policy to Ch45, Pages policy to Ch46, and vendor lifecycle to Ch48.
20. Present the topology map, organization strategy, charter and lifecycle process, role and team model, delegation matrix, and completed register to the executive sponsor and enterprise governance owner. Record the next decision: accept the strategy, pilot one organization or setting, plan a phased rollout, or accept and document a named risk.

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
