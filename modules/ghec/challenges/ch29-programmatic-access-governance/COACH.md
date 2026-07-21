# Ch29 — Programmatic Access Governance — Delivery Assurance

Apply the [Delivery Assurance Standard](../../../DELIVERY_ASSURANCE.md). The paired `README.md` is canonical.

## Assurance record

- **Authorized scope:** customer organization, inspection role, and enterprise-policy boundary.
- **Evidence:** inventory, Settings/API/audit snapshots, effective-source assessment, and register rows.
- **Open risk:** unowned access, incompatible automation, or unmanaged exception; name its owner.
- **Next decision:** pilot, migration, exception, policy export, or review date with owner.

## Reviewer focus

- Confirm all four controls are in the customer register: `INT-OAUTH-RESTRICTIONS`, `INT-APP-REVIEW`, `INT-FINE-GRAINED-PATS`, and `INT-CLASSIC-PATS`.
- Ask: “What breaks if OAuth restrictions are enabled for the first time?” Existing OAuth Apps are disrupted until approved; this is not a required pilot.
- Ask: “Which installed App can access what, who authorized it, and when is it reviewed again?”
- Confirm the only optional pilot is non-production fine-grained-PAT approval; classic-PAT restriction and broad lifetime enforcement remain inspect-and-propose unless separately authorized.
- For EMU, verify SCIM lifecycle and any administrator exemption are recorded with scope, expiry, owner, and reconciliation plan.
