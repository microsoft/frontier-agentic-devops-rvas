# Ch20 — Automation Capstone — Coach Guide

> Audience: facilitators and graders. Pair with the student `README.md`. This is the **track capstone** — grade it as integration, not as five separate exercises.

## Facilitation notes
- **Goal in one line:** the student builds **one end-to-end automation** where a **GitHub App** (installation auth) reacts to a **signature-verified webhook**, acts via **REST and GraphQL**, and is orchestrated by **Actions** — idempotently.
- **Independence matters.** This challenge **must stand alone**. It creates all its own `wth-ch20-*` state and assumes **no other challenge was run**. If a student says "I'll reuse my ch17 App," that's fine conceptually, but grading is against the **ch20 seeded artifacts** — they should provision ch20 fresh.
- **Where students get stuck:**
  - **Installation token vs PAT vs JWT.** They need a **JWT** (App auth) to mint an **installation token**, then use *that* for REST/GraphQL. Mixing these up is the #1 blocker.
  - **Signature verification over the wrong body.** HMAC must run over the **raw** request body, not a re-serialized JSON object. Constant-time compare.
  - **GraphQL node IDs.** Projects v2 mutations need the **board node id** and **issue node id** — students pass numbers and get null.
  - **Idempotency skipped.** They get a happy path working but redelivery double-labels / double-adds. Hold them to it — it's a core objective.
  - **Secrets in the repo.** Private key or webhook secret committed. Must live in **Actions secrets**.
- **How to unblock without giving the answer:** ask "which credential is authenticating *this* call, and where did it come from?" (→ JWT → installation token), and "what happens if GitHub redelivers this exact event?" (→ idempotency design).
- **Org-scoped note:** org + org-owner token; needs App-creation rights + `admin:org_hook`. No enterprise owner required. EMU-compatible — all resources are org-owned.

## Grading rubric (point-weighted, 100 pts)
| Criterion | Points | What "full marks" looks like |
|---|---:|---|
| App registered + installed + installation token | 15 | App on the seeded repo; `/installation/repositories` returns it |
| Webhook signature verification | 15 | HMAC-SHA256 over raw body vs `X-Hub-Signature-256`; bad sig rejected (shown) |
| REST action + idempotency | 20 | Label + comment on `issues.opened`; redelivery does **not** duplicate |
| GraphQL Projects v2 action + idempotency | 20 | Issue added to `wth-ch20-board` + Status set; replay doesn't double-add |
| Actions orchestration + secret handling | 15 | `automation.yml` runs the flow; all creds in Actions secrets; run summary posted |
| End-to-end demo + failure-mode write-up | 15 | One fresh issue drives all hops; failure modes documented |
| **Total** | **100** | |

> **Integration bonus framing:** if every part works in isolation but the **full loop** never runs from a single event, cap the last two rows — the capstone is the *integration*, not the parts.

## Automated verification hints
```bash
ORG=<org>; REPO=wth-ch20-automation-capstone

# App is installed on the seeded repo (run as the App's installation token)
gh api /installation/repositories --jq '.repositories[].full_name'

# REST action landed: triage label + an App-authored comment on the test issue
gh issue list --repo $ORG/$REPO --json number,labels --jq '.[] | {number, labels: [.labels[].name]}'
ISSUE=<n>
gh api repos/$ORG/$REPO/issues/$ISSUE/comments --jq '.[] | {user: .user.login, body: .body[0:60]}'

# GraphQL action landed: issue is an item on wth-ch20-board with a Status set
gh api graphql -f query='
  query($org:String!){ organization(login:$org){ projectV2(number: PROJECT_NUMBER){
    title items(first:20){ nodes{ content{ ... on Issue { number } }
      fieldValues(first:8){ nodes{ ... on ProjectV2ItemFieldSingleSelectValue { name } } } } } } } }' \
  -f org=$ORG

# Actions orchestration ran and secrets are referenced (not hardcoded)
gh run list --repo $ORG/$REPO --workflow automation.yml --json conclusion,headBranch --limit 5
gh api repos/$ORG/$REPO/actions/secrets --jq '.secrets[].name'   # expect App ID / private key / webhook secret names
```
- The strongest mastery signal is a **single fresh issue** that produces, in order: a verified delivery → REST label+comment → GraphQL board item with Status → an Actions run summary. Ask for evidence of each hop (delivery UUID, comment, board screenshot/query, run URL).
- For idempotency, have the student **Redeliver** the webhook and re-show the issue + board: counts must be unchanged.
- Grep the workflow for hardcoded keys — secrets must come from `${{ secrets.* }}`.

## Common pitfalls
- **JWT/installation-token confusion** — App auth (JWT) mints the installation token; REST/GraphQL use the installation token.
- **Signature over parsed body** — verify over the raw bytes; constant-time compare; reject on mismatch.
- **Numeric IDs in GraphQL** — Projects v2 needs node IDs, not issue/project numbers.
- **No idempotency** — redelivery duplicates labels/comments/board items. Core requirement, not optional.
- **Secrets committed** — private key / webhook secret in the repo instead of Actions secrets.
- **Treating it as five mini-exercises** — the capstone is the **end-to-end loop**; partial parts that never connect don't earn the integration rows.
- **Token scope** — `repo` + `admin:org_hook` + App-creation rights.

## Teardown
```bash
wth teardown ch20 --org <org> --yes
./scripts/teardown.sh ch20 --org <org> --yes   # Bash
./scripts/teardown.ps1 ch20 --org <org> --yes  # PowerShell
```
- Removes only `wth-ch20-*` artifacts (prefix-guarded): the seeded repo and the `wth-ch20-board` Projects v2 board.
- **Manual cleanup (required):** the **GitHub App** is not a `wth-ch20-*` repo artifact and is **not** auto-deleted — uninstall it from the org and delete the App registration (Org Settings → Developer settings → GitHub Apps). Revoke/delete the App **private key**. If you used a `smee.io` channel, it expires on its own.

## Time budget
- Setup + read scaffold: ~45 min
- Part A (register + install App): ~1 hr
- Part B (webhook + signature verification): ~1.5 hrs
- Part C (REST + idempotency): ~1 hr
- Part D (GraphQL Projects v2 + idempotency): ~1.5 hrs
- Part E (Actions orchestration + secrets): ~1 hr
- Part F (end-to-end demo + failure-mode write-up): ~1.25 hrs
- **Total facilitated:** ~8 hrs across multiple sessions.
