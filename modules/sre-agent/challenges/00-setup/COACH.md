# Coach Guide: Challenge 00 — Environment Setup

## Objectives

- Help every participant reach a verified working environment (Codespaces or local dev container).
- Confirm `gh` CLI authentication, Azure CLI authentication, and the Contoso Claims baseline app smoke test before track work begins.
- Establish team roles and a starter context artifact visible in the repository.
- Surface and document access blockers early; apply fallback paths before Challenge 01.

---

## Facilitation Hints

- **Push Codespaces first.** The dev container pre-installs everything (Node 22, Azure CLI, Bicep, GitHub Copilot). If local setup consumes more than 10 minutes, redirect to Codespaces.
- Ask for a show-of-hands "green terminal" check after the first 10 minutes: `gh auth status` and `az account show` should both succeed.
- Pair any participant who is blocked with a working neighbor; don't let one access blocker stall the group.
- If Copilot is not enabled for all participants, pair so every team still practices the prompt-review-validation loop.
- If Azure access is blocked entirely, distribute the fallback deployment evidence packet and keep teams on the GitHub-side tasks (issues, PRs, SDLC baseline).
- Remind teams: the starter context note should be small and in the repo — not a long doc, not in chat.

---

## Common Blockers & Fixes

| Symptom | Cause | Fix |
|---|---|---|
| `gh auth status` fails | Not logged in | Run `gh auth login` again; choose HTTPS |
| Codespace build times out | Network / quota | Retry once; fall back to local dev container |
| `az login` device code doesn't open | Corp proxy / blocked browser | Use `az login --use-device-code`; copy URL manually |
| `az account show` returns no subscription | Azure access not yet provisioned | Coach distributes the fallback deployment evidence packet |
| `az account show` shows wrong subscription | Multiple subs on the account | Run `az account set --subscription "<name>"` |
| `npm test` fails in `modules/sre-agent/resources/sample-app/` | `npm install` not run | Run `npm install` first, then `npm test` |
| `npm test` fails after install | Node version < 20 | Rebuild container; local: use `nvm use 22` |
| Org repo not accessible | Not added to org | Coach adds participant to org team; or provides read-only clone for the session |

---

## Success Check

Before releasing the group to Challenge 01, confirm per participant (or pair):

- [ ] `gh auth status` exits 0 and shows the correct username
- [ ] `az account show` returns the correct subscription with `state: Enabled`
- [ ] `gh repo view microsoft/frontier-agenticdevops-hackathon` succeeds
- [ ] `cd modules/sre-agent/resources/sample-app && npm test` passes
- [ ] Repository is open and writable (or readable with a documented fallback)
- [ ] Azure subscription confirmed or fallback evidence packet distributed

---

## Team Launch — Coach Checkpoints

After environment setup, verify the team launch deliverables:

- Ask each team to show their team context artifact (issue, project note, or repo file).
- Confirm at least one human is named for each role: architect, reviewer, escalation handler, operator.
- The context artifact must include at least one safety boundary and one review rule.
- Decide whether any team needs a coach-provided baseline branch before Challenge 01.

---

## Access-Blocked Fallback

If a participant cannot reach the environment, apply the smallest unblock:

1. **Codespaces quota:** Use local dev container or request org Codespaces billing increase.
2. **Org access:** Coach adds participant to org team, or provides a pre-cloned repo baseline branch.
3. **Azure subscription blocked:** Coach provides the pre-built deployment evidence packet:
   - Azure deployment logs (stdout from a passing `az deployment group create` run)
   - Incident packet (pre-generated Azure SRE Agent investigation notes and alert JSON)
   - Participant drives decisions and reviews without direct Azure console access.
4. **All paths blocked:** Coach screen-shares org-owner session for Challenge 00 while participant drives decisions. Unblock access asynchronously and re-run environment setup before Challenge 04 (Azure deploy).
