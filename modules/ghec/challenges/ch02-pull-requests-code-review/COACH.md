# Ch02 — Branches, Pull Requests & Code Review — Coach Guide

> Audience: facilitators and graders. Pair with the student `README.md`.

## Facilitation notes
- **Goal in one line:** the student establishes a real review culture — branch-per-change, required owner review, clean conflict resolution, and a deliberate merge-strategy choice.
- **Where students get stuck:**
  - **Self-approval.** A solo student can't approve their own PR when "required approvals ≥ 1" is set. This is *correct* behavior. Have them demonstrate the **gate** (PR blocked until someone else approves) rather than approving themselves. If a second account is available, use it.
  - **`CODEOWNERS` not triggering.** The file must live at `.github/CODEOWNERS` (or repo root / `docs/`), reference **teams/users that exist and have access**, and the rule must protect the branch with "require review from Code Owners" *on*. A non-existent team silently no-ops.
  - **Conflict fear.** Students panic at conflict markers. Reassure: edit out `<<<<<<<`, `=======`, `>>>>>>>`, keep the right content, commit.
- **How to unblock without giving the answer:** ask "who *must* look at this code before it ships?" (→ CODEOWNERS), and "what does the history look like after each merge type?" (→ `git log --graph`).
- **Org-scoped note:** runs with just an org + org-owner token. Creating the team in Task 7 needs `admin:org`/owner rights, which the org-owner token already has.

## Grading rubric (point-weighted, 100 pts)
| Criterion | Points | What "full marks" looks like |
|---|---:|---|
| PR lifecycle (branch → draft → ready → ≥3 PRs) | 20 | Three PRs, one started draft, all linked to issues with `Closes #n` |
| Review mechanics | 20 | Line comments + thread + `suggestion` block; a request-changes → fix → resolve cycle |
| CODEOWNERS + branch protection | 25 | Valid CODEOWNERS; main protected (PR + ≥1 approval + code-owner review); owner auto-requested |
| Merge-conflict resolution | 20 | Conflict deliberately created and resolved; branch merged cleanly afterward |
| Merge strategies + decision doc | 15 | All three enabled, each used once; `docs/merge-strategy.md` justifies a default |
| **Total** | **100** | |

## Automated verification hints
```bash
ORG=<org>; REPO=wth-ch02-pull-requests-code-review

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
- **"Require linear history" + merge commits** are mutually exclusive — students who enable both get a confusing block. Mentioned as a stretch on purpose.
- **Token scope** `read:org` is needed for team lookups; `repo` covers protection + PRs.

## Teardown
```bash
wth teardown ch02 --org <org> --yes
./scripts/teardown.sh ch02 --org <org> --yes   # Bash
./scripts/teardown.ps1 ch02 --org <org> --yes  # PowerShell
```
- Removes only `wth-ch02-*` artifacts (prefix-guarded): the repo and any `wth-ch02-*` seed branches.
- **Manual cleanup (if any):** the seeded `backend-team` (if the student created a real org team) is left in place if not prefixed; advise students to name it `wth-ch02-backend` or delete it manually.

## Time budget
- Setup + read PRs: ~30 min
- Parts A–B (branch, PR, review): ~1 hr
- Part C (CODEOWNERS + protection): ~45 min
- Part D (conflict): ~30 min
- Part E (merge strategies + doc): ~30 min
- **Total facilitated:** ~3–4 hrs across sessions.
