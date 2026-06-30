# Challenge S00 — Environment Setup

## Objectives

By the end of this challenge you will have:

- A Juice Shop repository pushed into an org you control
- GitHub Advanced Security features enabled on that repo
- Any needed participants manually onboarded to that repo
- A working development environment (GitHub Codespaces or local clone)
- OWASP Juice Shop running on port 3000 (for manual exploit testing)
- An authenticated `gh` CLI session
- A personal working branch created and pushed to the org repo

---

## Prerequisites

- GitHub account
- Basic Git and CLI usage
- An organization where you can create a repository and enable code security features
- GitHub Advanced Security available for the repository visibility you choose
- GitHub Copilot license assigned

> **Own-org workflow:** Do not rely on a preconfigured Microsoft or instructor repo.
> A participant, team lead, or organizer pushes Juice Shop into an org they control,
> enables GHAS features there, then manually adds any participants or teams that need
> repo access.

---

## Create the GHAS Target Repository

Use the provided provisioning script from this curriculum repo. It imports the pinned
OWASP Juice Shop release into your org, commits the CodeQL and Dependabot configuration,
and attempts to enable Actions, code scanning, Dependabot alerts, secret scanning, and
secret scanning push protection.

### macOS/Linux/Git Bash

```bash
cd modules/ghec/resources/provisioning/scripts
./setup.sh doctor ghas-s00 --org <your-org>
./setup.sh provision ghas-s00 --org <your-org>
./setup.sh status ghas-s00 --org <your-org>
```

### PowerShell

```powershell
cd modules/ghec/resources/provisioning/scripts
./setup.ps1 doctor ghas-s00 -Org <your-org>
./setup.ps1 provision ghas-s00 -Org <your-org>
./setup.ps1 status ghas-s00 -Org <your-org>
```

The default repository name is:

```text
<your-org>/wth-ghas-s00-juice-shop
```

If a feature cannot be enabled by automation because the org lacks the license or the
authenticated user lacks permission, the script prints a warning. In that case, an org
owner or repo admin must enable it manually in **Settings → Code security and analysis**.

After provisioning, manually add any participants who need access:

1. Open `https://github.com/<your-org>/wth-ghas-s00-juice-shop/settings/access`.
2. Add the participant, team, or outside collaborator with the access level your event needs.
3. Ask each participant to clone this org repo directly and work on a personal or team branch.

> **Branch workflow (not fork):** This module uses the org repo you just created. Do **not** fork.
> Clone directly and work on a personal branch. Use `team-{your-team-name}/challenge-work`
> for teams, or `participant/{your-name}` for individual participants.

---

## Option A: GitHub Codespaces (Recommended)

The fastest path — nothing to install locally.

1. Open the org repository created above on github.com.
2. Click **Code → Codespaces → Create codespace on main**.
3. Wait ~30–60 seconds for the dev container to build and dependencies to install.
4. When the terminal appears, continue to **Create your branch** below.

---

## Option B: Local Clone

If you prefer working locally, use Git and Node.js directly.

1. Install [Git](https://git-scm.com/), [GitHub CLI](https://cli.github.com/), and Node.js 20 or later.
2. Clone the org repo (do **not** fork it):
   ```bash
   git clone https://github.com/<your-org>/wth-ghas-s00-juice-shop.git
   cd wth-ghas-s00-juice-shop
   ```
3. Continue below.

---

## Authenticate the GitHub CLI

Your container does not have your GitHub credentials pre-loaded. Run:

```bash
gh auth login
```

Choose **HTTPS**, follow the device-code prompt in your browser, and grant the requested
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

All GHAS challenges work with OWASP Juice Shop for **manual exploit testing**. Because the setup script imports Juice Shop into your org repo, run the app from the repository root:

```bash
npm install
npm start
```

Juice Shop will be available at **port 3000**. In Codespaces, GitHub automatically
port-forwards it — click the **Ports** tab and open the forwarded URL. Locally, open
`http://localhost:3000` in your browser.

Confirm you see the Juice Shop storefront before moving on.

---

## Important: GHAS Alerts vs. Local Runtime

**Your local Juice Shop instance** is for manual testing and learning the app — it has **no GHAS alerts**. 

**GHAS alerts** (CodeQL, Dependabot, secret scanning) run on the **org repository you provisioned in this challenge**. All challenges reference alerts from that repo, not your local Juice Shop runtime.

See [`modules/ghas/setup.md`](../../setup.md) for details on how these two environments work together.

---

## Verify Your Setup

Run each command and confirm it succeeds:

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

> All checks must pass before you move on. If any fail, see **Common Blockers** in
> the coach guide.

---

## Next Step

Environment confirmed → proceed to **[S01 — Explore the Attack Surface](../s01-explore-attack-surface/README.md)**.
