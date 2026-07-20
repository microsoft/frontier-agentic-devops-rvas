# Activity S00 — Environment Setup

## Objectives

By the end of this activity, the delivery team will have:

- Selected a real repository or service to govern, or recorded OWASP Juice Shop as the fallback practice target
- Recorded GHAS configuration, scope, and ownership in `modules/ghas/resources/ghas-governance-practice.template.md`
- Defined the in-scope repository or service, its criticality, enabled and missing GHAS capabilities, and accountable roles
- Recorded the repository or service owner, security partner, and delivery team accountable for the baseline
- Recorded initial agentic delivery principles: least privilege; humans remain accountable for approval and merge; and agent-originated changes receive normal GHAS and PR validation
- Recorded access or licensing blockers with an owner and target date
- A Juice Shop repository pushed into an org the team controls when using the fallback
- GHAS features enabled on the target repository, or missing capabilities recorded for follow-up
- Any needed delivery team members manually onboarded to the repository
- A working development environment (GitHub Codespaces or local clone)
- OWASP Juice Shop running on port 3000 (for manual exploit testing)
- An authenticated `gh` CLI session
- A personal or team working branch created and pushed to the org repo

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

## Record GHAS Configuration and Ownership

Before treating setup as complete, create the first governance record in
`modules/ghas/resources/ghas-governance-practice.template.md`. This is delivery
record, not a setup checklist. Record:

- the real repository or service selected for this work, or Juice Shop as the fallback;
- the in-scope repository or service and its criticality;
- which GHAS capabilities are enabled and which remain missing;
- the repository or service owner, security partner, and delivery team accountable;
- the initial agentic delivery principles: least privilege; humans remain accountable
  for approval and merge; and agent-originated changes receive normal GHAS and PR
  validation; and
- every access or licensing blocker, its owner, and its target date.

Use the rest of this activity to complete that record. If the selected real
repository is not ready for hands-on work, use the Juice Shop repository below as the
practice fallback and keep the real repository or service recorded as the delivery
scope.

---

## Create the GHAS Target Repository

Use the provided provisioning script from this curriculum repo. It imports the pinned
OWASP Juice Shop release into your org, commits the CodeQL and Dependabot configuration,
and attempts to enable Actions, code scanning, Dependabot alerts, secret scanning, and
secret scanning push protection.

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

If a feature cannot be enabled by automation because the org lacks the license or the
authenticated user lacks permission, the script prints a warning. In that case, an org
owner or repo admin must enable it manually in **Settings → Code security and analysis**.

After provisioning, manually add any participants who need access:

1. Open `https://github.com/<your-org>/ghec-ghas-00-juice-shop/settings/access`.
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
   git clone https://github.com/<your-org>/ghec-ghas-00-juice-shop.git
   cd ghec-ghas-00-juice-shop
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

All GHAS activities work with OWASP Juice Shop for **manual exploit testing**. Because the setup script imports Juice Shop into your org repo, run the app from the repository root:

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

**GHAS alerts** (CodeQL, Dependabot, secret scanning) run on the **org repository you provisioned in this activity**. All activities reference alerts from that repo, not your local Juice Shop runtime.

See [`modules/ghas/setup.md`](../../setup.md) for details on how these two environments work together.

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

> Successful commands alone do not complete this activity. Before moving on, confirm the
> GHAS configuration and ownership record names the target and criticality, captures GHAS capability status
> and accountable roles, records the agentic delivery principles, and assigns every
> access or licensing blocker an owner and target date. See **Common Blockers** in the
> coach guide when setup cannot yet be completed.

## Success Criteria

- [ ] A real repository or service is selected, or Juice Shop is recorded as the fallback practice target
- [ ] The GHAS configuration and ownership record in `modules/ghas/resources/ghas-governance-practice.template.md` records the in-scope repository or service and its criticality
- [ ] Enabled and missing GHAS capabilities are recorded
- [ ] The repository or service owner, security partner, and delivery team are recorded as accountable roles
- [ ] The baseline records least privilege, human accountability for approval and merge, and normal GHAS and PR validation for agent-originated changes
- [ ] Access or licensing blockers are recorded with an owner and target date
- [ ] The target repository is accessible, GHAS enablement is verified or recorded as missing, and the working branch is pushed
- [ ] The delivery environment is usable: `gh auth status` and `gh repo view` succeed, and Juice Shop loads on port 3000 when using the fallback
