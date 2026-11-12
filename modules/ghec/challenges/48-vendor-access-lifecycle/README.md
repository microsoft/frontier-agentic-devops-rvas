# Ch48: Vendor access lifecycle

This optional outside-collaborator exercise applies to organizations using personal accounts. EMU customers need an approved managed guest or IdP process, which this guide doesn't cover. For EMU, record the exercise as not applicable or blocked. Don't invite a personal account.

**Session outcome:** An approved outside collaborator can read the selected private repository, then loses access after removal. The sponsor holds the grant and revocation evidence.

## Prerequisites

- Owner rights on a GitHub Enterprise Cloud organization.
- A token with the scopes listed by `modules/ghec/resources/provisioning/scripts/setup.sh doctor ch48 --org <org>`.
- Local tooling: `gh >= 2.x`, `git`, `jq`.
- A real vendor access review, or the seeded fallback register.

## Customer delivery objectives

You will:

- Inventory outside collaborators and pending invitations.
- Build an access register with owner, scope, permission, start and end date, and review cadence.
- Approve least-privilege vendor access through an issue or register row that leaves a trail.
- Test removal and offboarding, and check the audit log.
- Record exceptions and the next review date.

## Scenario

A customer uses outside collaborators for vendor work. Repository admins grant access, reviews are rare, and business approvals are hard to trace. Record each grant's scope, approver, expiry, review date, reviewer, and removal process.

> [!IMPORTANT]
> Use a real approved access review if you have one. If not, practice with `ghec-ch48-vendor-access-register`. Don't invite, remove, or change vendor access unless the customer explicitly approves the participant step.

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
6. If you're authorized, review the org settings for who can invite outside collaborators. Otherwise record a rollout proposal.

### Part C: Approve and grant access

7. Create or review an access request issue.
8. Check least privilege and the end date before any grant.
9. If explicitly approved, add the outside collaborator through the repository UI or API. Example only:
   ```bash
   gh api -X PUT repos/<org>/<repo>/collaborators/<username> -f permission=pull
   ```
10. Record the invitation URL and status. Store no personal or secret information beyond the approved register fields.

### Part D: Review and offboard

11. For each active vendor, confirm the business owner still approves access.
12. With approval, remove the test collaborator after they accept access. Use their identity to verify read access before removal and a denied fetch afterwards. Check all grants, including team and organization base permissions, before you interpret the result.
13. Capture the removal event and the denied-access result. Removing access can't recall existing local clones, so follow the customer's data-handling agreement. A register end date alone doesn't revoke access.

## Reference links

- [Managing outside collaborators](https://docs.github.com/en/organizations/managing-user-access-to-your-organizations-repositories/managing-outside-collaborators)
- [Adding outside collaborators](https://docs.github.com/en/organizations/managing-user-access-to-your-organizations-repositories/managing-outside-collaborators/adding-outside-collaborators-to-repositories-in-your-organization)
- [Removing outside collaborators](https://docs.github.com/en/enterprise-cloud@latest/organizations/managing-user-access-to-your-organizations-repositories/managing-outside-collaborators/removing-an-outside-collaborator-from-an-organization-repository)
- [Setting permissions for adding outside collaborators](https://docs.github.com/en/enterprise-cloud@latest/organizations/managing-organization-settings/setting-permissions-for-adding-outside-collaborators)
- [Reviewing the organization audit log](https://docs.github.com/en/organizations/keeping-your-organization-secure/managing-security-settings-for-your-organization/reviewing-the-audit-log-for-your-organization)
- [Outside collaborators REST API](https://docs.github.com/en/rest/orgs/outside-collaborators)
