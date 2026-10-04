# Activity S00: Prepare the remediation repository

**Session outcome:** You can test changes in the approved repository and read its security alerts. Access or licensing gaps have owners.

## Objectives

Complete these steps:

- Reuse the customer repository selected for this engagement. Use OWASP Juice Shop when you need a separate practice repository
- Check repository ownership and security settings. Record only missing decisions or access blockers
- Confirm least privilege and human review for all changes, including agent-authored changes
- When using the fallback, push a Juice Shop repository into an org the team controls and add the required participants
- Enable GHAS features on the target repository, or record missing capabilities for follow-up
- Prepare a working GitHub Codespaces or local development environment with an authenticated `gh` CLI session
- Run the selected application's tests; start Juice Shop on port 3000 only for the fallback
- Create and push a personal or team working branch to the org repository

> [!NOTE]
> Continue here for alert triage and hands-on remediation. If
> you own organization rollout, licensing, or policy controls, start with
> [Security configuration pilot and rollout](../01-admin-security-configuration-pilot-rollout/README.md).

---

## Prerequisites

- GitHub account
- Basic Git and CLI usage
- Access to the approved repository, or an organization for an isolated practice repository
- GitHub Advanced Security available for the repository visibility you choose
- GitHub Copilot license only when using Copilot assistance

For an existing repository, skip provisioning and Juice Shop startup. Use its
approved development environment and test commands for triage and remediation.

For the fallback, an organizer imports Juice Shop into an org they control and
grants participant access. Do not introduce vulnerable fixtures into a customer repository.

---

## Check existing ownership and controls

Use the team's existing GitHub work and ownership records. The
[optional gap template](../../resources/ghas-governance-practice.template.md) covers
missing decisions without creating a second tracker.
If the customer repository is blocked, label Juice Shop results **practice** and
record who will resolve the blocker and when to retest.

---

## Fallback only: create the GHAS target repository

Use the provisioning script in this curriculum repo. It imports the pinned OWASP
Juice Shop release into your org and commits the CodeQL and Dependabot configuration.
It then tries to enable Actions, code scanning, Dependabot alerts, secret scanning,
and secret scanning push protection.

### macOS/Linux/Git Bash

```bash
cd modules/ghec/resources/provisioning/scripts
./setup.sh doctor ghas-00 --org <your-org>
./setup.sh provision ghas-00 --org <your-org>
./setup.sh status ghas-00 --org <your-org>
```

### PowerShell

```powershell
cd modules/ghec/resources/provisioning/scripts
./setup.ps1 doctor ghas-00 -Org <your-org>
./setup.ps1 provision ghas-00 -Org <your-org>
./setup.ps1 status ghas-00 -Org <your-org>
```

The default repository name is:

```text
<your-org>/ghec-ghas-00-juice-shop
```

If the org lacks a license or the authenticated user lacks permission, the script
prints a warning. An org owner or repo admin must then enable the feature in
Settings → Code security and analysis.

After provisioning, manually add any participants who need access:

1. Open `https://github.com/<your-org>/ghec-ghas-00-juice-shop/settings/access`.
2. Add the participant, team, or outside collaborator with the access level your event needs.
3. Ask each participant to clone this org repo directly and work on a personal or team branch. Do not fork it.

---

## Option A: GitHub Codespaces

This option requires no local installation.

1. Open the selected org repository on github.com.
2. Click Code → Codespaces → Create codespace on main.
3. Wait ~30–60 seconds for the dev container to build and dependencies to install.
4. When the terminal appears, continue to Create your branch below.

---

## Option B: Local clone

If you prefer working locally, use Git and Node.js directly.

1. Install [Git](https://git-scm.com/), [GitHub CLI](https://cli.github.com/), and Node.js 20 or later.
2. Clone the selected org repo. For the fallback:
   ```bash
   git clone https://github.com/<your-org>/ghec-ghas-00-juice-shop.git
   cd ghec-ghas-00-juice-shop
   ```
3. Continue below.

If neither option works, [`modules/ghas/setup.md`](../../setup.md) covers the Docker
and organizer-hosted runtimes.

---

## Authenticate the GitHub CLI

Your container does not have your GitHub credentials. Run:

```bash
gh auth login
```

Choose HTTPS, follow the device-code prompt in your browser, and grant the requested
permissions.

Verify:

```bash
gh auth status
```

---

## Create your branch

```bash
# For teams
git checkout -b team-{your-team-name}/challenge-work
git push -u origin team-{your-team-name}/challenge-work

# For individual participants
git checkout -b participant/{your-github-handle}
git push -u origin participant/{your-github-handle}
```

---

## Fallback only: start Juice Shop locally

The fallback uses OWASP Juice Shop for manual exploit testing. Run the app
from the root of the repository created by the setup script:

```bash
npm install
npm start
```

Juice Shop runs on port 3000. In Codespaces, GitHub forwards the port
automatically. Open the Ports tab and select the forwarded URL. Locally, open
`http://localhost:3000` in your browser.

Confirm you see the Juice Shop storefront before moving on. This local instance is
for manual exploit testing only: CodeQL, Dependabot, and secret scanning alerts run
on the org repository. See [`modules/ghas/setup.md`](../../setup.md) for how the two
environments work together.

---

## Verify your setup

Run these checks in the selected repository:

```bash
# 1. CLI version
gh --version

# 2. Authentication
gh auth status

# 3. Repository access
gh repo view

# 4. Branch is pushed
git status
git log --oneline -1
```

Run the repository's tests and confirm access to the security alerts needed for
your selected case. For the fallback, also confirm the Juice Shop homepage loads.

> Link the evidence for each control and assign unresolved blockers to an owner.
> A working local app does not prove GitHub scanning is enabled.

## Choose the next fix

Use the [remediation checklist](../../resources/start-remediation.md) inside the case that matches your finding. You can start with injection, XSS, or authorization. Credential response and tested dependency updates use their corresponding security-control sessions. There is no separate triage exercise to complete first.
