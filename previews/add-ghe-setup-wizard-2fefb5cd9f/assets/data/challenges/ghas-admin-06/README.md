# Activity 6: Run a bounded security campaign

**Session outcome:** A developer completes a reviewed code fix in a published campaign. A rescan verifies the fix and the campaign shows its progress.

## Before you start

- Complete `ghas-admin-01` and `ghas-admin-03`, or show equivalent live configuration and CodeQL merge checks.
- Work as an organization owner or security manager who can view Security Overview and create campaigns.
- Ask a developer with write access to the selected repository to own a campaign fix.
- If you test delegated dismissal, confirm it is configured for the alert type.
- Use the customer's existing issue or risk system if an exception needs approval.

GitHub stores alert and campaign state. The approved risk system stores the exception approval, expiry, and return path.

Agree on response targets with the security owner. Use the customer's severity
policy and alert creation time to set due dates in the existing restricted work
system. Assign a remediation owner and an escalation contact. Check one real
alert against its target and follow up if it is overdue. Handle Dependabot and
secret alerts separately; campaigns track code scanning only. Keep sensitive
alert details out of public issues and AI prompts.

## Set up the alerts

Reuse the approved repository from the rollout. If no customer pilot is available,
reuse the fixture from `ghas-admin-01`, or provision it now:

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

### 1. Verify the alerts through the API

The fixture produces alerts from several tools. Query each needed alert type separately.
For customer work, substitute the approved repository in these commands:

```bash
gh api repos/<org>/ghas-admin-01-06-security-operations/code-scanning/alerts \
  --paginate --jq 'length'

gh api repos/<org>/ghas-admin-01-06-security-operations/dependabot/alerts \
  --paginate --jq 'length'

gh api repos/<org>/ghas-admin-01-06-security-operations/secret-scanning/alerts \
  --paginate --jq 'length'
```

Query organization-wide CodeQL alerts:

```bash
gh api orgs/<org>/code-scanning/alerts --paginate \
  --jq '.[] | select(.state=="open") | {number, repo: .repository.name, rule: .rule.id, severity: .rule.security_severity_level}'
```

Record the query time and each alert type's count. With `--paginate`, `length`
prints a count per page. Sum the pages for each endpoint. These repository-wide
counts are separate from the campaign's counts. The campaign includes
**code scanning alerts only**.
If you expect alerts but find none, check the feature state and scan results.

### 2. Check coverage and repair gaps

Open the organization's **Security and quality** view. In Coverage, filter to the selected repository.

Check for gaps, such as:

- A missing security configuration attachment.
- Secret scanning or push protection disabled.
- Dependabot alerts or security updates disabled.
- A stale or failed CodeQL analysis.

Repair any gap in GitHub and verify the new state. If coverage already meets the
approved scope, save that evidence. Do not disable a control to create work.
An `unaffected` row still needs investigation when the feature is off.

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

Copy the campaign URL and number into the existing campaign issue or approved
work item. The fixture's pre-created issue can hold this evidence.

Publish the campaign in GitHub. A campaign plan alone does not complete this step.

### 5. Start the developer's contribution

Ask the developer with write access to:

1. Open the published campaign.
2. Open the campaign-generated repository issue, when GitHub creates one.
3. Trace an assigned alert and confirm the fix scope with its owner.
4. Open a fix PR with a regression test, then obtain review in step 7.
5. Record any access failure without sharing sensitive alert data.

Fix the permission or assignment if the developer cannot reach the work. Repeating the administrator view is not an access test.

### 6. Review an exception if needed

Only use an exception when the team has a defensible reason to defer a fix.
Otherwise skip this step. Add these fields to the approved exception record:

| Field | Required value |
| --- | --- |
| Alert and repository | Direct links |
| Business owner | Named approver |
| Technical reason | Evidence from the alert or runtime |
| Compensating control | Named control and latest test |
| Expiry | A date within the customer's approved policy |
| Return path | Fix, reapproval, or reopen |

Have the developer request dismissal. A delegated reviewer must approve or reject it against the record. The remediation owner cannot approve their own accepted risk.

If approved, verify the alert state and campaign count. Schedule the expiry review in the system that owns the exception. GitHub's dismissed state does not enforce the expiry date.

You can test delegated dismissal with a reviewer using a safe sample alert.
Label it **practice**. Do not create a real risk exception to test the workflow.

### 7. Complete a campaign fix

Have the participating developer complete one assigned code scanning fix.
In the fixture, use `ghas-admin-06-campaign-remediation`. Run a regression test
and obtain human review before merging through the active controls.

Wait for the default-branch rescan. Verify the alert reports fixed and the published
campaign reflects that change. An open PR alone does not prove campaign progress.

Dependency updates and secret response can run alongside the campaign when needed.
Report their alert changes separately. Mark a never-issued synthetic secret
`used_in_tests`. It does not count as a revoked real credential.

### 8. Measure burn-down

Capture the campaign's starting and ending open-alert counts. Calculate:

```text
burn-down = starting open alerts - ending open alerts
completion rate = burn-down / starting open alerts
```

Keep the filters and included repositories unchanged for this comparison. Record
elapsed time and separate code fixes from dismissals. Note new alerts or scope
changes that affect the counts. The difference alone does not prove fixes.
Do not include Dependabot or secret-scanning counts in these calculations.

Open the campaign as the developer once more and confirm that its count and completion state match the alert changes.

### 9. Decide the next rollout wave

Approve the next repository set only when:

- The selected repository has the intended security configuration.
- Scans are current.
- The developer can reach assigned campaign work.
- Each exception has an owner and an expiry review scheduled.
- The measured burn-down matches the underlying alert states.

Stop rollout for any unexplained attachment failure, stale scan, access failure, campaign limit breach, or overdue exception. Name the rollback owner and the condition that allows work to resume.

## Completion check

You are done only when you have:

- Evidence from Coverage that you have checked the repository and repaired any gaps.
- A published campaign URL and number.
- A developer's merged code fix with passing tests and human review.
- A default-branch rescan that verifies the fix, with progress shown in the campaign.
- Starting and ending code scanning counts that separate fixes from dismissals.
- A delegated decision and scheduled expiry review for any exception.
- A rollout or stop decision with a named owner.

## Common failures

- Publishing a campaign that exceeds the alert or active-campaign limit.
- Treating the administrator view as proof that developers have access.
- Counting dismissed alerts as fixed code.
- Recording an exception only in an alert comment.
- Expanding rollout while coverage, scans, or campaign access still fail.
- Counting dependency or secret-alert changes as campaign progress.

## References

- [About Security Overview](https://docs.github.com/en/enterprise-cloud@latest/code-security/concepts/security-at-scale/security-overview)
- [Security Overview permissions](https://docs.github.com/en/enterprise-cloud@latest/code-security/reference/permissions/security-overview)
- [About security campaigns](https://docs.github.com/en/code-security/concepts/security-at-scale/about-security-campaigns)
- [Creating and managing security campaigns](https://docs.github.com/en/code-security/how-tos/manage-security-alerts/remediate-alerts-at-scale/creating-managing-security-campaigns)
- [Participating in a code security campaign](https://docs.github.com/en/code-security/tutorials/manage-security-alerts/best-practices-for-participating-in-a-security-campaign)
- [Delegated alert dismissal](https://docs.github.com/en/code-security/concepts/security-at-scale/delegated-alert-dismissal)
- [REST API endpoints for security campaigns](https://docs.github.com/en/rest/campaigns/campaigns)
