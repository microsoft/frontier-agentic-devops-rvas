# Activity 1: Security Configuration Pilot & Rollout

Create an organization security configuration, attach it to a real pilot repository, and decide whether to enforce or roll it back. But an accepted request is only the start. You must follow the repository to a final configuration state.

## Before you start

- Use a test organization or an approved production pilot.
- Confirm that the organization has the required GitHub Code Security and GitHub Secret Protection entitlement for the selected repository.
- Work as an organization owner or security manager who can manage security configurations.
- Name the rollout owner and rollback owner.
- Set the pilot's success and stop conditions before changing the repository.

Keep the scope small. This lab needs one representative repository, one configuration, and one controlled repair.

## Set up the fixture

If you do not have an approved pilot repository, create the shared fixture:

```bash
bash modules/ghas/resources/provisioning/challenges/admin-01-06-security-configuration-campaigns-fixture/provision.sh \
  provision --org <org>
```

```powershell
modules/ghas/resources/provisioning/challenges/admin-01-06-security-configuration-campaigns-fixture/provision.ps1 `
  provision -Org <org>
```

The fixture creates `ghas-admin-01-06-security-operations`. It also seeds an advanced CodeQL workflow, Dependabot configuration, a non-live secret, two repair branches, and tracking issues used by this session and `ghas-admin-06`.

## Exercise

### 1. Record the pilot boundary

Record these decisions in the `ghas-admin-01: configuration attachment repair` issue or the customer's approved change system:

| Field | Required value |
| --- | --- |
| Pilot repository | Exact GitHub URL |
| Products | GitHub Code Security, GitHub Secret Protection, or both |
| Configuration owner | Named person or team |
| Rollback owner | Named person |
| Targeting | Selected repository |
| Exception | Owner, reason, expiry, and return path |
| Success condition | Final attached state and expected features |
| Stop condition | Any unexplained failure, unexpected replacement, scan loss, or owner objection |

Do not widen the target during the lab.

### 2. Capture the live baseline

List the current configurations and save the pilot repository ID:

```bash
gh api orgs/<org>/code-security/configurations \
  --jq '.[] | {id, name, enforcement}'

REPO_ID="$(gh api repos/<org>/ghas-admin-01-06-security-operations --jq '.id')"
printf '%s\n' "$REPO_ID"
```

Open the organization's **Security and quality** view and filter Coverage to the pilot repository. Record its current configuration, feature state, and latest CodeQL analysis.

### 3. Create the configuration in GitHub

Open **Organization settings > Code security > Configurations**. Create `ghas-admin-01-pilot` with enforcement off.

Enable only the controls approved for the pilot. The fixture already has CodeQL advanced setup, so do not enable default setup unless you intend to test and repair that conflict. Review every setting before saving.

Capture the new configuration ID:

```bash
CONFIG_ID="$(
  gh api orgs/<org>/code-security/configurations \
    --jq '.[] | select(.name=="ghas-admin-01-pilot") | .id'
)"
test -n "$CONFIG_ID"
printf '%s\n' "$CONFIG_ID"
```

**A payload draft does not complete this step.** The configuration must exist in the organization.

### 4. Attach the selected repository

In the configuration's **Repositories** view, attach only `ghas-admin-01-06-security-operations`. Confirm the target before applying the change.

Poll the live repository list:

```bash
while :; do
  gh api "orgs/<org>/code-security/configurations/$CONFIG_ID/repositories" \
    --paginate \
    --jq '.[] | {repository: .repository.name, status: .status}'
  sleep 15
done
```

Stop the loop after GitHub reports a final state. Save the status history. Do not treat `attaching` or `updating` as completion.

### 5. Repair a failure or detachment

If the attachment fails, use GitHub's failure reason to fix the setting or repository condition. Reapply the configuration and poll again.

If the first attachment succeeds, run this controlled detachment test:

1. Detach the pilot configuration from the repository.
2. Poll until GitHub shows that the attachment is gone or reports its final removal state.
3. Record the event in the fixture issue.
4. Reattach the same configuration.
5. Poll until the repository reaches the expected final state.

Do not manufacture a passing record. Keep the exact state and error text GitHub returned.

### 6. Enforce or roll back

Compare the result with the conditions from step 1.

**Enforce** only when:

- The intended repository is attached.
- Every required feature is on.
- CodeQL still produces analysis.
- No unexplained failure remains.
- The repository and rollback owners approve.

If those checks pass, change the configuration to enforced and poll again.

**Roll back** when a stop condition fires. Detach the configuration, verify the final removal state, and restore the prior repository settings. Assign unresolved work to an owner with a retest condition.

## Completion check

You are done only when you have:

- A live `ghas-admin-01-pilot` configuration ID.
- A live attachment and its final state history.
- Evidence that you repaired a failure or completed the detachment and reattachment test.
- An enforced configuration or a verified rollback.
- A named approver and rollback owner.

A JSON payload, runbook, or successful HTTP response does not prove rollout.

## Common failures

- Attaching to `all` instead of the approved repository.
- Enabling default setup over an existing advanced CodeQL workflow without a repair plan.
- Stopping while the repository still reports `attaching` or `updating`.
- Enforcing with an unexplained failure.
- Rolling back without checking that the repository reached its final removal state.

## References

- [Create a custom organization configuration](https://docs.github.com/en/enterprise-cloud@latest/code-security/how-tos/secure-at-scale/configure-organization-security/establish-complete-coverage/create-custom-configuration)
- [Apply a custom security configuration](https://docs.github.com/en/code-security/how-tos/secure-at-scale/configure-organization-security/establish-complete-coverage/apply-custom-configuration)
- [Security configuration statuses](https://docs.github.com/en/enterprise-cloud@latest/code-security/reference/security-at-scale/configuration-statuses)
- [Diagnosing security configuration issues](https://docs.github.com/en/code-security/reference/security-at-scale/troubleshoot-security-configurations/configuration-issue-diagnosis)
- [REST API endpoints for code security configurations](https://docs.github.com/en/rest/code-security/configurations)
