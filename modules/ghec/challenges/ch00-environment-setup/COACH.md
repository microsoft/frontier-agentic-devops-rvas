# Coach Guide: Activity 00 — Environment Setup

## Objectives

- Help every participant reach a verified working environment (Codespaces or local dev container).
- Confirm `gh` CLI authentication and org-owner rights before track work begins.
- Surface and resolve access blockers early; apply fallback paths before Activity 01.

---

## Facilitation Hints

- **Push Codespaces first.** If a participant's local setup consumes more than 10 minutes, redirect them to Codespaces — it eliminates tooling issues entirely.
- Ask for a show-of-hands "green terminal" check after the first 10 minutes: "Raise your hand if `gh auth status` shows your username."
- Pair any blocked participant with a working neighbor; one person's network issue should not stall the group.
- If org invitations have not been sent yet, send them now. Participants cannot run `gh org list` or access the repo until they accept. Send invites from **Organization Settings → Members → Invite member** or via `gh api orgs/<org>/invitations`.
- Remind participants to use the **branch workflow, not fork**: `git checkout -b setup/<handle>`. This matters for the org-scoped provisioning scripts in later activities.

---

## Common Blockers & Fixes

| Symptom | Cause | Fix |
|---|---|---|
| `gh auth status` fails with "not logged in" | Not authenticated | Run `gh auth login`, choose HTTPS, complete the device-code flow |
| `gh org list` returns empty or missing org | Not yet a member, or invitation not accepted | Coach sends/resends org invitation; participant accepts via email or notification bell |
| `gh repo view` returns 404 | Not added to the org team that has repo access | Coach adds participant to the correct team under **Org Settings → Teams** |
| Codespace build times out or fails | Network quota, billing limit, or Docker image pull failure | Retry once; if it fails again, fall back to local dev container |
| `gh --version` not found (local setup) | `gh` not installed | Install from [cli.github.com](https://cli.github.com/); or use Codespaces instead |
| Dev container fails to open locally | Docker not running, or Dev Containers extension not installed | Start Docker Desktop; install the [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) |
| `./scripts/setup.sh` permission denied | Script not executable | Run `chmod +x ./scripts/setup.sh` |
| Token missing `read:org` scope | `gh auth login` granted fewer than required scopes | Re-run `gh auth login` and explicitly grant `read:org`; or run `gh auth refresh -s read:org` |

---

## Success Check

Before releasing the group to Activity 01, confirm per participant:

- [ ] `gh auth status` exits 0 and shows the correct GitHub username
- [ ] `gh --version` returns `gh version 2.x.x` (>= 2.0.0)
- [ ] `gh org list` lists the delivery session organization
- [ ] `gh repo view <org>/<repo>` returns repository metadata without error
- [ ] Participant is on a personal branch (`git branch` shows `setup/<handle>` or equivalent)

---

## Access-Blocked Fallback

Apply the smallest unblock first:

1. **Codespaces quota / billing:** Switch to local dev container, or request the org owner to enable Codespaces billing for the participant's account under **Enterprise/Org Settings → Codespaces**.
2. **Org access not granted:** Coach adds participant to the org directly and grants access to the relevant team. If org provisioning is genuinely blocked (e.g. SCIM/EMU policy), coach screen-shares an org-owner session for Activity 01 while the access issue is escalated.
3. **Token scope issues:** Run `gh auth refresh -s repo,read:org` to add missing scopes without a full re-login.
4. **No internet / firewall blocks GitHub.com:** Coordinate with the event network team. As a last resort, coach provides a read-only export of the repository so the participant can follow along with the activity content while access is restored.

> **EMU orgs:** All GHEC activities (including ch00) are EMU-compatible. If the org is EMU-managed, participants authenticate via their enterprise IdP — the `gh auth login` flow will redirect to the SAML SSO endpoint automatically once the participant enters their org name.
