# Activity 4: CodeQL Merge Enforcement

Make CodeQL part of the merge decision. The control passes only when the prepared vulnerable pull request is blocked and a corrected revision of that same pull request passes under the same rule.

## Before you start

- Complete `ghas-admin-03`.
- Keep its successful CodeQL setup and coverage evidence.
- Use the prepared `codeql/vulnerable-pr` pull request from the fixture.
- Get repository ruleset administration access.
- Confirm who may bypass repository rules.

Set the same target used in the previous activity:

```bash
export GHAS_REPO=<org>/<repo>
export PR_NUMBER="$(gh pr list --repo "$GHAS_REPO" --state open \
  --head codeql/vulnerable-pr --json number --jq '.[0].number')"
test -n "$PR_NUMBER"
```

The pull request must be ready for review. A draft pull request is already blocked for another reason and cannot prove the CodeQL control.

## Exercise

### 1. Configure and prove the scan triggers

The protected branch needs analysis after:

- a pull request change;
- a push to `main`;
- the scheduled full scan;
- a `merge_group` event when the repository uses merge queue and depends on a workflow check.

Default setup manages pull-request, default-branch, and scheduled scans. Verify each one from live runs. Push a fresh commit to the prepared pull request so its result belongs to the current configuration:

```bash
git fetch origin codeql/vulnerable-pr
git checkout -B codeql/vulnerable-pr origin/codeql/vulnerable-pr
git commit --allow-empty -m "Trigger CodeQL enforcement test"
git push origin codeql/vulnerable-pr
gh pr checks "$PR_NUMBER" --repo "$GHAS_REPO" --watch
```

Confirm the schedule in Tool Status. Record the next run and the most recent scheduled run, if one exists. If the repository has not reached its first scheduled run, name the owner who will attach that result later. Do not change the clock or treat `workflow_dispatch` as proof of a scheduled event.

If the repository uses merge queue, add `merge_group` to the workflow that supplies the queue's required check. The fixture's recovery workflow already includes it:

```bash
git show origin/codeql/advanced-setup:.github/workflows/codeql.yml
```

Native **Require code scanning results** protection does not apply to merge queue groups. For a repository with merge queue, use both controls:

- Require code scanning results for pull requests.
- Require the CodeQL workflow status for `merge_group`.

If explicit trigger control requires advanced setup, restore the fixture workflow to `main`, run it, and confirm a real result. A workflow left on the recovery branch does not pass.

If the repository does not use merge queue, record `merge_group: not applicable` with the repository setting that proves it.

### 2. Keep permissions narrow and failures visible

For advanced setup, start with no workflow-wide permissions and grant only the analysis job:

```yaml
permissions: {}

jobs:
  analyze:
    permissions:
      actions: read
      contents: read
      security-events: write
```

Review the live workflow before making it required:

```bash
gh api "repos/$GHAS_REPO/contents/.github/workflows/codeql.yml?ref=main" \
  --jq '.content' | base64 --decode
```

Remove `continue-on-error`, `|| true`, fallback success steps, and broad write permissions. Keep a unique analysis category for each language or component. Use the current approved CodeQL Action major.

Trigger a scan after the review. A failed extractor, build, or upload must fail the job and remain visible in the pull request.

### 3. Create the rule in Evaluate mode

Create a branch ruleset that targets `main`.

1. Set enforcement to **Evaluate**.
2. Add **Require a pull request before merging**.
3. Add **Require code scanning results**.
4. Select **CodeQL** and the approved threshold. Use **High or higher** for this test unless your policy is stricter.
5. Add the required workflow status only when merge queue uses it.
6. Remove role-wide bypass. Add only a named emergency team or GitHub App when there is an approved need.

Record the ruleset ID and configuration:

```bash
gh api "repos/$GHAS_REPO/rulesets" \
  --jq '.[] | {id, name, enforcement}'
export RULESET_ID=<ruleset-id>
gh api "repos/$GHAS_REPO/rulesets/$RULESET_ID" \
  --jq '{id, name, enforcement, bypass_actors, conditions, rules}'
```

Evaluate mode does not block the pull request. Use the ruleset insights to confirm that the vulnerable revision would fail. Fix the rule target, tool, or threshold if it does not appear.

### 4. Turn the same rule on

Change that ruleset from **Evaluate** to **Active**. Do not create a second rule for the proof.

Push another empty commit to the prepared pull request and wait for CodeQL:

```bash
git commit --allow-empty -m "Test active CodeQL merge protection"
git push origin codeql/vulnerable-pr
gh pr checks "$PR_NUMBER" --repo "$GHAS_REPO" --watch
```

Open the pull request and attempt the normal merge path. Confirm all of these points:

- CodeQL reports the new SQL injection or reflected XSS path on the pull request.
- The active ruleset names code scanning as the blocking rule.
- The pull request cannot merge.
- The block is not caused only by draft state, a missing review, or an unrelated status check.

List the open pull-request alerts:

```bash
gh api "repos/$GHAS_REPO/code-scanning/alerts?state=open&pr=$PR_NUMBER" \
  --jq '.[] | {number, rule: .rule.id, severity: .rule.security_severity_level, state}'
```

If the pull request can merge, stop and repair the target branch, CodeQL tool selection, severity threshold, analysis category, or bypass list. Push a new revision and repeat the test.

### 5. Fix the same pull request

Replace `routes/ghasCodeqlLookup.js` on `codeql/vulnerable-pr` with the safe version:

```bash
cat > routes/ghasCodeqlLookup.js <<'EOF'
const express = require('express')
const sqlite3 = require('sqlite3')
const router = express.Router()

router.get('/ghas-codeql-lookup', (req, res) => {
  const db = new sqlite3.Database(':memory:')
  db.all(
    'SELECT * FROM Products WHERE name = ?',
    [req.query.name],
    (err, rows) => {
      if (err) {
        res.status(500).json({ error: 'lookup failed' })
        return
      }
      res.json({ query: req.query.name, rows })
    }
  )
})

module.exports = router
EOF

git add routes/ghasCodeqlLookup.js
git commit -m "Fix insecure product lookup"
git push origin codeql/vulnerable-pr
gh pr checks "$PR_NUMBER" --repo "$GHAS_REPO" --watch
```

Wait for the same CodeQL configuration and active ruleset. Confirm that the pull-request alert is gone, CodeQL passes, and the merge path is no longer blocked by code scanning.

Query the ruleset again and compare its ID, threshold, target, and bypass actors with the blocked revision. They must be unchanged.

Do not merge the pull request unless the repository owner wants to keep the fixture fix.

### 6. Check bypass access

Review every bypass actor. Remove broad repository roles and teams that do not own emergency response.

For each remaining actor, record:

- the named user, team, or GitHub App;
- why it needs bypass;
- whether bypass is always allowed or pull-request only;
- the owner and review date.

An empty bypass list is valid. Admin access alone is not a reason to bypass the rule.

## If a feature is unavailable

If **Require code scanning results**, ruleset Evaluate mode, merge queue, or an entitled feature is unavailable, mark that item **blocked** with the repository, plan or entitlement, screenshot or API response, and date.

Keep the available work live. Run the pull-request scan, expose scanner failures, review permissions, inspect the vulnerable alert, push the safe fix to the same pull request, and confirm the new scan result. A workflow draft or ruleset proposal does not count as a live test.

## Completion check

- Pull-request and protected-branch push scans have live evidence.
- The scheduled trigger is active, with its next run or latest scheduled result recorded.
- `merge_group` ran when merge queue applies, or its exclusion has repository evidence.
- Workflow permissions are least privilege and scanner failures remain visible.
- One ruleset moved from Evaluate to Active.
- The prepared vulnerable pull request was blocked by Require code scanning results.
- The corrected revision of the same pull request passed under the same rule.
- Only approved named actors can bypass the rule.

## References

- [Code scanning merge protection](https://docs.github.com/en/code-security/concepts/code-scanning/merge-protection)
- [Set code scanning merge protection](https://docs.github.com/en/enterprise-cloud@latest/code-security/how-tos/find-and-fix-code-vulnerabilities/manage-your-configuration/set-merge-protection)
- [Available rules for rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets)
- [Workflow syntax](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax)
- [Events that trigger workflows](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows)
- [Secure use reference](https://docs.github.com/en/actions/reference/security/secure-use)
- [GitHub CodeQL Action](https://github.com/github/codeql-action)
