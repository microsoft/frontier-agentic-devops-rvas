# Ch48: Vendor access lifecycle

This optional outside-collaborator exercise applies to organizations using personal accounts. EMU customers need an approved managed guest or IdP process, which this guide does not implement. Record this exercise as not applicable or blocked rather than inviting a personal account.

**Session outcome:** An approved outside collaborator can read the selected private repository, then loses access after removal. The sponsor has the grant and revocation evidence.

## Prerequisites

- An organization you own (or org-owner rights) on GitHub Enterprise Cloud.
- A token with the scopes listed by `modules/ghec/resources/provisioning/scripts/setup.sh doctor ch48 --org <org>`.
- Local tooling: `gh >= 2.x`, `git`, `jq`.
- A real vendor/access review candidate, or the seeded fallback register.

## Customer delivery objectives

You will:

- Inventory outside collaborators and pending invitations.
- Create an access register with owner, scope, permission, start/end date, and review cadence.
- Approve least-privilege vendor access through an auditable issue or register row.
- Validate removal/offboarding and audit log evidence.
- Record exceptions and next review date.

## Scenario

A customer uses outside collaborators for vendor work. Repository admins grant access, reviews are rare, and business approvals are hard to trace. Create a lifecycle that makes each vendor grant scoped, time-bound, reviewable, and removable.

> [!IMPORTANT]
> Use a real approved access review if available. If not, use `ghec-ch48-vendor-access-register` to practice the workflow. Do not invite, remove, or change vendor access unless the customer explicitly approves the participant step.

## Sample test repository or environment

```bash
bash modules/ghec/resources/provisioning/scripts/setup.sh provision ch48 --org <org>
```
```powershell
modules/ghec/resources/provisioning/scripts/setup.ps1 provision ch48 --org <org>
```

What setup creates:

- `ghec-ch48-vendor-access-register` with access request and review issue forms.
- Labels for requested, approved, active, review-due, offboarded, and exception states.
- A sample vendor access request issue.
- Printed outside-collaborator and pending-invitation snapshots when readable.

## Tasks

### Part A: Inventory current access

1. Snapshot outside collaborators and pending invitations:
   ```bash
   gh api /orgs/<org>/outside_collaborators --paginate
   gh api /orgs/<org>/invitations --paginate
   ```
2. Identify stale access, pending invitations, broad permissions, and missing business owners.
3. Record gaps in the access register.

### Part B: Define lifecycle controls

4. Define required fields: vendor, sponsor, repositories, permission, start date, end date, data classification, and review owner.
5. Decide who can approve new vendor access and who performs quarterly review.
6. If authorized, review org settings for who can invite outside collaborators. Otherwise record a rollout proposal.

### Part C: Approve and grant access

7. Create or review an access request issue.
8. Validate least privilege and end date before any grant.
9. If explicitly approved, add the outside collaborator through the repository UI or API. Example only:
   ```bash
   gh api -X PUT repos/<org>/<repo>/collaborators/<username> -f permission=pull
   ```
10. Record the invitation URL/status without storing personal or secret information beyond the approved register fields.

### Part D: Review and offboard

11. For each active vendor, confirm the business owner still approves access.
12. With approval, remove the test collaborator after they have accepted access. Use their identity to verify read access before removal and a denied fetch afterwards. Check all grants, including team and organization base permissions, before interpreting the result.
13. Capture the removal event and denied-access result. Removing access cannot recall existing local clones. Follow the customer's data-handling agreement. A register end date alone does not revoke access.

## Reference links

- [Managing outside collaborators](https://docs.github.com/en/organizations/managing-user-access-to-your-organizations-repositories/managing-outside-collaborators)
- [Adding outside collaborators](https://docs.github.com/en/organizations/managing-user-access-to-your-organizations-repositories/managing-outside-collaborators/adding-outside-collaborators-to-repositories-in-your-organization)
- [Removing outside collaborators](https://docs.github.com/en/enterprise-cloud@latest/organizations/managing-user-access-to-your-organizations-repositories/managing-outside-collaborators/removing-an-outside-collaborator-from-an-organization-repository)
- [Setting permissions for adding outside collaborators](https://docs.github.com/en/enterprise-cloud@latest/organizations/managing-organization-settings/setting-permissions-for-adding-outside-collaborators)
- [Reviewing the organization audit log](https://docs.github.com/en/organizations/keeping-your-organization-secure/managing-security-settings-for-your-organization/reviewing-the-audit-log-for-your-organization)
- [Outside collaborators REST API](https://docs.github.com/en/rest/orgs/outside-collaborators)
