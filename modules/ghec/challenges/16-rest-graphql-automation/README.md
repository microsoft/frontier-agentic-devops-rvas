# Ch16 — REST & GraphQL API Automation

> Deliver safe, idempotent GitHub automation using REST and GraphQL APIs, complete pagination, and rate-limit-aware operation.

## Prerequisites
- An organization you own (or org-owner rights) on GitHub Enterprise Cloud.
- A token with the scopes listed by `modules/ghec/resources/provisioning/scripts/setup.sh doctor ch16 --org <org>` (least-privilege; for this activity: `repo` + `read:org` + `project` + `read:project`).
- Local tooling: `gh >= 2.x`, `git`, `jq`.
- Comfort reading JSON. The whole activity is API-first — you'll live in `gh api`, not the web UI.

If setup fails at the project step with missing scopes, add them in place and re-run:
```bash
gh auth refresh -h github.com -s project,read:project
```

## What you will deliver
- Call the REST API for reads and writes with `gh api` (verbs, paths, `--method`, `-f`/`-F` fields).
- Write GraphQL queries and mutations against the single `graphql` endpoint, using variables and fragments.
- Choose REST vs GraphQL deliberately — over-fetching, round-trips, and shape of the data.
- Paginate correctly: REST `Link` headers / `--paginate`, and GraphQL cursor-based `pageInfo`.
- Read and respect rate limits (primary + secondary), and back off cleanly.
- Wrap it all into a small idempotent automation script that reconciles state instead of duplicating it.

## Scenario
A GHEC customer's platform team keeps doing the same triage by hand: relabeling issues, posting status comments, rolling items onto a project board, and exporting reports for leadership. Clicking doesn't scale. You'll rebuild that work as API automation — REST where it's simplest, GraphQL where it saves round-trips — that pages through everything, stays under rate limits, and can be re-run safely any day of the week.

> [!IMPORTANT]
> Default to an authorised customer repository or automation task where an API script will remove recurring toil.
>
> Have a candidate? Use it everywhere this guide says `ghec-ch16-rest-graphql-automation`, and skip Setup below. Otherwise use the seeded sample below for validation only, then hand the validated script and its owner off for production execution.

## Sample test repository or environment
Skip if you brought your own automation target.

```bash
# Bash
bash modules/ghec/resources/provisioning/scripts/setup.sh provision ch16 --org <org>
```
```powershell
# PowerShell
modules/ghec/resources/provisioning/scripts/setup.ps1 provision ch16 --org <org>
```

Setup creates these resources (all names use the `ghec-ch16-*` prefix, and teardown is prefix-guarded):
- A seeded repo `ghec-ch16-rest-graphql-automation` with a README and a `src/`/`docs/` layout.
- ~60 seeded issues in mixed states (open/closed, some labeled, many unlabeled) — enough volume to force real pagination.
- A starter label set (`bug`, `enhancement`, `triage`, `area: backend`, `area: docs`) plus deliberate label gaps you'll fill via API.
- An empty org Projects v2 board `ghec-ch16-board` you'll populate from GraphQL.
- A printed Next steps block telling you where to start.

## Tasks

### Part A — REST reads
1. Authenticate and confirm identity. Run `gh api user --jq '.login'` and `gh api orgs/<org> --jq '.login'` to prove the token reaches the org.
2. List the seeded repo and its issues. `gh api repos/<org>/ghec-ch16-rest-graphql-automation --jq '{name,open_issues_count}'`, then `gh api 'repos/<org>/ghec-ch16-rest-graphql-automation/issues?state=open&per_page=100'`.
3. Shape the output. Use `--jq` to print `number`, `title`, and label names for each issue so you can eyeball what needs triage.

### Part B — REST writes (mutations)
4. Create a missing label. `gh api repos/<org>/ghec-ch16-rest-graphql-automation/labels -f name='needs-info' -f color='d4c5f9' -f description='Awaiting reporter'`.
5. Label unlabeled issues. For each issue with zero labels, add `triage`: `gh api repos/<org>/ghec-ch16-rest-graphql-automation/issues/<n>/labels -f labels[]='triage'`.
6. Comment via API. Post a templated status comment on one issue with `--method POST … -f body='…'`. Re-run your loop and confirm it does not double-post (idempotency check).

### Part C — Pagination done right
7. Page through every issue with REST. Use `gh api --paginate 'repos/<org>/ghec-ch16-rest-graphql-automation/issues?state=all&per_page=100'` and count results; confirm the count matches the seeded total (don't stop at page 1).
8. Do it the manual way once. Inspect the `Link` response header (`gh api -i …`) and follow `rel="next"` yourself so you understand what `--paginate` automates.

### Part D — GraphQL queries
9. Run your first query. `gh api graphql -f query='{ viewer { login } }'`.
10. Query issues with variables. Write a query that takes `$owner`, `$repo`, and `$first`, returns `issues(first:$first, states:OPEN)` with `nodes { number title labels(first:5){nodes{name}} }` and `pageInfo { hasNextPage endCursor }`. Pass variables with `-F owner=<org> -F repo=ghec-ch16-rest-graphql-automation -F first=50`.
11. Cursor-paginate in GraphQL. Loop using `after:$cursor` until `hasNextPage` is false. Compare the round-trip count to the REST version from Part C.

### Part E — GraphQL mutations + Projects v2
12. Find the project node ID. Query `organization(login:$org){ projectV2(number:<n>){ id title } }` for `ghec-ch16-board`.
13. Add items to the board. For a handful of issues, run the `addProjectV2ItemById` mutation with the project ID and each issue's node ID. Confirm they appear on the board.
14. Set a field. Read the board's single-select `Status` field options via GraphQL, then use `updateProjectV2ItemFieldValue` to set added items to `Todo`.

### Part F — Rate limits & a reconcile script
15. Inspect your budget. `gh api rate_limit --jq '.resources.core, .resources.graphql'`. Note `remaining` and `reset`.
16. Build a small reconcile script (Bash or PowerShell) that: pages all issues, ensures every issue has at least one label, adds untracked issues to the board, and checks `rate_limit` between batches, sleeping until `reset` if `remaining` is low. Re-run it twice and confirm the second run makes no changes (pure reconcile).

## Reference links
- About the REST API — https://docs.github.com/en/rest/about-the-rest-api/about-the-rest-api
- Using pagination in the REST API — https://docs.github.com/en/rest/using-the-rest-api/using-pagination-in-the-rest-api
- Rate limits for the REST API — https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api
- About the GraphQL API — https://docs.github.com/en/graphql/overview/about-the-graphql-api
- Forming calls with GraphQL — https://docs.github.com/en/graphql/guides/forming-calls-with-graphql
- Using the API to manage Projects — https://docs.github.com/en/issues/planning-and-tracking-with-projects/automating-your-project/using-the-api-to-manage-projects
- `gh api` CLI manual — https://cli.github.com/manual/gh_api
