# Ch05 — Advanced PR Automation & Rulesets — Coach Guide

> Audience: facilitators and graders. Pair with the student `README.md`.

## Grounding conversation (you will be called)

Students are **expected to call you** to talk through this challenge's real-world impact before they consider it done. This is a required completion step, not optional — it is how we keep the learning grounded in their actual day-to-day work.

**Their question:** Coach conversation — which repetitive PR task on your current team (auto-labeling, reviewer assignment, size checks, changelog enforcement) costs the most human time per week, and what could a composite action or reusable workflow replace? Talk it through with your coach and connect it to a real project, task, or workflow you own.

Use these follow-ups to steer the conversation:
- List the manual steps that happen every time a PR is opened in your main repo — who does each one?
- Which of those steps is most error-prone or most often skipped under time pressure?
- What single Actions workflow file could you open a PR for in the next two days?

## Facilitation notes
- **Goal in one line:** the student replaces manual merge babysitting with policy + automation — layered rulesets, auto-merge, and Actions-driven PR housekeeping that runs itself safely.
- **Where students get stuck:**
  - **Rulesets vs classic branch protection.** They coexist and the **most restrictive wins**. Students sometimes set both and get confused about which rule blocked them. Reference [about rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets) to teach them to read the "rules" tooltip on the blocked PR.
  - **Auto-merge prerequisites.** Auto-merge only arms when the repo setting is on *and* the PR has required checks/reviews pending (not already mergeable, not draft). Reference [automatically merging](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/incorporating-changes-from-a-pull-request/automatically-merging-a-pull-request) to clarify the "it just merged" surprise.
  - **`labeler` trigger.** `pull_request_target` runs in the base-repo context (needed for fork PRs to get labels) — explain the security nuance (don't check out untrusted code in that context). See [actions/labeler](https://github.com/actions/labeler).
  - **Org ruleset scope.** The repo-name pattern `wth-ch05-*` must match; a typo means the org rule silently covers nothing. See [managing rulesets for organizations](https://docs.github.com/en/organizations/managing-organization-settings/creating-rulesets-for-repositories-in-your-organization).
- **How to unblock without giving the answer:** ask "if two policies disagree, which one applies?" (→ strictest), and "what conditions must be *pending* for auto-merge to wait rather than merge now?"
- **Org-scoped note:** runs with an org + org-owner token. The **org ruleset** (Part F) needs `admin:org`, which the org-owner token has. No enterprise owner required.

## Grading rubric (point-weighted, 100 pts)
| Criterion | Points | What "full marks" looks like |
|---|---:|---|
| Repository ruleset | 20 | Active; PR + approval + code-owner + `build` check + linear history; direct push rejected (shown) |
| CODEOWNERS + reviewers + bypass | 15 | Valid CODEOWNERS; owner auto-requested; documented bypass actor; non-bypass user fully gated |
| Auto-merge | 20 | Clean PR merged itself after gates; failing PR held back; demonstrated both |
| Draft PR + template | 15 | Template pre-fills; draft blocks auto-merge/reviewers until ready |
| Actions PR housekeeping | 20 | Path auto-labeling works; open-PR comment fires; stale workflow labels/closes correctly |
| Organization ruleset | 10 | Org ruleset targets `wth-ch05-*`, active, layers with repo ruleset |
| **Total** | **100** | |

## Automated verification hints
```bash
ORG=<org>; REPO=wth-ch05-advanced-pr-automation

# Repository rulesets (expect an Active ruleset with the rules below)
gh api repos/$ORG/$REPO/rulesets --jq '.[] | {name, enforcement}'
RID=$(gh api repos/$ORG/$REPO/rulesets --jq '.[0].id')
gh api repos/$ORG/$REPO/rulesets/$RID --jq '.rules[].type'   # pull_request, required_status_checks, non_fast_forward, required_linear_history...

# CODEOWNERS valid
gh api repos/$ORG/$REPO/codeowners/errors --jq '.errors'     # expect []

# Auto-merge allowed on the repo
gh api repos/$ORG/$REPO --jq '.allow_auto_merge'             # expect true

# PRs and their auto-merge / state
gh pr list --repo $ORG/$REPO --state all --json number,isDraft,autoMergeRequest,mergedAt,labels

# Workflows present (labeler / stale / comment)
gh api repos/$ORG/$REPO/contents/.github/workflows --jq '.[].name'
gh api repos/$ORG/$REPO/contents/.github/labeler.yml --jq '.path'

# Organization ruleset targeting wth-ch05-*
gh api /orgs/$ORG/rulesets --jq '.[] | {name, enforcement, target}'
```
- The **ruleset `rules[].type`** list is the fastest mastery signal — it should include `pull_request`, `required_status_checks`, `non_fast_forward`, and `required_linear_history`.
- For auto-merge, `autoMergeRequest` on a PR being non-null proves it was armed; a later non-null `mergedAt` proves it self-merged.
- For stale automation, have the student run the workflow via `workflow_dispatch` and show the labeled/closed PRs.

## Common pitfalls
- **Both classic protection and a ruleset active** → confusing double-gates. Prefer rulesets here; if classic protection exists from setup, note which rule wins. See [about rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets).
- **Auto-merge "merged instantly"** because no required check was configured yet — set the ruleset's required check *before* arming auto-merge to see the wait behavior. Clarify with [auto-merge docs](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/incorporating-changes-from-a-pull-request/automatically-merging-a-pull-request).
- **`labeler` permissions** — the workflow needs `pull-requests: write`; missing perms silently skip labeling. Confirm in [actions/labeler](https://github.com/actions/labeler) docs.
- **Org ruleset pattern typo** — `wth-ch5-*` vs `wth-ch05-*` matches nothing. Verify pattern matching in [org rulesets](https://docs.github.com/en/organizations/managing-organization-settings/creating-rulesets-for-repositories-in-your-organization).
- **Stale workflow on a schedule** won't have fired during a short session — use `workflow_dispatch` to demonstrate. See [actions/stale](https://github.com/actions/stale).
- **Token scope** — `admin:org` required for the org ruleset; `workflow` to push workflow files.

## Teardown
```bash
wth teardown ch05 --org <org> --yes
./scripts/teardown.sh ch05 --org <org> --yes   # Bash
./scripts/teardown.ps1 ch05 --org <org> --yes  # PowerShell
```
- Removes only `wth-ch05-*` artifacts (prefix-guarded): the repo (with its repo ruleset, workflows, PRs) **and** the `wth-ch05-org` organization ruleset.
- **Manual cleanup (if any):** any org **team** the student created for CODEOWNERS that isn't `wth-ch05-*` prefixed must be removed by hand; advise naming teams `wth-ch05-*`.

## Time budget
- Setup + read PR states: ~30 min
- Part A (repo ruleset): ~1 hr
- Part B (CODEOWNERS + bypass): ~45 min
- Part C (auto-merge): ~45 min
- Part D (draft + template): ~30 min
- Part E (Actions housekeeping): ~1.5 hrs
- Part F (org ruleset): ~30 min
- **Total facilitated:** ~5–6 hrs across sessions.
