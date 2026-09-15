# GHAS Module Setup

The GHAS developer activities use
[OWASP Juice Shop](https://owasp.org/www-project-juice-shop/), an intentionally
vulnerable Node.js application. The module also includes separate remote fixtures
for the Admin & Governance track.

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

## Admin & Governance fixtures

Admin activities use four isolated provisioners. They create distinct repositories
for secret protection, CodeQL, and dependency work. Activities 01 and 06 share a
security-operations repository so activity 06 can measure the rollout started in
activity 01.

See [`resources/provisioning/README.md`](resources/provisioning/README.md) for the
default repository names and the Bash and PowerShell commands. Run `status` after
each provision command before starting the activity. Do not provision all four
fixtures unless the cohort will use every admin activity.

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

## Important: GHAS alerts run on GitHub repositories

- **Local Juice Shop (port 3000):** manual exploit testing and application exploration
- **Org-owned developer repository:** GHAS alerts for activities 00 through 06
- **Admin fixture repositories:** security configuration, secret protection,
  CodeQL enforcement, dependency protection, and campaign evidence

See [`docs/EXTERNAL-REPOS.md`](../../docs/EXTERNAL-REPOS.md) for how Juice Shop and other external dependencies are managed and pinned.
