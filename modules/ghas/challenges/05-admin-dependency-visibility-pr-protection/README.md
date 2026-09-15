# Activity 5: Dependency Visibility & Pull Request Protection

Build a dependency control that works end to end. The repository must show what the build uses, Dependabot must fix a real alert, and a required dependency-review check must block a risky pull request before the corrected revision passes.

## Before you start

- Complete `ghas-admin-01`.
- Use a public fallback repository or a private/internal repository with GitHub Code Security.
- Get repository administration, Actions, and security-alert access.
- Install GitHub CLI, Git, jq, Node.js, and npm.
- Pick a repository owner who can merge the security update and confirm the merge rule.

The fallback fixture imports OWASP Juice Shop at `v20.0.0`, then adds a small npm manifest with known vulnerable versions. It also creates `feature/risky-dependency`.

## Provision the fallback

Skip this section when you have an approved pilot repository.

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
- `feature/risky-dependency`, which adds `lodash@4.17.4` as a new runtime dependency.

Set the target once:

```bash
export TARGET="<org>/ghas-admin-05-dependency-visibility-fixture"
```

## Exercise

### 1. Compare the dependency graph with the build

Open **Insights > Dependency graph > Dependencies**. Confirm that GitHub finds `dependency-lab/package-lock.json` and its declared packages.

Run the fixture build:

```bash
git clone "https://github.com/${TARGET}.git"
cd ghas-admin-05-dependency-visibility-fixture
bash dependency-lab/build.sh
cat dependency-lab/build-resolved-components.json
```

The build resolves `cowsay@1.6.0`, but that package is not in `dependency-lab/package.json`. Check the graph or current SBOM:

```bash
gh api "repos/${TARGET}/dependency-graph/sbom" \
  --jq '.sbom.packages[] | select(.name == "cowsay") | {name, versionInfo}'
```

An empty result proves the static graph missed a build dependency.

### 2. Submit the missing dependency

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

Run the workflow. Then repeat the SBOM query and confirm it returns `cowsay@1.6.0`. The graph now matches the fixture build.

### 3. Export and inspect the SBOM

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

Keep the export as point-in-time evidence. The live dependency graph remains the source used by Dependabot and dependency review.

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

Do not dismiss a fixable fixture alert.

### 5. Merge a security-update pull request

Dependabot security updates target the minimum version that fixes the alert. Find the pull request linked from the alert or list Dependabot pull requests:

```bash
gh pr list --repo "$TARGET" --author app/dependabot \
  --state open --json number,title,url,headRefName
```

Choose a small update for a fixture dependency. Inspect the advisory link, changed lock file, compatibility notes, and checks. Merge only after the repository tests pass:

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

### 6. Configure scheduled version updates

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

Security-update pull requests fix a known advisory and usually move to the minimum patched version. Scheduled version updates keep packages current even when no alert exists. The `routine-version-updates` group applies only to version updates, so its name appears in those pull-request titles and branches. Confirm the difference in the pull-request body and the Dependabot update log.

### 7. Test private-registry access when available

The fallback fixture uses the public npm registry. It does **not** prove access to a private registry.

Run this branch only in a pilot repository that already has an approved private package:

1. Store a read-only credential as a Dependabot secret, or use the approved OIDC path when the registry supports it.
2. Add the registry under `registries` in `.github/dependabot.yml`. Reference the secret; never put its value in the file.
3. Attach the registry to the relevant update entry.
4. Run **Check for updates** and inspect the update job.
5. Pass only when Dependabot resolves the private package and opens or evaluates an update without an authentication error.

Record the registry, credential owner, scope, and rotation date. If you use the fallback, mark this branch **not tested: fixture has no private registry**.

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

The workflow and job names are fixed. The resulting check is **Dependency review**.

Create a ruleset for `main`, or update the existing merge ruleset:

1. Add **Require status checks to pass**.
2. Select `Dependency review`.
3. Require the branch to be current before merge.
4. Keep bypass limited to named break-glass actors.
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

Wait for the check:

```bash
gh pr checks <number> --repo "$TARGET" --watch
gh pr view <number> --repo "$TARGET" \
  --json mergeStateStatus,statusCheckRollup
```

`Dependency review` must fail because the pull request introduces `lodash@4.17.4`. Try the normal merge path. The ruleset must block it. A red workflow without a blocked merge does not pass.

If the check passes, inspect the workflow trigger, severity, scope, dependency snapshot, and ruleset target. Fix the control and push a new risky revision. Do not lower the test severity or use `warn-only`.

### 10. Correct the same pull request

Check out the test branch and update the dependency:

```bash
git fetch origin feature/risky-dependency
git switch feature/risky-dependency
npm --prefix risky-dependency install lodash@4.17.21 \
  --save-exact --package-lock-only --ignore-scripts
git add risky-dependency/package.json risky-dependency/package-lock.json
git commit -m "Update risky dependency to patched version"
git push
```

Wait for the same required check. It must pass, and the pull request must become mergeable through the normal review path.

## Exceptions

Use an exception only when no compatible patched version exists. Name the owner, affected package and advisory, compensating control, review date, and expiry. Remove the exception when the patch becomes usable.

## Completion check

- The dependency graph includes the manifest dependencies and submitted `cowsay@1.6.0`.
- The exported SBOM contains the expected fixture packages.
- A real advisory review records the GHSA or CVE, affected range, and patched version.
- A merged security-update pull request closes its linked alert.
- A scheduled version-update pull request is clearly distinct from a security update.
- Private-registry access passed, or the fallback limitation is recorded.
- The required `Dependency review` check blocks the risky revision.
- The corrected revision passes under the same workflow and ruleset.

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
