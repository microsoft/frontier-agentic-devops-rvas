# Ch16 — REST & GraphQL API Automation — Delivery Assurance Guide

> Audience: delivery assurance leads and authorized customer implementation owners. Pair with the corresponding customer implementation `README.md`.
> **Customer authorization and rollout boundary:** Apply changes in a customer-owned tenant or repository only after the named customer owner authorizes the scope. A fallback is a sample test repository or environment, not the destination: record its evidence, risks and controls, accountable owner, handover, and the explicit tenant adoption, cutover, or rollout decision.


## Customer adoption decision

**Required delivery assurance check:** before implementation is accepted, confirm the authorized tenant scope, implementation evidence, risk controls, accountable owner, handover, and next adoption action.

**Decision prompt:** what manual GitHub task does someone on your team do by clicking through the UI every week that a twenty-line API script could eliminate, and what is the organizational cost (time, error rate, toil) of not automating it? Record the accountable owner, implementation evidence, risk or blocker, and next customer adoption action.

> **Customer implementation preference:** prioritize an authorized customer tenant or artifact over the `ghec-ch16-rest-graphql-automation` sample. If a sample is necessary, record the target tenant scope, accountable owner, authorization blocker, evidence to carry forward, and the adoption, cutover, or rollout decision. The sample is a safe fallback, not the destination.

Use these prompts to verify customer ownership and the next action:
- Describe the specific manual click-through task — who does it, how often, and how long does it take?
- What API endpoint (REST or GraphQL) would replace the most time-consuming step?
- What is the smallest working script you could write and share with your team before next week?

## Delivery assurance notes
- **Customer adoption outcome:** the customer implementation owner drives GitHub entirely from its APIs — REST and GraphQL reads/writes — and ships an **idempotent, rate-limit-aware** reconcile script.
- **Implementation risks to verify:**
  - **Pagination stops at page 1.** The classic bug: they read 30/100 issues and think they're done. Make them compare their count to the seeded total — if it's short, they're not paginating.
  - **GraphQL node IDs vs REST numbers.** Projects v2 mutations need **node IDs** (`gh api graphql … id`), not issue numbers. This trips everyone the first time.
  - **`-f` vs `-F`.** `-f` sends strings; `-F` sends typed/JSON values (and reads `@file`). GraphQL variables usually want `-F`.
  - **Idempotency.** Their first script double-posts comments / re-adds labels. Push them to "check-then-write."
- **Delivery lead prompts:** ask "how do you *know* you've read every issue?" (→ count vs total, `pageInfo.hasNextPage`), and "what would happen if you ran this twice in a row?" (→ idempotency).
- **Org-scoped note:** runs with just an org + org-owner token. `project` scope is needed for Projects v2 GraphQL mutations; `read:org` to resolve the org and board.

## Implementation acceptance evidence
| Criterion | Assurance weight | Customer-owned evidence |
|---|---:|---|
| REST reads | 15 | Identity confirmed; issues listed and shaped with `--jq` |
| REST writes | 20 | Label created; unlabeled issues triaged; comment posted via API |
| Pagination | 15 | All seeded issues paged (REST `--paginate`); count matches total; `Link` header understood |
| GraphQL queries | 20 | Parameterized query with variables; cursor-paginated to completion |
| GraphQL mutations + Projects v2 | 20 | Issues added to `ghec-ch16-board`; `Status` field set via `updateProjectV2ItemFieldValue` |
| Rate limits + idempotency | 10 | `rate_limit` inspected; script backs off; second run = no changes |
| **Assurance coverage** | **100** | |

## Implementation verification evidence
```bash
ORG=<org>; REPO=ghec-ch16-rest-graphql-automation   # swap REPO for the customer implementation owner's own repo if they brought one

# Repo exists and issue volume is there
gh api repos/$ORG/$REPO --jq '{name, open_issues_count}'

# Every issue has at least one label (expect empty output = none unlabeled)
gh api --paginate "repos/$ORG/$REPO/issues?state=all&per_page=100" \
  --jq '.[] | select((.labels | length) == 0) | .number'

# The custom label was created via API
gh api repos/$ORG/$REPO/labels --jq '.[].name' | grep -x 'needs-info'

# GraphQL reachable + board exists with items
gh api graphql -f query='{ viewer { login } }' --jq '.data.viewer.login'
gh api graphql -F org=$ORG -f query='
  query($org:String!){ organization(login:$org){ projectsV2(first:10){ nodes { number title } } } }' \
  --jq '.data.organization.projectsV2.nodes[] | select(.title｜test("ghec-ch16"))'

# Rate-limit budget (the script should read this)
gh api rate_limit --jq '.resources.core, .resources.graphql'
```
- The fastest mastery signal is the **"unlabeled issues" query returning empty** plus **board items present** — proves both REST writes and GraphQL mutations ran across the full set.
- Ask the customer implementation owner to run their reconcile script twice and show the second run printing **"0 changes"** — that's the idempotency proof.

## Common pitfalls
- **Single-page reads** mistaken for complete — always reconcile count vs seeded total.
- **Issue number passed where a node ID is required** — Projects v2 mutations fail silently or 422.
- **`-f` used for GraphQL variables** that need types — use `-F` (e.g., `-F first=50`).
- **No back-off** — hammering the API trips the **secondary** rate limit (a `403` with `Retry-After`), which `rate_limit` core counters won't show. Honor `Retry-After`.
- **Token scope** — missing `project` blocks Projects v2 mutations even when REST issue calls work.

## References for delivery leads

- [About the REST API](https://docs.github.com/en/rest/about-the-rest-api/about-the-rest-api), [Using pagination in the REST API](https://docs.github.com/en/rest/using-the-rest-api/using-pagination-in-the-rest-api).

## Teardown
```bash
bash modules/ghec/resources/provisioning/scripts/setup.sh teardown ch16 --org <org> --yes   # Bash
modules/ghec/resources/provisioning/scripts/setup.ps1 teardown ch16 --org <org> --yes  # PowerShell
```
- Removes only `ghec-ch16-*` artifacts (prefix-guarded): the repo (with its issues/labels/comments) **and** the `ghec-ch16-board` org project.
- **Manual cleanup (if any):** none beyond the prefixed repo and board.

## Time budget
- Setup + read: ~30 min
- Parts A–B (REST reads + writes): ~45 min
- Part C (pagination): ~30 min
- Parts D–E (GraphQL queries + Projects v2 mutations): ~1.5 hrs
- Part F (rate limits + reconcile script): ~45 min
- **Indicative implementation effort:** ~3–4 hrs across sessions.
