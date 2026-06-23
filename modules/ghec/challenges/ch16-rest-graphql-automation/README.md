# Ch16 — REST & GraphQL API Automation

> By the end of this challenge you can drive GitHub end-to-end from its APIs — read and mutate with the REST API, run typed GraphQL queries and mutations, page through large result sets, and stay inside rate limits — using an org and an org-owner token.

| | |
|---|---|
| **Track** | Automation & AI |
| **Difficulty** | Foundational *(per-track ramp)* |
| **Duration** | ~3–4 hrs total, multi-session |
| **Minimum input** | An **org** + an **org-owner token**. *(All challenges are org-scoped — no enterprise owner required.)* |
| **App** | seed |
| **EMU compatible** | yes |

## Prerequisites
- An organization you own (or org-owner rights) on GitHub Enterprise Cloud.
- A token with the scopes listed by `wth doctor ch16 --org <org>` (least-privilege; for this challenge: `repo` + `read:org` + `project`).
- Local tooling: `gh >= 2.x`, `git`, `jq`.
- Comfort reading JSON. The whole challenge is API-first — you'll live in `gh api`, not the web UI.

## Learning objectives
By completing this challenge you will:
- Call the **REST API** for reads and writes with `gh api` (verbs, paths, `--method`, `-f`/`-F` fields).
- Write **GraphQL** queries and mutations against the single `graphql` endpoint, using variables and fragments.
- Choose **REST vs GraphQL** deliberately — over-fetching, round-trips, and shape of the data.
- **Paginate** correctly: REST `Link` headers / `--paginate`, and GraphQL cursor-based `pageInfo`.
- Read and respect **rate limits** (primary + secondary), and back off cleanly.
- Wrap it all into a small **idempotent automation script** that reconciles state instead of duplicating it.

## Scenario
A GHEC customer's platform team keeps doing the same triage by hand: relabeling issues, posting status comments, rolling items onto a project board, and exporting reports for leadership. Clicking doesn't scale. You'll rebuild that work as API automation — REST where it's simplest, GraphQL where it saves round-trips — that pages through everything, stays under rate limits, and can be re-run safely any day of the week.

## Setup
Run the provisioning entrypoint (Bash or PowerShell — both supported). `wth` is the documented command surface; it wraps the scripts in `modules/ghec/resources/provisioning/scripts/`.

```bash
# Bash
wth setup ch16 --org <org>
# or directly:
bash modules/ghec/resources/provisioning/scripts/setup.sh ch16 --org <org>
```
```powershell
# PowerShell
wth setup ch16 --org <org>
# or directly:
modules/ghec/resources/provisioning/scripts/setup.ps1 ch16 --org <org>
```

**What setup creates** (all artifacts namespaced `wth-ch16-*`, idempotent, prefix-guarded teardown):
- A seeded repo **`wth-ch16-rest-graphql-automation`** with a README and a `src/`/`docs/` layout.
- **~60 seeded issues** in mixed states (open/closed, some labeled, many unlabeled) — enough volume to force real pagination.
- A **starter label set** (`bug`, `enhancement`, `triage`, `area: backend`, `area: docs`) plus deliberate label gaps you'll fill via API.
- An empty org **Projects v2 board** `wth-ch16-board` you'll populate from GraphQL.
- A printed **Next steps** block telling you where to start.

> Re-running `setup` reconciles (create-if-absent). `wth teardown ch16 --org <org> --yes` removes only `wth-ch16-*` artifacts.

## Tasks

### Part A — REST reads
1. **Authenticate and confirm identity.** Run `gh api user --jq '.login'` and `gh api orgs/<org> --jq '.login'` to prove the token reaches the org.
2. **List the seeded repo and its issues.** `gh api repos/<org>/wth-ch16-rest-graphql-automation --jq '{name,open_issues_count}'`, then `gh api 'repos/<org>/wth-ch16-rest-graphql-automation/issues?state=open&per_page=100'`.
3. **Shape the output.** Use `--jq` to print `number`, `title`, and label names for each issue so you can eyeball what needs triage.

### Part B — REST writes (mutations)
4. **Create a missing label.** `gh api repos/<org>/wth-ch16-rest-graphql-automation/labels -f name='needs-info' -f color='d4c5f9' -f description='Awaiting reporter'`.
5. **Label unlabeled issues.** For each issue with zero labels, add `triage`: `gh api repos/<org>/wth-ch16-rest-graphql-automation/issues/<n>/labels -f labels[]='triage'`.
6. **Comment via API.** Post a templated status comment on one issue with `--method POST … -f body='…'`. Re-run your loop and confirm it does **not** double-post (idempotency check).

### Part C — Pagination done right
7. **Page through every issue with REST.** Use `gh api --paginate 'repos/<org>/wth-ch16-rest-graphql-automation/issues?state=all&per_page=100'` and count results; confirm the count matches the seeded total (don't stop at page 1).
8. **Do it the manual way once.** Inspect the `Link` response header (`gh api -i …`) and follow `rel="next"` yourself so you understand what `--paginate` automates.

### Part D — GraphQL queries
9. **Run your first query.** `gh api graphql -f query='{ viewer { login } }'`.
10. **Query issues with variables.** Write a query that takes `$owner`, `$repo`, and `$first`, returns `issues(first:$first, states:OPEN)` with `nodes { number title labels(first:5){nodes{name}} }` and `pageInfo { hasNextPage endCursor }`. Pass variables with `-F owner=<org> -F repo=wth-ch16-rest-graphql-automation -F first=50`.
11. **Cursor-paginate in GraphQL.** Loop using `after:$cursor` until `hasNextPage` is false. Compare the round-trip count to the REST version from Part C.

### Part E — GraphQL mutations + Projects v2
12. **Find the project node ID.** Query `organization(login:$org){ projectV2(number:<n>){ id title } }` for `wth-ch16-board`.
13. **Add items to the board.** For a handful of issues, run the `addProjectV2ItemById` mutation with the project ID and each issue's node ID. Confirm they appear on the board.
14. **Set a field.** Read the board's single-select `Status` field options via GraphQL, then use `updateProjectV2ItemFieldValue` to set added items to `Todo`.

### Part F — Rate limits & a reconcile script
15. **Inspect your budget.** `gh api rate_limit --jq '.resources.core, .resources.graphql'`. Note `remaining` and `reset`.
16. **Build a small reconcile script** (Bash or PowerShell) that: pages all issues, ensures every issue has at least one label, adds untracked issues to the board, and **checks `rate_limit` between batches**, sleeping until `reset` if `remaining` is low. Re-run it twice and confirm the second run makes **no changes** (pure reconcile).

## Validation / Definition of Done
You are done when ALL of the following are true:
- [ ] You performed both a **REST read** and a **REST write** (label created, issues labeled, comment posted) via `gh api`.
- [ ] You **paged through all seeded issues** with REST `--paginate` and the count matches the seeded total.
- [ ] You ran a **parameterized GraphQL query** with variables and **cursor-paginated** it to completion.
- [ ] You executed at least one **GraphQL mutation** (added issues to `wth-ch16-board` and set their `Status`).
- [ ] You inspected **`rate_limit`** and your reconcile script **backs off** when `remaining` is low.
- [ ] Your reconcile script is **idempotent** — a second run produces **no changes**.
- [ ] Coach conversation — what manual GitHub task does someone on your team do by clicking through the UI every week that a twenty-line API script could eliminate, and what is the organizational cost (time, error rate, toil) of not automating it? Talk it through with your coach and connect it to a real project, task, or workflow you own.

> Coaches verify these via the automated hints in `COACH.md`.

## Stretch goals
- Re-implement the triage in **pure GraphQL** (issue search + `addLabelsToLabelable`) and compare the request count to the REST version.
- Add **secondary-rate-limit** handling: detect a `403` with `Retry-After` and honor it.
- Emit a **leadership report** (open/closed by label) as a single GraphQL query feeding a `jq` table.

## Reference links
- About the REST API — https://docs.github.com/en/rest/about-the-rest-api/about-the-rest-api
- Using pagination in the REST API — https://docs.github.com/en/rest/using-the-rest-api/using-pagination-in-the-rest-api
- Rate limits for the REST API — https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api
- About the GraphQL API — https://docs.github.com/en/graphql/overview/about-the-graphql-api
- Forming calls with GraphQL — https://docs.github.com/en/graphql/guides/forming-calls-with-graphql
- Using the API to manage Projects — https://docs.github.com/en/issues/planning-and-tracking-with-projects/automating-your-project/using-the-api-to-manage-projects
- `gh api` CLI manual — https://cli.github.com/manual/gh_api
