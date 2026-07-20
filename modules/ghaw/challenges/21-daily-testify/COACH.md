---

## Grounding conversation

**Required coach check-in:** agree the production boundary before the workflows are enabled on a schedule.

Ask the customer delivery team:

- Which repository has enough real test debt to justify this pipeline?
- What makes a test valuable for that repository beyond increasing coverage?
- Who reviews Testify issues, who reviews Test Improver pull requests, and who can pause each workflow?
- Which test directories may the Improver modify, and which production paths are off limits?

The team should name the test owner, maintainer, label, schedule, issue limit, pull-request limit, and rollback action before enabling the daily schedules.

## Delivery guidance

This activity installs two coordinated workflows, not a fully autonomous coding agent:

1. **Testify** is the analyst. It has read access and can create bounded, specific issues.
2. **A human** accepts or rejects the analysis by reviewing the issue.
3. **Test Improver** is the implementer. It can read issues and create one test-only pull request.
4. **A maintainer** validates the test and merges or closes the pull request.

The issue is the contract between analyst and implementer. If it does not identify a concrete test gap, do not let the Improver act on it. Tighten Testify's prompt instead.

When customer delivery team members are unsure whether a frontmatter field or permission is valid, use the [GitHub Actions workflow syntax](https://docs.github.com/en/actions/writing-workflows/workflow-syntax-for-github-actions) and [GITHUB_TOKEN permissions](https://docs.github.com/en/actions/security-for-github-actions/security-guides/automatic-token-authentication) documentation.

## Common blockers

| Symptom | Coaching response |
|---|---|
| Generic test-quality advice | Ask for the team's own framework, test conventions, failure modes, and quality bar. Add those facts to Testify's prompt. |
| Issue flood | Reduce Testify to three issues per run and require high-confidence, file-specific findings. |
| The Improver writes weak tests | Require a precise assertion and an error or edge case. Have the maintainer reject tests that only execute code. |
| The Improver changes source code | Narrow the prompt and repository path constraints to test directories only. |
| The workflow is not ready for scheduling | Keep both workflows on `workflow_dispatch` until one reviewed issue-to-pull-request cycle succeeds. |

## How to verify delivery

1. Trigger Testify manually and inspect each issue for specificity and the agreed label.
2. Have the customer owner review one issue; close or relabel weak issues rather than passing them to the Improver.
3. Dry-run Test Improver against an accepted issue.
4. Review the proposed pull request: it must change tests only, link the issue, and prove a meaningful behavior.
5. Enable the 09:00 and 10:00 schedules only after the team agrees the output remains useful and manageable.
