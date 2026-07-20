# Ch04 — GitHub Actions CI Fundamentals — Delivery Assurance Guide

> Audience: delivery assurance leads and authorized customer implementation owners. Pair with the corresponding customer implementation `README.md`.
> Customer authorization and rollout boundary: Apply changes in a customer-owned tenant or repository only after the named customer owner authorizes the scope. A fallback is a sample test repository or environment, not the destination: record its evidence, risks and controls, accountable owner, handover, and the explicit tenant adoption, cutover, or rollout decision.


## Customer adoption decision

Required delivery assurance check: before implementation is accepted, confirm the authorized tenant scope, implementation evidence, risk controls, accountable owner, handover, and next adoption action.

Decision prompt: pick one test suite or build process from your actual work that runs manually or inconsistently: what would an always-on, branch-triggered Actions workflow catch in the next two weeks that human discipline alone has missed? Record the accountable owner, implementation evidence, risk or blocker, and next customer adoption action.

> Customer implementation preference: prioritize an authorized customer tenant or artifact over the `ghec-ch04-actions-ci-fundamentals` sample. If a sample is necessary, record the target tenant scope, accountable owner, authorization blocker, evidence to carry forward, and the adoption, cutover, or rollout decision. The sample is a safe fallback, not the destination.

Use these prompts to verify customer ownership and the next action:
- Name the specific repo and the test or build step you're thinking of — what triggers it today?
- What has slipped through in the past six months that a CI gate would have caught?
- What's the smallest workflow YAML you could commit to that repo today to start getting signal?

## Delivery assurance notes
- Customer adoption outcome: the customer implementation owner builds a real CI pipeline that runs across a matrix, caches deps, publishes artifacts, and — the key outcome — blocks merges when CI is red.
- Implementation risks to verify:
  - Required-check name mismatch. The required status check must match the job name (or matrix-expanded check name) exactly. If they require `ci` but the job is `build-test`, the gate never satisfies. Show them the check names on a real PR.
  - Cache key correctness. A cache that never invalidates (or never hits) usually means the key isn't keyed on the lockfile hash. `setup-node` cache is the easy path.
  - Conditionals on `github.ref`. Customer implementation owners test `if: main` and get string-comparison surprises — it's `refs/heads/main`.
  - Environment protection blocks the job waiting for a reviewer — that's expected; they approve the deployment to continue.
- Delivery lead prompts: ask "what *exact* string does the merge gate look for?" (→ check name), and "what makes the second run faster than the first?" (→ cache hit).
- Org-scoped note: runs with just an org + org-owner token. Public repo = free Actions minutes; recommend public to avoid metering. `workflow` scope is needed to push workflow files via API/CLI.

## Implementation acceptance evidence
| Criterion | Assurance weight | Customer-owned evidence |
|---|---:|---|
| Core workflow (triggers + lint/test/build steps) | 20 | Push + PR triggers; three distinct script steps; run is green |
| Matrix | 15 | ≥3 Node versions, `fail-fast: false`, all legs visible |
| Caching | 15 | Cache configured; second run shows a hit and is faster |
| Artifacts | 15 | Test report uploaded and downloadable via UI + CLI |
| Job graph + conditional | 15 | `needs` + `if` so the second job only runs on main |
| Environment + secrets | 10 | `staging` env with protection rule; variable echoed, secret referenced (not printed) |
| Required check gating | 10 | `build-test` required on main; red blocks, green unblocks (demonstrated) |
| Assurance coverage | 100 | |

## Implementation verification evidence
```bash
ORG=<org>; REPO=ghec-ch04-actions-ci-fundamentals   # swap REPO for the customer implementation owner's own repo if they brought one

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
- The required-check truth source is `.../required_status_checks/.contexts` — it must list `build-test` (or the matrix-expanded names).
- To verify gating end-to-end, have the customer implementation owner show a PR with a red CI run and a disabled merge button, then a follow-up green run that re-enables it.

## Common pitfalls
- Check name ≠ required context → the gate is permanently unsatisfied or trivially satisfied. Match exactly.
- Caching the wrong directory — npm cache vs `node_modules`. Prefer `setup-node` `cache: 'npm'`.
- Secrets printed to logs — dock points; secrets must never be `echo`'d. Variables are fine to print.
- `workflow` scope missing — pushing `.github/workflows/*` via API 403s without it.
- Private repo metering — long matrices burn minutes; keep to 3 legs.

## References for delivery leads

- [Understanding GitHub Actions](https://docs.github.com/en/actions/learn-github-actions/understanding-github-actions), [Workflow syntax for GitHub Actions](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions).

## Teardown
```bash
bash modules/ghec/resources/provisioning/scripts/setup.sh teardown ch04 --org <org> --yes   # Bash
modules/ghec/resources/provisioning/scripts/setup.ps1 teardown ch04 --org <org> --yes  # PowerShell
```
- Removes only `ghec-ch04-*` artifacts (prefix-guarded): the repo (which carries its workflows, environments, and artifacts).
- Manual cleanup (if any): none beyond the repo; deleting the repo removes its runs, artifacts, and the `staging` environment.

## Time budget
- Setup + read: ~30 min
- Part A (core workflow): ~1 hr
- Parts B–D (matrix, cache, artifacts): ~1.5 hrs
- Part E (job graph): ~30 min
- Part F (environment + required check gating): ~1 hr
- Indicative implementation effort: ~4–5 hrs across sessions.
