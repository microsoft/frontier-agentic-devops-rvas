# Ch04 — GitHub Actions CI Fundamentals — Coach Guide

> Audience: facilitators and graders. Pair with the student `README.md`.

## Grounding conversation (you will be called)

Students are **expected to call you** to talk through this challenge's real-world impact before they consider it done. This is a required completion step, not optional — it is how we keep the learning grounded in their actual day-to-day work.

**Their question:** Coach conversation — pick one test suite or build process from your actual work that runs manually or inconsistently: what would an always-on, branch-triggered Actions workflow catch in the next two weeks that human discipline alone has missed? Talk it through with your coach and connect it to a real project, task, or workflow you own.

Use these follow-ups to steer the conversation:
- Name the specific repo and the test or build step you're thinking of — what triggers it today?
- What has slipped through in the past six months that a CI gate would have caught?
- What's the smallest workflow YAML you could commit to that repo today to start getting signal?

## Facilitation notes
- **Goal in one line:** the student builds a real CI pipeline that runs across a matrix, caches deps, publishes artifacts, and — the key outcome — **blocks merges when CI is red**.
- **Where students get stuck:**
  - **Required-check name mismatch.** The required status check must match the **job name** (or matrix-expanded check name) exactly. If they require `ci` but the job is `build-test`, the gate never satisfies. Show them the check names on a real PR.
  - **Cache key correctness.** A cache that never invalidates (or never hits) usually means the key isn't keyed on the lockfile hash. `setup-node` cache is the easy path.
  - **Conditionals on `github.ref`.** Students test `if: main` and get string-comparison surprises — it's `refs/heads/main`.
  - **Environment protection blocks the job** waiting for a reviewer — that's expected; they approve the deployment to continue.
- **How to unblock without giving the answer:** ask "what *exact* string does the merge gate look for?" (→ check name), and "what makes the second run faster than the first?" (→ cache hit).
- **Org-scoped note:** runs with just an org + org-owner token. Public repo = free Actions minutes; recommend public to avoid metering. `workflow` scope is needed to push workflow files via API/CLI.

## Grading rubric (point-weighted, 100 pts)
| Criterion | Points | What "full marks" looks like |
|---|---:|---|
| Core workflow (triggers + lint/test/build steps) | 20 | Push + PR triggers; three distinct script steps; run is green |
| Matrix | 15 | ≥3 Node versions, `fail-fast: false`, all legs visible |
| Caching | 15 | Cache configured; second run shows a hit and is faster |
| Artifacts | 15 | Test report uploaded and downloadable via UI + CLI |
| Job graph + conditional | 15 | `needs` + `if` so the second job only runs on main |
| Environment + secrets | 10 | `staging` env with protection rule; variable echoed, secret referenced (not printed) |
| Required check gating | 10 | `build-test` required on main; red blocks, green unblocks (demonstrated) |
| **Total** | **100** | |

## Automated verification hints
```bash
ORG=<org>; REPO=wth-ch04-actions-ci-fundamentals

# Workflow exists and has matrix + cache (inspect raw yaml)
gh api repos/$ORG/$REPO/contents/.github/workflows/ci.yml -H "Accept: application/vnd.github.raw" \
  | grep -E "on:|matrix|cache|needs|environment" 

# Recent runs and their conclusions
gh run list --repo $ORG/$REPO --limit 10 --json name,headBranch,event,conclusion

# Artifacts produced by the latest run
RUN=$(gh run list --repo $ORG/$REPO --limit 1 --json databaseId --jq '.[0].databaseId')
gh api repos/$ORG/$REPO/actions/runs/$RUN/artifacts --jq '.artifacts[].name'

# Required status checks on main
gh api repos/$ORG/$REPO/branches/main/protection/required_status_checks --jq '.contexts'

# Environment present with protection
gh api repos/$ORG/$REPO/environments --jq '.environments[].name'
gh api repos/$ORG/$REPO/environments/staging --jq '.protection_rules'
```
- The **required-check** truth source is `.../required_status_checks/.contexts` — it must list `build-test` (or the matrix-expanded names).
- To verify gating end-to-end, have the student show a PR with a **red CI run** and a disabled merge button, then a follow-up green run that re-enables it.

## Common pitfalls
- **Check name ≠ required context** → the gate is permanently unsatisfied or trivially satisfied. Match exactly.
- **Caching the wrong directory** — npm cache vs `node_modules`. Prefer `setup-node` `cache: 'npm'`.
- **Secrets printed to logs** — dock points; secrets must never be `echo`'d. Variables are fine to print.
- **`workflow` scope missing** — pushing `.github/workflows/*` via API 403s without it.
- **Private repo metering** — long matrices burn minutes; keep to 3 legs.

## Useful references for coaching

- [Understanding GitHub Actions](https://docs.github.com/en/actions/learn-github-actions/understanding-github-actions), [Workflow syntax for GitHub Actions](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions).

## Teardown
```bash
wth teardown ch04 --org <org> --yes
./scripts/teardown.sh ch04 --org <org> --yes   # Bash
./scripts/teardown.ps1 ch04 --org <org> --yes  # PowerShell
```
- Removes only `wth-ch04-*` artifacts (prefix-guarded): the repo (which carries its workflows, environments, and artifacts).
- **Manual cleanup (if any):** none beyond the repo; deleting the repo removes its runs, artifacts, and the `staging` environment.

## Time budget
- Setup + read: ~30 min
- Part A (core workflow): ~1 hr
- Parts B–D (matrix, cache, artifacts): ~1.5 hrs
- Part E (job graph): ~30 min
- Part F (environment + required check gating): ~1 hr
- **Total facilitated:** ~4–5 hrs across sessions.
