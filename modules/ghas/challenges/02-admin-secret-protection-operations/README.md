# Activity 2: Secret Protection operations

**Session outcome:** Secret scanning detects the test secrets and push protection blocks a synthetic secret. The UI and API show the same alert response. Test delegated bypass and custom patterns only if the customer needs them.

## Before you start

- Complete `ghas-admin-01`.
- Use an organization-owned test repository where GitHub Secret Protection is licensed.
- Assign an operator to test detection and push protection and handle the alerts.
- For delegated bypass, assign a reviewer with a different GitHub account.
- Install `gh`, `git`, and `jq`.
- Never replace the seeded values with a live credential.

The operator needs repository admin permissions and secret-scanning alert access.
For delegated bypass, the reviewer needs GitHub's review permission.
Keep an organization owner or security manager available for incident escalation.

Steps 1 through 4 and step 7 cover detection, push protection, and the alert
response. Do steps 5 and 6 only if the customer needs those controls. Record
each result as passed, not selected, or blocked.

## Provision the test repository

For an approved customer repository, skip fixture provisioning and do only the control and response steps it needs. **Never seed synthetic secrets into production history.** Practice detection and bypass in the isolated fixture. For a real incident, use the customer path below.

The fixture imports OWASP Juice Shop at `v20.0.0`, strips upstream Git history, and creates new GHAS lab history. It adds two synthetic AWS credential pairs on `main`, a safe custom-pattern candidate, `SECRETS-MANIFEST.md`, and the `seed/push-protection-history` branch.

```bash
bash modules/ghas/resources/provisioning/challenges/02-admin-secret-protection-operations-rebuild-secret-operations/provision.sh \
  provision --org <org>
```

```powershell
pwsh -File modules/ghas/resources/provisioning/challenges/02-admin-secret-protection-operations-rebuild-secret-operations/provision.ps1 `
  provision -Org <org>
```

The default repository is private and named `ghas-admin-02-secret-operations`. The fixture also opens an issue named "GHAS Admin 02: secret protection operations evidence". Use it for alert numbers, commit SHAs, reviewer names, and blocked items. **Do not paste secret values.**

Check the fixture before continuing:

```bash
bash modules/ghas/resources/provisioning/challenges/02-admin-secret-protection-operations-rebuild-secret-operations/provision.sh \
  status --org <org>
```

## 1. Enable and verify Secret Protection

Set shell variables once:

```bash
ORG=<org>
REPO=ghas-admin-02-secret-operations
```

Open **Settings > Advanced Security** for the repository. Enable:

- Secret scanning.
- Push protection.
- Validity checks, if the organization permits provider checks.
- Delegated bypass for push protection, with the reviewer assigned, only if step 5 is selected.

Verify the two required controls through the API:

```bash
gh api "repos/$ORG/$REPO" \
  --jq '.security_and_analysis | {
    secret_scanning: .secret_scanning.status,
    push_protection: .secret_scanning_push_protection.status,
    validity_checks: .secret_scanning_validity_checks.status
  }'
```

Confirm that `secret_scanning` and `push_protection` both return `enabled`.

If the private repository can't enable GitHub Secret Protection, record the entitlement or permission error in the evidence issue and mark this item **blocked**. A public repository doesn't prove the licensed control.

## 2. Reconcile seeded history with the manifest

Open `SECRETS-MANIFEST.md` on `main`. It lists two provider-pattern seeds, one custom-pattern candidate, and one provider-pattern seed on `seed/push-protection-history`.

Wait for the initial scan to finish, then list the alerts:

```bash
gh api "repos/$ORG/$REPO/secret-scanning/alerts?per_page=100" --paginate \
  --jq '.[] | {
    number,
    secret_type,
    state,
    validity,
    path: .first_location_detected.path,
    commit: .first_location_detected.commit_sha
  }'
```

For each provider-pattern row, open the alert and query its locations:

```bash
gh api "repos/$ORG/$REPO/secret-scanning/alerts/<alert-number>/locations" \
  --jq '.[] | {type, details}'
```

Match the alert type, path, branch or commit, and count to the manifest. The `GHAS_LAB_DEMO_...` row has no alert yet because its custom pattern isn't published.

Review exposure before closing any alert, whatever its validity. If it's `active`, revoke or rotate the credential immediately. `inactive` still needs an exposure review. `unknown` means the provider didn't confirm status, **not** that the credential is safe.

## 3. Resolve the seeded provider alerts

The fixture values were never issued, so resolve their alerts as `used_in_tests`. Comment with the manifest row and note that the value is synthetic.

```bash
gh api -X PATCH \
  "repos/$ORG/$REPO/secret-scanning/alerts/<alert-number>" \
  -f state=resolved \
  -f resolution=used_in_tests \
  -f resolution_comment="Synthetic GHAS Admin 02 fixture value; reconciled to SECRETS-MANIFEST.md row <row>."
```

Query each alert again and record its `state`, `resolution`, `resolution_comment`, and `resolved_by.login`.

If any value might be real, stop treating it as fixture data. Find the credential owner and open or link the incident. Revoke or rotate the credential, and confirm the old value no longer works before you resolve the alert. The handoff names the responder and next action, without the secret.

## 4. Prove clean and blocked pushes

Clone the repository and create a lab branch:

```bash
gh repo clone "$ORG/$REPO"
cd "$REPO"
git switch -c lab/ghas-admin-02-push-check
printf 'secret protection clean push\n' > ghas-admin-02-clean.txt
git add ghas-admin-02-clean.txt
git commit -m "Add clean secret protection check"
git push -u origin HEAD
```

The clean push must succeed.

Now add a new synthetic AWS pair. The split strings keep the full test value out of this guide:

```bash
AWS_ID='AKIA''ADMIN02BLOCK0001'
AWS_SECRET='Admin02SyntheticSecretValue0000000000000'
cat > ghas-admin-02-blocked.ini <<EOF
[fixture]
aws_access_key_id = $AWS_ID
aws_secret_access_key = $AWS_SECRET
EOF
git add ghas-admin-02-blocked.ini
git commit -m "Test push protection block"
git push
```

GitHub must reject the push and report the expected secret type and file. Save the blocked commit SHA and the request URL. Don't copy the detected value into the evidence issue.

If the push goes through, this item fails. Confirm push protection is enabled and the provider pattern supports it, then repeat with a new branch and a new synthetic pair.

## 5. Test delegated bypass if required

Do this only if the customer requires reviewed push-protection bypass.
Otherwise, leave the rejected commit unpushed, return to a clean branch, and
go to step 7. Don't bypass protection just to finish the core path.

Open the request URL from the blocked push. The operator submits a bypass request with this reason:

> Synthetic GHAS Admin 02 validation. Approval is limited to this test commit; remove the value after the alert is recorded.

The assigned reviewer checks the repository, commit, secret type, and request comment, then approves from their own GitHub account. Self-review fails this step.

Bypass requests expire after **seven days**. An expired request must be resubmitted. Record the request and expiry dates in the evidence issue.

After approval, the operator pushes the same commit:

```bash
git push
```

Query the resulting alert and bypass state:

```bash
gh api "repos/$ORG/$REPO/secret-scanning/alerts?is_bypassed=true&per_page=100" --paginate \
  --jq '.[] | {
    number,
    state,
    secret_type,
    bypassed: .push_protection_bypassed,
    requester: .push_protection_bypassed_by.login,
    reviewer: .push_protection_bypass_request_reviewer.login,
    request_comment: .push_protection_bypass_request_comment,
    reviewer_comment: .push_protection_bypass_request_reviewer_comment,
    request_url: .push_protection_bypass_request_html_url
  }'
```

Confirm that the alert shows the operator as requester, the other account as reviewer, and `push_protection_bypassed: true`.

Remove the file in a new commit and push it. Then resolve the alert as `used_in_tests`. The bypass left an exposure record even though the value was synthetic.

## 6. Publish a custom pattern if required

Do this only if provider patterns don't cover a customer token format.
The fixture below lets you test publishing without a real token.

Open **Settings > Advanced Security > Custom patterns** and create a repository pattern:

| Field | Value |
| --- | --- |
| Name | `GHAS lab demo token` |
| Secret format | `GHAS_LAB_DEMO_[A-Z0-9]{20}` |
| Test string | `GHAS_LAB_DEMO_ADMIN02HISTORYSEED01` |

Run the dry run and confirm it finds `fixtures/internal-token.txt`. Fix any unexpected matches first.

Click **Publish pattern**. **A saved dry run isn't enough.** Publishing starts a scan of the repository's Git history and branches.

Query the pattern and alert state:

```bash
gh api "repos/$ORG/$REPO/secret-scanning/custom-patterns" \
  --jq '.[] | {id, name, state, push_protection_enabled}'

gh api "repos/$ORG/$REPO/secret-scanning/alerts?per_page=100" --paginate \
  --jq '.[] | select(.secret_type_display_name == "GHAS lab demo token") |
    {number, state, secret_type, path: .first_location_detected.path}'
```

Confirm the pattern is published and a live alert points to `fixtures/internal-token.txt`.

Resolve the custom-pattern alert as `used_in_tests` with a comment that names the fixture and pattern. If the product, license, or role can't publish the pattern, mark this item **blocked**. A regex draft or dry run doesn't pass.

## 7. Verify the final state in the UI and API

Open **Security > Secret scanning** and check the provider alerts and any custom-pattern alerts. Then run:

```bash
gh api "repos/$ORG/$REPO/secret-scanning/alerts?per_page=100" --paginate \
  --jq '.[] | {
    number,
    type: .secret_type_display_name,
    state,
    resolution,
    validity,
    resolved_by: .resolved_by.login,
    bypassed: .push_protection_bypassed,
    bypass_reviewer: .push_protection_bypass_request_reviewer.login
  }'
```

Update the evidence issue with:

- The enabled control state.
- Manifest rows matched to alert numbers.
- The clean and blocked push commit SHAs.
- For selected bypass tests, the requester, reviewer, decision, and seven-day expiry date.
- For selected custom-pattern tests, the published pattern ID and live alert number.
- Each resolution reason and final API state.
- Any incident handoff, including who rotated or revoked a credential and how they verified the old value was unusable.

Keep the evidence issue open while any real credential action or incident handoff is open.

## Customer path: Respond to an exposed credential

Use the application's existing incident process and the credential owner. **Never add a real credential to test scanning.**

1. Link the alert to the incident. Confirm the affected provider and exposure scope without copying the value. The credential owner revokes or rotates it and confirms the old value no longer works. Review how it was used during the exposure.
2. In the application checkout, locate the hardcoded value and its consumers. Replace it with the approved runtime-secret configuration. In Node.js that may be `process.env`; if the application already has a secret-management library, keep using it. Missing configuration must fail clearly, not fall back to a fixture credential.
3. Document the required configuration names, not values. Add or update tests for startup configuration and the affected authentication or integration behavior.
4. Open a PR linking the alert and incident. Get independent review, pass the application's checks, and merge. Confirm through the approved deployment process that the deployed application uses the replacement.
5. Resolve the alert only after the credential owner has acted and the application is verified. Record the revocation or rotation evidence and the reviewed PR. **Removing the text from source doesn't revoke the credential or remove it from history.**

If you need Copilot help, use this prompt with the affected code, excluding credential values:

```text
Replace this hardcoded credential lookup with the application's approved
runtime secret configuration. Keep its existing library and error handling.
Add tests for missing configuration and the affected behavior. Never include
the old or replacement value in code, logs, test fixtures, or documentation.
Identify any deployment configuration the owner must approve separately.
```

You can resolve a never-issued fixture value as `used_in_tests`, but that proves nothing about revoking a real credential.

## Completion check

The core path passes when GitHub shows all of these:

- Secret scanning and push protection are enabled.
- Seeded history matches `SECRETS-MANIFEST.md`.
- Every seeded provider alert has an explicit resolution reason.
- The clean push succeeded and the synthetic secret push was blocked.
- The UI and API agree on the final alert state.

If you tested delegated bypass, record the separate review and the bypass alert
you can query. For a custom pattern, record the published pattern and live alert.
Mark required but unavailable features **blocked**. Mark unused steps
**not selected** and say when the customer would need them. None of those
statuses, a draft, or a dry run proves the feature works.

## References

- [About secret scanning](https://docs.github.com/en/code-security/concepts/secret-security/secret-scanning)
- [Enable push protection](https://docs.github.com/en/code-security/how-tos/secure-your-secrets/prevent-future-leaks/enable-push-protection)
- [Supported secret scanning patterns](https://docs.github.com/en/code-security/reference/secret-security/supported-secret-scanning-patterns)
- [Manage secret scanning alerts](https://docs.github.com/en/code-security/secret-scanning/managing-alerts-from-secret-scanning)
- [Delegated bypass](https://docs.github.com/en/code-security/concepts/secret-security/delegated-bypass)
- [Review bypass requests](https://docs.github.com/en/code-security/how-tos/secure-your-secrets/manage-bypass-requests/review-bypass-requests)
- [Define custom patterns](https://docs.github.com/en/code-security/how-tos/secure-your-secrets/customize-leak-detection/define-custom-patterns)
- [Delegated alert dismissal](https://docs.github.com/en/code-security/concepts/security-at-scale/delegated-alert-dismissal)
- [Secret scanning REST API](https://docs.github.com/en/rest/secret-scanning/secret-scanning)
- [Custom patterns REST API](https://docs.github.com/en/rest/secret-scanning/custom-patterns)
