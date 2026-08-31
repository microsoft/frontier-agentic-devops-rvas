# Customer-Owned GitHub Enterprise Cloud Governance Settings Register

**Purpose:** Record each approved governance decision, its effective
configuration, owner, rationale, and evidence.

**Scope:** Enterprise, organization, and repository controls. The customer owns
this register. It records each effective value and source level, including
enterprise inheritance and Enterprise Managed Users (EMU) constraints.

**Companion:** Use the
[GHEC and EMU Governance Control Catalogue](GOVERNANCE-CONTROL-CATALOGUE.md)
to select controls, check availability, and find the activity that produces
each decision. The catalogue is guidance; this register is the customer's
source of truth.

## Start here

1. Copy this file to the customer-owned repository, for example
   `docs/GOVERNANCE-SETTINGS-REGISTER.md`.
2. Record the customer scope, accountable governance owner, approvers, and
   review cadence below.
3. Add a row for every applicable catalogue Control ID. Start with controls
   covered by the customer delivery plan. When Ch52 is used, begin with the
   landing-zone rows below and add the remaining applicable catalogue controls.
4. Inspect the inherited or effective setting. Use an **approved pilot** only
   for a safely scoped change that the customer authorizes. Otherwise, use
   **inspect-and-propose** and attach the decision record.
5. Attach objective evidence: an API/configuration export, audit event,
   workflow result, or access test. Do not store secrets in this register.

## Customer scope

| Field | Customer value |
|---|---|
| Enterprise / organization |  |
| Identity model | Standard GHEC / EMU / other:  |
| Current and target organization count |  |
| Organization-boundary rationale |  |
| In-scope repositories or property cohorts |  |
| Governance owner |  |
| Approvers |  |
| Normal review cadence |  |
| Register location and evidence convention |  |

## Governance decisions

| Control ID | Domain | Setting / decision | Effective level and source | Delivery status | Desired or approved value | Rationale | Implementation path | Evidence | Accountable owner | Review cadence | Exception / rollback | Next decision |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `ENT-ORG-TOPOLOGY` | operating model | Current and target organization topology | Enterprise | `not started` | Smallest justified organization set with a named purpose and owner for each organization | Makes organization boundaries deliberate and reviewable | `inspect-and-propose` | Enterprise organization export and topology map | Enterprise governance owner | Annual and on M&A/regulatory change | Preserve access and repository ownership during consolidation |  |
| `ENT-ORG-BOUNDARIES` | operating model | Organization-count and boundary decision | Enterprise | `not started` | Organizations exist only for material work, governance, access, confidentiality, residency, external-collaboration, or open-source boundaries | Avoids both a forced single organization and unnecessary proliferation | `inspect-and-propose` | Boundary decision with rejected alternatives | Executive sponsor | Annual and on material change | Revisit before creating or consolidating an organization |  |
| `ENT-ORG-LIFECYCLE` | operating model | Organization charter, intake, and retirement process | Enterprise | `not started` | Every organization has an owner, approved purpose, baseline, and retirement path | Prevents orphaned and permanently experimental organizations | `inspect-and-propose` | Charter and lifecycle workflow | Enterprise governance owner | Annual | Require repository, team, billing, and access disposition before retirement |  |
| `ENT-ENTERPRISE-TEAMS` | access | Enterprise-team and IdP-group model | Enterprise | `not started` | Enterprise teams grant organization access, licenses, and delegated roles where supported | Centralizes high-impact membership decisions | `inspect-and-propose` | Enterprise-team export and IdP mapping | Identity owner | Quarterly | Retain a documented break-glass access path |  |
| `ENT-POLICY-DELEGATION` | governance | Enterprise enforcement and organization delegation | Enterprise, org, and repo | `not started` | Every material domain names the effective source, permitted org additions/overrides, and accountable delegate | Prevents local settings from being mistaken for enterprise policy | `inspect-and-propose` | Delegation/inheritance matrix and policy exports | Enterprise governance owner | Quarterly | Record time-bound exceptions and the winning effective setting |  |
| `ENT-UNAFFILIATED-USERS` | identity | Unaffiliated-user offboarding policy | Enterprise | `not started` | Users removed from every organization follow the approved removal or transfer path | Closes the enterprise membership lifecycle | `inspect-and-propose` | Enterprise People export and offboarding runbook | Identity owner | Monthly | Preserve approved records and break-glass accounts |  |
| `ENT-EMAIL-DOMAINS` | data protection | Restricted notifications and approved domains | Enterprise and org | `not started` | Notifications are limited to approved domains where required | Reduces information leakage to personal email accounts | `inspect-and-propose` | Enterprise policy and verified-domain inventory | Enterprise governance owner | Quarterly | Document approved domains and exception expiry |  |
| `ENT-DATA-RESIDENCY` | data governance | Hosting and residency model | Enterprise | `not started` | Region and affected organizations are explicitly recorded with feature constraints | Aligns platform placement with regulatory and business requirements | `inspect-and-propose` | Subscription/residency evidence and impact assessment | Enterprise governance owner | Annual and on regulatory change | Record migration dependencies or accepted exception |  |
| `FIN-COST-CENTER-MODEL` | cost | Enterprise cost-center structure | Enterprise or org | `not started` | Cost allocation follows accountable business units independently of organization topology | Avoids creating organizations solely for chargeback | `inspect-and-propose` | Cost-center export and resource-assignment map | Billing owner | Monthly | Reconcile unassigned resources before billing close |  |
| `ORG-BASE-PERMISSIONS` | access | Default member repository permission | Org; record enterprise override if present | `not started` | `read` or `none` | Least-privilege baseline; grants come through teams and roles | `approved pilot` | Org settings/API snapshot and before/after diff | Org owner | Quarterly | Revert only with explicit risk approval |  |
| `ACT-WORKFLOW-TOKEN` | automation | Default `GITHUB_TOKEN` permission | Org; record enterprise policy if inherited | `not started` | `read` by default; individual workflows request more only when justified | Reduces workflow write scope | `inspect-and-propose` | Actions policy export and CI evidence | Platform owner | Quarterly | Document approved write exceptions |  |
| `ENT-EMU-LIFECYCLE` | identity | Enterprise Managed Users lifecycle | Enterprise | `not applicable` unless EMU | IdP-managed SCIM provisioning and deprovisioning | Centralizes identity lifecycle | `inspect-and-propose` | IdP/SCIM configuration export and join/leave evidence | Identity owner | Monthly | Tested break-glass and rollback plan |  |

## Delivery status values

Use one of these values:

- `not started` — applicable but not yet assigned to a delivery activity.
- `inspecting` — the team is identifying the effective configuration and inheritance.
- `proposed` — inspect-and-propose decision awaits approval.
- `piloted` — approved, bounded configuration change has evidence.
- `adopted` — customer accepted the effective setting and owner/cadence.
- `exception` — accepted deviation with a named owner and expiry/review date.
- `unavailable` — the current reviewer cannot access the authoritative setting
  or export; record the requested evidence source and owner instead of treating
  the control as compliant.
- `not applicable` — the control does not apply because of licensing, identity
  model, product availability, or customer scope; record the reason in
  **Rationale**.

## Row quality checks

- **Control ID:** comes from the catalogue; do not invent a near-duplicate.
- **Effective level and source:** Write `enterprise`, `org`, or `repo`. Name
  the inherited policy or configuration that takes precedence.
- **Implementation path:** use `approved pilot` or `inspect-and-propose`.
- **Evidence:** link to a non-secret, time-bounded configuration export, test,
  audit event, workflow run, or customer decision record.
- **Accountable owner:** a named customer role or person, never `TBD`.
- **Exception / rollback:** State the safety condition, expiry, and reversal
  path when the team does not use the standard baseline.

## Maintenance

- Review changed and exception rows at the customer's normal governance sync.
- Review high-risk operational controls at the cadence recorded in the row.
- Compare the catalogue with the register each year. Add newly applicable
  controls, retire obsolete entries, and confirm ownership.
- Reassess a row whenever GitHub changes the available feature, inherited
  policy, licensing, identity model, or customer risk posture.
