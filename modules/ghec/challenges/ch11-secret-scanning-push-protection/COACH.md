# Ch11 — Secret Scanning & Push Protection — Coach Guide

> Audience: facilitators and graders. Pair with the student `README.md`.

## Grounding conversation (you will be called)

Students are **expected to call you** to talk through this challenge's real-world impact before they consider it done. This is a required completion step, not optional — it is how we keep the learning grounded in their actual day-to-day work.

**Their question:** Coach conversation — if you turned push protection on across your real org tomorrow, whose workflow breaks first and what secret would it have caught in your last six months of commits? Talk it through with your coach and connect it to a real project, task, or workflow you own.

> **Bring-your-own grading:** prefer students who ran this on a **real org repo** over the Juice Shop sample. If they used the sample, confirm they can name the actual repo/team they'll roll this out to and any blockers (license, repo visibility). The lasting outcome is the goal; the sample is fallback.

Use these follow-ups to steer the conversation:
- Name a specific repo or team where secrets have historically been committed — what kind (tokens, keys, connection strings)?
- Who would push protection block first, and what would their workaround be if you didn't communicate it in advance?
- What is the one org-wide push protection setting you would enable, and what rollout message would you send to developers?

## Facilitation notes
- **Goal in one line:** the student surfaces and triages every leaked credential in a repo's history, then proves push protection stops the *next* secret before it lands — and can audit who bypassed it.
- **Where students get stuck:**
  - **"Why aren't Juice Shop's own secrets alerting?"** Because they're app-internal, not partner-pattern. The **planted** AWS/GitHub-style secrets are the detection material — point students at `SECRETS-MANIFEST.md`.
  - **Push protection only blocks the *push*, not the commit.** Students commit fine, then are surprised at `git push`. That's expected — the gate is server-side.
  - **Custom-pattern alerts aren't instant.** A custom pattern only scans content pushed *after* it's published (plus a backfill scan that takes a moment). Tell them to push fresh matching content.
  - **Resolution vs deletion.** Resolving an alert doesn't remove the secret from history — in real life they must also **rotate/revoke** the credential. Reinforce that distinction even though the planted ones are non-live.
- **How to unblock without giving the answer:** ask "what makes a secret *detectable* by a partner — what shape does GitHub recognize?" (→ provider prefixes like `AKIA`/`ghp_`), and "where does the block happen — on your machine or on the server?" (→ push protection is server-side).
- **Org-scoped note:** runs with just an org + org-owner token. The Juice Shop import is **public** so **secret scanning and push protection** are free; `admin:org`/`security_events` scope is needed for the security configuration and alerts API. **Note:** **custom patterns (Part D) require GitHub Secret Protection** on an org-owned repo — they are *not* free on public repos. If the org lacks Secret Protection, Part D can't be completed; have students treat it as awareness and grade accordingly.

## Grading rubric (point-weighted, 100 pts)
| Criterion | Points | What "full marks" looks like |
|---|---:|---|
| Enable scanning + push protection (Part A) | 15 | Both features read `enabled` via the `security_and_analysis` API |
| Alert triage backlog (Part B) | 30 | Every planted secret has an alert; all alerts resolved with a correct, explicit reason |
| Push protection demonstrated (Part C) | 25 | A fresh secret is blocked at `git push`; a clean push after removal; one deliberate bypass recorded |
| Custom pattern (Part D) | 15 | A custom pattern is published and raised at least one alert |
| Bypass audit + summary (Part E) | 15 | Bypass surfaced via API with actor + reason; triage-summary issue filed |
| **Total** | **100** | |

## Automated verification hints
Use these to check Definition of Done quickly (prefer `gh` CLI / API over manual clicks):
```bash
ORG=<org>; REPO=wth-ch11-juice-shop   # swap REPO for the student's own repo if they brought one

# Repo exists, public, and scanning + push protection are enabled
gh repo view $ORG/$REPO --json name,visibility
gh api repos/$ORG/$REPO --jq '.security_and_analysis | {secret_scanning, secret_scanning_push_protection}'

# All secret-scanning alerts: count, types, and states (expect planted types present)
gh api repos/$ORG/$REPO/secret-scanning/alerts --paginate --jq '.[] | {number, secret_type, state, resolution}'
gh api repos/$ORG/$REPO/secret-scanning/alerts --paginate --jq 'length'

# No alert should remain open
gh api repos/$ORG/$REPO/secret-scanning/alerts --paginate --jq '.[] | select(.state=="open") | .number'   # expect EMPTY

# Push-protection bypasses (who pushed a secret anyway + why)
gh api repos/$ORG/$REPO/secret-scanning/alerts --paginate \
  --jq '.[] | select(.push_protection_bypassed==true) | {number, secret_type, by: .push_protection_bypassed_by.login}'

# Triage summary issue exists
gh issue list --repo $ORG/$REPO --search "triage summary" --json number,title
```
- **Alert reconciliation:** open `SECRETS-MANIFEST.md` in the repo and confirm each documented plant has a matching `secret_type` in the alerts list. Missing the AWS or GitHub-token alert → not full marks.
- **Push protection:** the truth source is the student demonstrating a blocked `git push` live (or a screenshot of the CLI block). The bypass shows up as `push_protection_bypassed==true` on an alert.
- **Custom pattern:** a custom-pattern alert has a `secret_type` matching the pattern name they created — confirm it's not a built-in type.

## Common pitfalls
- **Expecting Juice Shop's own secrets to alert.** They won't reliably — the planted partner-pattern secrets are the point.
- **Token missing `security_events` / `admin:org`.** Alerts API and security-configuration calls 403. Fix: `gh auth refresh -s security_events,admin:org`.
- **Resolved ≠ removed.** History still contains the secret; in production they must rotate it. Make sure they say so in the summary.
- **Custom pattern published but no alert.** They committed matching content *before* publishing, or didn't push new content after. Push a fresh match.
- **Custom patterns unavailable.** The **Custom patterns** option only appears with **GitHub Secret Protection** enabled on the org — it is not part of the free public-repo feature set. Without it, Part D is awareness-only.
- **Private-repo trap.** If someone re-creates the repo private without a license, scanning silently won't run. Keep it public.

## Useful references for coaching

- [About secret scanning](https://docs.github.com/en/code-security/secret-scanning/about-secret-scanning), [Configuring secret scanning for your repositories](https://docs.github.com/en/code-security/secret-scanning/enabling-secret-scanning-features/enabling-secret-scanning-for-your-repository).

## Teardown
```bash
bash modules/ghec/resources/provisioning/scripts/setup.sh teardown ch11 --org <org> --yes   # Bash
modules/ghec/resources/provisioning/scripts/setup.ps1 teardown ch11 --org <org> --yes  # PowerShell
```
- Removes only `wth-ch11-*` artifacts (prefix-guarded): the imported `wth-ch11-juice-shop` repo (which carries its history, planted secrets, alerts, and custom patterns).
- **Manual cleanup (if any):** none. Deleting the repo removes its alerts and any repo-scoped custom patterns. If a student published a pattern at **org** level (stretch), remove it from the org security settings manually.

## Time budget
- Setup + read manifest: ~30 min
- Part A (enable): ~20 min
- Part B (triage backlog): ~1 hr
- Part C (push protection + bypass): ~1 hr
- Part D (custom pattern): ~30 min
- Part E (audit + summary): ~30 min
- **Total facilitated:** ~4 hrs across sessions.
