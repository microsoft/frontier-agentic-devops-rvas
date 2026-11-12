# Activity 3: Configure CodeQL and enforce reviewed fixes

**Session outcome:** CodeQL covers the application's supported source code. An active rule blocks a vulnerable PR, then accepts the reviewed fix under the same configuration. A default-branch rescan confirms the merged change.

If you have no approved customer repository, this activity uses a public OWASP Juice Shop copy. The fixture keeps the advanced workflow off `main`, so default setup remains the first live test.

## Before you start

- Complete `ghas-admin-01`.
- Use an organization-owned repository where you have repository admin access.
- Install GitHub CLI, Git, and `jq`.
- Have a repository owner or build engineer review the source and build decisions.
- For a private or internal repository, confirm that GitHub Code Security is enabled.

Copilot Autofix is available for public repositories and for private or internal repositories with GitHub Code Security. It doesn't suggest a fix for every alert.

## Prepare the live fixture

Skip this step if you brought an approved repository with a known CodeQL finding.

```bash
export CURRICULUM="$PWD"
bash modules/ghas/resources/provisioning/challenges/03-admin-codeql-deployment-data-flow-autofix/provision.sh \
  provision --org <org>
```

```powershell
pwsh -File modules/ghas/resources/provisioning/challenges/03-admin-codeql-deployment-data-flow-autofix/provision.ps1 `
  -Action provision -Org <org>
```

To seed an existing repository, add `--repo <repo>` or `-Repo <repo>`. The fixture:

- imports OWASP Juice Shop at `v20.0.0` when the target repository does not exist;
- adds `tools/ghas_codeql_coverage_probe.py` to `main`;
- stores the advanced workflow on `codeql/advanced-setup`;
- opens a prepared pull request from `codeql/vulnerable-pr`;
- creates an issue with the fixture paths and the secure replacement.

Use the prepared pull request for the blocked-then-fixed test below. One reviewed fix is enough.

Set the target once:

```bash
export GHAS_REPO=<org>/<repo>
```

## Exercise

### 1. Inventory the code before scanning

Record the repository's actual language mix:

```bash
gh api "repos/$GHAS_REPO/languages"
git clone "https://github.com/$GHAS_REPO.git"
cd "$(basename "$GHAS_REPO")"
git ls-files | awk -F/ 'NF > 1 {print $1}' | sort -u
git ls-files '*.js' '*.ts' '*.tsx' '*.py' | sed 's#/[^/]*$##' | sort -u
```

For the fixture, expect JavaScript/TypeScript under the application roots and Python under `tools/`. Keep this inventory. You'll compare it with Tool Status after each run.

Record which languages CodeQL doesn't support and how the team analyzes them.
A successful CodeQL run says nothing about coverage for those languages.

#### Compare CodeQL coverage against Codename MDASH

Codename MDASH is Microsoft's multi-model agentic scanning harness, a separate preview capability inside Microsoft Defender that complements CodeQL. You won't run it here. Use the table to check its documented support for your language gaps and decide whether to seek preview enrollment. `ghas-admin-08` covers onboarding and operation.

Use your language inventory above to fill in one row per source type:

| Source type | CodeQL support | Current security control | MDASH documented support | Decision and reason |
| --- | --- | --- | --- | --- |
| | | | | |
| | | | | |

Keep the completed table in the fixture's or customer repository's tracking issue.

### 2. Check the setup

For an existing customer repository, look at its current setup and last successful
analysis first. Keep a working advanced setup if the build needs it.
For a new setup, start with default setup.

The commands and language-gap exercise below apply to the fallback fixture:

Confirm that `main` has no advanced CodeQL workflow:

```bash
gh api "repos/$GHAS_REPO/contents/.github/workflows/codeql.yml?ref=main" >/dev/null 2>&1 \
  && echo "STOP: advanced workflow exists on main" \
  || echo "main is ready for default setup"
```

Open **Settings > Advanced Security > CodeQL analysis**, select **Set up > Default**, and edit the detected languages before enabling it.

Select the supported languages in the repository. To practice repairing coverage
in the isolated fixture, select only **JavaScript/TypeScript** and leave Python
out. **Never create a coverage gap in a customer repository.**
Enable CodeQL and wait for the first analysis to finish.

```bash
gh run list --repo "$GHAS_REPO" --workflow "CodeQL" --limit 5
gh api "repos/$GHAS_REPO/code-scanning/analyses" \
  --jq '.[0] | {id, tool: .tool.name, ref, category, created_at, commit_sha}'
```

### 3. Inspect Tool Status and run logs

Open **Security and quality > Code scanning > Tool Status**. Check the default branch configuration and record:

- detected and configured languages;
- expected source roots and the downloadable scanned-files list;
- file coverage for each configured language;
- extraction warnings or errors;
- first and most recent analysis times;
- the age of the latest successful analysis.

Compare Tool Status with the inventory from step 1. In the fixture gap exercise, the first configuration omits Python under `tools/`.

Check the run logs too. Search for extractor warnings, missing dependencies, files scanned, and database finalization:

```bash
RUN_ID="$(gh run list --repo "$GHAS_REPO" --workflow "CodeQL" \
  --limit 1 --json databaseId --jq '.[0].databaseId')"
gh run view "$RUN_ID" --repo "$GHAS_REPO" --log \
  | grep -Ei 'warning|error|extract|source|file|database' || true
```

`grep` may find nothing. This command is only a diagnostic. Never use it to wrap the CodeQL job or hide a scanner failure.

### 4. Fix the missing coverage and rerun

In the fixture gap exercise, edit default setup and add **Python**.
Save and wait for the new analysis.

Then return to Tool Status. Confirm that JavaScript/TypeScript
and Python appear and that `tools/ghas_codeql_coverage_probe.py` is in the
scanned-files report. Compare the new analysis timestamp and coverage with the first run.

For a customer repository, fix gaps in its languages or source roots.
Don't add Python just for this exercise. Common causes are a missed language,
an excluded path, private-registry access, or an incomplete build. If coverage
already matches, note that in the tracking issue and continue.

**A successful run that skips application code doesn't prove coverage.**

### 5. Choose and run the build mode

Choose the smallest build mode that analyzes the real application:

| Mode | Use it when |
| --- | --- |
| `none` | CodeQL can extract the language without compiling, and generated code isn't required |
| `autobuild` | GitHub can reproduce the real build without custom commands |
| `manual` | The repository needs explicit production build commands, private dependencies, generated code, or a specific toolchain |

The fixture uses interpreted JavaScript/TypeScript and Python. Keep default setup and confirm its no-build analysis covers both languages. **Don't switch to advanced setup just to copy a workflow.**

Move to advanced setup only when default setup can't meet the repository's build requirements. The fixture keeps a recovery workflow with narrow permissions on `codeql/advanced-setup`.

```bash
git fetch origin codeql/advanced-setup
git show origin/codeql/advanced-setup:.github/workflows/codeql.yml
```

If you need advanced setup, disable default setup, restore the workflow to `main`, set the language and `build-mode`, add any manual build commands, and push. Watch the run to the end.

```bash
git checkout main
git pull --ff-only
git checkout origin/codeql/advanced-setup -- .github/workflows/codeql.yml
# Edit the matrix and build steps for the approved build.
git add .github/workflows/codeql.yml
git commit -m "Configure CodeQL for the production build"
git push
gh run watch --repo "$GHAS_REPO"
```

If you build a compiled language manually, start clean and run the same commands production uses. CodeQL must observe the compiler. Record the build mode and the Tool Status evidence from the finished run.

### 6. Prepare one finding and verify scan triggers

Use the prepared `codeql/vulnerable-pr` PR, or one approved customer PR with a finding. Keep it ready for review, not draft. Trace its CodeQL path before changing the code.

For the fixture:

```bash
export PR_NUMBER="$(gh pr list --repo "$GHAS_REPO" --state open \
  --head codeql/vulnerable-pr --json number --jq '.[0].number')"
test -n "$PR_NUMBER"
git fetch origin codeql/vulnerable-pr
git switch -c codeql-enforcement-test --track origin/codeql/vulnerable-pr
git commit --allow-empty -m "Run CodeQL against the enforcement candidate"
git push origin HEAD:codeql/vulnerable-pr
gh pr checks "$PR_NUMBER" --repo "$GHAS_REPO" --watch
```

Reuse the local branch if it already exists. Confirm the PR and default-branch scans ran. Check the scheduled scan in Tool Status; if it hasn't run yet, name who will verify its first result.

For advanced setup, keep `contents: read`, `actions: read`, and `security-events: write` on the analysis job only. Remove error suppression and give each language its own analysis category. Use the approved CodeQL Action version.

If merge queue is enabled, the workflow supplying its required check must also run on `merge_group`. Native **Require code scanning results** doesn't protect merge queue groups. Require the CodeQL workflow status for the queue and verify with a real queue run. If you don't use a merge queue, record it as not applicable.

Read the path from the first source node to the sink. Record:

- the rule ID and alert number;
- the untrusted source and its file;
- the sink and its file;
- any sanitizer or transformation between them;
- why the path is exploitable in this application.

Don't stop at the alert title. Follow each path node in the code and confirm the source can reach the sink.

### 7. Activate the merge rule and prove the block

With the repository administrator, create or update one ruleset targeting the default branch:

1. Require a PR and **Require code scanning results → CodeQL**. Use the approved threshold, **High or higher** for the fixture unless customer policy is stricter.
2. Limit bypass to named emergency actors with an approved need. An empty bypass list is fine. Don't allow whole repository roles.
3. For an existing production repository, inspect the result in **Evaluate** mode first. Move the same rule to **Active** before testing.

Capture the rule:

```bash
gh api "repos/$GHAS_REPO/rulesets" --jq '.[] | {id,name,enforcement}'
export RULESET_ID="YOUR-RULESET-ID"
gh api "repos/$GHAS_REPO/rulesets/$RULESET_ID" \
  --jq '{id,enforcement,bypass_actors,conditions,rules}'
gh api "repos/$GHAS_REPO/code-scanning/alerts?state=open&pr=$PR_NUMBER" \
  --jq '.[] | {number,rule: .rule.id,severity: .rule.security_severity_level}'
```

Push a fresh revision if the rule or analysis configuration changed. As a contributor without bypass, attempt the normal merge path. Confirm GitHub names code scanning as the blocker. A draft, a missing review, or an unrelated failing check doesn't prove this rule works.

### 8. Correct and merge the same PR

Write a manual fix or review an eligible Copilot Autofix suggestion. Read every changed line and test the affected behavior. Don't weaken the scan threshold or change the ruleset to make the fix pass.

For the isolated fixture, generate its supplied safe replacement from the curriculum checkout:

```bash
export TARGET_CHECKOUT="/path/to/existing-fixture-checkout"
bash "$CURRICULUM/modules/ghas/resources/provisioning/challenges/03-admin-codeql-deployment-data-flow-autofix/provision.sh" \
  render-fix > "$TARGET_CHECKOUT/routes/ghasCodeqlLookup.js"
cd "$TARGET_CHECKOUT"
```

Replace the checkout path first. The replacement uses parameter binding and JSON output. Inspect it and run the application's relevant tests. For a customer repository, use that application's safe APIs and real tests instead.

For the fixture, commit and push the correction:

```bash
git add routes/ghasCodeqlLookup.js
git commit -m "Fix insecure product lookup"
git push origin HEAD:codeql/vulnerable-pr
gh pr checks "$PR_NUMBER" --repo "$GHAS_REPO" --watch
```

Wait for CodeQL and the application's required tests, then confirm the finding is gone and code scanning no longer blocks the merge. Compare the ruleset ID and configuration with the blocked revision.

Get independent human review, merge the PR, and wait for the default-branch analysis. Confirm the merged code is covered and the finding is gone. A finding that exists only on this PR may never have created a default-branch alert.

If Autofix offers no suggestion, finish the manual fix and record that Autofix wasn't tested. If the scanner, merge-protection feature, or a required permission is unavailable, name the blocker. **A workflow draft or an inactive rule isn't enforcement.**

## Completion check

- The setup fits the repository. New configurations use default setup unless the build needs advanced setup.
- Tool Status matches the actual languages and expected source roots.
- Any coverage gaps are fixed and verified. The Python exercise is optional fixture practice.
- The CodeQL-versus-MDASH coverage table is complete, with a decision and reason for each source type.
- You chose the build mode from a real build requirement and ran it.
- One alert was traced from source to sink.
- One fix is merged after review and tests, and a rescan confirms it. Record whether you used Autofix or why it was unavailable.
- The vulnerable and fixed revisions of that PR were evaluated under the same active rule.
- The bypass list contains only approved emergency actors. Merge queue has its required workflow check when used.
- The latest analysis is successful and current.

## References

- [Codename MDASH overview](https://learn.microsoft.com/en-us/security-exposure-management/ai-code-security-overview). See the full note in [`resources/README.md`](../../resources/README.md).
- [Configure code scanning default setup](https://docs.github.com/en/code-security/how-tos/find-and-fix-code-vulnerabilities/configure-code-scanning/configure-code-scanning)
- [Evaluate default setup](https://docs.github.com/en/enterprise-cloud@latest/code-security/tutorials/customize-code-scanning/evaluate-default-setup)
- [About the Tool Status page](https://docs.github.com/en/code-security/concepts/code-scanning/tool-status-page)
- [CodeQL for compiled languages](https://docs.github.com/en/code-security/how-tos/find-and-fix-code-vulnerabilities/manage-your-configuration/codeql-for-compiled-languages)
- [Configure advanced setup](https://docs.github.com/en/code-security/code-scanning/creating-an-advanced-setup-for-code-scanning/configuring-advanced-setup-for-code-scanning)
- [Resolve code scanning alerts with Copilot Autofix](https://docs.github.com/en/code-security/how-tos/manage-security-alerts/manage-code-scanning-alerts/resolve-alerts)
- [Code scanning REST API](https://docs.github.com/en/rest/code-scanning/code-scanning)
- [Code scanning merge protection](https://docs.github.com/en/code-security/concepts/code-scanning/merge-protection)
