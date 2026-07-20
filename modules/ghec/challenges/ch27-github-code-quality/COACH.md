# Ch27 - GitHub Code Quality: Code Health & Coverage - Delivery Assurance Guide

> Audience: delivery assurance leads and authorized customer implementation owners. Pair with the customer delivery team `README.md`.

## Delivery intent

This activity establishes the GitHub Code Quality product on a real customer repository. The delivery team should enable the product, receive rules-based Code Health findings, publish Cobertura coverage from CI, make an explicit threshold decision, and prepare a controlled organization rollout. The customer owns all configuration and remediation decisions; Copilot suggestions are proposed changes that still require normal pull-request review.

## Delivery checkpoints

| Phase | Duration |
|---|---:|
| Scope, availability, ownership, and baseline | ~45 min |
| Enablement and first analysis | ~45 min |
| Coverage generation and upload | ~75 min |
| Pull-request finding triage and threshold decision | ~75 min |
| Organization pilot and handover | ~40 min |
| Total | ~5 hrs |

## Expected evidence

- Code Quality is enabled in the selected customer repository and its language and runner decisions are captured.
- Standard findings shows maintainability and reliability scores plus a reviewed baseline backlog.
- The CI workflow creates Cobertura XML and uploads it using `contents: read` and `code-quality: write`.
- A PR shows `github-code-quality[bot]` coverage feedback; capture aggregate and per-file evidence.
- A rules-based PR finding has a recorded fix or a specific dismissal rationale, with Autofix review evidence where used.
- The customer has an explicit informational-versus-blocking threshold decision and an organization pilot proposal.

## Assurance guidance

### Keep the product boundary clear

Code Quality uses CodeQL technology for maintainability and reliability, but it is not the CodeQL security code-scanning activity. `ghec-ch12` is about security vulnerabilities, advanced CodeQL workflow control, and security-alert triage. This activity is about Code Health, coverage, product findings, and native Code Quality rollout.

Likewise, a generic lint result, code-review bot, or organization ruleset does not enable the product. They can complement the session, but the delivery team must navigate to Settings -> Security -> Code quality and demonstrate actual Code Quality outputs.

### Product and tenant constraints

- Confirm that the tenant is GitHub Team or Enterprise Cloud, the enterprise allows Code Quality when applicable, Actions is enabled, and the repository contains a supported language.
- Coverage is contingent on a real test suite producing Cobertura XML. Do not create fake coverage data just to satisfy the exercise.
- An organization may choose a staged native repository-access rollout. Do not enable every repository without an authorized cohort and rollback decision.
- Copilot review is optional. Rules-based findings and product enablement must still be demonstrable when Copilot licenses or AI features are unavailable.

### Threshold and remediation guardrails

- Use Error, Warning, and Note severity for rules-based Code Quality decisions only.
- A threshold should reflect the customer’s repository context and team capacity. Do not prescribe a universal coverage percentage or severity gate.
- Require the delivery team to explain each dismissal; a dismissal is a risk decision, not a way to hide backlog.
- Review Autofix patches like any other pull-request change. Never configure automatic merge from a Code Quality suggestion.

## Implementation verification

Use the UI evidence first because Code Quality availability and API details are tenant-dependent. Supplement with the CLI for repository and workflow evidence:

```bash
ORG=<org>
REPO=<repository>

# Confirm the authorized repository and its default branch.
gh repo view "$ORG/$REPO" --json name,visibility,defaultBranchRef

# Confirm the CI workflow grants the narrowly scoped coverage upload permission.
gh api "repos/$ORG/$REPO/contents/.github/workflows/ci.yml" \
  -H "Accept: application/vnd.github.raw" \
  | grep -E "code-quality: write|upload-code-coverage|cobertura|coverage"

# Inspect the latest runs for default-branch and PR coverage evidence.
gh run list --repo "$ORG/$REPO" --limit 10
```

Verify manually in GitHub:

1. Settings -> Security -> Code quality: enabled; languages and runner match the recorded decision.
2. Security and quality -> Code quality -> Standard findings: reliability and maintainability scores are visible, with the reviewed backlog.
3. Test pull request: the coverage comment comes from `github-code-quality[bot]`; it includes aggregate coverage and per-file deltas.
4. Files changed: rules-based comments from `github-code-quality[bot]` are distinguished from optional Copilot comments.
5. Checks: the merge-block behavior matches the customer’s approved Code Quality threshold, if one was configured.
6. Organization Settings -> Security -> Code quality: the pilot repository access selection, owners, and enforcement decision are recorded.

## Delivery risks and recovery

### Code Quality is unavailable or cannot be enabled

Symptom: The Code quality setting is absent, unavailable, or cannot be saved.  
Fix: Confirm the plan, enterprise allow-list, Actions availability, organization policy, repository access, and supported language. Record the blocker and produce an authorized enablement request rather than substituting another product.

### Coverage does not appear on the pull request

Symptom: The workflow passes but there is no coverage comment or branch comparison.  
Fix: Confirm a valid Cobertura XML report exists, the upload action executed, `code-quality: write` is present, and runs exist on both the default branch and the PR branch. For forked PRs, preserve the documented upload guard instead of granting write access to untrusted code.

### No quality findings appear

Symptom: Code Quality is enabled but the selected PR has no rules-based comments.  
Fix: Verify that the changed files use a supported language and the CodeQL - Code Quality check completed. A clean PR is valid evidence; review the default-branch baseline and choose a focused, authorized change only if the customer agrees it is safe to do so.

### Scores appear inconsistent with engineering judgment

Symptom: A small repository scores highly despite limited code, or generated code lowers maintainability.  
Fix: Interpret scores in repository context. Capture the cause, exclude no code without authorization, and use the baseline and trend rather than a generic target.

### A merge gate blocks unexpectedly

Symptom: A PR remains blocked after a visible finding is addressed.  
Fix: Recheck every rules-based finding at or above the selected threshold and confirm the configured threshold. Copilot comments do not count toward the rules-based Code Quality gate.

## Progressive support

1. Availability: Ask the delivery team to find the repository’s Settings -> Security -> Code quality page and identify the selected languages before naming a setting for them.
2. Coverage: Ask which test command creates the report, then have them inspect the output path before adding the upload step.
3. Triage: Ask who authored a PR comment and what its severity means before suggesting a fix, dismissal, or Autofix review.
4. Rollout: Ask which two repositories are safest for a pilot and what result would cause the customer to stop or expand it.

## Handover questions

- Which Code Quality signals will be informational, and which severity threshold—if any—will block merges for this repository?
- Who owns the Standard findings backlog, and how often will that owner review it with the engineering team?
- Which pilot repositories meet the rollout criteria, and what objective evidence would trigger rollback or expansion?

## References for delivery leads

- [Enabling GitHub Code Quality](https://docs.github.com/en/code-security/how-tos/maintain-quality-code/enable-code-quality)
- [Setting up code coverage](https://docs.github.com/en/code-security/how-tos/maintain-quality-code/set-up-code-coverage)
- [Preventing code quality issues from reaching the default branch](https://docs.github.com/en/code-security/tutorials/improve-code-quality/catch-issues-before-merge)
- [Metrics and scores reference](https://docs.github.com/en/code-security/reference/code-quality/metrics-and-ratings)
