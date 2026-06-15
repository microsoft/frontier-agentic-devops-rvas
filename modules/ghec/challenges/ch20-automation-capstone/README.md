# Ch20 — Automation Capstone

> By the end of this challenge you have built one **end-to-end automation** that ties the whole track together: a **GitHub App** authenticates against the **REST and GraphQL APIs**, a **webhook** drives it in real time, and **Actions** runs the glue — all on a self-contained seeded repo using an org and an org-owner token.

| | |
|---|---|
| **Track** | Automation & AI |
| **Difficulty** | Advanced *(capstone — hardest in the track)* |
| **Duration** | ~8 hrs total, multi-session |
| **Minimum input** | An **org** + an **org-owner token**. *(All challenges are org-scoped — no enterprise owner required.)* |
| **App** | seed |
| **EMU compatible** | yes — all steps run on org-owned, prefix-namespaced resources. |

> **Independent by design.** This capstone **stands alone** — it provisions all its own `wth-ch20-*` state and requires **no other challenge to have been run**. It *revisits the skills* from ch16 (REST/GraphQL), ch17 (webhooks + GitHub App), and ch18 (Actions runners) conceptually, but you do **not** need their artifacts.

## Prerequisites
- An organization you own (or org-owner rights) on GitHub Enterprise Cloud.
- A token with the scopes listed by `wth doctor ch20 --org <org>` (least-privilege; this challenge needs `repo`, `admin:org_hook`, and the ability to create a GitHub App in the org).
- Local tooling: `gh >= 2.x`, `git`, `jq`, and **Node.js 18+** (the seeded App handler is Node; a Bash path is provided where practical).
- A way to receive webhook deliveries during development: **`smee.io`** for local relay, **or** the provided **Actions `repository_dispatch` receiver** for a no-public-endpoint path.
- Comfort with the building blocks from earlier in the track (API calls, HMAC signature verification, installation tokens, Actions workflows). This capstone assumes them rather than re-teaching from zero.

## Learning objectives
By completing this challenge you will:
- **Register and install a GitHub App** in the org and authenticate as an **installation**.
- Call both the **REST API** and the **GraphQL API** (including a **Projects v2** mutation) from the App's installation token.
- **Verify inbound webhook signatures** (HMAC-SHA256, `X-Hub-Signature-256`) and route events to handlers.
- Wire **Actions** as the orchestration layer that ties the pieces together and runs on push/dispatch.
- Compose all four into **one reliable, idempotent, end-to-end flow** triggered by a real repo event.
- Reason about **least-privilege**, **secret handling**, and **failure modes** across the whole automation.

## Scenario
Your org wants a single automation that reacts to activity and keeps a project board honest without anyone touching it manually. When an issue is opened on the seeded repo, a webhook fires → your **GitHub App** (authenticated as an installation) **labels and triages** the issue via REST, **adds it to a Projects v2 board** via GraphQL, and an **Actions** workflow records the result and posts a summary. You'll build this from the seeded scaffold, prove it runs end to end, and make it **idempotent** so replays don't create duplicates. This is the track's payoff: every primitive you practiced, working together.

## Setup
Run the provisioning entrypoint (Bash or PowerShell — both supported). `wth` wraps the scripts in `./scripts/`.

```bash
# Bash
wth setup ch20 --org <org>
# or directly:
./scripts/setup.sh ch20 --org <org>
```
```powershell
# PowerShell
wth setup ch20 --org <org>
# or directly:
./scripts/setup.ps1 ch20 --org <org>
```

**What setup creates** (all artifacts namespaced `wth-ch20-*`, idempotent, prefix-guarded teardown):
- A seeded repo **`wth-ch20-automation-capstone`** containing the **App handler scaffold** (Node, with HMAC verification + REST/GraphQL stubs), an **Actions workflow** (`automation.yml`), and a `CAPSTONE.md` build guide.
- A **GitHub App manifest** (`app-manifest.json`) you finish registering + installing — the supported auth path for this automation.
- An **empty org Projects v2 board** **`wth-ch20-board`** for the GraphQL step to populate.
- A printed **Next steps** block (App registration URL flow, where to put the webhook secret, how to drive deliveries via `smee.io` or `repository_dispatch`).

> Re-running `setup` reconciles (create-if-absent). `wth teardown ch20 --org <org> --yes` removes only `wth-ch20-*` artifacts; the GitHub App itself needs **manual** removal (see Teardown).

## Tasks

### Part A — Register & install the App
1. **Register the App** from the seeded `app-manifest.json` (manifest flow) so it lands with the right permissions and webhook config. Capture the **App ID** and generate a **private key**.
2. **Install the App** on the seeded repo (or the org, scoped to that repo).
3. **Mint an installation token** and confirm it works: `gh api /installation/repositories` (as the App) returns the seeded repo.

### Part B — Wire the inbound webhook
4. **Set the webhook secret** and point the App's webhook at your receiver: a **`smee.io`** relay for local dev **or** the **`repository_dispatch`** Actions receiver if you have no public endpoint.
5. **Verify signatures.** In the handler, compute HMAC-SHA256 over the raw body with your secret and constant-time-compare against `X-Hub-Signature-256`. **Reject** mismatches.
6. **Trigger a delivery** by opening a test issue; confirm the handler receives `issues.opened` and the signature check passes.

### Part C — Act via REST
7. **Triage via REST.** On `issues.opened`, have the App **add a triage label** and post a brief **acknowledgement comment** using its installation token.
8. **Make it idempotent.** Re-deliver the same event (Redeliver in the webhook UI) and confirm you do **not** double-label or double-comment.

### Part D — Act via GraphQL (Projects v2)
9. **Add the issue to the board.** Using GraphQL, look up `wth-ch20-board` and run `addProjectV2ItemById` to add the new issue. Capture the returned item id.
10. **Set a field.** Set a single-select **Status** field on the new item (e.g., `Triage`) via `updateProjectV2ItemFieldValue`.
11. **Idempotency again.** Confirm a replay doesn't add the issue twice.

### Part E — Orchestrate with Actions
12. **Run the glue in Actions.** Have `automation.yml` execute on the event (via `repository_dispatch` or a scheduled reconcile) to run the handler logic in CI and **post a run summary** to the workflow log / job summary.
13. **Store secrets correctly.** Put the App ID, private key, and webhook secret in **Actions secrets** — never in the repo. Reference them from the workflow.

### Part F — Prove end-to-end & harden
14. **Full-loop demo.** Open a fresh issue → observe: signature verified → labeled + commented (REST) → added to board with status (GraphQL) → Actions summary recorded. Capture evidence of each hop.
15. **Failure modes.** In `docs/CAPSTONE-NOTES.md`, document: what happens on a bad signature, an expired installation token, and a webhook redelivery — and how your design handles each. Note least-privilege choices.

## Validation / Definition of Done
You are done when ALL of the following are true:
- [ ] A **GitHub App** is **registered and installed** on the seeded repo and mints a working **installation token**.
- [ ] Inbound webhooks are **signature-verified** (HMAC-SHA256); bad signatures are rejected.
- [ ] On `issues.opened`, the App **labels + comments** via REST and the action is **idempotent** on redelivery.
- [ ] The issue is **added to `wth-ch20-board`** with a **Status** field set via **GraphQL**, also idempotent.
- [ ] **Actions** orchestrates the flow and records a **run summary**, with all credentials in **Actions secrets**.
- [ ] You demonstrated the **full end-to-end loop** from a single fresh issue and documented its **failure modes**.

> Coaches verify these via the automated hints in `COACH.md`.

## Stretch goals
- Extend the automation to **close-out**: on `issues.closed`, move the board item to `Done` and remove the triage label.
- Add a **reconcile** Actions job (scheduled) that re-syncs board state from issues, proving convergence after missed deliveries.
- Swap the single seeded event for **two event types** and route them to different handlers cleanly.

## Reference links
- REST API quickstart — https://docs.github.com/en/rest/quickstart
- GraphQL API — forming calls — https://docs.github.com/en/graphql/guides/forming-calls-with-graphql
- Using the GraphQL API for Projects (Projects v2) — https://docs.github.com/en/issues/planning-and-tracking-with-projects/automating-your-project/using-the-api-to-manage-projects
- About creating GitHub Apps — https://docs.github.com/en/apps/creating-github-apps/about-creating-github-apps/about-creating-github-apps
- Authenticating as a GitHub App installation — https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/authenticating-as-a-github-app-installation
- Validating webhook deliveries — https://docs.github.com/en/webhooks/using-webhooks/validating-webhook-deliveries
- Using secrets in GitHub Actions — https://docs.github.com/en/actions/security-for-github-actions/security-guides/using-secrets-in-github-actions
- `gh api` manual — https://cli.github.com/manual/gh_api
