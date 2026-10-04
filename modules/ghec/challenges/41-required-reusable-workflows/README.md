# Ch41: Required reusable workflows

**Session outcome:** An approved repository runs real shared CI. An organization ruleset requires the trusted workflow before its contributors can merge.

## Prerequisites

Use an organization owner, an approved workflow source repository, and one consumer application with tested CI from Ch04. Start with one repository, not the whole organization.

The [baseline workflow](../../resources/ci/baseline.yml) supports Node.js 22 applications with `package-lock.json`, `npm test`, and `npm run build`. Use the working Ch38 application template as its source repository. For another stack, replace those commands with the already-tested customer CI before publishing it. Every selected consumer must support the agreed commands.

## Tasks

### Part A: Publish working shared CI

1. Copy `resources/ci/baseline.yml` into the source repository as `.github/workflows/baseline.yml`. Review existing workflows before replacing files.
2. Run the exact build and test commands locally. Open a PR in the source application and confirm the workflow passes real tests. Keep `contents: read`; it does not need deployment secrets.
3. Protect the workflow and its test/build scripts with independent CODEOWNERS review. Merge the reviewed workflow and obtain its commit SHA:

   ```bash
   gh api repos/YOUR-ORG/YOUR-TEMPLATE/commits/HEAD --jq .sha
   ```

4. For a private or internal source, open **Settings → Actions → General → Access** and allow the approved organization consumers to use its workflows. A private source can enforce workflows only in private targets; an internal source supports internal and private targets. Choose compatible visibility before continuing.

### Part B: Call it from the consumer

Add `.github/workflows/ci.yml` in the consumer, replacing the source repository and ref with the reviewed **40-character commit SHA**:

```yaml
name: Shared CI
on:
  pull_request:
  merge_group:
permissions:
  contents: read
jobs:
  baseline:
    uses: YOUR-ORG/YOUR-TEMPLATE/.github/workflows/baseline.yml@REVIEWED_COMMIT_SHA
```

Merge the caller through the normal review process. Open a new consumer PR that changes application code. Confirm the run checks out the **consumer's proposed code**, executes its actual tests, and identifies the pinned shared workflow. Do not pass `secrets: inherit`.

### Part C: Require the workflow identity

1. Open **Organization settings → Repository → Rulesets**. Create or edit an approved branch ruleset targeting this consumer's **default branch only**.
2. Add **Require workflows to pass before merging**. Select the trusted source repository and `.github/workflows/baseline.yml`, using the reviewed ref offered by the rule. Record it; align the consumer's pinned version with this required version.
3. The supplied baseline has `pull_request` and `merge_group` triggers as well as `workflow_call`, so the same file can serve as the required entry. A workflow with only `workflow_call` cannot be the ruleset entry. Ruleset workflows ignore event filters; do not rely on path or branch filters to limit their coverage.
4. Enable enforcement for the approved consumer only. Use a contributor without bypass permissions to introduce a real failing test. Confirm the selected ruleset workflow fails and blocks merging.
5. On the test PR, remove the consumer caller. Confirm the organization rule still schedules the trusted source workflow. Add a harmless alternate workflow with the same check name: its passing result must not replace the failing required workflow.
6. Restore the caller and repair the test. Confirm the genuine required workflow passes, then obtain independent review and merge.

If the tenant lacks the workflow-specific rule, record that enforcement as blocked. A required status check can restrict the reporting GitHub App, but cannot distinguish two workflows run by GitHub Actions. Do not describe that fallback as trusted-workflow enforcement.

### Part D: Maintain it

Name the shared CI owner and agree how consumers receive reviewed version updates. Test updates on this consumer before adding another cohort. Keep the ruleset, source SHA, and failed/passing PR runs as [completion evidence](../../../README.md#completion-evidence).

## References

- [Reusing workflows](https://docs.github.com/en/actions/how-tos/reuse-automations/reuse-workflows)
- [Required workflow rules and supported events](https://docs.github.com/en/enterprise-cloud@latest/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets#require-workflows-to-pass-before-merging)
- [Organization rulesets](https://docs.github.com/en/enterprise-cloud@latest/organizations/managing-organization-settings/creating-rulesets-for-repositories-in-your-organization)
