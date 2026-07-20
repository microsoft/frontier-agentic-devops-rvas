# Ch20 — Automation Capstone

> Deliver one secure, end-to-end automation: a GitHub App uses REST and GraphQL, a webhook drives the flow, and Actions orchestrates it.

| | |
|---|---|
| **Track** | Automation & AI |
| **Difficulty** | Advanced *(capstone — hardest in the track)* |
| **Duration** | ~8 hrs total, multi-session |
| **Minimum input** | An **org** + an **org-owner token**. *(All activities are org-scoped — no enterprise owner required.)* |
| **App** | Provisioned starter repository (created by setup) |
| **EMU compatible** | yes — all steps run on org-owned, prefix-namespaced resources. |

## Customer delivery target

- **Customer objective:** deliver one owned, secure, end-to-end automation for a customer workflow.
- **Customer-tenant target:** an approved customer App, webhook, Actions workflow, API automation, and project-board integration.
- **Approval and safety boundary:** create Apps, secrets, webhooks, and write automation in the customer tenant only with accountable owner approval; otherwise use the seeded capstone as a controlled proving ground and leave an implementation proposal.
- **Enduring evidence:** retain the source-controlled automation, permission matrix, secret-handling record, event trace, idempotency evidence, and failure-mode notes.
- **Adoption owner / handover:** the customer integration owner accepts operations and rotation; the workflow owner accepts business outcomes.
- **Accountable next action:** authorise production enablement for the selected workflow or assign the owner and decision date for the rollout proposal.

> **Independent by design.** This capstone **stands alone** — it provisions all its own `ghec-ch20-*` state and requires **no other activity to have been run**. It *revisits the skills* from ch16 (REST/GraphQL), ch17 (webhooks + GitHub App), and ch18 (Actions runners) conceptually, but you do **not** need their artifacts.

## Prerequisites
- An organization you own (or org-owner rights) on GitHub Enterprise Cloud.
- A token with the scopes listed by `modules/ghec/resources/provisioning/scripts/setup.sh doctor ch20 --org <org>` (least-privilege; this activity needs `repo`, `admin:org_hook`, and the ability to create a GitHub App in the org).
- Local tooling: `gh >= 2.x`, `git`, `jq`, and **Node.js 18+** (the seeded App handler is Node; a Bash path is provided where practical).
- A way to receive webhook deliveries during development: **`smee.io`** for local relay, **or** the provided **Actions `repository_dispatch` receiver** for a no-public-endpoint path.
- Comfort with the building blocks from earlier in the track (API calls, HMAC signature verification, installation tokens, Actions workflows). This capstone assumes them rather than re-teaching from zero.

## Customer delivery objectives
This delivery engagement establishes:
- **Register and install a GitHub App** in the org and authenticate as an **installation**.
- Call both the **REST API** and the **GraphQL API** (including a **Projects v2** mutation) from the App's installation token.
- **Verify inbound webhook signatures** (HMAC-SHA256, `X-Hub-Signature-256`) and route events to handlers.
- Wire **Actions** as the orchestration layer that ties the pieces together and runs on push/dispatch.
- Compose all four into **one reliable, idempotent, end-to-end flow** triggered by a real repo event.
- Reason about **least-privilege**, **secret handling**, and **failure modes** across the whole automation.

## Scenario
Your org wants a single automation that reacts to activity and keeps a project board honest without anyone touching it manually. When an issue is opened on the seeded repo, a webhook fires → your **GitHub App** (authenticated as an installation) **labels and triages** the issue via REST, **adds it to a Projects v2 board** via GraphQL, and an **Actions** workflow records the result and posts a summary. Validate the seeded scaffold end to end and make it **idempotent** so replays do not create duplicates. This is an integrated delivery pattern for the customer tenant.

> [!IMPORTANT]
> **Bring your own outcome (do this first)**
> Default to an authorised customer workflow that combines Actions, API automation, and security controls into a lasting delivery artifact. Complete the work on **that** artifact and retain the evidence, guardrails, or automation.
>
> - **Have a candidate?** Use it everywhere this guide says `ghec-ch20-automation-capstone`. Skip the Setup step below entirely.
> - **No suitable one?** Use the fallback below: a seeded capstone repo for controlled end-to-end automation validation.
>
> Record the selected target, customer integration owner, and accountable next action. The sample is only a controlled proving ground; move the validated automation to an approved customer tenant.

## Controlled proving ground (when tenant delivery is constrained)
Skip this if you brought your own workflow/repo. Otherwise run the provisioning entrypoint (Bash or PowerShell — both supported): the `setup.sh` / `setup.ps1` scripts in `modules/ghec/resources/provisioning/scripts/`.

```bash
# Bash
bash modules/ghec/resources/provisioning/scripts/setup.sh provision ch20 --org <org>
```
```powershell
# PowerShell
modules/ghec/resources/provisioning/scripts/setup.ps1 provision ch20 --org <org>
```

**What setup creates** (all artifacts namespaced `ghec-ch20-*`, idempotent, prefix-guarded teardown):
- A seeded repo **`ghec-ch20-automation-capstone`** containing the **App handler scaffold** (`src/handler.js` — Node, HMAC verification + REST/GraphQL TODOs), **ready-made App auth helpers** (`src/auth.js` — App JWT signing + installation-token exchange), an **Actions workflow** (`automation.yml`), and a `CAPSTONE.md` build guide.
- An **empty org Projects v2 board** **`ghec-ch20-board`** for the GraphQL step to populate.
- A printed **Next steps** block (App registration URL flow, where to put the webhook secret, how to drive deliveries via `smee.io` or `repository_dispatch`).


## Tasks
> Throughout, **`ghec-ch20-automation-capstone` is the fallback sample**. If you brought your own artifact, substitute its name in every command and use your real history, teams, settings, or data as the material to work from.

### Part A — Register & install the App
1. **Register the App.** Create it from the **New GitHub App** form, filling the form by hand. Go to Org **Settings → Developer settings → GitHub Apps → New GitHub App** (page titled *Create GitHub App*) and set:
   - **GitHub App name** (required): `ghec-ch20-capstone-app` — names are globally unique, so add a suffix if it's taken.
   - **Homepage URL** (required): any valid URL — use the repo, e.g. `https://github.com/<org>/ghec-ch20-automation-capstone`.
   - **Identifying and authorizing users** and **Post installation**: leave the Callback/Setup URLs blank.
   - **Webhook → Active:** if you already have your receiver URL from Part B (a `smee.io` channel), keep **Active** checked and paste it as the **Webhook URL** with a **Secret** now. Otherwise **uncheck Active** and add the URL + secret later in Part B (you can edit the App at any time).
   - **Permissions → Repository permissions:** set **Issues** to **Read and write** (for labeling + commenting). **Metadata** is already **Read-only** (mandatory) — leave it.
   - **Permissions → Organization permissions:** set **Projects** to **Read and write** — this is required to add items to the org-level `ghec-ch20-board` Projects v2 board (repository-level Projects does **not** cover org boards).
   - **Subscribe to events:** the **Issues** checkbox appears here *only after* you set the Issues permission above. Check **Issues** and leave any other events unchecked.
   - **Where can this GitHub App be installed?** Choose **Only on this account**, then click **Create GitHub App**.
   - On the App's *General* page, **record the App ID and Client ID**, then **Private keys → Generate a private key** and save the `.pem`.
2. **Install the App** on the seeded repo: in the App's left sidebar click **Install App**, choose your org, and select **Only select repositories → `ghec-ch20-automation-capstone`**.
3. **Mint an installation token** and confirm it works. JWT signing is done for you — the seeded **`src/auth.js`** exposes `createAppJwt(appId, pem)` and `getInstallationToken(jwt, installationId)`, and `src/handler.js` wraps both in `mintInstallationToken()` (reads the `APP_ID`, `INSTALLATION_ID`, and `PRIVATE_KEY_PATH` env vars). Capture the installation ID, then verify the token works — e.g. call `mintInstallationToken()` (or `gh api /app/installations/<installation_id>/access_tokens` as the App) and check `gh api /installation/repositories` returns the seeded repo. You should never hand-sign a JWT with openssl.

### Part B — Wire the inbound webhook
4. **Set the webhook secret** and point the App's webhook at your receiver: a **`smee.io`** relay for local dev **or** the **`repository_dispatch`** Actions receiver if you have no public endpoint.
5. **Verify signatures.** In the handler, compute HMAC-SHA256 over the raw body with your secret and constant-time-compare against `X-Hub-Signature-256`. **Reject** mismatches.
6. **Trigger a delivery** by opening a test issue; confirm the handler receives `issues.opened` and the signature check passes.

### Part C — Act via REST
7. **Triage via REST.** On `issues.opened`, have the App **add a triage label** and post a brief **acknowledgement comment** using its installation token.
8. **Make it idempotent.** Re-deliver the same event (Redeliver in the webhook UI) and confirm you do **not** double-label or double-comment.

### Part D — Act via GraphQL (Projects v2)
9. **Add the issue to the board.** Using GraphQL, look up `ghec-ch20-board` and run `addProjectV2ItemById` to add the new issue. Capture the returned item id.
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
- [ ] The issue is **added to `ghec-ch20-board`** with a **Status** field set via **GraphQL**, also idempotent.
- [ ] **Actions** orchestrates the flow and records a **run summary**, with all credentials in **Actions secrets**.
- [ ] You demonstrated the **full end-to-end loop** from a single fresh issue and documented its **failure modes**.
- [ ] Real-outcome check — if you brought your own workflow, the capstone automation now leaves behind a reusable delivery artifact; if you used the sample, you can name the production workflow you will automate next.
- [ ] **Adoption handover** — record the customer workflow owner, highest-value manual workflow, security boundary, and next approved action.

> Coaches verify these via the automated hints in `COACH.md`.

## Operational extensions
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
