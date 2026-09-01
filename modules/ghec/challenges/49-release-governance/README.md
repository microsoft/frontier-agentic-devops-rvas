# Ch49: Release Governance

> Deliver a governed release path: release candidates, explicit approval evidence, release notes, tag standards, and rollback ownership.

## Prerequisites

- A GitHub Enterprise Cloud organization and a repository where you can administer issues, contents, Actions, and releases.
- A token with the scopes listed by `modules/ghec/resources/provisioning/scripts/setup.sh doctor ch49 --org <org>` (least privilege; for this activity: `repo` + `read:org`).
- Local tooling: `gh >= 2.x`, `git`, `jq`.
- No setup step changes organization settings, rulesets, environments, or release permissions.

## Customer delivery objectives

You will:

- Define release ownership, approval, release-note, tag, rollback, and exception standards.
- Capture release candidate evidence before a release is published.
- Use issues, labels, checklists, and a manually triggered evidence workflow to show the governance trail.
- Inspect higher-impact controls such as rulesets or deployment environments and record an owner-approved rollout decision.
- Publish a sample release or document why production publication is deferred.

## Scenario

A customer publishes releases from several repositories. Approvals live in chat, release notes vary, and nobody clearly owns rollback. Define the controls, create a candidate record, collect validation evidence, and record the approval or rejection with the release history.

> [!IMPORTANT]
> Choose the target before setup. Use an authorised customer release repository if you have one, wherever this guide names `ghec-ch49-release-governance`, and skip setup. Otherwise use the fallback seeded repository below. Rulesets, deployment environments, and org-wide release permissions can block teams: inspect and propose them, but change them only with owner approval.

## Sample test repository or environment

```bash
bash modules/ghec/resources/provisioning/scripts/setup.sh provision ch49 --org <org>
```
```powershell
modules/ghec/resources/provisioning/scripts/setup.ps1 provision ch49 -Org <org>
```

Setup is idempotent and creates only these namespaced artifacts. Teardown accepts only the `ghec-ch49-*` prefix.

- `ghec-ch49-release-governance` with release governance documentation, changelog, and release readiness issue form.
- Labels for `release: candidate`, `release: approved`, `release: blocked`, and `release: rollback-ready`.
- `.github/workflows/release-evidence.yml`, a manual workflow scaffold for recording validation evidence.
- A sample release candidate issue.
- Printed commands for inspecting release, ruleset, and environment controls; setup does not mutate those controls.

## Tasks

### Part A — Inspect current release controls

1. Snapshot repository release and tag evidence:
   ```bash
   gh release list --repo <org>/ghec-ch49-release-governance --limit 20
   gh api repos/<org>/ghec-ch49-release-governance/tags --jq '.[].name'
   ```
2. Inspect higher-impact controls without changing them:
   ```bash
   gh api repos/<org>/ghec-ch49-release-governance/rulesets --jq '.[]? | {name, target, enforcement}'
   gh api repos/<org>/ghec-ch49-release-governance/environments --jq '.environments[]? | {name, protection_rules}'
   ```
3. Record who can approve releases, who can publish them, and which controls require explicit owner approval before enforcement.

### Part B — Define release governance

4. Complete `docs/release-governance.md` with:
   - release owner and approver group
   - tag naming pattern, for example `vMAJOR.MINOR.PATCH`
   - release notes source and required sections
   - validation evidence required before approval
   - rollback owner and rollback evidence
   - exception route and review cadence
5. Decide which controls are enforced now and which remain a signed rollout proposal.

### Part C — Create a release candidate record

6. Open a release candidate issue using the provided template.
7. Attach scope, risk, validation plan, approver, rollback plan, and planned release tag.
8. Apply `release: candidate` and keep comments or workflow links as the evidence trail.

### Part D — Collect evidence and approve

9. Run the manual evidence workflow or attach equivalent validation output:
   ```bash
   gh workflow run release-evidence.yml --repo <org>/ghec-ch49-release-governance -f release_tag=v0.1.0 -f evidence_url=<url-or-record-id>
   ```
10. Approver reviews the candidate issue and applies either `release: approved` or `release: blocked`.
11. If approval is blocked, record the reason, owner, and next decision date.

### Part E — Publish or dry-run the release

12. If authorized, create the release:
    ```bash
    gh release create v0.1.0 --repo <org>/ghec-ch49-release-governance --title 'v0.1.0' --notes-file CHANGELOG.md
    ```
13. If production release publication is not authorized, create a draft release or record a signed dry-run decision instead.
14. Link the release, draft, or dry-run evidence back to the candidate issue.

## Reference links

- About releases — https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases
- Managing releases — https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository
- Manually running a workflow — https://docs.github.com/en/actions/managing-workflow-runs/manually-running-a-workflow
- About rulesets — https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets
- Release webhook event — https://docs.github.com/en/webhooks-and-events/webhooks/webhook-events-and-payloads#release
