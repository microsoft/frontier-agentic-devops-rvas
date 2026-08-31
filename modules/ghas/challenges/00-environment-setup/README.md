# Activity S00: Environment Setup

## Objectives

Finish this activity with:

- Select a real repository or service to govern, or record OWASP Juice Shop as the fallback practice target
- Record the target, criticality, GHAS capability status, accountable roles, and access or licensing blockers in `modules/ghas/resources/ghas-governance-practice.template.md`
- Record least privilege, human accountability for approval and merge, and normal GHAS and PR validation for agent-originated changes
- When using the fallback, push a Juice Shop repository into an org the team controls and add the required participants
- Enable GHAS features on the target repository, or record missing capabilities for follow-up
- Prepare a working GitHub Codespaces or local development environment with an authenticated `gh` CLI session
- Run OWASP Juice Shop on port 3000 for manual exploit testing
- Create and push a personal or team working branch to the org repository

---

## Prerequisites

- GitHub account
- Basic Git and CLI usage
- An organization where you can create a repository and enable code security features
- GitHub Advanced Security available for the repository visibility you choose
- GitHub Copilot license assigned

There is no preconfigured Microsoft or instructor repo. A participant, team lead, or
organizer pushes Juice Shop into an org they control, enables GHAS features there,
and adds the participants or teams that need access.

---

## Record GHAS Configuration and Ownership

Before marking setup complete, create the first governance record in
`modules/ghas/resources/ghas-governance-practice.template.md` covering the items
listed in Objectives above. Update the record as you work. If the selected
repository is not ready for hands-on work, use Juice Shop for practice but keep the
real repository or service as the recorded delivery scope.

---

## Create the GHAS Target Repository

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
3. Ask each participant to clone this org repo directly — do not fork it — and work on a personal or team branch.

---

## Option A: GitHub Codespaces (Recommended)

This option requires no local installation.

1. Open the org repository created above on github.com.
2. Click Code → Codespaces → Create codespace on main.
3. Wait ~30–60 seconds for the dev container to build and dependencies to install.
4. When the terminal appears, continue to Create your branch below.

---

## Option B: Local Clone

If you prefer working locally, use Git and Node.js directly.

1. Install [Git](https://git-scm.com/), [GitHub CLI](https://cli.github.com/), and Node.js 20 or later.
2. Clone the org repo:
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

## Create Your Branch

```bash
# For teams
git checkout -b team-{your-team-name}/challenge-work
git push -u origin team-{your-team-name}/challenge-work

# For individual participants
git checkout -b participant/{your-github-handle}
git push -u origin participant/{your-github-handle}
```

---

## Start Juice Shop (Local Runtime)

The GHAS activities use OWASP Juice Shop for manual exploit testing. Run the app
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

## Verify Your Setup

Run each command and use the results to update the GHAS configuration and ownership record:

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

Then open `http://localhost:3000` (or the Codespaces-forwarded URL) and confirm the
Juice Shop homepage loads.

> **Commands alone do not complete this activity.** Confirm the governance record
> is filled in with the target, GHAS capability status, accountable roles, and
> any access or licensing blocker owner and target date.
