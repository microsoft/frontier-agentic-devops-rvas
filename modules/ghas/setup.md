# GHAS module setup

**Use the customer's approved repository and test environment** for GHAS triage
and remediation. If it's ready, skip sample provisioning.
[OWASP Juice Shop](https://owasp.org/www-project-juice-shop/) is the intentionally
vulnerable fallback for safe practice. The module also ships isolated admin fixtures.

The Juice Shop fallback needs two environments:

1. A local Juice Shop runtime for manual exploit testing.
2. An org-owned Juice Shop repository where GitHub Advanced Security (CodeQL, Dependabot, and secret scanning) produces alerts.

## GHAS target repository

Activity S00 creates `<your-org>/ghec-ghas-00-juice-shop` with the shared GHEC
provisioning scripts: it imports the pinned Juice Shop release, commits the CodeQL
and Dependabot configuration, and tries to enable Actions, code scanning, Dependabot
alerts, secret scanning, and push protection. S00 has the commands, the manual
fallback when a feature cannot be enabled, and the steps for adding participants.

Participants clone the org repo and work on personal or team branches. Do not fork it.

## Admin test repositories

Admin activities 01 through 06 use four isolated provisioners. They create separate
repositories for secret protection, CodeQL, and dependency work. Activities 01 and
06 share a security-operations repository, so activity 06 can measure the rollout
you started in activity 01.

Activities 07 and 08 don't ship a provisioner. Activity 07 needs real external
Azure and GitHub infrastructure. Activity 08 reuses Activity 03's pilot repository.
See each activity's README for its prerequisites.

See [`resources/provisioning/README.md`](resources/provisioning/README.md) for the
default repository names and the Bash and PowerShell commands. Run `status` after
each provision command before you start the activity. Provision all four
repositories only if the cohort will do every admin activity.

### Two independent numbering tracks

This module numbers its two tracks separately:

- **Developer Flow** activities use `S00`-`S04`.
- **Admin & Governance** activities use `1`-`8`.

Run either track on its own. An admin activity's prerequisite is another admin
activity (for example, `ghas-admin-03` needs `ghas-admin-01`), not a developer-flow
activity with a similar number.

## Local Juice Shop runtime

S00 runs Juice Shop from a Codespace or a local clone of the org repository. If
that doesn't work for you, use one of these:

### Local Docker

Run Juice Shop without cloning the app:

```bash
docker run -p 3000:3000 bkimminich/juice-shop
```

### Organizer-hosted

An organizer runs Juice Shop on a cloud VM and shares the URL. Use this when
participants lack local Docker or need a ready-made environment.

## Verification

For a local runtime, open [http://localhost:3000](http://localhost:3000). For Codespaces or an organizer-hosted instance, open the forwarded or hosted URL. **Setup is done when the Juice Shop UI loads.**

## Where to test and scan

- Use local Juice Shop on port 3000 for manual exploit testing and application exploration.
- Use the org-owned developer repository for GHAS alerts in activities 00 through 05.
- Use admin fixture repositories for security configuration, secret protection,
  CodeQL enforcement, dependency protection, and campaign evidence.

See [`docs/EXTERNAL-REPOS.md`](../../docs/EXTERNAL-REPOS.md) for how Juice Shop and other external dependencies are managed and pinned.
