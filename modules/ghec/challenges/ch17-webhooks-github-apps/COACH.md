# Ch17 — Webhooks & GitHub Apps — Coach Guide

> Audience: facilitators and graders. Pair with the student `README.md`.

## Grounding conversation (you will be called)

**Required coach check-in:** before completion, ask the learner to connect the exercise to work they actually own.

**Their question:** Coach conversation — which external system in your workflow (Jira, Slack, PagerDuty, a deployment dashboard) is updated by hand after a GitHub event, and what webhook payload or GitHub App permission would let you wire it up automatically? Talk it through with your coach and connect it to a real project, task, or workflow you own.

> **Bring-your-own grading:** prefer students who ran this on a **real artifact they own** over the `ghec-ch17-webhooks-github-apps` sample. If they used the sample, confirm they can name the actual repo, team, project, or workflow they'll apply this to and any blockers. The lasting outcome is the goal; the sample is fallback.

Use these follow-ups to steer the conversation:
- Name the external system and the GitHub event (push, PR merged, release created) that should trigger the update.
- What is the current human-in-the-loop step that introduces delay or inconsistency?
- What is the minimal webhook receiver or App you could prototype in a day to prove the integration out?

## Facilitation notes
- **Goal in one line:** the student receives real webhook deliveries, **verifies them cryptographically**, and graduates from a passive listener to an installed **GitHub App** that acts back as a bot identity.
- **Where students get stuck:**
  - **No public host.** Many corporate machines can't expose a port. Steer them to **smee.io** or the seeded **Actions `repository_dispatch` receiver** — don't let them rabbit-hole on ngrok/firewalls.
  - **Signature over the raw body.** The HMAC must be computed over the **exact raw bytes** GitHub sent — re-serializing the JSON changes whitespace and breaks the digest. This is the #1 failure.
  - **App auth chain confusion.** App JWT (signed with private key) → installation token (exchanged via JWT) → API calls (use installation token). They mix up which credential goes where.
  - **Permissions not granted at install.** Adding a permission after install requires the org to **approve** the new permission; the install must be refreshed.
- **How to unblock without giving the answer:** ask "what exact bytes did you sign, and what exact bytes did GitHub sign?" (→ raw body), and "which of your three credentials is allowed to comment?" (→ installation token, not the JWT, not your PAT).
- **Org-scoped note:** runs with an org + org-owner token. Org webhooks and org App installs need org-owner; `admin:org_hook` covers org webhook management. No enterprise owner required.

## Grading rubric (point-weighted, 100 pts)
| Criterion | Points | What "full marks" looks like |
|---|---:|---|
| Repository webhook + delivery | 15 | Hook on Issues + Push; deliveries visible; redelivery shown |
| Delivery inspection | 10 | Identifies event/delivery/signature headers and key payload fields |
| Signature verification | 25 | HMAC-SHA256 over raw body; constant-time compare; tampered payload rejected (demonstrated) |
| Organization webhook | 15 | Org hook created; real org event delivered and verified |
| App registration + install | 20 | App with scoped permissions + event subs; installed on org; install ID captured |
| Installation auth + auto-react | 15 | JWT → installation token; App comments as a **bot** identity, and the **Part G handler posts that comment automatically** on `issues.opened` (manual `gh api` comment alone = partial credit) |
| **Total** | **100** | |

## Automated verification hints
```bash
ORG=<org>; REPO=ghec-ch17-webhooks-github-apps   # swap REPO for the student's own repo if they brought one

# Repo webhook exists with the right events
gh api repos/$ORG/$REPO/hooks --jq '.[] | {id, events, active}'

# Recent deliveries (proves events actually flowed)
HID=$(gh api repos/$ORG/$REPO/hooks --jq '.[0].id')
gh api repos/$ORG/$REPO/hooks/$HID/deliveries --jq '.[] | {event, status_code, delivered_at}' | head

# Org webhook exists
gh api orgs/$ORG/hooks --jq '.[] | {id, events, active}'

# The GitHub App installation on the org
gh api /orgs/$ORG/installations --jq '.installations[] | {id, app_slug, target_type}'

# Bot-authored comment exists (proves installation-token action)
gh api repos/$ORG/$REPO/issues/comments --jq '.[] | {user: .user.login, type: .user.type}' | grep -i Bot
```
- The strongest mastery signal is a **comment whose `user.type` is `Bot`** — only an installation token produces that. A PAT comment shows `type: User`.
- For signature verification, have the student **redeliver** a payload, tamper one byte locally, and show the receiver logging a **reject**.
- **Part G check:** with `app/handler.js` running (behind smee), opening a *new* issue should produce a bot comment **without any manual command**. The accelerator already does verify + routing + auth, so a failure here is almost always in the student's TODO (wrong endpoint, missing `Authorization: token <token>` header, or not reading `issue.number`/`issue.user.login` from the payload). If nothing appears, check the handler logs for `bad signature` (secret mismatch with the repo webhook) vs `handler error` (their POST).

## Common pitfalls
- **Hashing re-serialized JSON** instead of the raw body → signature never matches. Capture and sign the raw bytes.
- **Wrong secret on the hook vs the verifier** → every delivery "fails" verification; check both ends.
- **JWT used directly to call the API** → `401`; you must exchange it for an installation token first.
- **JWT clock skew / >10-min expiry** → `401`; keep `exp` ≤ 10 minutes and the machine clock correct.
- **Token scope** — `admin:org_hook` needed for org webhooks; org-owner needed to install the App.
- **Leftover org hook / temp repo** — remind students to delete the `ghec-ch17-temp` repo from Part D.

## Useful references for coaching

- [smee.io](https://smee.io), [About webhooks](https://docs.github.com/en/webhooks/about-webhooks).

## Teardown
```bash
bash modules/ghec/resources/provisioning/scripts/setup.sh teardown ch17 --org <org> --yes   # Bash
modules/ghec/resources/provisioning/scripts/setup.ps1 teardown ch17 --org <org> --yes  # PowerShell
```
- Removes only `ghec-ch17-*` artifacts (prefix-guarded): the repo (with its repo webhook) and any `ghec-ch17-*` org webhook the script created.
- **Manual cleanup (required):** the **GitHub App registration** and its **installation** are owned by the org's developer settings and are **not** prefix-deletable by the script — remove them by hand (Org Settings → Developer settings → GitHub Apps → delete; Installations → uninstall). Delete any `ghec-ch17-temp` repo if left over. Revoke the smee.io channel.

## Time budget
- Setup + read: ~30 min
- Parts A–B (receive + inspect): ~1 hr
- Part C (signature verification): ~1 hr
- Part D (org webhook): ~30 min
- Parts E–F (App register/install + installation auth): ~1.5 hrs
- Part G (auto-acknowledge via the seeded handler): ~30 min — auth/verification/routing are provided; the only work is composing the comment and POSTing it with the installation token.
- **Total facilitated:** ~4.5–5.5 hrs across sessions.
