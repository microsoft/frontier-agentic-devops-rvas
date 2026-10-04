# Activity 2: Secret Protection operations

**Session outcome:** Secret scanning detects the test secrets and push protection blocks a synthetic secret. The UI and API show the same alert response. Test delegated bypass or custom patterns only when the customer needs them.

## Before you start

- Complete `ghas-admin-01`.
- Use an organization-owned test repository where GitHub Secret Protection is licensed.
- Assign an operator to test detection and push protection, then handle the alerts.
- For the delegated-bypass branch, assign a reviewer using a different GitHub account.
- Install `gh`, `git`, and `jq`.
- Never replace the seeded values with a live credential.

The operator needs repository administration and secret-scanning alert access.
For delegated bypass, the reviewer needs GitHub's required review permission.
Keep an organization owner or security manager available for incident escalation.

Complete steps 1 through 4 and step 7 to test detection and push protection, then
verify the alert response. Steps 5 and 6 apply only when the customer needs those
controls. Record each one's result as passed, not selected, or blocked.

## Provision the test repository

For an approved customer repository, skip fixture provisioning and apply only the controls and response steps it needs. Do not seed synthetic secrets into production history. Use the isolated fixture for detection or bypass practice; use the customer path below for a real incident.

The fixture imports OWASP Juice Shop at `v20.0.0`, strips upstream Git history, and creates new GHAS lab history. It then adds two synthetic AWS credential pairs on `main`, a safe custom-pattern candidate, `SECRETS-MANIFEST.md`, and the `seed/push-protection-history` branch.

```bash
bash modules/ghas/resources/provisioning/challenges/02-admin-secret-protection-operations-rebuild-secret-operations/provision.sh \
  provision --org <org>
```

```powershell
pwsh -File modules/ghas/resources/provisioning/challenges/02-admin-secret-protection-operations-rebuild-secret-operations/provision.ps1 `
  provision -Org <org>
```

The default repository is private and named `ghas-admin-02-secret-operations`. The fixture also opens an issue named "GHAS Admin 02: secret protection operations evidence". Use that issue for alert numbers, commit SHAs, reviewer names, and blocked acceptance items. **Do not paste secret values.**

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

If the private repository cannot enable GitHub Secret Protection, record the entitlement or permission error in the evidence issue and mark this acceptance item **blocked**. A public-repository substitute does not prove the licensed control.

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

Match the alert type, path, branch or commit, and count to the manifest. The `RVAS_DEMO_...` row should not have an alert yet because its custom pattern is not published.

Review exposure before closing an alert, whatever its validity result. `active` needs immediate revocation or rotation. `inactive` still needs an exposure review. `unknown` means the provider did not confirm status; it does not mean the credential is safe.

## 3. Resolve the seeded provider alerts

The fixture values were never issued, so resolve their alerts as `used_in_tests`. Use a comment that names the manifest row and confirms that the value is synthetic.

```bash
gh api -X PATCH \
  "repos/$ORG/$REPO/secret-scanning/alerts/<alert-number>" \
  -f state=resolved \
  -f resolution=used_in_tests \
  -f resolution_comment="Synthetic GHAS Admin 02 fixture value; reconciled to SECRETS-MANIFEST.md row <row>."
```

Query each alert again and record its `state`, `resolution`, `resolution_comment`, and `resolved_by.login`.

If any value may be real, stop treating it as fixture data. Assign the credential owner, open or link the incident handoff, revoke or rotate the credential, verify that the old value no longer works, and only then resolve the alert. The handoff must name the responder and next action without copying the secret.

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

GitHub must reject the push and report the expected secret type and file. Save the blocked commit SHA and the request URL. Do not copy the detected value into the evidence issue.

If the push succeeds without a block, this item fails. Confirm that push protection is enabled and that the provider pattern supports push protection, then repeat with a new branch and new synthetic pair.

## 5. Test delegated bypass if required

Use this branch when the customer requires reviewed push-protection bypass.
Otherwise, leave the rejected commit unpushed and return to a clean branch before
continuing to step 7. Do not bypass protection just to complete the core path.

Open the request URL from the blocked push. The operator submits a bypass request with this reason:

> Synthetic GHAS Admin 02 validation. Approval is limited to this test commit; remove the value after the alert is recorded.

The assigned reviewer checks the repository, commit, secret type, and request comment. The reviewer approves this controlled request from their own GitHub account. Self-review fails this branch.

Bypass requests expire after **seven days**. An expired request must be submitted again. Record the request date and expiry date in the evidence issue so reviewers know the deadline.

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

Remove the file in a new commit and push the cleanup. Then resolve the alert as `used_in_tests`. The bypass created an exposure record even though the value was synthetic.

## 6. Publish a custom pattern if required

Use this branch when provider patterns do not cover a customer token format.
Use the safe fixture below to test publishing without a real token.

Open **Settings > Advanced Security > Custom patterns** and create a repository pattern:

| Field | Value |
| --- | --- |
| Name | `RVAS Admin 02 demo token` |
| Secret format | `RVAS_DEMO_[A-Z0-9]{20}` |
| Test string | `RVAS_DEMO_ADMIN02HISTORYSEED01` |

Run the dry run and confirm that it finds `fixtures/internal-token.txt`. Fix unexpected matches before continuing.

Click **Publish pattern**. A saved dry run is not enough. Publishing starts a scan of the repository's Git history and branches.

Query the pattern and alert state:

```bash
gh api "repos/$ORG/$REPO/secret-scanning/custom-patterns" \
  --jq '.[] | {id, name, state, push_protection_enabled}'

gh api "repos/$ORG/$REPO/secret-scanning/alerts?per_page=100" --paginate \
  --jq '.[] | select(.secret_type_display_name == "RVAS Admin 02 demo token") |
    {number, state, secret_type, path: .first_location_detected.path}'
```

Confirm that the pattern state is published and a live alert points to `fixtures/internal-token.txt`.

Resolve the custom-pattern alert as `used_in_tests` with a comment that names the fixture and pattern. If the product, license, or role cannot publish the pattern, mark this item **blocked**. A regex draft or dry-run result does not pass.

## 7. Verify the final state in the UI and API

Open **Security > Secret scanning**. Check the provider alerts and any selected custom-pattern alerts. Then run:

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

Do not close the evidence issue while a real credential action or incident handoff is open.

## Customer path: Respond to an exposed credential

Use the application's existing incident process and the credential owner. Never introduce a real credential to test scanning.

1. Link the alert to the incident. Confirm the affected provider and exposure scope without copying the value. The credential owner revokes or rotates it and verifies that the old value no longer works. Review its use during the exposure.
2. In the application checkout, locate the hardcoded value and its consumers. Replace it with the approved runtime-secret configuration. For Node.js, that may use `process.env`; keep the existing secret-management library when the application has one. Missing required configuration must fail clearly rather than fall back to a fixture credential.
3. Document required configuration names without values. Add or update application tests for startup configuration and the affected authentication or integration behavior.
4. Open a PR linking the alert and incident. Obtain independent review, pass the application's checks, and merge. Confirm the deployed application uses the replacement through the approved deployment process.
5. Resolve the alert only after the credential-owner action and application verification are complete. Record revocation or rotation evidence and the reviewed PR. Removing source text does not revoke a credential or remove it from history.

If you need Copilot help, use this prompt with the affected code, excluding credential values:

```text
Replace this hardcoded credential lookup with the application's approved
runtime secret configuration. Keep its existing library and error handling.
Add tests for missing configuration and the affected behavior. Never include
the old or replacement value in code, logs, test fixtures, or documentation.
Identify any deployment configuration the owner must approve separately.
```

A never-issued fixture value may be resolved as `used_in_tests`. State that limitation; it cannot prove real credential revocation.

## Completion check

The core path passes only when GitHub shows all of these results:

- Secret scanning and push protection are enabled.
- Seeded history matches `SECRETS-MANIFEST.md`.
- Every seeded provider alert has an explicit resolution reason.
- The clean push succeeded and the synthetic secret push was blocked.
- The UI and API agree on the final alert state.

If you tested delegated bypass, record the separate review and queryable bypass
alert. For a custom pattern, record the published pattern and live alert.
Mark required but unavailable features **blocked**. Mark unused branches
**not selected** and state when the customer would need them. These statuses do not
prove the feature works. A draft or dry run cannot replace live evidence.

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
