# Activity 6: Security Overview, Delegated Triage & Campaign Operations

Turn a live alert backlog into a published security campaign with named owners and measurable burn-down. You will also repair one coverage gap and run an expiring exception through delegated review.

## Before you start

- Complete `ghas-admin-02`, `ghas-admin-04`, and `ghas-admin-05`.
- Work as an organization owner or security manager who can view Security Overview and create campaigns.
- Ask a developer with write access to the fixture repository to join the access test.
- Confirm delegated dismissal is configured for the alert type you will review.
- Use the customer's approved issue or risk system for exception ownership and expiry.

GitHub stores alert and campaign state. The approved risk system stores the exception approval, expiry, and return path.

## Set up the alert corpus

Reuse the fixture from `ghas-admin-01`, or provision it now:

```bash
bash modules/ghas/resources/provisioning/challenges/admin-01-06-security-configuration-campaigns-fixture/provision.sh \
  provision --org <org>
```

```powershell
modules/ghas/resources/provisioning/challenges/admin-01-06-security-configuration-campaigns-fixture/provision.ps1 `
  provision -Org <org>
```

The fixture imports OWASP Juice Shop at the pinned `v20.0.0` tag. It seeds CodeQL, Dependabot, and a non-live secret so the repository can produce a mixed alert queue. Wait for the CodeQL workflow and GitHub security features to finish their first analysis.

## Exercise

### 1. Verify the corpus through the API

Count each alert type:

```bash
gh api repos/<org>/ghas-admin-01-06-security-operations/code-scanning/alerts \
  --paginate --jq 'length'

gh api repos/<org>/ghas-admin-01-06-security-operations/dependabot/alerts \
  --paginate --jq 'length'

gh api repos/<org>/ghas-admin-01-06-security-operations/secret-scanning/alerts \
  --paginate --jq 'length'
```

Query an organization-wide CodeQL slice:

```bash
gh api orgs/<org>/code-scanning/alerts --paginate \
  --jq '.[] | select(.state=="open") | {number, repo: .repository.name, rule: .rule.id, severity: .rule.security_severity_level}'
```

Record the query time and counts. If an alert type is empty, check its feature state and workflow result before continuing.

### 2. Repair one configuration gap

Open the organization's **Security and quality** view. In Coverage, filter to `ghas-admin-01-06-security-operations`.

Find one gap, such as:

- A missing security configuration attachment.
- Secret scanning or push protection disabled.
- Dependabot alerts or security updates disabled.
- A stale or failed CodeQL analysis.

Repair the gap in GitHub. Refresh Coverage and rerun the relevant API query until the new state appears. An `unaffected` row still needs investigation when the feature is off.

### 3. Set the campaign boundary

Choose a finite set of code scanning alerts from the default branch. Record:

- The filters and starting count.
- Included repositories.
- Campaign manager and engineering sponsor.
- Due date and remediation guidance.
- Completion rule.
- Exception and escalation path.

Keep the campaign at or below 1,000 alerts. If the filtered set is larger, narrow it or split the work into separate campaigns. Check the existing published campaigns before adding another overlapping effort.

List the current campaigns:

```bash
gh api orgs/<org>/campaigns --paginate \
  --jq '.[] | {number, name, state, ends_at}'
```

### 4. Publish the campaign

Create the campaign from **Security and quality > Campaigns**. Use the filters from step 3, assign the manager, set the due date, and add practical remediation guidance.

Copy the campaign URL and number into the `ghas-admin-06: expiring exception and campaign burn-down` issue.

**A campaign plan does not complete this step.** The campaign must be published in GitHub.

### 5. Prove developer access

Ask the developer with write access to:

1. Open the published campaign.
2. Open the campaign-generated repository issue, when GitHub creates one.
3. Follow the guidance to an assigned alert.
4. Record any access failure without sharing sensitive alert data.

Fix the permission or assignment if the developer cannot reach the work. Repeating the administrator view is not an access test.

### 6. Run delegated review with an expiring exception

Choose one alert that has a defensible temporary exception. Add these fields to the approved exception record:

| Field | Required value |
| --- | --- |
| Alert and repository | Direct links |
| Business owner | Named approver |
| Technical reason | Evidence from the alert or runtime |
| Compensating control | Named control and latest test |
| Expiry | A date within 30 days |
| Return path | Fix, reapproval, or reopen |

Have the developer request dismissal. A delegated reviewer must approve or reject it against the record. The remediation owner cannot approve their own accepted risk.

If approved, verify the alert state and campaign count. Schedule the expiry review in the system that owns the exception. GitHub's dismissed state does not enforce the expiry date.

### 7. Change several real alerts

Move at least three real alerts to a new final state:

- Fix one campaign code scanning alert on `ghas-admin-06-campaign-remediation` and merge the change to the default branch.
- Complete the delegated dismissal from step 6, or reject it and fix the alert.
- Merge a Dependabot security update or make an equivalent reviewed dependency fix.
- Resolve the planted non-live secret alert after removing the value and recording the synthetic credential as revoked.

Use at least three of these paths. Wait for rescans and verify each final state through GitHub or the API. Keep fixed, dismissed, and resolved counts separate.

### 8. Measure burn-down

Capture the campaign's starting and ending open-alert counts. Calculate:

```text
burn-down = starting open alerts - ending open alerts
completion rate = burn-down / starting open alerts
```

Record elapsed time, fixed alerts, approved dismissals, and remaining alerts. But do not report a dismissal as a code fix.

Open the campaign as the developer once more and confirm that its count and completion state match the alert changes.

### 9. Decide the next rollout wave

Approve the next repository set only when:

- The fixture has the intended security configuration.
- Scans are current.
- The developer can reach assigned campaign work.
- Exception ownership and expiry are active.
- The measured burn-down matches the underlying alert states.

Stop rollout for any unexplained attachment failure, stale scan, access failure, campaign limit breach, or overdue exception. Name the rollback owner and the condition that allows work to resume.

## Completion check

You are done only when you have:

- A repaired Coverage gap.
- A published campaign URL and number.
- A successful developer access test.
- At least three verified alert state changes.
- Starting and ending counts with calculated burn-down.
- One delegated decision tied to an exception that expires within 30 days.
- A rollout or stop decision with a named owner.

## Common failures

- Publishing a campaign that exceeds the alert or active-campaign limit.
- Treating the administrator view as proof that developers have access.
- Counting dismissed alerts as fixed code.
- Recording an exception only in an alert comment.
- Expanding rollout while coverage, scans, or campaign access still fail.

## References

- [About Security Overview](https://docs.github.com/en/enterprise-cloud@latest/code-security/concepts/security-at-scale/security-overview)
- [Security Overview permissions](https://docs.github.com/en/enterprise-cloud@latest/code-security/reference/permissions/security-overview)
- [About security campaigns](https://docs.github.com/en/code-security/concepts/security-at-scale/about-security-campaigns)
- [Creating and managing security campaigns](https://docs.github.com/en/code-security/how-tos/manage-security-alerts/remediate-alerts-at-scale/creating-managing-security-campaigns)
- [Participating in a code security campaign](https://docs.github.com/en/code-security/tutorials/manage-security-alerts/best-practices-for-participating-in-a-security-campaign)
- [Delegated alert dismissal](https://docs.github.com/en/code-security/concepts/security-at-scale/delegated-alert-dismissal)
- [REST API endpoints for security campaigns](https://docs.github.com/en/rest/campaigns/campaigns)
