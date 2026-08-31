# GHAS Module Setup

The GHAS activities use [OWASP Juice Shop](https://owasp.org/www-project-juice-shop/),
an intentionally vulnerable Node.js application. The module uses two environments:

1. A local Juice Shop runtime for manual exploit testing.
2. An org-owned Juice Shop repository where GitHub Advanced Security (CodeQL, Dependabot, and secret scanning) produces alerts.

Run Juice Shop locally for testing; use the org repository for GHAS features.

## GHAS Target Repository

For Activity S00, a participant, team lead, or organizer creates the GHAS target
in an org they control. Use the shared GHEC provisioning scripts:

```bash
cd modules/ghec/resources/provisioning/scripts
./setup.sh doctor ghas-00 --org <your-org>
./setup.sh provision ghas-00 --org <your-org>
```

PowerShell:

```powershell
cd modules/ghec/resources/provisioning/scripts
./setup.ps1 doctor ghas-00 -Org <your-org>
./setup.ps1 provision ghas-00 -Org <your-org>
```

This creates `<your-org>/ghec-ghas-00-juice-shop`, imports the pinned Juice Shop
release, and commits the CodeQL and Dependabot configuration. It also tries to
enable Actions, code scanning, Dependabot alerts, secret scanning, and push
protection. If that fails, an org owner or repo admin must enable the feature in
Settings → Code security and analysis.

After the repo is ready, add participants or teams under Settings → Collaborators and teams. Participants should clone the org repo and work on personal or team branches. Do not fork it.

## Local Juice Shop Runtime

### Option A: GitHub Codespaces (preferred)

Open the provisioned Juice Shop repo in a Codespace.

1. Open `<your-org>/ghec-ghas-00-juice-shop` on GitHub and click Code → Codespaces → Create codespace on main.
2. Wait for the devcontainer to finish provisioning.
3. Install dependencies and start Juice Shop:
   ```bash
   npm install
   npm start
   ```
4. Open the forwarded port 3000 in your browser for exploit testing.

### Option B: Local Docker

To run Juice Shop locally without cloning the app, use Docker:

```bash
docker run -p 3000:3000 bkimminich/juice-shop
```

### Option C: Organizer-hosted

An organizer can run Juice Shop on a cloud VM and share the URL. Use this
option when participants lack local Docker or need a ready-to-use environment.

## Verification

For a local runtime, open [http://localhost:3000](http://localhost:3000). For Codespaces or an organizer-hosted instance, open the forwarded or hosted URL. Setup is complete when the Juice Shop UI loads.

## Important: GHAS Alerts Run on the Org Repository

- **Local Juice Shop (port 3000):** manual exploit testing and application exploration
- **Org-owned Juice Shop repository:** GHAS alerts, security dashboards, and PR checks

See [`docs/EXTERNAL-REPOS.md`](../../docs/EXTERNAL-REPOS.md) for how Juice Shop and other external dependencies are managed and pinned.
