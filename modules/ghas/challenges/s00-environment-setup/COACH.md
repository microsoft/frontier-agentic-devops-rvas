# Coach Guide: Challenge S00 — Environment Setup

## Objectives

- Help every participant reach a verified working environment (Codespaces or local dev container).
- Confirm `gh` CLI authentication, working branch creation, and Juice Shop running on port 3000.
- Surface and document access blockers early; apply fallback paths before Challenge S01.

---

## Facilitation Hints

- **Push Codespaces first.** If local setup consumes more than 10 minutes, redirect to Codespaces.
- Ask for a show-of-hands "green terminal + Juice Shop storefront" check after the first 10 minutes.
- Pair any blocked participant with a working neighbor; one blocker should not stall the group.
- Verify that **Codespaces is enabled for the org** before the event starts (org Settings → Codespaces → Allow for all members). If not enabled, participants see no Codespace option.
- If Copilot is not yet licensed for all participants, pair them so every team still practices the Copilot-assisted review loop in S01–S06.
- Confirm **GHAS is enabled** on the org repo (Settings → Code security and analysis). CodeQL, secret scanning, Dependabot, and push protection must all be on — these are the backbone of S01–S06.

---

## Common Blockers & Fixes

| Symptom | Cause | Fix |
|---|---|---|
| `gh auth status` fails | Not logged in | Run `gh auth login` again; choose HTTPS |
| Codespace build times out | Network / quota | Retry once; fall back to local dev container |
| `npm start` fails in `app/` | Node deps not installed | Run `npm install` in `app/` first, then `npm start` |
| Port 3000 not accessible in Codespace | Port not forwarded | Open Ports tab in VS Code; forward port 3000 manually if needed |
| Branch push rejected | Branch protection misconfigured | Check that push protection only blocks `main`, not participant branches |
| Org repo not accessible | Participant not added to org | Add participant to org team (Settings → Members); or provide read-only clone baseline |
| Codespaces option missing | Codespaces not enabled for org | Enable under org Settings → Codespaces before the event |
| Juice Shop shows only `Cannot GET /` | App started from wrong directory | Ensure `cd app` before `npm start` |

---

## Success Check

Before releasing the group to Challenge S01, confirm per participant:

- [ ] `gh auth status` exits 0 and shows the correct username
- [ ] `git push` for their branch succeeded (no "rejected" errors)
- [ ] Juice Shop homepage loads at port 3000 (Codespace forwarded URL or localhost)
- [ ] `gh repo view` returns repo metadata without error
- [ ] GHAS alerts visible in the repo Security tab (confirms GHAS is enabled and first scan ran)

---

## Access-Blocked Fallback

If a participant cannot reach the full environment, apply the smallest unblock:

1. **Codespaces quota:** Use local dev container (VS Code + Docker Desktop), or request org Codespaces billing before the event.
2. **Org access:** Coach adds participant to org team, or provides a pre-cloned repo baseline branch via `git bundle`.
3. **Juice Shop unavailable (Docker blocked locally, Codespace quota exhausted):**
   - Participants can still complete S01–S05 review steps by reading the pre-populated alert corpus in the Security tab — no live app required for the code-review loop.
   - Coach provides a **pre-scanned results packet**: export of CodeQL SARIF results + Dependabot alert JSON + secret scanning summary so participants can proceed with the analysis tasks even without a running app.
   - For fixes: participants write and submit PRs; CodeQL runs on the PR branch in GitHub Actions and validates the fix without needing a local running instance.
4. **GitHub Actions / CodeQL not running:** Coach triggers a manual workflow run (`gh workflow run codeql.yml`) or shares pre-generated SARIF results for the alert-reading portion.

## Useful references for coaching

- [Codespaces quickstart](https://docs.github.com/en/codespaces/getting-started/quickstart), [GitHub CLI manual](https://cli.github.com/manual/).

