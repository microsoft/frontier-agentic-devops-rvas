# Ch29 — Programmatic Access Governance — Delivery Assurance

Review the completed work against the [Delivery Assurance Standard](../../../DELIVERY_ASSURANCE.md) and the paired `README.md`.

## Assurance record

- **Authorized scope:** customer organization, inspection role, and enterprise-policy boundary.
- **Evidence:** inventory, Settings/API/audit snapshots, and effective-source assessment.
- **Open risk:** unowned access, incompatible automation, or unmanaged exception; name its owner.
- **Next decision:** pilot, migration, exception, policy export, or review date with owner.

## Reviewer focus

- Confirm OAuth restrictions, installed GitHub Apps, fine-grained PAT policy, and classic PAT policy were inspected separately.
- Ask: “What breaks if OAuth restrictions are enabled for the first time?” Existing OAuth Apps are disrupted until approved; this is not a required pilot.
- Ask: “Which installed App can access what, who authorized it, and when is it reviewed again?”
- Confirm the only optional test is non-production fine-grained-PAT approval; classic-PAT restriction and broad lifetime enforcement remain unchanged unless separately authorized.
- For EMU, verify SCIM lifecycle and any administrator exemption are recorded with scope, expiry, owner, and reconciliation plan.
