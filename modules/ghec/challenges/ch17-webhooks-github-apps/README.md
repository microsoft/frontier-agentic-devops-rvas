# Ch17 — Webhooks & GitHub Apps

> By the end of this challenge you can receive GitHub events over webhooks, verify their payloads cryptographically, and register and install a minimal GitHub App that authenticates as an installation — all from an org and an org-owner token.

| | |
|---|---|
| **Track** | Automation & AI |
| **Difficulty** | Intermediate *(per-track ramp)* |
| **Duration** | ~4–5 hrs total, multi-session |
| **Minimum input** | An **org** + an **org-owner token**. *(All challenges are org-scoped — no enterprise owner required.)* |
| **App** | seed |
| **EMU compatible** | yes |

## Prerequisites
- An organization you own (or org-owner rights) on GitHub Enterprise Cloud.
- A token with the scopes listed by `wth doctor ch17 --org <org>` (least-privilege; for this challenge: `repo` + `admin:org_hook` + `read:org`).
- Local tooling: `gh >= 2.x`, `git`, `jq`, plus `openssl` (for HMAC verification). Node or Python for the receiver is optional — an Actions-based receiver works too.
- A way to receive a public callback: a [`smee.io`](https://smee.io) channel (no install/account) **or** the Actions-based `repository_dispatch` receiver this challenge seeds. Both paths are documented below.

## Learning objectives
By completing this challenge you will:
- Configure a **repository webhook** and an **organization webhook**, choosing events deliberately.
- Read a **delivery payload** and the `X-GitHub-Event` / `X-GitHub-Delivery` headers.
- **Verify payloads** by computing the `X-Hub-Signature-256` HMAC-SHA256 with a shared secret.
- **Register a GitHub App**, generate its private key, and set its **permissions + event subscriptions**.
- **Install** the App on your org and exchange the App JWT for an **installation access token**.
- Understand **webhooks vs Apps**: when a passive listener is enough vs when you need to act back as an identity.

## Scenario
A GHEC customer wants to react to activity in real time — auto-acknowledge new issues, notify on pushes, kick off downstream jobs — without polling the API on a timer. You'll wire up webhooks so GitHub pushes events to a receiver you control, prove each delivery is authentic by verifying its signature, and then graduate from a passive listener to a real **GitHub App** that can authenticate and act back on the org. By the end you'll know exactly when a webhook is enough and when you need an App.

## Setup
Run the provisioning entrypoint (Bash or PowerShell — both supported). `wth` is the documented command surface; it wraps the scripts in `modules/ghec/resources/provisioning/scripts/`.

```bash
# Bash
wth setup ch17 --org <org>
# or directly:
bash modules/ghec/resources/provisioning/scripts/setup.sh setup ch17 --org <org>
```
```powershell
# PowerShell
wth setup ch17 --org <org>
# or directly:
modules/ghec/resources/provisioning/scripts/setup.ps1 setup ch17 --org <org>
```

**What setup creates** (all artifacts namespaced `wth-ch17-*`, idempotent, prefix-guarded teardown):
- A seeded repo **`wth-ch17-webhooks-github-apps`** containing a **receiver scaffold**: a tiny webhook-verification snippet (Bash + Node) and an Actions workflow `receiver.yml` triggered by `repository_dispatch` for the no-public-host path.
- A populated `WEBHOOK-SETUP.md` walking the **smee.io** and **Actions receiver** options.
- A **GitHub App manifest** (`app-manifest.json`) you'll use to register the App in a few clicks.
- A printed **Next steps** block (including a generated webhook **secret** suggestion) telling you where to start.

> Re-running `setup` reconciles (create-if-absent). `wth teardown ch17 --org <org> --yes` removes only `wth-ch17-*` artifacts. (Webhooks live on the repo/org; teardown removes the `wth-ch17-*` repo hook and any org hook it created — see Teardown.)

## Tasks

### Part A — Receive your first delivery
1. **Pick a receiver.** Start a `smee.io` channel (copy its URL) **or** plan to use the seeded Actions `receiver.yml`. Note the public callback URL.
2. **Create a repository webhook.** On `wth-ch17-webhooks-github-apps`: Settings → Webhooks → Add webhook. Set **Payload URL** to your receiver, **Content type** `application/json`, a **secret**, and subscribe to **Issues** + **Pushes**. (Or do it by API: `gh api repos/<org>/wth-ch17-webhooks-github-apps/hooks -f name=web -f config[url]=<url> -f config[content_type]=json -f config[secret]=<secret> -f 'events[]=issues' -f 'events[]=push'`.)
3. **Trigger an event.** Open an issue in the repo and watch the delivery arrive at your receiver.

### Part B — Inspect the delivery
4. **Read the headers.** Identify `X-GitHub-Event` (the event name), `X-GitHub-Delivery` (a unique GUID), and `X-Hub-Signature-256`.
5. **Read the payload.** Find the `action` field and the `issue`/`repository` blocks. Use **Recent Deliveries** on the webhook page (or `gh api repos/<org>/wth-ch17-webhooks-github-apps/hooks/<id>/deliveries`) to re-inspect and **Redeliver**.

### Part C — Verify the signature (the security core)
6. **Compute the HMAC.** With the same secret, compute `sha256=<hex>` over the **raw body**: `printf '%s' "$BODY" | openssl dgst -sha256 -hmac "$SECRET"`.
7. **Constant-time compare** the result to `X-Hub-Signature-256` and **reject on mismatch**. Demonstrate a rejection by deliberately using the wrong secret.
8. **Wire verification into the receiver.** Make the seeded snippet (Bash or Node) verify before processing, and log accept/reject.

### Part D — Organization webhook
9. **Create an org webhook** (Org Settings → Webhooks, or `gh api orgs/<org>/hooks …`) subscribed to **Repository** + **Membership** events. Note the **scope difference** vs a repo hook.
10. **Trigger and verify** an org-level event (e.g., create a throwaway `wth-ch17-temp` repo) and confirm it's delivered and passes signature verification, then delete the temp repo.

### Part E — Register & install a GitHub App
11. **Register the App.** Use the seeded `app-manifest.json` flow (Org Settings → Developer settings → GitHub Apps → New) or the manifest conversion flow. Set **Permissions** (Issues: Read & write; Metadata: Read) and **Subscribe to events** (Issues).
12. **Generate a private key** and record the **App ID** and **Client ID**.
13. **Install the App** on your org, scoped to `wth-ch17-webhooks-github-apps`. Capture the **installation ID** (`gh api /orgs/<org>/installations` or the install URL).

### Part F — Authenticate as the installation
14. **Mint an App JWT** signed with the private key (RS256, `iss`=App ID, ≤10-min expiry). The seeded helper shows the exact `openssl`/jwt steps.
15. **Exchange for an installation token.** `POST /app/installations/<installation_id>/access_tokens` with the JWT → short-lived installation token.
16. **Act as the App.** Use the installation token to comment on an issue (`POST /repos/<org>/wth-ch17-webhooks-github-apps/issues/<n>/comments`). Confirm the comment is authored by **your App (bot)**, not your user.

## Validation / Definition of Done
You are done when ALL of the following are true:
- [ ] A **repository webhook** delivers **Issues** and **Push** events to your receiver (shown in Recent Deliveries).
- [ ] You can identify `X-GitHub-Event`, `X-GitHub-Delivery`, and `X-Hub-Signature-256` on a delivery.
- [ ] Your receiver **verifies the HMAC-SHA256 signature** and **rejects** a tampered/wrong-secret payload (demonstrated).
- [ ] An **organization webhook** exists and a real org event was delivered and verified.
- [ ] A **GitHub App** is registered with scoped permissions + event subscriptions and **installed** on the org.
- [ ] You minted an **installation access token** and the App **posted a comment as a bot identity**.
- [ ] Coach conversation — which external system in your workflow (Jira, Slack, PagerDuty, a deployment dashboard) is updated by hand after a GitHub event, and what webhook payload or GitHub App permission would let you wire it up automatically? Talk it through with your coach and connect it to a real project, task, or workflow you own.

> Coaches verify these via the automated hints in `COACH.md`.

## Stretch goals
- Have the App **auto-acknowledge** new issues: on the `issues.opened` webhook, post a templated comment using a freshly minted installation token.
- Add **delivery retry handling** — make the receiver idempotent on `X-GitHub-Delivery` so a redelivery doesn't double-act.
- Convert the manual JWT steps into a tiny **reusable signer** (Node/Python) you can drop into Ch20.

## Reference links
- About webhooks — https://docs.github.com/en/webhooks/about-webhooks
- Webhook events and payloads — https://docs.github.com/en/webhooks/webhook-events-and-payloads
- Validating webhook deliveries — https://docs.github.com/en/webhooks/using-webhooks/validating-webhook-deliveries
- About creating GitHub Apps — https://docs.github.com/en/apps/creating-github-apps/about-creating-github-apps/about-creating-github-apps
- Registering a GitHub App from a manifest — https://docs.github.com/en/apps/sharing-github-apps/registering-a-github-app-from-a-manifest
- Authenticating as a GitHub App installation — https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/authenticating-as-a-github-app-installation
- `gh api` CLI manual — https://cli.github.com/manual/gh_api
