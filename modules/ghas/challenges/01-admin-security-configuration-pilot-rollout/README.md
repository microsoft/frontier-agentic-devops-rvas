# Activity 1: Security configuration pilot and rollout

**Session outcome:** An organization security configuration is attached to a pilot repository, and you've verified its final state and one recovery path (repair or rollback).

## Before you start

- Use a test organization or an approved production pilot.
- Confirm the organization has the GitHub Code Security and GitHub Secret Protection entitlements the repository needs.
- Work as an organization owner or security manager who can manage security configurations.
- Agree who approves enforcement and who rolls back, and what counts as a stop condition (unexplained failure, unexpected replacement, scan loss).

Use one representative repository and one configuration. Don't widen the target.

## Set up the fixture

If you have no approved pilot repository, create the shared fixture:

```bash
bash modules/ghas/resources/provisioning/challenges/admin-01-06-security-configuration-campaigns-fixture/provision.sh \
  provision --org <org>
```

```powershell
modules/ghas/resources/provisioning/challenges/admin-01-06-security-configuration-campaigns-fixture/provision.ps1 `
  provision -Org <org>
```

The fixture creates `ghas-admin-01-06-security-operations`. It also seeds an advanced CodeQL workflow, a Dependabot configuration, a fake secret that was never a real credential, two repair branches, and tracking issues used by this session and `ghas-admin-06`.

## Exercise

### 1. Confirm the pilot scope

Note these in the `ghas-admin-01: configuration attachment repair` issue:

- The exact pilot repository URL.
- Products in scope: Code Security, Secret Protection, or both.
- The expected final state: attached, with the expected features on.

### 2. Capture the current baseline

List the current configurations and save the pilot repository ID:

```bash
gh api orgs/<org>/code-security/configurations \
  --jq '.[] | {id, name, enforcement}'

REPO_ID="$(gh api repos/<org>/ghas-admin-01-06-security-operations --jq '.id')"
printf '%s\n' "$REPO_ID"
```

Open the organization's **Security and quality** view and filter Coverage to the pilot repository. Note its current configuration, feature state, and latest CodeQL analysis.

### 3. Create the configuration in GitHub

Open **Organization settings > Code security > Configurations**. Create `ghas-admin-01-pilot` with enforcement off.

Enable only the controls approved for the pilot. The fixture already has CodeQL advanced setup, so don't enable default setup unless you want to test and repair that conflict. Review every setting before saving.

Capture the new configuration ID:

```bash
CONFIG_ID="$(
  gh api orgs/<org>/code-security/configurations \
    --jq '.[] | select(.name=="ghas-admin-01-pilot") | .id'
)"
test -n "$CONFIG_ID"
printf '%s\n' "$CONFIG_ID"
```

The configuration must exist in the organization. A payload draft doesn't count.

### 4. Attach the selected repository

In the configuration's **Repositories** view, attach only `ghas-admin-01-06-security-operations`. Confirm the target before applying the change.

Poll the current repository list:

```bash
while :; do
  gh api "orgs/<org>/code-security/configurations/$CONFIG_ID/repositories" \
    --paginate \
    --jq '.[] | {repository: .repository.name, status: .status}'
  sleep 15
done
```

Stop the loop once GitHub reports a final state. `attaching` and `updating` are not final.

### 5. Recover from a failure or detachment

If the attachment fails, use GitHub's failure reason to fix the setting or repository condition, then reapply the configuration and poll again.

If the first attachment succeeds, run this controlled detachment test:

1. Detach the pilot configuration from the repository.
2. Poll until GitHub shows that the attachment is gone.
3. Reattach the same configuration.
4. Poll until the repository reaches the expected final state.

### 6. Enforce or roll back

**Enforce** only when the intended repository is attached, every required feature is on, CodeQL still produces analysis, no unexplained failure remains, and the approver agrees. Then change the configuration to enforced and poll again.

**Roll back** if a stop condition occurs. Detach the configuration, verify the final removal state, and restore the prior repository settings.

## Completion check

You're done when:

- `ghas-admin-01-pilot` exists and is attached to the pilot repository, or you detached it as part of a verified rollback.
- You repaired a failure or completed the detach and reattach test.
- The configuration is enforced, or you verified the rollback.

**Check the configuration and repository state.** A successful HTTP response doesn't prove the rollout worked.

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
