# Delivery Assurance Guide: Activity 00 — Environment Setup

## Customer implementation intent

- Prepare an authorized customer implementation owner to work safely in the target tenant (Codespaces or a local dev container).
- Verify `gh` CLI authentication and org-owner rights before any tenant implementation begins.
- Resolve access blockers early, record the accountable owner, and use a controlled fallback only when it leads to a documented tenant-adoption decision.

---

## Delivery assurance checks

- Prefer the authorized customer tenant. If local setup takes more than 10 minutes, use Codespaces where the customer has approved it; it reduces tooling variance without bypassing tenant controls.
- Confirm that `gh auth status` shows the authorized implementation owner's username and that the target organization is correct before continuing.
- Escalate blocked access to the customer access owner rather than sharing accounts or credentials.
- If an organization invitation is pending, have the authorized org owner send or resend it from Organization Settings → Members → Invite member or with `gh api orgs/<org>/invitations`.
- Use the branch workflow, not a fork: `git checkout -b setup/<handle>`. This preserves the org-scoped provisioning model used later.

---

## Common Blockers & Fixes

| Symptom | Cause | Fix |
|---|---|---|
| `gh auth status` fails with "not logged in" | Not authenticated | Run `gh auth login`, choose HTTPS, complete the device-code flow |
| `gh org list` returns empty or missing org | Not yet a member, or invitation not accepted | Authorized org owner sends/resends the invitation; implementation owner accepts via email or notification bell |
| `gh repo view` returns 404 | Not added to the org team that has repo access | Authorized org owner adds the implementation owner to the correct team under Org Settings → Teams |
| Codespace build times out or fails | Network quota, billing limit, or Docker image pull failure | Retry once; if it fails again, fall back to local dev container |
| `gh --version` not found (local setup) | `gh` not installed | Install from [cli.github.com](https://cli.github.com/); or use Codespaces instead |
| Dev container fails to open locally | Docker not running, or Dev Containers extension not installed | Start Docker Desktop; install the [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) |
| `./scripts/setup.sh` permission denied | Script not executable | Run `chmod +x ./scripts/setup.sh` |
| Token missing `read:org` scope | `gh auth login` granted fewer than required scopes | Re-run `gh auth login` and explicitly grant `read:org`; or run `gh auth refresh -s read:org` |

---

## Customer-owned implementation evidence

Before proceeding, confirm with the customer implementation owner:

- [ ] `gh auth status` exits 0 and shows the correct GitHub username
- [ ] `gh --version` returns `gh version 2.x.x` (>= 2.0.0)
- [ ] `gh org list` lists the delivery session organization
- [ ] `gh repo view <org>/<repo>` returns repository metadata without error
- [ ] Implementation owner is on a personal branch (`git branch` shows `setup/<handle>` or equivalent)

---

## Access-Blocked Fallback

Apply the smallest unblock first:

1. Codespaces quota / billing: Switch to a local dev container, or request the org owner to enable Codespaces billing for the implementation owner's account under Enterprise/Org Settings → Codespaces.
2. Org access not granted: The authorized org owner adds the implementation owner to the relevant team. If provisioning is genuinely blocked (e.g. SCIM/EMU policy), use an authorized org-owner screen share for Activity 01 while the access issue is escalated.
3. Token scope issues: Run `gh auth refresh -s repo,read:org` to add missing scopes without a full re-login.
4. No internet / firewall blocks GitHub.com: Coordinate with the customer's network owner. As a last resort, use a read-only repository export as a sample test repository or environment; record the target tenant, access blocker, accountable owner, and explicit decision to adopt, defer, or roll out once access is restored.

> EMU orgs: All GHEC activities (including ch00) are EMU-compatible. If the org is EMU-managed, implementation owners authenticate via their enterprise IdP — the `gh auth login` flow redirects to the SAML SSO endpoint after they enter their org name.
