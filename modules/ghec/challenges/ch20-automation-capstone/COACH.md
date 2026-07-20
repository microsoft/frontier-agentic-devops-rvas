# Ch20 — Automation Capstone — Delivery Assurance Guide

> Audience: delivery assurance leads and authorized customer implementation owners. Pair with the corresponding customer implementation `README.md`.
> Customer authorization and rollout boundary: Apply changes in a customer-owned tenant or repository only after the named customer owner authorizes the scope. A fallback is a sample test repository or environment, not the destination: record its evidence, risks and controls, accountable owner, handover, and the explicit tenant adoption, cutover, or rollout decision.
> This is the track capstone — accept it only as an integrated customer implementation, not as five separate components.

## Customer adoption decision

Required delivery assurance check: before implementation is accepted, confirm the authorized tenant scope, implementation evidence, risk controls, accountable owner, handover, and next adoption action.

Decision prompt: looking across everything you've automated in this activity, what is the single workflow in your real org that is still entirely manual and would benefit most from combining the Actions, API, and security layers you just built? Record the accountable owner, implementation evidence, risk or blocker, and next customer adoption action.

> Customer implementation preference: prioritize an authorized customer tenant or artifact over the `ghec-ch20-automation-capstone` sample. If a sample is necessary, record the target tenant scope, accountable owner, authorization blocker, evidence to carry forward, and the adoption, cutover, or rollout decision. The sample is a safe fallback, not the destination.

Use these prompts to verify customer ownership and the next action:
- Describe that manual workflow end-to-end — what triggers it, who does each step, and where does it break down?
- Which of the three layers (Actions orchestration, REST/GraphQL API, security gate) would give the biggest leverage if applied to it?
- What is the concrete design you'd pitch to your team this week to start automating it?

## Delivery assurance notes
- Customer adoption outcome: the customer implementation owner delivers one end-to-end automation where a GitHub App (installation auth) reacts to a signature-verified webhook, acts via REST and GraphQL, and is orchestrated by Actions — idempotently.
- Independence matters. This implementation must stand alone. It creates all its own `ghec-ch20-*` state and assumes no other activity was run. If a customer implementation owner reuses a ch17 App, acceptance evidence must still cover the ch20 seeded artifacts — provision ch20 fresh.
- Implementation risks to verify:
  - Installation token vs PAT vs JWT. They need a JWT (App auth) to mint an installation token, then use *that* for REST/GraphQL. Mixing these up is the #1 blocker.
  - Signature verification over the wrong body. HMAC must run over the raw request body, not a re-serialized JSON object. Constant-time compare.
  - GraphQL node IDs. Projects v2 mutations need the board node id and issue node id — customer implementation owners pass numbers and get null.
  - Idempotency skipped. A happy path can work while redelivery double-labels / double-adds. Require replay evidence — it is a core acceptance requirement.
  - Secrets in the repo. Private key or webhook secret committed. Must live in Actions secrets.
- Delivery lead prompts: ask "which credential is authenticating *this* call, and where did it come from?" (→ JWT → installation token), and "what happens if GitHub redelivers this exact event?" (→ idempotency design).
- Org-scoped note: org + org-owner token; needs App-creation rights + `admin:org_hook`. No enterprise owner required. EMU-compatible — all resources are org-owned.

## Implementation acceptance evidence
| Criterion | Assurance weight | Customer-owned evidence |
|---|---:|---|
| App registered + installed + installation token | 15 | App on the seeded repo; `/installation/repositories` returns it |
| Webhook signature verification | 15 | HMAC-SHA256 over raw body vs `X-Hub-Signature-256`; bad sig rejected (shown) |
| REST action + idempotency | 20 | Label + comment on `issues.opened`; redelivery does not duplicate |
| GraphQL Projects v2 action + idempotency | 20 | Issue added to `ghec-ch20-board` + Status set; replay doesn't double-add |
| Actions orchestration + secret handling | 15 | `automation.yml` runs the flow; all creds in Actions secrets; run summary posted |
| End-to-end demo + failure-mode write-up | 15 | One fresh issue drives all hops; failure modes documented |
| Assurance coverage | 100 | |

> Integration bonus framing: if every part works in isolation but the full loop never runs from a single event, cap the last two rows — the capstone is the *integration*, not the parts.

## Implementation verification evidence
```bash
ORG=<org>; REPO=ghec-ch20-automation-capstone   # swap REPO for the customer implementation owner's own repo if they brought one

# App is installed on the seeded repo (run as the App's installation token)
gh api /installation/repositories --jq '.repositories[].full_name'

# REST action landed: triage label + an App-authored comment on the test issue
gh issue list --repo $ORG/$REPO --json number,labels --jq '.[] | {number, labels: [.labels[].name]}'
ISSUE=<n>
gh api repos/$ORG/$REPO/issues/$ISSUE/comments --jq '.[] | {user: .user.login, body: .body[0:60]}'

# GraphQL action landed: issue is an item on ghec-ch20-board with a Status set
gh api graphql -f query='
  query($org:String!){ organization(login:$org){ projectV2(number: PROJECT_NUMBER){
    title items(first:20){ nodes{ content{ ... on Issue { number } }
      fieldValues(first:8){ nodes{ ... on ProjectV2ItemFieldSingleSelectValue { name } } } } } } } }' \
  -f org=$ORG

# Actions orchestration ran and secrets are referenced (not hardcoded)
gh run list --repo $ORG/$REPO --workflow automation.yml --json conclusion,headBranch --limit 5
gh api repos/$ORG/$REPO/actions/secrets --jq '.secrets[].name'   # expect App ID / private key / webhook secret names
```
- The strongest mastery signal is a single fresh issue that produces, in order: a verified delivery → REST label+comment → GraphQL board item with Status → an Actions run summary. Ask for evidence of each hop (delivery UUID, comment, board screenshot/query, run URL).
- For idempotency, have the customer implementation owner Redeliver the webhook and re-show the issue + board: counts must be unchanged.
- Grep the workflow for hardcoded keys — secrets must come from `${{ secrets.* }}`.

## Common pitfalls
- JWT/installation-token confusion — App auth (JWT) mints the installation token; REST/GraphQL use the installation token.
- Signature over parsed body — verify over the raw bytes; constant-time compare; reject on mismatch.
- Numeric IDs in GraphQL — Projects v2 needs node IDs, not issue/project numbers.
- No idempotency — redelivery duplicates labels/comments/board items. Core requirement, not optional.
- Secrets committed — private key / webhook secret in the repo instead of Actions secrets.
- Treating it as five mini-implementations — the capstone is the end-to-end loop; partial parts that never connect don't earn the integration rows.
- Token scope — `repo` + `admin:org_hook` + App-creation rights.

## References for delivery leads

- [REST API quickstart](https://docs.github.com/en/rest/quickstart), [GraphQL API — forming calls](https://docs.github.com/en/graphql/guides/forming-calls-with-graphql).

## Teardown
```bash
bash modules/ghec/resources/provisioning/scripts/setup.sh teardown ch20 --org <org> --yes   # Bash
modules/ghec/resources/provisioning/scripts/setup.ps1 teardown ch20 --org <org> --yes  # PowerShell
```
- Removes only `ghec-ch20-*` artifacts (prefix-guarded): the seeded repo and the `ghec-ch20-board` Projects v2 board.
- Manual cleanup (required): the GitHub App is not a `ghec-ch20-*` repo artifact and is not auto-deleted — uninstall it from the org and delete the App registration (Org Settings → Developer settings → GitHub Apps). Revoke/delete the App private key. If you used a `smee.io` channel, it expires on its own.

## Time budget
- Setup + read scaffold: ~45 min
- Part A (register + install App): ~1 hr
- Part B (webhook + signature verification): ~1.5 hrs
- Part C (REST + idempotency): ~1 hr
- Part D (GraphQL Projects v2 + idempotency): ~1.5 hrs
- Part E (Actions orchestration + secrets): ~1 hr
- Part F (end-to-end demo + failure-mode write-up): ~1.25 hrs
- Indicative implementation effort: ~8 hrs across multiple sessions.
