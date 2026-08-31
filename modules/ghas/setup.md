# GHAS Module Setup

The GHAS activities use [OWASP Juice Shop](https://owasp.org/www-project-juice-shop/),
an intentionally vulnerable Node.js application. The module uses two environments:

1. A local Juice Shop runtime for manual exploit testing.
2. An org-owned Juice Shop repository where GitHub Advanced Security (CodeQL, Dependabot, and secret scanning) produces alerts.

Run Juice Shop locally for testing; use the org repository for GHAS features.

## GHAS Target Repository

Activity S00 creates `<your-org>/ghec-ghas-00-juice-shop` with the shared GHEC
provisioning scripts: it imports the pinned Juice Shop release, commits the CodeQL
and Dependabot configuration, and tries to enable Actions, code scanning, Dependabot
alerts, secret scanning, and push protection. S00 has the commands, the manual
fallback when a feature cannot be enabled, and the steps for adding participants.

Participants clone the org repo and work on personal or team branches. Do not fork it.

## Local Juice Shop Runtime

S00 runs Juice Shop from a Codespace (or a local clone) on the org repository. Two
alternatives when that is not practical:

### Local Docker

Runs Juice Shop without cloning the app:

```bash
docker run -p 3000:3000 bkimminich/juice-shop
```

### Organizer-hosted

An organizer can run Juice Shop on a cloud VM and share the URL. Use this
option when participants lack local Docker or need a ready-to-use environment.

## Verification

For a local runtime, open [http://localhost:3000](http://localhost:3000). For Codespaces or an organizer-hosted instance, open the forwarded or hosted URL. Setup is complete when the Juice Shop UI loads.

## Important: GHAS Alerts Run on the Org Repository

- **Local Juice Shop (port 3000):** manual exploit testing and application exploration
- **Org-owned Juice Shop repository:** GHAS alerts, security dashboards, and PR checks

See [`docs/EXTERNAL-REPOS.md`](../../docs/EXTERNAL-REPOS.md) for how Juice Shop and other external dependencies are managed and pinned.
