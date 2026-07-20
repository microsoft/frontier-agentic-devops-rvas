# Coach Guide: Activity S00 — Environment Setup

## Objectives

- Facilitate a GHAS configuration and ownership record in `modules/ghas/resources/ghas-governance-practice.template.md`, not merely a completed setup.
- Help the delivery team select a real repository or service, or explicitly use Juice Shop as the fallback practice target.
- Ensure the baseline records scope and criticality, enabled and missing GHAS capabilities, and the repository or service owner, security partner, and delivery team.
- Ensure the baseline records least privilege, human accountability for approval and merge, and normal GHAS and PR validation for agent-originated changes.
- Ensure the GHAS target repository is created in a participant/team/organizer-owned org, not a Microsoft-provided shared repo.
- Verify GHAS enablement, access, `gh` authentication, branch creation, and the Codespaces or local environment; validate Juice Shop on port 3000 when used as the fallback.
- Surface access and licensing blockers early, assign each an owner and target date, and apply fallback paths before Activity S01.

---

## Facilitation Hints

- **Push Codespaces first.** If local setup consumes more than 10 minutes, redirect to Codespaces.
- Start with the GHAS configuration and ownership record. Ask which real repository or service is in scope, why its criticality matters, and whether Juice Shop is only the fallback practice target.
- Ask for a show-of-hands check after the first 10 minutes: successful commands and a completed record with named owners.
- Pair any blocked participant with a working neighbor; one blocker should not stall the group.
- Start by having the responsible participant, team lead, or organizer run:
  `./setup.sh provision ghas-00 --org <org>` or `./setup.ps1 provision ghas-00 -Org <org>`.
- Verify that **Codespaces is enabled for the org** before the event starts (org Settings → Codespaces → Allow for all members). If not enabled, participants see no Codespace option.
- If Copilot is not yet licensed for all participants, pair them so every team still practices the Copilot-assisted review loop in S01–S06.
- Confirm **GHAS is enabled** on the provisioned org repo (Settings → Code security and analysis). CodeQL, secret scanning, Dependabot alerts, and push protection must all be on — S01–S06 depend on them.
- Confirm the repository access list includes every participant or team that needs to push a branch. The script creates/configures the repo; it does not guess workshop roster membership.
- Do not accept a feature toggle or a running storefront as completion by itself. Validate that enabled and missing GHAS capabilities, accountable roles, agentic delivery principles, and blocker ownership and dates are recorded in the baseline.
- When discussing agentic delivery, keep the scope to the documented principles: least privilege; humans remain accountable for approval and merge; and agent-originated changes receive normal GHAS and PR validation.

---

## Common Blockers & Fixes

| Symptom | Cause | Fix |
|---|---|---|
| `gh auth status` fails | Not logged in | Run `gh auth login` again; choose HTTPS |
| Codespace build times out | Network / quota | Retry once; fall back to local clone |
| `npm start` fails | Node deps not installed | Run `npm install` from the Juice Shop repo root first, then `npm start` |
| Port 3000 not accessible in Codespace | Port not forwarded | Open Ports tab in VS Code; forward port 3000 manually if needed |
| Branch push rejected | Branch protection misconfigured | Check that push protection only blocks `main`, not participant branches |
| Org repo not accessible | Participant not added to repo/org | Add participant or team under repo Settings → Collaborators and teams; or provide read-only clone baseline |
| Codespaces option missing | Codespaces not enabled for org | Enable under org Settings → Codespaces before the event |
| Juice Shop shows only `Cannot GET /` | App started from wrong directory or partial install | Ensure the participant is in the provisioned Juice Shop repo root and rerun `npm install && npm start` |
| GHAS setup script warns on feature enablement | Missing license or insufficient admin permission | Have an org owner or repo admin enable the feature manually in Settings → Code security and analysis |

---

## Success Check

Before releasing the group to Activity S01, validate the following evidence with the
delivery team:

- [ ] A real repository or service is selected, or Juice Shop is recorded as the fallback practice target
- [ ] `modules/ghas/resources/ghas-governance-practice.template.md` records the in-scope repository or service and its criticality
- [ ] Enabled and missing GHAS capabilities are recorded
- [ ] The repository or service owner, security partner, and delivery team are recorded as accountable roles
- [ ] The GHAS configuration and ownership record includes least privilege, human accountability for approval and merge, and normal GHAS and PR validation for agent-originated changes
- [ ] Access or licensing blockers are recorded with an owner and target date
- [ ] The target repository is accessible, GHAS enablement is verified or recorded as missing, and the working branch is pushed
- [ ] The delivery environment is usable: `gh auth status` and `gh repo view` succeed, and Juice Shop loads on port 3000 when using the fallback

---

## Access-Blocked Fallback

If a participant cannot reach the full environment, apply the smallest unblock:

1. **Codespaces quota:** Use a local clone with Node.js installed, or request org Codespaces billing before the event.
2. **Org access:** Coach adds participant to the repo or org team, or provides a pre-cloned repo baseline branch via `git bundle`.
3. **Juice Shop unavailable (Docker blocked locally, Codespace quota exhausted):**
   - Participants can still complete S01–S06 review steps by reading the pre-populated alert corpus in the Security tab — no live app required for the code-review loop.
   - Coach provides a **pre-scanned results packet**: export of CodeQL SARIF results + Dependabot alert JSON + secret scanning summary so participants can proceed with the analysis tasks even without a running app.
   - For fixes: participants write and submit PRs; CodeQL runs on the PR branch in GitHub Actions and validates the fix without needing a local running instance.
4. **GitHub Actions / CodeQL not running:** Coach triggers a manual workflow run (`gh workflow run codeql.yml`) or shares pre-generated SARIF results for the alert-reading portion.

## Useful references for coaching

- [Codespaces quickstart](https://docs.github.com/en/codespaces/getting-started/quickstart), [GitHub CLI manual](https://cli.github.com/manual/).
