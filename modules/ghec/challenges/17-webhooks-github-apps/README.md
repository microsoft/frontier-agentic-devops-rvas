# Ch17: Webhooks and GitHub Apps

**Session outcome:** Your GitHub App responds to a test webhook using an installation token with only the required permissions. The receiver verifies webhook signatures and rejects invalid ones.

## Prerequisites
- An organization you own (or org-owner rights) on GitHub Enterprise Cloud.
- A token with the scopes listed by `modules/ghec/resources/provisioning/scripts/setup.sh doctor ch17 --org <org>` (least-privilege; for this activity: `repo` + `admin:org_hook` + `read:org`).
- Local tooling: `gh >= 2.x`, `git`, `jq`, plus `openssl` (for HMAC verification). Node or Python for the receiver is optional. An Actions-based receiver also works.
- A way to receive a public callback: a [`smee.io`](https://smee.io) channel (no install/account) or the Actions-based `repository_dispatch` receiver this activity seeds. Both paths are documented below.

## What you will deliver
- Configure a repository webhook and an organization webhook, choosing events deliberately.
- Read a delivery payload and the `X-GitHub-Event` / `X-GitHub-Delivery` headers.
- Verify payloads by computing the `X-Hub-Signature-256` HMAC-SHA256 with a shared secret.
- Register a GitHub App, generate its private key, and set its permissions + event subscriptions.
- Install the App on your org and exchange the App JWT for an installation access token.
- Understand webhooks vs Apps: when a passive listener is enough vs when you need to act back as an identity.

## Scenario
A GHEC customer wants to acknowledge new issues, send push notifications, and start downstream jobs without polling the API. Configure webhooks to send events to a controlled receiver and verify each delivery's signature. Use a GitHub App when the integration needs to authenticate and act on the organisation.

> [!IMPORTANT]
> Default to an authorised customer integration target where a GitHub event should update another system.
>
> If you have an approved target, use it wherever this guide says `ghec-ch17-webhooks-github-apps` and skip Setup below. Otherwise, use the seeded sample for validation only, then hand the validated integration to the customer owner.

## Sample test repository or environment
Skip if you brought your own integration target.

```bash
# Bash
bash modules/ghec/resources/provisioning/scripts/setup.sh provision ch17 --org <org>
```
```powershell
# PowerShell
modules/ghec/resources/provisioning/scripts/setup.ps1 provision ch17 --org <org>
```

Setup creates these resources (all names use the `ghec-ch17-*` prefix, and teardown is prefix-guarded):
- A seeded repo `ghec-ch17-webhooks-github-apps` containing a receiver scaffold: a tiny webhook-verification snippet (Bash + Node) and an Actions workflow `receiver.yml` triggered by `repository_dispatch` for the no-public-host path.
- An App handler (`app/handler.js` + `app/auth.js`, zero dependencies) with signature verification, event routing, and App→installation-token auth. It has one TODO for Part G.
- A populated `WEBHOOK-SETUP.md` walking the smee.io and Actions receiver options.
- A printed Next steps block (including a generated webhook secret suggestion) telling you where to start.

## Tasks

### Part A: Receive your first delivery
1. Pick a receiver. Start a `smee.io` channel (copy its URL) or plan to use the seeded Actions `receiver.yml`. Note the public callback URL.
2. Create a repository webhook. On `ghec-ch17-webhooks-github-apps`: Settings → Webhooks → Add webhook. Set Payload URL to your receiver, Content type `application/json`, a secret, and subscribe to Issues + Pushes. (Or do it by API: `gh api repos/<org>/ghec-ch17-webhooks-github-apps/hooks -f name=web -f config[url]=<url> -f config[content_type]=json -f config[secret]=<secret> -f 'events[]=issues' -f 'events[]=push'`.)
3. Trigger an event. Open an issue in the repo and watch the delivery arrive at your receiver.

### Part B: Inspect the delivery
4. Read the headers. Identify `X-GitHub-Event` (the event name), `X-GitHub-Delivery` (a unique GUID), and `X-Hub-Signature-256`.
5. Read the payload. Find the `action` field and the `issue`/`repository` blocks. Use Recent Deliveries on the webhook page (or `gh api repos/<org>/ghec-ch17-webhooks-github-apps/hooks/<id>/deliveries`) to re-inspect and Redeliver.

### Part C: Verify the signature
6. Compute the HMAC. With the same secret, compute `sha256=<hex>` over the raw body: `printf '%s' "$BODY" | openssl dgst -sha256 -hmac "$SECRET"`.
7. Constant-time compare the result to `X-Hub-Signature-256` and reject on mismatch. Demonstrate a rejection by deliberately using the wrong secret.
8. Wire verification into the receiver. Make the seeded snippet (Bash or Node) verify before processing, and log accept/reject.

### Part D: Organization webhook
9. Create an org webhook (Org Settings → Webhooks, or `gh api orgs/<org>/hooks …`) subscribed to Repository + Membership events. Note the scope difference vs a repo hook.
10. Trigger and verify an org-level event (e.g., create a throwaway `ghec-ch17-temp` repo) and confirm it's delivered and passes signature verification, then delete the temp repo.

### Part E: Register and install a GitHub App

> GitHub Apps are created by filling the New GitHub App form. The form is long, but for this activity only a few fields matter; leave everything else at its default.

11. Open the form at Org Settings → Developer settings → GitHub Apps → New GitHub App (the page is titled *Create GitHub App*), then fill it in top to bottom:
    - GitHub App name (required): `ghec-ch17-app`. Names are globally unique, so add a suffix if it's taken.
    - Homepage URL (required): use a valid URL such as `https://github.com/<org>/ghec-ch17-webhooks-github-apps`.
    - Identifying and authorizing users and Post installation: leave the Callback/Setup URLs blank. They are not needed here.
    - Webhook → Active: uncheck it. It's on by default, which makes Webhook URL required; you aren't hosting the App's own webhook in this activity, so turning it off skips that field.
    - Permissions → Repository permissions: expand it and set Issues to Read and write. Leave Metadata at its mandatory Read-only setting.
    - Subscribe to events: the Issues checkbox appears here *only after* you set the Issues permission above (the event list is driven by your permissions). Check Issues and leave any other events unchecked.
    - Where can this GitHub App be installed? Choose Only on this account.
    - Click Create GitHub App.
12. Record the App ID and Client ID from the App's General settings page, then scroll to Private keys → Generate a private key and save the downloaded `.pem`. Use it to sign the App JWT in Part F.
13. Install the App. In the App's left sidebar click Install App, pick your org, choose Only select repositories → `ghec-ch17-webhooks-github-apps`, and install. Capture the installation ID:
    ```bash
    gh api /orgs/<org>/installations --jq '.installations[] | {id, app_slug}'
    ```

### Part F: Authenticate as the installation
14. Mint an App JWT signed with the private key (RS256, `iss`=App ID or Client ID, `iat` slightly in the past, `exp` ≤10 min). See *Generating a JSON Web Token* in the docs linked below for the exact `openssl`/script steps.
15. Exchange for an installation token. `POST /app/installations/<installation_id>/access_tokens` with the JWT → short-lived installation token.
16. Act as the App. Use the installation token to comment on an issue (`POST /repos/<org>/ghec-ch17-webhooks-github-apps/issues/<n>/comments`). Confirm the comment is authored by your App (bot), not your user.

### Part G: Make the App act automatically
> Connect the App to the receiver so it reacts to events automatically. The repo includes `app/handler.js` and auth helpers in `app/auth.js` (zero dependencies, Node 18+). They verify signatures, route `issues.opened`, ignore bot-authored issues to avoid self-triggering, and mint an installation token. Complete the acknowledgement handler.

17. Run the handler. Use the secret you set on the repo webhook in Part A and the App ID / installation ID / private key from Parts E–F:
    ```bash
    APP_ID=<app-id> INSTALLATION_ID=<installation-id> WEBHOOK_SECRET=<secret> \
      PRIVATE_KEY_PATH=./ghec-ch17-app.private-key.pem node app/handler.js
    # in another shell, relay your repo webhook's public deliveries to it:
    npx smee-client --url <your-smee-url> --target http://localhost:3000/
    ```
18. Fill in the TODO. In `onIssueOpened()`, build an acknowledgement from the payload (greet `issue.user.login`, restate `issue.title`, say what happens next) and `POST` it to `issues/<number>/comments` with the installation `token`. Verification, routing, and auth are already implemented.
19. Prove it end to end. Open a new issue and watch the App comment automatically, authored by your bot (`user.type: Bot`). Tamper with the secret and confirm the handler rejects the delivery instead of acting.

### Part G: Inspect the effective integration settings

20. Verify the repository and organization webhook scope, subscribed events,
    signature verification, GitHub App permissions, installation scope, and
    credential rotation. If enterprise hooks are authorized and visible,
    inspect their event scope, receiver, HMAC verification, and retention. The
    repository and organization work remains complete when enterprise settings
    are outside the participant's access.

## Reference links
- [About webhooks](https://docs.github.com/en/webhooks/about-webhooks)
- [Webhook events and payloads](https://docs.github.com/en/webhooks/webhook-events-and-payloads)
- [Validating webhook deliveries](https://docs.github.com/en/webhooks/using-webhooks/validating-webhook-deliveries)
- [About creating GitHub Apps](https://docs.github.com/en/apps/creating-github-apps/about-creating-github-apps/about-creating-github-apps)
- [Registering a GitHub App](https://docs.github.com/en/apps/creating-github-apps/registering-a-github-app/registering-a-github-app)
- [Generating a JSON Web Token (JWT) for a GitHub App](https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/generating-a-json-web-token-jwt-for-a-github-app)
- [Authenticating as a GitHub App installation](https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/authenticating-as-a-github-app-installation)
- [`gh api` CLI manual](https://cli.github.com/manual/gh_api)
