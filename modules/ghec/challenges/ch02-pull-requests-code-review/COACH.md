# Ch02 — Branches, Pull Requests & Code Review — Delivery Assurance Guide

> Audience: delivery assurance leads and authorized customer implementation owners. Pair with the corresponding customer implementation `README.md`.
> **Customer authorization and rollout boundary:** Apply changes in a customer-owned tenant or repository only after the named customer owner authorizes the scope. A fallback is a sample test repository or environment, not the destination: record its evidence, risks and controls, accountable owner, handover, and the explicit tenant adoption, cutover, or rollout decision.


## Customer adoption decision

**Required delivery assurance check:** before implementation is accepted, confirm the authorized tenant scope, implementation evidence, risk controls, accountable owner, handover, and next adoption action.

**Decision prompt:** think about the last pull request that sat open too long or had a painful review cycle on your team: which of the branch protection rules, required reviewers, or PR templates you just configured would have shortened it, and what's still missing? Record the accountable owner, implementation evidence, risk or blocker, and next customer adoption action.

> **Customer implementation preference:** prioritize an authorized customer tenant or artifact over the `ghec-ch02-pull-requests-code-review` sample. If a sample is necessary, record the target tenant scope, accountable owner, authorization blocker, evidence to carry forward, and the adoption, cutover, or rollout decision. The sample is a safe fallback, not the destination.

Use these prompts to verify customer ownership and the next action:
- Describe a recent PR that stalled or caused friction — who was involved and why did it stall?
- Which protection or template element from this activity would have caught the problem earlier?
- What one branch-protection rule or CODEOWNERS entry will you propose to your team this week?

## Delivery assurance notes
- **Customer adoption outcome:** the customer implementation owner establishes a real review culture — branch-per-change, required owner review, clean conflict resolution, and a deliberate merge-strategy choice.
- **Implementation risks to verify:**
  - **Self-approval.** A solo customer implementation owner can't approve their own PR when "required approvals ≥ 1" is set. This is *correct* behavior. Have them demonstrate the **gate** (PR blocked until someone else approves) rather than approving themselves. If a second account is available, use it.
  - **`CODEOWNERS` not triggering.** The file must live at `.github/CODEOWNERS` (or repo root / `docs/`), reference **teams/users that exist and have access**, and the rule must protect the branch with "require review from Code Owners" *on*. A non-existent team silently no-ops.
  - **Conflict fear.** Customer implementation owners panic at conflict markers. Reassure: edit out `<<<<<<<`, `=======`, `>>>>>>>`, keep the right content, commit.
- **Delivery lead prompts:** ask "who *must* look at this code before it ships?" (→ CODEOWNERS), and "what does the history look like after each merge type?" (→ `git log --graph`).
- **Org-scoped note:** runs with just an org + org-owner token. Creating the team in Task 7 needs `admin:org`/owner rights, which the org-owner token already has.

## Implementation acceptance evidence
| Criterion | Assurance weight | Customer-owned evidence |
|---|---:|---|
| PR lifecycle (branch → draft → ready → ≥3 PRs) | 20 | Three PRs, one started draft, all linked to issues with `Closes #n` |
| Review mechanics | 20 | Line comments + thread + `suggestion` block; a request-changes → fix → resolve cycle |
| CODEOWNERS + branch protection | 25 | Valid CODEOWNERS; main protected (PR + ≥1 approval + code-owner review); owner auto-requested |
| Merge-conflict resolution | 20 | Conflict deliberately created and resolved; branch merged cleanly afterward |
| Merge strategies + decision doc | 15 | All three enabled, each used once; `docs/merge-strategy.md` justifies a default |
| **Assurance coverage** | **100** | |

## Implementation verification evidence
```bash
ORG=<org>; REPO=ghec-ch02-pull-requests-code-review   # swap REPO for the customer implementation owner's own repo if they brought one

# Branch protection on main (expect required_pull_request_reviews + require_code_owner_reviews=true)
gh api repos/$ORG/$REPO/branches/main/protection --jq '{required_reviews: .required_pull_request_reviews}'

# CODEOWNERS present and valid
gh api repos/$ORG/$REPO/contents/.github/CODEOWNERS --jq '.path'
gh api repos/$ORG/$REPO/codeowners/errors --jq '.errors'   # expect [] (no errors)

# PR count and at least one merged via each strategy (inspect merge_commit_sha + commit shape)
gh pr list --repo $ORG/$REPO --state all --json number,title,isDraft,mergedAt,reviewDecision

# Allowed merge methods enabled
gh api repos/$ORG/$REPO --jq '{merge: .allow_merge_commit, squash: .allow_squash_merge, rebase: .allow_rebase_merge}'

# Decision doc exists
gh api repos/$ORG/$REPO/contents/docs/merge-strategy.md --jq '.path'
```
- **CODEOWNERS errors endpoint** is the fast truth source: `[]` means the file parses and all owners are valid.
- For merge strategies, check `git log --oneline --graph` in a fresh clone: a squash merge yields one commit, a merge commit yields a two-parent node, rebase yields linear replays.

## Common pitfalls
- **Protecting `main` *after* opening PRs** is fine, but the owner auto-request only applies to PRs opened/updated *after* CODEOWNERS + the rule exist. Push a new commit to re-trigger.
- **Team has no repo access.** `CODEOWNERS` owners must be able to read the repo or the request silently drops. Grant the team access.
- **"Require linear history" + merge commits** are mutually exclusive — customer implementation owners who enable both get a confusing block. Mentioned as a stretch on purpose.
- **Token scope** `read:org` is needed for team lookups; `repo` covers protection + PRs.

## References for delivery leads

- [About pull requests](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/about-pull-requests), [About code owners](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners).

## Teardown
```bash
bash modules/ghec/resources/provisioning/scripts/setup.sh teardown ch02 --org <org> --yes   # Bash
modules/ghec/resources/provisioning/scripts/setup.ps1 teardown ch02 --org <org> --yes  # PowerShell
```
- Removes only `ghec-ch02-*` artifacts (prefix-guarded): the repo and any `ghec-ch02-*` seed branches.
- **Manual cleanup (if any):** the seeded `backend-team` (if the customer implementation owner created a real org team) is left in place if not prefixed; advise customer implementation owners to name it `ghec-ch02-backend` or delete it manually.

## Time budget
- Setup + read PRs: ~30 min
- Parts A–B (branch, PR, review): ~1 hr
- Part C (CODEOWNERS + protection): ~45 min
- Part D (conflict): ~30 min
- Part E (merge strategies + doc): ~30 min
- **Indicative implementation effort:** ~3–4 hrs across sessions.
