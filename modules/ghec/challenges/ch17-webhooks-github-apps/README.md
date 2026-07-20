# Ch17 — Webhooks & GitHub Apps

> Deliver a secure customer event integration with verified webhooks and a least-privilege GitHub App installation.

| | |
|---|---|
| Track | Automation & AI |
| Difficulty | Intermediate *(per-track ramp)* |
| Duration | ~4–5 hrs total, multi-session |
| Minimum input | An org + an org-owner token. *(All activities are org-scoped — no enterprise owner required.)* |
| App | Provisioned starter repository (created by setup) |
| EMU compatible | yes |

## Customer delivery target

- Customer objective: deliver an approved, secure event integration that operates in the customer tenant.
- Customer-tenant target: the customer webhook/App configuration, least-privilege permissions, receiver, and installation authentication path.
- Approval and safety boundary: create webhooks, Apps, keys, and installations only with the accountable organisation owner’s approval; the seeded resources are a sample test environment for signature and permission validation.
- Records to keep: retain the App registration details, permission/event matrix, signature-validation evidence, installation scope, and key-handling runbook.
- Adoption owner / handover: the customer integration owner accepts credential rotation, receiver operations, and App permissions.
- Next action and owner: approve the customer App installation or hand over the validated integration package and decision owner.

## Prerequisites
- An organization you own (or org-owner rights) on GitHub Enterprise Cloud.
- A token with the scopes listed by `modules/ghec/resources/provisioning/scripts/setup.sh doctor ch17 --org <org>` (least-privilege; for this activity: `repo` + `admin:org_hook` + `read:org`).
- Local tooling: `gh >= 2.x`, `git`, `jq`, plus `openssl` (for HMAC verification). Node or Python for the receiver is optional — an Actions-based receiver works too.
- A way to receive a public callback: a [`smee.io`](https://smee.io) channel (no install/account) or the Actions-based `repository_dispatch` receiver this activity seeds. Both paths are documented below.

## Customer delivery objectives
This delivery engagement establishes:
- Configure a repository webhook and an organization webhook, choosing events deliberately.
- Read a delivery payload and the `X-GitHub-Event` / `X-GitHub-Delivery` headers.
- Verify payloads by computing the `X-Hub-Signature-256` HMAC-SHA256 with a shared secret.
- Register a GitHub App, generate its private key, and set its permissions + event subscriptions.
- Install the App on your org and exchange the App JWT for an installation access token.
- Understand webhooks vs Apps: when a passive listener is enough vs when you need to act back as an identity.

## Scenario
A GHEC customer wants to react to activity in real time — auto-acknowledge new issues, notify on pushes, kick off downstream jobs — without polling the API on a timer. Configure webhooks so GitHub pushes events to a controlled receiver, prove each delivery is authentic by verifying its signature, then use a GitHub App when the integration must authenticate and act back on the organisation.

> [!IMPORTANT]
> Use an approved customer target (do this first)
> Default to an authorised customer integration target where a GitHub event should update another system. Complete the work on that artifact and retain the evidence, guardrails, or automation.
>
> - Have a candidate? Use it everywhere this guide says `ghec-ch17-webhooks-github-apps`. Skip the Setup step below entirely.
> - No suitable one? Use the fallback below: a seeded sample repo and App/webhook controlled-validation target.
>
> Record the selected target, customer integration owner, and next action and owner. Use the sample only for testing; move the validated integration to an approved customer tenant.

## Sample test repository or environment (when tenant delivery is constrained)
Skip this if you brought your own integration target. Otherwise run the provisioning entrypoint (Bash or PowerShell — both supported).

```bash
# Bash
bash modules/ghec/resources/provisioning/scripts/setup.sh provision ch17 --org <org>
```
```powershell
# PowerShell
modules/ghec/resources/provisioning/scripts/setup.ps1 provision ch17 --org <org>
```

What setup creates (all artifacts namespaced `ghec-ch17-*`, idempotent, prefix-guarded teardown):
- A seeded repo `ghec-ch17-webhooks-github-apps` containing a receiver scaffold: a tiny webhook-verification snippet (Bash + Node) and an Actions workflow `receiver.yml` triggered by `repository_dispatch` for the no-public-host path.
- An App handler accelerator (`app/handler.js` + `app/auth.js`, zero dependencies) that already does signature verification, event routing, and App→installation-token auth — leaving one TODO for Part G.
- A populated `WEBHOOK-SETUP.md` walking the smee.io and Actions receiver options.
- A printed Next steps block (including a generated webhook secret suggestion) telling you where to start.


## Tasks
> Throughout, `ghec-ch17-webhooks-github-apps` is the fallback sample. If you brought your own artifact, substitute its name in every command and use your real history, teams, settings, or data as the material to work from.

### Part A — Receive your first delivery
1. Pick a receiver. Start a `smee.io` channel (copy its URL) or plan to use the seeded Actions `receiver.yml`. Note the public callback URL.
2. Create a repository webhook. On `ghec-ch17-webhooks-github-apps`: Settings → Webhooks → Add webhook. Set Payload URL to your receiver, Content type `application/json`, a secret, and subscribe to Issues + Pushes. (Or do it by API: `gh api repos/<org>/ghec-ch17-webhooks-github-apps/hooks -f name=web -f config[url]=<url> -f config[content_type]=json -f config[secret]=<secret> -f 'events[]=issues' -f 'events[]=push'`.)
3. Trigger an event. Open an issue in the repo and watch the delivery arrive at your receiver.

### Part B — Inspect the delivery
4. Read the headers. Identify `X-GitHub-Event` (the event name), `X-GitHub-Delivery` (a unique GUID), and `X-Hub-Signature-256`.
5. Read the payload. Find the `action` field and the `issue`/`repository` blocks. Use Recent Deliveries on the webhook page (or `gh api repos/<org>/ghec-ch17-webhooks-github-apps/hooks/<id>/deliveries`) to re-inspect and Redeliver.

### Part C — Verify the signature (the security core)
6. Compute the HMAC. With the same secret, compute `sha256=<hex>` over the raw body: `printf '%s' "$BODY" | openssl dgst -sha256 -hmac "$SECRET"`.
7. Constant-time compare the result to `X-Hub-Signature-256` and reject on mismatch. Demonstrate a rejection by deliberately using the wrong secret.
8. Wire verification into the receiver. Make the seeded snippet (Bash or Node) verify before processing, and log accept/reject.

### Part D — Organization webhook
9. Create an org webhook (Org Settings → Webhooks, or `gh api orgs/<org>/hooks …`) subscribed to Repository + Membership events. Note the scope difference vs a repo hook.
10. Trigger and verify an org-level event (e.g., create a throwaway `ghec-ch17-temp` repo) and confirm it's delivered and passes signature verification, then delete the temp repo.

### Part E — Register & install a GitHub App

> GitHub Apps are created by filling the New GitHub App form. The form is long, but for this activity only a few fields matter; leave everything else at its default.

11. Open the form at Org Settings → Developer settings → GitHub Apps → New GitHub App (the page is titled *Create GitHub App*), then fill it in top to bottom:
    - GitHub App name (required): `ghec-ch17-app` — names are globally unique, so add a suffix if it's taken.
    - Homepage URL (required): any valid URL works — use your repo, e.g. `https://github.com/<org>/ghec-ch17-webhooks-github-apps`.
    - Identifying and authorizing users and Post installation: leave the Callback/Setup URLs blank — not needed here.
    - Webhook → Active: uncheck it. It's on by default, which makes Webhook URL required; you aren't hosting the App's own webhook in this activity, so turning it off skips that field.
    - Permissions → Repository permissions: expand it and set Issues to Read and write. Metadata is already Read-only (mandatory) — leave it as is.
    - Subscribe to events: the Issues checkbox appears here *only after* you set the Issues permission above (the event list is driven by your permissions). Check Issues and leave any other events unchecked.
    - Where can this GitHub App be installed? Choose Only on this account.
    - Click Create GitHub App.
12. Record the App ID and Client ID from the App's *General* settings page, then scroll to Private keys → Generate a private key and save the downloaded `.pem` — you'll sign the App JWT with it in Part F.
13. Install the App. In the App's left sidebar click Install App, pick your org, choose Only select repositories → `ghec-ch17-webhooks-github-apps`, and install. Capture the installation ID:
    ```bash
    gh api /orgs/<org>/installations --jq '.installations[] | {id, app_slug}'
    ```

### Part F — Authenticate as the installation
14. Mint an App JWT signed with the private key (RS256, `iss`=App ID or Client ID, `iat` slightly in the past, `exp` ≤10 min). See *Generating a JSON Web Token* in the docs linked below for the exact `openssl`/script steps.
15. Exchange for an installation token. `POST /app/installations/<installation_id>/access_tokens` with the JWT → short-lived installation token.
16. Act as the App. Use the installation token to comment on an issue (`POST /repos/<org>/ghec-ch17-webhooks-github-apps/issues/<n>/comments`). Confirm the comment is authored by your App (bot), not your user.

### Part G — Make the App act automatically
> So far the App acts only when *you* run a command. Now wire it into the receiver so it reacts to events on its own. The repo ships an almost-complete handler — `app/handler.js` plus auth helpers in `app/auth.js` (zero dependencies, Node 18+) — that already verifies the signature, routes `issues.opened`, ignores bot-authored issues (so the App can't trigger itself), and mints an installation token. One piece is left for you.

17. Run the handler. Use the secret you set on the repo webhook in Part A and the App ID / installation ID / private key from Parts E–F:
    ```bash
    APP_ID=<app-id> INSTALLATION_ID=<installation-id> WEBHOOK_SECRET=<secret> \
      PRIVATE_KEY_PATH=./ghec-ch17-app.private-key.pem node app/handler.js
    # in another shell, relay your repo webhook's public deliveries to it:
    npx smee-client --url <your-smee-url> --target http://localhost:3000/
    ```
18. Fill in the TODO. In `onIssueOpened()`, build a context-aware acknowledgement from the payload (greet `issue.user.login`, restate `issue.title`, say what happens next) and `POST` it to `issues/<number>/comments` with the installation `token`. Everything else — verification, routing, auth — is already done.
19. Prove it end to end. Open a new issue and watch the App comment automatically, authored by your bot (`user.type: Bot`). Tamper with the secret and confirm the handler rejects the delivery instead of acting.

## Validation / Definition of Done
You are done when ALL of the following are true:
- [ ] A repository webhook delivers Issues and Push events to your receiver (shown in Recent Deliveries).
- [ ] You can identify `X-GitHub-Event`, `X-GitHub-Delivery`, and `X-Hub-Signature-256` on a delivery.
- [ ] Your receiver verifies the HMAC-SHA256 signature and rejects a tampered/wrong-secret payload (demonstrated).
- [ ] An organization webhook exists and a real org event was delivered and verified.
- [ ] A GitHub App is registered with scoped permissions + event subscriptions and installed on the org.
- [ ] You minted an installation access token and the App posted a comment as a bot identity.
- [ ] Automated reaction — opening a new issue makes the running handler post a context-aware acknowledgement on its own, authored by the bot, and a bad-signature delivery is rejected.
- [ ] Real-outcome check — if you brought your own integration target, a real GitHub event now drives another system or workflow; if you used the sample, you can name the webhook/App integration you will build next.
- [ ] Adoption handover — record the customer integration owner, target external system, required event and App permissions, and next approved action.

> Coaches verify these via the automated hints in `COACH.md`.

## Operational extensions
- Triage, don't just acknowledge: in `onIssueOpened()`, also label the issue by content (e.g. `bug` vs `question`) and assign or `@`-mention an owner — remember the App needs the matching permission, and labeling fires `issues.labeled`, so keep guarding against self-triggering.
- Add delivery retry handling — make the handler idempotent on `X-GitHub-Delivery` (and check for an existing bot comment) so a redelivery doesn't double-act.
- Convert `app/auth.js` into a tiny reusable signer package you can drop into Ch20.

## Reference links
- About webhooks — https://docs.github.com/en/webhooks/about-webhooks
- Webhook events and payloads — https://docs.github.com/en/webhooks/webhook-events-and-payloads
- Validating webhook deliveries — https://docs.github.com/en/webhooks/using-webhooks/validating-webhook-deliveries
- About creating GitHub Apps — https://docs.github.com/en/apps/creating-github-apps/about-creating-github-apps/about-creating-github-apps
- Registering a GitHub App — https://docs.github.com/en/apps/creating-github-apps/registering-a-github-app/registering-a-github-app
- Generating a JSON Web Token (JWT) for a GitHub App — https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/generating-a-json-web-token-jwt-for-a-github-app
- Authenticating as a GitHub App installation — https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/authenticating-as-a-github-app-installation
- `gh api` CLI manual — https://cli.github.com/manual/gh_api
