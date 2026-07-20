# Ch21 — Migrate Azure DevOps Repos with GitHub Enterprise Importer — Coach Guide

> Audience: facilitators and graders. Pair with the delivery team member `README.md`.

## Grounding conversation (you will be called)

**Required coach check-in:** before completion, ask the customer practitioner to tie the exercise to an actual migration they influence.

**Their question:** Coach conversation — name the real repository, owning team, cutover window, and follow-up backlog for Boards, Pipelines, LFS, permissions, and branch policies.

Use these follow-ups to steer the conversation:
- What is the smallest ADO Git repo with real PR history that proves the path without risking a critical cutover?
- Who owns source freeze, communication, and post-migration validation?
- Which non-migrated items become ch22 Boards work and ch23 Pipelines work?

## Facilitation intent

The goal is not to memorize `gh ado2gh` syntax. The delivery team member should experience the full operational loop: access readiness, inventory, pilot selection, script generation, single-repo migration, validation, logs, mannequin reclaim, and explicit follow-up work for the assets GEI does not migrate. Emphasize evidence over speed.

## Timing (reference)

| Phase | Duration |
|---|---:|
| Setup, access, and PAT validation | ~35 min |
| Inventory and pilot repo selection | ~35 min |
| Generated script review | ~35 min |
| Single-repo migration and wait/log handling | ~60 min |
| Validation of migrated and non-migrated content | ~35 min |
| Mannequin reclaim plan or execution | ~25 min |
| Debrief and follow-up backlog | ~15 min |
| **Total** | **~240 min** |

## Expected outputs / evidence

When a delivery team member completes this activity successfully, you should see:

- `gh extension list` includes `github/gh-ado2gh`.
- Shell environment has `GH_PAT` and `ADO_PAT` set, without the values appearing in committed files or logs.
- `repos.csv` from `gh ado2gh inventory-report --ado-org <ADO_ORG>` exists and has been reviewed for PR counts.
- `migrate-ado-repos.ps1` exists and the customer practitioner can explain what repos it queues or migrates.
- A GitHub repo exists in the target org with migrated Git history and PR metadata.
- The repo visibility is verified; private-by-default behavior or an intentional `--target-repo-visibility` choice is documented.
- Migration logs are downloaded within 24 hours, or the customer practitioner has the migration ID and exact log-download command.
- `mannequins.csv` exists and at least one mannequin is reclaimed, or an org-owner-approved reclaim plan exists.
- A follow-up backlog calls out Azure Boards, Azure Pipelines, Git LFS, permissions, branch policies, webhooks, and code-search re-indexing.

## Automated verification hints

```bash
GITHUB_ORG=<github-org>
TARGET_REPO=<target-repo>

gh extension list | grep ado2gh
gh repo view "$GITHUB_ORG/$TARGET_REPO" --json name,visibility,url --jq '{name, visibility, url}'
gh pr list --repo "$GITHUB_ORG/$TARGET_REPO" --state all --limit 10
gh api repos/$GITHUB_ORG/$TARGET_REPO/pulls?state=all --jq '.[0] | {number,title,state,user:.user.login}'
gh api repos/$GITHUB_ORG/$TARGET_REPO/branches --jq '.[].name'
test -f repos.csv || find . -name repos.csv -maxdepth 3
test -f mannequins.csv && head -n 5 mannequins.csv
```

Ask the customer practitioner to show the source ADO PR and the migrated GitHub PR side by side. If work item links existed on the source PR, verify the link is visible on the migrated PR.

## Common pitfalls

### Fine-grained GitHub PAT rejected
**Symptom:** GEI permission errors or migration creation failure even though the PAT appears valid.
**Fix:** Create a **classic** PAT. For org-owner migrations use `repo`, `admin:org`, and `workflow` scopes.

### SAML PAT not authorized
**Symptom:** `Resource is protected by organization SAML enforcement`.
**Fix:** Authorize the classic PAT for SAML SSO in GitHub token settings for the destination org.

### Destination rulesets block migrated history
**Symptom:** `GH013: Repository rule violations found`.
**Fix:** Add **Repository migrations** to the ruleset bypass list during migration, then remove temporary bypasses after validation.

### Private email blocks migrated commits
**Symptom:** `GH007: push would publish a private email address`.
**Fix:** Disable the email-block setting for the migration window or rewrite the affected history before migration.

### Repository metadata too big
**Symptom:** `Repository metadata too big to migrate`.
**Fix:** Re-run with `--skip-releases`; large release metadata is a common cause.

### TFVC mistaken for Git
**Symptom:** The repo is absent from supported migration paths or fails because it is not a Git repo.
**Fix:** GEI supports Azure DevOps Services **Git** repositories only. Convert TFVC to Git in Azure Repos first, then migrate the Git repo.

### Missing Azure DevOps data after migration
**Symptom:** Customer practitioner expects Boards work items, Azure Pipelines, Git LFS objects, or repo permissions to appear in GitHub.
**Fix:** Clarify scope: GEI migrates source, commit history, PRs, PR user history, PR work item links, PR attachments, and repo branch policies. Boards items, Pipelines, LFS objects, permissions, user-scoped policies, and cross-repo policies need follow-up work.

## Progressive hints

Use these in order — give the first hint, wait, then give the next only if the delivery team member is still stuck.

1. **Hint 1 (gentle):** Start with evidence. What did `inventory-report` say about this repository's PR count and type?
2. **Hint 2 (medium):** If the migration fails early, check token type, scopes, SAML SSO authorization, and org-owner rights before changing migration commands.
3. **Hint 3 (specific):** For a controlled pilot, run `gh ado2gh migrate-repo ... --queue-only --skip-releases --target-repo-visibility private`, copy the `RM_...` migration ID, then use `wait-for-migration` and `download-logs`.

## Debrief questions

- Which part of the migration was highest risk: identity, metadata fidelity, source freeze, or post-migration integrations?
- What did GEI migrate that a plain `git push --mirror` would not have migrated?
- Which items must be scheduled after cutover because GEI does not migrate them?
- How will you decide when a repo is ready for ch22 Boards follow-up and ch23 Pipelines follow-up?

## Grading rubric (point-weighted, 100 pts)

| Criterion | Points | What full marks looks like |
|---|---:|---|
| Access and token readiness | 15 | Classic GitHub PAT, correct scopes, SAML handled, ADO PAT scopes understood |
| Inventory and pilot choice | 15 | `repos.csv` reviewed; PR count and TFVC/Git status used in planning |
| Script generation | 10 | Generated `.ps1` inspected before execution; target names and visibility understood |
| Single-repo migration execution | 20 | `migrate-repo` run or queued with correct org/project/repo/target flags |
| Validation of migrated content | 15 | Git history, PRs, work item link behavior, branch/policy scope, and visibility verified |
| Logs and failure handling | 10 | Logs downloaded within 24h; common errors mapped to correct fixes |
| Mannequin reclaim | 10 | CSV generated and at least one reclaim completed or responsibly planned by org owner |
| Follow-up backlog and coach conversation | 5 | Real repo, owner, cutover window, and ch22/ch23 follow-ups are named |
| **Total** | **100** | |

## Notes for this module

This activity is org-scoped and intentionally has no activity prerequisites. Recommended ordering belongs in prose: ch21 proves repository migration, ch22 handles Azure Boards follow-up, and ch23 handles Azure Pipelines / Actions migration. Do not let customer delivery team members treat GEI as a complete Azure DevOps migration by itself.
