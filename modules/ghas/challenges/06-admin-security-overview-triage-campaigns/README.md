# Activity 6: Run a bounded security campaign

**Session outcome:** A developer completes a reviewed code fix in a published campaign. A rescan confirms the fix and the campaign shows progress.

## Before you start

- Complete `ghas-admin-01` and `ghas-admin-03`, or show equivalent live configuration and CodeQL merge checks.
- Work as an organization owner or security manager who can view Security Overview and create campaigns.
- Find a developer with write access to the repository who will own a campaign fix.

**Campaigns track code scanning only.** Handle Dependabot and secret alerts separately. Keep sensitive alert details out of public issues and AI prompts.

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

The fixture imports OWASP Juice Shop at the pinned `v20.0.0` tag. It seeds CodeQL, Dependabot, and a fake secret value that was never a real credential so the repository produces a mixed alert queue. Wait for the CodeQL workflow and the other GitHub security features to finish their first analysis.

## Exercise

### 1. Verify the alerts through the API

The fixture produces alerts from several tools. Query each alert type separately.
For customer work, substitute the approved repository:

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

Note the query time and each alert type's count. With `--paginate`, `length`
prints a count per page, so sum the pages for each endpoint. These repository-wide
counts differ from the campaign's, which include **code scanning alerts only**.
If you expect alerts but find none, check the feature state and scan results.

### 2. Check coverage and fix gaps

Open the organization's **Security and quality** view. In Coverage, filter to the selected repository.

Check for gaps, such as:

- A missing security configuration attachment.
- Secret scanning or push protection disabled.
- Dependabot alerts or security updates disabled.
- A stale or failed CodeQL analysis.

Fix any gap in GitHub and verify the new state. Don't disable a control to create work.

### 3. Define the campaign alert set

Pick a finite set of code scanning alerts from the default branch. Note the filters, starting count, included repositories, campaign manager, due date, and remediation guidance.

Keep the campaign at or below 1,000 alerts. If the filtered set is larger, narrow it or split it into separate campaigns. Check the published campaigns first so you don't overlap with one.

List the current campaigns:

```bash
gh api orgs/<org>/campaigns --paginate \
  --jq '.[] | {number, name, state, ends_at}'
```

To narrow the set by production risk (`has:deployment`, `runtime-risk:`), complete `ghas-admin-07` first. Optional.

### 4. Publish the campaign

Create the campaign from **Security and quality > Campaigns**. Use the filters from step 3, assign the manager, set the due date, and add practical remediation guidance.

Publish the campaign in GitHub and copy its URL and number into the fixture's campaign issue. **A campaign plan alone doesn't complete this step.**

### 5. Start the developer's contribution

Ask the developer with write access to:

1. Open the published campaign.
2. Open the campaign-generated repository issue, when GitHub creates one.
3. Trace an assigned alert and confirm the fix scope with its owner.
4. Open a fix PR with a regression test, then obtain review in step 6.

If the developer can't reach the work, fix the permission or assignment. Looking at the administrator view again isn't an access test.

### 6. Complete a campaign fix

Have the developer complete one assigned code scanning fix.
In the fixture, use `ghas-admin-06-campaign-remediation`. Run a regression test
and get human review before merging through the active controls.

Wait for the default-branch rescan. Verify the alert reports fixed and the published
campaign reflects it. **An open PR alone doesn't prove campaign progress.**

Dependency updates and secret response can run alongside the campaign if needed.
Report their alert changes separately. Mark a never-issued synthetic secret
`used_in_tests`. It doesn't count as a revoked real credential.

### 7. Measure burn-down

Note the campaign's starting and ending open-alert counts. Calculate:

```text
burn-down = starting open alerts - ending open alerts
completion rate = burn-down / starting open alerts
```

Keep the filters and included repositories the same for this comparison. Separate code fixes from dismissals. Leave Dependabot and secret-scanning counts out.

Open the campaign as the developer again and confirm its count and completion state match the alert changes.

### Optional: exceptions and delegated dismissal

If a team has a defensible reason to defer a fix, have the developer request dismissal and a delegated reviewer approve or reject it. The remediation owner can't approve their own risk. GitHub's dismissed state doesn't enforce an expiry date, so track expiry where the exception is approved. Test with a **practice** alert only. Never create a real exception to test the workflow. See [Delegated alert dismissal](https://docs.github.com/en/code-security/concepts/security-at-scale/delegated-alert-dismissal).

## Completion check

You're done when:

- Coverage for the repository is checked and gaps are fixed.
- A campaign is published, with its URL and number in the campaign issue.
- A developer's code fix is merged with passing tests and human review.
- A default-branch rescan confirms the fix and the campaign shows progress.
- Starting and ending code scanning counts separate fixes from dismissals.

## Common failures

- Publishing a campaign that exceeds the alert or active-campaign limit.
- Treating the administrator view as proof that developers have access.
- Counting dismissed alerts as fixed code.
- Counting dependency or secret-alert changes as campaign progress.

## References

- [Microsoft Defender for Cloud's production-context filters](https://docs.github.com/en/code-security/tutorials/secure-your-organization/prioritize-alerts-in-production-code) (`has:deployment`, runtime-risk). See the full note in [`resources/README.md`](../../resources/README.md).
- [About Security Overview](https://docs.github.com/en/enterprise-cloud@latest/code-security/concepts/security-at-scale/security-overview)
- [Security Overview permissions](https://docs.github.com/en/enterprise-cloud@latest/code-security/reference/permissions/security-overview)
- [About security campaigns](https://docs.github.com/en/code-security/concepts/security-at-scale/about-security-campaigns)
- [Creating and managing security campaigns](https://docs.github.com/en/code-security/how-tos/manage-security-alerts/remediate-alerts-at-scale/creating-managing-security-campaigns)
- [Participating in a code security campaign](https://docs.github.com/en/code-security/tutorials/manage-security-alerts/best-practices-for-participating-in-a-security-campaign)
- [Delegated alert dismissal](https://docs.github.com/en/code-security/concepts/security-at-scale/delegated-alert-dismissal)
- [REST API endpoints for security campaigns](https://docs.github.com/en/rest/campaigns/campaigns)
