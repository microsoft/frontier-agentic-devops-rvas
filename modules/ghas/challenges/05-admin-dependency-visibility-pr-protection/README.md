# Activity 5: Dependency visibility and pull request protection

**Session outcome:** A tested dependency fix closes its alert. Required dependency review blocks a risky pull request, then accepts the fixed revision under the same controls.

Start with the coverage check in step 1 and the tested fix in steps 4 and 5.
Then prove the merge control in steps 8 through 10. Do the other steps only if
the customer needs them. Use dependency submission only if the graph misses
packages resolved during the build.

For an exposed credential, follow [Secret Protection response](../02-admin-secret-protection-operations/README.md#customer-path-respond-to-an-exposed-credential) before any dependency work.

## Before you start

- Complete `ghas-admin-01`.
- Use a public fallback repository or a private/internal repository with GitHub Code Security.
- Get repository administration, Actions, and security-alert access.
- Install GitHub CLI, Git, jq, Node.js, and npm.
- Pick a repository owner who can merge the security update and confirm the merge rule.

The fallback fixture imports OWASP Juice Shop at `v20.0.0`, then adds a small npm manifest with known vulnerable versions. It also creates `feature/risky-dependency`.

## Provision the fallback

Skip this section if you have an approved pilot repository.

```bash
bash modules/ghas/resources/provisioning/challenges/ghas-admin-05-dependency-visibility-fixture/provision.sh \
  provision --org <org>
```

```powershell
modules/ghas/resources/provisioning/challenges/ghas-admin-05-dependency-visibility-fixture/provision.ps1 `
  provision -Org <org>
```

The default repository name is `ghas-admin-05-dependency-visibility-fixture`. The provisioner creates:

- OWASP Juice Shop from the official `v20.0.0` tag, with its MIT license.
- `dependency-lab/package.json` and `package-lock.json` with vulnerable direct dependencies.
- `dependency-lab/build.sh`, which resolves `cowsay@1.6.0` during the build without declaring it in the npm manifest.
- `dependency-lab/build-resolved-components.json`, the build inventory used for dependency submission.
- `feature/risky-dependency`, which adds `lodash@4.17.4` as a new runtime dependency in `risky-dependency/package.json` and its lockfile.

Set the target once:

```bash
export TARGET="<org>/ghas-admin-05-dependency-visibility-fixture"
```

For customer work, set `TARGET` to the approved repository and use its package
paths and test commands. Keep seeded risky dependencies in the isolated fixture,
and never merge the vulnerable revision.

## Exercise

### 1. Compare the dependency graph with the build

Use the existing local checkout, or clone the selected repository:

```bash
git clone "https://github.com/${TARGET}.git"
cd "$(basename "$TARGET")"
```

Open **Insights > Dependency graph > Dependencies**. Confirm that GitHub finds the
application's manifests and lock files. Compare the packages with its normal build.
For the fallback's core path, use the packages declared in `dependency-lab/package-lock.json`.
The extra build-only dependency is an optional coverage exercise.

For the build-coverage extension, run the fixture build:

```bash
bash dependency-lab/build.sh
cat dependency-lab/build-resolved-components.json
```

The build resolves `cowsay@1.6.0`, but `dependency-lab/package.json` doesn't list it. Check the graph or current SBOM:

```bash
gh api "repos/${TARGET}/dependency-graph/sbom" \
  --jq '.sbom.packages[] | select(.name == "cowsay") | {name, versionInfo}'
```

If the query succeeds but returns nothing, the static graph missed this build dependency.

### 2. Submit a build dependency if the graph misses it

Do this step if the customer's build resolves packages the graph can't see, or
to practice that case with the fixture. Skip it if the graph already covers the
packages in scope. Mark missing build coverage **blocked** until you fix it.

Add `.github/workflows/dependency-submission.yml` on `main`:

```yaml
name: Dependency submission

on:
  workflow_dispatch:
  push:
    branches:
      - main
    paths:
      - dependency-lab/build-resolved-components.json
      - .github/workflows/dependency-submission.yml

permissions:
  contents: write

jobs:
  submit-build-inventory:
    name: Submit build inventory
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - name: Submit dependency snapshot
        env:
          GH_TOKEN: ${{ github.token }}
        run: |
          package_url="$(jq -r '.components[0].package_url' dependency-lab/build-resolved-components.json)"
          scanned="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
          jq -n \
            --arg sha "$GITHUB_SHA" \
            --arg ref "$GITHUB_REF" \
            --arg run_id "$GITHUB_RUN_ID" \
            --arg scanned "$scanned" \
            --arg package_url "$package_url" \
            --arg detector_url "$GITHUB_SERVER_URL/$GITHUB_REPOSITORY" \
            '{
              version: 0,
              sha: $sha,
              ref: $ref,
              job: {
                correlator: "ghas-admin-05-build-inventory",
                id: $run_id
              },
              detector: {
                name: "ghas-admin-05-fixture",
                version: "1.0.0",
                url: $detector_url
              },
              scanned: $scanned,
              manifests: {
                "dependency-lab/build-resolved-components.json": {
                  name: "Build-resolved components",
                  file: {
                    source_location: "dependency-lab/build-resolved-components.json"
                  },
                  resolved: {
                    cowsay: {
                      package_url: $package_url,
                      relationship: "direct",
                      scope: "development",
                      dependencies: []
                    }
                  }
                }
              }
            }' > snapshot.json
          gh api --method POST \
            "repos/$GITHUB_REPOSITORY/dependency-graph/snapshots" \
            --input snapshot.json
```

Run the workflow, then repeat the SBOM query. It should now return `cowsay@1.6.0`, matching the fixture build.

### 3. Export and inspect the SBOM if needed

Export the SPDX document:

```bash
gh api "repos/${TARGET}/dependency-graph/sbom" > sbom.json
jq '{
  name: .sbom.name,
  format: .sbom.spdxVersion,
  packages: (.sbom.packages | length),
  fixture_packages: [
    .sbom.packages[]
    | select(.name == "lodash" or .name == "marked" or .name == "minimist" or .name == "cowsay")
    | {name, versionInfo}
  ]
}' sbom.json
```

Keep the export as a point-in-time record. Dependabot and dependency review still use the live dependency graph.

### 4. Enable Dependabot and inspect a real advisory

Enable **Dependabot alerts** and **Dependabot security updates** under **Settings > Code security**. You can also use the API:

```bash
gh api --method PUT "repos/${TARGET}/vulnerability-alerts"
gh api --method PUT "repos/${TARGET}/automated-security-fixes"
```

Wait for alerts, then list open findings with the advisory details:

```bash
gh api "repos/${TARGET}/dependabot/alerts?state=open&per_page=100" --paginate \
  --jq '.[] | {
    number,
    package: .dependency.package.name,
    manifest: .dependency.manifest_path,
    scope: .dependency.scope,
    severity: .security_advisory.severity,
    ghsa: .security_advisory.ghsa_id,
    cve: (
      [.security_advisory.identifiers[] | select(.type == "CVE") | .value][0] // "none"
    ),
    affected: [
      .security_vulnerability.vulnerable_version_range
    ],
    patched: (
      .security_vulnerability.first_patched_version.identifier // "no patch"
    )
  }'
```

Open one High or Critical alert with a patched version. Read the advisory and record:

- The GHSA and CVE, when the advisory has one.
- The affected version range.
- The first patched version.
- The dependency path and whether it runs in production.

Don't dismiss a fixable fixture alert.

### 5. Merge a security-update pull request

Dependabot security updates target the minimum version that fixes the alert. Find the pull request linked from the alert or list Dependabot pull requests:

```bash
gh pr list --repo "$TARGET" --author app/dependabot \
  --state open --json number,title,url,headRefName
```

Pick a small update for a fixture dependency. Check the advisory link, the changed lock file, the compatibility notes, and the checks. Merge only after the repository tests pass.

For a customer application, trace how production uses the dependency and run the relevant tests, including compatibility checks for the changed API. If there's no Dependabot PR, make the smallest update to the advisory's patched version with the existing package manager. Keep manifest and lock-file changes together and get independent review.

```bash
gh pr checks <number> --repo "$TARGET"
gh pr merge <number> --repo "$TARGET" --merge
```

Poll the alert used for the test:

```bash
gh api "repos/${TARGET}/dependabot/alerts/<alert-number>" \
  --jq '{state, fixed_at, package: .dependency.package.name, ghsa: .security_advisory.ghsa_id}'
```

This step passes when the merged update reaches `main` and the corresponding alert reports `fixed`.

### 6. Configure scheduled version updates if needed

Add `.github/dependabot.yml`:

```yaml
version: 2

updates:
  - package-ecosystem: npm
    directory: /dependency-lab
    schedule:
      interval: weekly
      day: monday
      time: "09:00"
      timezone: America/New_York
    open-pull-requests-limit: 5
    labels:
      - dependencies
    groups:
      routine-version-updates:
        applies-to: version-updates
        update-types:
          - minor
          - patch
```

Open **Insights > Dependency graph > Dependabot**, run **Check for updates**, and inspect the resulting pull request.

Security-update pull requests fix a known advisory, usually with the minimum patched version. Scheduled version updates keep packages current even without an alert. The `routine-version-updates` group name appears only in version-update titles and branches, so check the PR body and Dependabot log to tell the two apart.

### 7. Test private-registry access if required

The fallback fixture uses only the public npm registry, so private-registry access needs a separate test.

Run this test only if the repository needs an approved private package:

1. Store a read-only credential as a Dependabot secret, or use the approved OIDC path when the registry supports it.
2. Add the registry under `registries` in `.github/dependabot.yml`. Reference the secret. **Never put its value in the file.**
3. Attach the registry to the relevant update entry.
4. Run **Check for updates** and inspect the update job.
5. The test passes when Dependabot resolves the private package and opens or evaluates an update with no authentication error.

Record the registry, credential owner, scope, and rotation date. If you use the fallback, mark this test **not tested: fixture has no private registry**.

### 8. Add a stable dependency-review check

Add `.github/workflows/dependency-review.yml` to `main`:

```yaml
name: Dependency review

on:
  pull_request:
    branches:
      - main

permissions:
  contents: read

jobs:
  dependency-review:
    name: Dependency review
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - uses: actions/dependency-review-action@v4
        with:
          fail-on-severity: high
          fail-on-scopes: runtime
          retry-on-snapshot-warnings: true
          show-patched-versions: true
```

Keep the workflow and job names as shown so the resulting check is **Dependency review**.

Create a ruleset for `main`, or update the existing merge ruleset:

1. Add **Require status checks to pass**.
2. Select `Dependency review`.
3. Require the branch to be current before merge.
4. Keep bypass limited to named emergency-access accounts.
5. Start in Evaluate mode if the repository already carries production traffic. Move to Active before the fail/pass test.

### 9. Prove the risky revision fails

Open the seeded branch:

```bash
gh pr create --repo "$TARGET" \
  --base main \
  --head feature/risky-dependency \
  --title "Test dependency-review protection" \
  --body "Controlled GHAS administrator lab change. Do not merge while the required check fails."
```

Update the PR with the latest `main` before testing the required check. An outdated
branch is a separate merge blocker.

Wait for the check:

```bash
gh pr checks <number> --repo "$TARGET" --watch
gh pr view <number> --repo "$TARGET" \
  --json mergeStateStatus,statusCheckRollup
```

`Dependency review` must fail because the pull request introduces `lodash@4.17.4`. Try the normal merge path. The ruleset must block it. **A failing workflow alone doesn't prove merging is blocked.**

If the check passes, inspect the workflow trigger, severity, scope, dependency snapshot, and ruleset target. Fix the control and push a new risky revision. Don't lower the test severity or use `warn-only`.

### 10. Correct the same pull request

Check out the test branch and update the dependency:

```bash
git fetch origin
git switch feature/risky-dependency
git merge origin/main
npm --prefix risky-dependency install lodash@4.17.21 \
  --save-exact --package-lock-only --ignore-scripts
git add risky-dependency/package.json risky-dependency/package-lock.json
git commit -m "Update risky dependency to patched version"
git push
```

Wait for the same required check. It must pass, and the pull request must become mergeable through normal review.

### Optional: Add the approved license policy to the same check

Use this path only if the customer needs a license gate. Have the legal owner approve explicit SPDX identifiers and the distribution scope. Check the dependency graph or exported SBOM for missing license information. Unknown licenses need a decision, not an assumption.

Extend step 8's existing `dependency-review-action` configuration with either `allow-licenses` or `deny-licenses`, never both. Keep the vulnerability threshold, runtime scope, and **Dependency review** job name unchanged. For example:

```yaml
with:
  fail-on-severity: high
  fail-on-scopes: runtime
  allow-licenses: MIT, Apache-2.0, BSD-3-Clause
  retry-on-snapshot-warnings: true
  show-patched-versions: true
```

The list is an example, not legal advice. Use the approved customer policy.

In the isolated fixture, create a fresh branch. Set `LICENSE_TEST_PACKAGE` and `LICENSE_TEST_VERSION` to a test package approved by the legal owner. Its known license must be outside the policy, and it must have no vulnerability above the configured threshold:

```bash
git switch -c test/license-policy
npm view "$LICENSE_TEST_PACKAGE@$LICENSE_TEST_VERSION" license
npm --prefix dependency-lab install "$LICENSE_TEST_PACKAGE@$LICENSE_TEST_VERSION" \
  --save-exact --package-lock-only --ignore-scripts
git add dependency-lab/package.json dependency-lab/package-lock.json
git commit -m "Test the approved dependency license policy"
git push -u origin HEAD
gh pr create --repo "$TARGET" --base main --fill
```

Use the customer's manifest paths when testing an approved customer repository. Never execute the test package. Confirm **Dependency review** reports the disallowed license and stops a contributor without bypass from merging.

Remove or replace that dependency on the same PR, wait for the same check to pass, and get independent review. If the license can't be identified or the feature is unavailable, record the blocker.

For a time-bound exception, use the existing legal intake route, or copy the [license exception form](../../resources/license-exception.yml) into `.github/ISSUE_TEMPLATE/` through a reviewed PR. Record the package version, usage, legal decision, and expiry.

A label or approved issue doesn't change the check. Add a license-only exception through review with `allow-dependencies-licenses` and the approved package's PURL. Verify its scope on the same PR, keep vulnerability checks on, and remove the exception when it expires.

## Exceptions

Use an exception only if no compatible patched version exists. Name the owner, the package and advisory, the compensating control, the review date, and the expiry. Remove the exception once a usable patch exists.

## Completion check

- The dependency graph covers the selected application's manifests and lock files.
- A real advisory review records the GHSA or CVE, affected range, and patched version.
- A security-update pull request has passed tests and human review. After merge, its linked alert reports fixed.
- The required `Dependency review` check blocks the risky revision.
- The fixed revision passes under the same workflow and ruleset.

For each extra step you did, record its result. Look for the submitted
package in the graph or SBOM. If you configured version updates, tell their PR
apart from a security update. If the repository uses private packages, confirm
Dependabot resolves them. **Not selected** and **blocked** don't count as
verified coverage or controls.

If you did the license policy, keep the legal approval and the blocked-then-fixed PR. Keep one dependency-review workflow. Don't create a separate license-only check.

## References

- [How the dependency graph recognizes dependencies](https://docs.github.com/en/code-security/concepts/supply-chain-security/dependency-graph-data)
- [Using the dependency submission API](https://docs.github.com/en/code-security/how-tos/secure-your-supply-chain/secure-your-dependencies/use-dependency-submission-api)
- [Dependency submission REST API](https://docs.github.com/en/rest/dependency-graph/dependency-submission)
- [Exporting an SBOM](https://docs.github.com/en/code-security/supply-chain-security/understanding-your-software-supply-chain/exporting-a-software-bill-of-materials-for-your-repository)
- [Dependabot alerts](https://docs.github.com/en/code-security/dependabot/dependabot-alerts/about-dependabot-alerts)
- [Dependabot security updates](https://docs.github.com/en/code-security/concepts/supply-chain-security/dependabot-security-updates)
- [Dependabot version updates](https://docs.github.com/en/code-security/dependabot/dependabot-version-updates/configuring-dependabot-version-updates)
- [Private registries for Dependabot](https://docs.github.com/en/code-security/dependabot/working-with-dependabot/configuring-access-to-private-registries-for-dependabot)
- [Dependency review](https://docs.github.com/en/code-security/concepts/supply-chain-security/dependency-review)
- [Dependency Review Action](https://github.com/actions/dependency-review-action)
