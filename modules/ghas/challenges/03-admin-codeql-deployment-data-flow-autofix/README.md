# Activity 3: CodeQL Deployment, Data Flow & Autofix

Start with CodeQL default setup. A successful workflow is only the first signal. You must also prove that CodeQL found the right languages, scanned the expected source, and produced a current analysis.

This activity uses a public OWASP Juice Shop copy when you do not have an approved customer repository. The fixture keeps the advanced workflow off `main`, so default setup remains the first live test.

## Before you start

- Complete `ghas-admin-01`.
- Use an organization-owned repository where you have repository admin access.
- Install GitHub CLI, Git, and `jq`.
- Ask a repository owner or build engineer to review the source and build decisions.
- For a private or internal repository, confirm that GitHub Code Security is enabled.

Copilot Autofix is available for public repositories and for private or internal repositories with GitHub Code Security. It does not produce a suggestion for every alert.

## Prepare the live fixture

Skip this step if you brought an approved repository with a known CodeQL finding.

```bash
bash modules/ghas/resources/provisioning/challenges/ghas-admin-codeql-live-20260915/provision.sh \
  provision --org <org>
```

```powershell
pwsh -File modules/ghas/resources/provisioning/challenges/ghas-admin-codeql-live-20260915/provision.ps1 `
  -Action provision -Org <org>
```

To seed an existing repository, add `--repo <repo>` or `-Repo <repo>`. The fixture:

- imports OWASP Juice Shop at `v20.0.0` when the target repository does not exist;
- adds `tools/ghas_codeql_coverage_probe.py` to `main`;
- stores the advanced workflow on `codeql/advanced-setup`;
- opens a prepared pull request from `codeql/vulnerable-pr`;
- creates an issue with the fixture paths and the secure replacement.

The prepared pull request belongs to `ghas-admin-04`. **Do not fix it in this activity.**

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

For the fixture, expect JavaScript/TypeScript under the application roots and Python under `tools/`. Keep this inventory. You will compare it with Tool Status after each run.

### 2. Enable default setup first

Confirm that `main` has no advanced CodeQL workflow:

```bash
gh api "repos/$GHAS_REPO/contents/.github/workflows/codeql.yml?ref=main" >/dev/null 2>&1 \
  && echo "STOP: advanced workflow exists on main" \
  || echo "main is ready for default setup"
```

Open **Settings > Advanced Security > CodeQL analysis**, select **Set up > Default**, and edit the detected languages before enabling it.

For the fixture's first run, select only **JavaScript/TypeScript**. Leave Python out on purpose. This creates a small, controlled coverage gap that you will find and fix. Enable CodeQL and wait for the initial analysis to finish.

```bash
gh run list --repo "$GHAS_REPO" --workflow "CodeQL" --limit 5
gh api "repos/$GHAS_REPO/code-scanning/analyses" \
  --jq '.[0] | {id, tool: .tool.name, ref, category, created_at, commit_sha}'
```

### 3. Inspect Tool Status, not just the run

Open **Security and quality > Code scanning > Tool Status**. Check the default branch configuration and record:

- detected and configured languages;
- expected source roots and the downloadable scanned-files list;
- file coverage for each configured language;
- extraction warnings or errors;
- first and most recent analysis times;
- the age of the latest successful analysis.

Use the repository inventory from step 1. Python exists under `tools/`, but the first configuration does not analyze it. That is the gap.

Check the run logs too. Search for extractor warnings, missing dependencies, files scanned, and database finalization:

```bash
RUN_ID="$(gh run list --repo "$GHAS_REPO" --workflow "CodeQL" \
  --limit 1 --json databaseId --jq '.[0].databaseId')"
gh run view "$RUN_ID" --repo "$GHAS_REPO" --log \
  | grep -Ei 'warning|error|extract|source|file|database' || true
```

`grep` may find no warning. The command is diagnostic only; it must not wrap the CodeQL job itself or hide a scanner failure.

### 4. Fix the missing coverage and rerun

Edit the default setup configuration and add **Python**. Save the change and wait for the new analysis.

Return to Tool Status. Confirm that JavaScript/TypeScript and Python now appear and that `tools/ghas_codeql_coverage_probe.py` is in the scanned-files report. Compare the new analysis timestamp and coverage with the first run.

For an approved customer repository, fix every unexplained gap before continuing. Common fixes include adding a missed language, correcting an excluded path, granting access to a private registry, or using the production build instead of a partial build.

**A green run with missing application code does not pass.**

### 5. Make and execute the build decision

Choose the smallest build mode that analyzes the real application:

| Mode | Use it when |
| --- | --- |
| `none` | CodeQL can extract the language without compiling, and generated code is not required |
| `autobuild` | GitHub can reproduce the real build without custom commands |
| `manual` | The repository needs explicit production build commands, private dependencies, generated code, or a specific toolchain |

The fixture uses interpreted JavaScript/TypeScript and Python. Keep default setup and confirm its no-build analysis covers both languages. **Do not switch to advanced setup just to copy a workflow.**

Move to advanced setup only when the repository has a real build need that default setup cannot meet. The fixture keeps a recovery workflow on `codeql/advanced-setup` with narrow permissions.

```bash
git fetch origin codeql/advanced-setup
git show origin/codeql/advanced-setup:.github/workflows/codeql.yml
```

If advanced setup is justified, disable default setup, restore the workflow to `main`, set the language and `build-mode`, add any manual build commands, then push it. Watch the run through completion.

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

For a manual compiled-language build, start clean and run the same commands production uses. CodeQL must observe the compiler. Record the selected mode and the Tool Status evidence from the completed run.

### 6. Trace one data-flow path

Open a CodeQL alert with a path. SQL injection, command injection, path traversal, and reflected XSS alerts are good candidates.

Read the path from the first source node to the sink. Record:

- the rule ID and alert number;
- the untrusted source and its file;
- the sink and its file;
- any sanitizer or transformation between them;
- why the path is exploitable in this application.

Do not stop at the alert title. Follow each path node in the code and confirm that the source can reach the sink.

### 7. Review and apply Copilot Autofix

Use an eligible alert on the default branch. Keep the prepared `codeql/vulnerable-pr` pull request unchanged for the next activity.

1. Select **Generate fix** on the alert.
2. Read the explanation and every changed line.
3. Check whether the patch removes the source-to-sink path without changing expected behavior.
4. Create the Autofix pull request.
5. Test the patch. Revise it if the generated change is incomplete or too broad.
6. Merge the approved fix and wait for CodeQL to scan the new default-branch commit.
7. Confirm that the alert closes or no longer appears on the new analysis. Record the new analysis ID and timestamp.

Autofix output is a proposed patch, not an approval. The rescan decides whether the CodeQL path is gone.

If Autofix is unavailable or the alert has no supported suggestion, mark only this item **blocked**. Capture the repository, alert number, availability message, and date. Keep the default setup, coverage repair, build decision, live scan, and data-flow review in scope.

## Completion check

- Default setup ran before any advanced setup.
- Tool Status matches the actual languages and expected source roots.
- The Python coverage gap was fixed and verified in a later analysis.
- The build mode was chosen from a real build requirement and executed.
- One alert was traced from source to sink.
- An Autofix patch was reviewed, tested, and rescanned, or that item has clear blocked evidence.
- The latest analysis is successful and current.

## References

- [Configure code scanning default setup](https://docs.github.com/en/code-security/how-tos/find-and-fix-code-vulnerabilities/configure-code-scanning/configure-code-scanning)
- [Evaluate default setup](https://docs.github.com/en/enterprise-cloud@latest/code-security/tutorials/customize-code-scanning/evaluate-default-setup)
- [About the Tool Status page](https://docs.github.com/en/code-security/concepts/code-scanning/tool-status-page)
- [CodeQL for compiled languages](https://docs.github.com/en/code-security/how-tos/find-and-fix-code-vulnerabilities/manage-your-configuration/codeql-for-compiled-languages)
- [Configure advanced setup](https://docs.github.com/en/code-security/code-scanning/creating-an-advanced-setup-for-code-scanning/configuring-advanced-setup-for-code-scanning)
- [Resolve code scanning alerts with Copilot Autofix](https://docs.github.com/en/code-security/how-tos/manage-security-alerts/manage-code-scanning-alerts/resolve-alerts)
- [Code scanning REST API](https://docs.github.com/en/rest/code-scanning/code-scanning)
