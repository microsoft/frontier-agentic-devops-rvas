# Ch20: Automation capstone

**Session outcome:** A verified webhook triggers your GitHub App and Actions automation. An end-to-end test confirms that its REST and GraphQL calls make the expected repository and project updates.

> This capstone provisions its own `ghec-ch20-*` state and does not require artifacts from another activity. It uses concepts from ch16 (REST/GraphQL), ch17 (webhooks + GitHub App), and ch18 (Actions runners).

## Prerequisites
- An organization you own (or org-owner rights) on GitHub Enterprise Cloud.
- A token with the scopes listed by `modules/ghec/resources/provisioning/scripts/setup.sh doctor ch20 --org <org>` (least-privilege; this activity needs `repo`, `admin:org_hook`, and the ability to create a GitHub App in the org).
- Local tooling: `gh >= 2.x`, `git`, `jq`, and Node.js 18+ (the seeded App handler is Node; a Bash path is provided where practical).
- A way to receive webhook deliveries during development: `smee.io` for local relay, or the provided Actions `repository_dispatch` receiver for a no-public-endpoint path.
- Comfort with the building blocks from earlier in the track (API calls, HMAC signature verification, installation tokens, Actions workflows). This capstone assumes them rather than re-teaching from zero.

## What you'll do
- Register and install a GitHub App in the org and authenticate as an installation.
- Call both the REST API and the GraphQL API (including a Projects v2 mutation) from the App's installation token.
- Verify inbound webhook signatures (HMAC-SHA256, `X-Hub-Signature-256`) and route events to handlers.
- Wire Actions as the orchestration layer that ties the pieces together and runs on push/dispatch.
- Combine them into one reliable, idempotent flow triggered by a real repository event.
- Reason about least-privilege, secret handling, and failure modes across the whole automation.

## Scenario
Your org wants one automation that keeps a project board aligned with issue activity. When an issue opens in the seeded repository, a webhook fires. The GitHub App authenticates as an installation, labels and triages the issue through REST, adds it to a Projects v2 board through GraphQL, and records the result in GitHub Actions. Validate the full flow and make it idempotent so replays do not create duplicates.

> [!IMPORTANT]
> Use an authorised customer workflow that needs Actions, API automation, and security controls.
>
> If you have an approved target, use it wherever this guide says `ghec-ch20-automation-capstone` and skip Setup below. Otherwise, use the seeded capstone for validation only, then hand the validated automation to the customer owner.

## Sample test repository or environment
Skip if you brought your own workflow/repo.

```bash
# Bash
bash modules/ghec/resources/provisioning/scripts/setup.sh provision ch20 --org <org>
```
```powershell
# PowerShell
modules/ghec/resources/provisioning/scripts/setup.ps1 provision ch20 --org <org>
```

What setup creates (all artifacts namespaced `ghec-ch20-*`, idempotent, prefix-guarded teardown):
- A seeded repo `ghec-ch20-automation-capstone` with a Node App handler scaffold at `src/handler.js`, HMAC verification, and REST/GraphQL TODOs. It also includes App JWT signing and installation-token helpers at `src/auth.js`, an Actions workflow (`automation.yml`), and a `CAPSTONE.md` build guide.
- An empty org Projects v2 board `ghec-ch20-board` for the GraphQL step to populate.
- A printed Next steps block (App registration URL flow, where to put the webhook secret, how to drive deliveries via `smee.io` or `repository_dispatch`).

## Tasks

### Part A: Register and install the App
1. Register the App. Create it from the New GitHub App form, filling the form by hand. Go to Org Settings → Developer settings → GitHub Apps → New GitHub App (page titled *Create GitHub App*) and set:
   - GitHub App name (required): `ghec-ch20-capstone-app`. Names are globally unique, so add a suffix if it's taken.
   - Homepage URL (required): use a valid URL such as `https://github.com/<org>/ghec-ch20-automation-capstone`.
   - Identifying and authorizing users and Post installation: leave the Callback/Setup URLs blank.
   - Webhook → Active: if you already have your receiver URL from Part B (a `smee.io` channel), keep Active checked and paste it as the Webhook URL with a Secret now. Otherwise uncheck Active and add the URL + secret later in Part B (you can edit the App at any time).
   - Permissions → Repository permissions: set Issues to Read and write for labeling and commenting. Leave Metadata at its mandatory Read-only setting.
   - Permissions → Organization permissions: set Projects to Read and write to add items to the org-level `ghec-ch20-board` Projects v2 board. Repository-level Projects does not cover org boards.
   - Subscribe to events: the Issues checkbox appears here *only after* you set the Issues permission above. Check Issues and leave any other events unchecked.
   - Where can this GitHub App be installed? Choose Only on this account, then click Create GitHub App.
   - On the App's *General* page, record the App ID and Client ID, then Private keys → Generate a private key and save the `.pem`.
2. Install the App on the seeded repo: in the App's left sidebar click Install App, choose your org, and select Only select repositories → `ghec-ch20-automation-capstone`.
3. Mint an installation token and confirm it works. The seeded `src/auth.js` exposes `createAppJwt(appId, pem)` and `getInstallationToken(jwt, installationId)`. `src/handler.js` wraps both in `mintInstallationToken()`, which reads `APP_ID`, `INSTALLATION_ID`, and `PRIVATE_KEY_PATH`. Capture the installation ID, then call `mintInstallationToken()` or `gh api /app/installations/<installation_id>/access_tokens` as the App. Check that `gh api /installation/repositories` returns the seeded repo. Use the helpers rather than hand-signing a JWT with openssl.

### Part B: Connect the inbound webhook
4. Set the webhook secret and point the App's webhook at your receiver: a `smee.io` relay for local dev or the `repository_dispatch` Actions receiver if you have no public endpoint.
5. Verify signatures. In the handler, compute HMAC-SHA256 over the raw body with your secret and constant-time-compare against `X-Hub-Signature-256`. Reject mismatches.
6. Trigger a delivery by opening a test issue; confirm the handler receives `issues.opened` and the signature check passes.

### Part C: Act via REST
7. Triage via REST. On `issues.opened`, have the App add a triage label and post a brief acknowledgement comment using its installation token.
8. Make it idempotent. Re-deliver the same event (Redeliver in the webhook UI) and confirm you do not double-label or double-comment.

### Part D: Act via GraphQL (Projects v2)
9. Add the issue to the board. Using GraphQL, look up `ghec-ch20-board` and run `addProjectV2ItemById` to add the new issue. Capture the returned item id.
10. Set a field. Set a single-select Status field on the new item (e.g., `Triage`) via `updateProjectV2ItemFieldValue`.
11. Idempotency again. Confirm a replay doesn't add the issue twice.

### Part E: Orchestrate with Actions
12. Have `automation.yml` run the handler in CI via `repository_dispatch` or a scheduled reconcile. Post a run summary to the workflow log / job summary.
13. Put the App ID, private key, and webhook secret in Actions secrets, never in the repo. Reference them from the workflow.

### Part F: Test the full flow and harden it
14. Full-loop demo. Open a fresh issue → observe: signature verified → labeled + commented (REST) → added to board with status (GraphQL) → Actions summary recorded. Capture evidence of each hop.
15. In `docs/CAPSTONE-NOTES.md`, document how your design handles a bad signature, an expired installation token, and a webhook redelivery. Note least-privilege choices.

## Reference links
- [REST API quickstart](https://docs.github.com/en/rest/quickstart)
- [Forming calls with GraphQL](https://docs.github.com/en/graphql/guides/forming-calls-with-graphql)
- [Using the GraphQL API for Projects (Projects v2)](https://docs.github.com/en/issues/planning-and-tracking-with-projects/automating-your-project/using-the-api-to-manage-projects)
- [About creating GitHub Apps](https://docs.github.com/en/apps/creating-github-apps/about-creating-github-apps/about-creating-github-apps)
- [Authenticating as a GitHub App installation](https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/authenticating-as-a-github-app-installation)
- [Validating webhook deliveries](https://docs.github.com/en/webhooks/using-webhooks/validating-webhook-deliveries)
- [Using secrets in GitHub Actions](https://docs.github.com/en/actions/security-for-github-actions/security-guides/using-secrets-in-github-actions)
- [`gh api` manual](https://cli.github.com/manual/gh_api)
