# Challenge S00 — Environment Setup

## Objectives

By the end of this challenge you will have:

- A working development environment (GitHub Codespaces or local dev container)
- OWASP Juice Shop running on port 3000
- An authenticated `gh` CLI session
- A personal working branch created and pushed to the shared org repo

---

## Prerequisites

- GitHub account
- Basic Git and CLI usage
- GitHub Advanced Security enabled on the shared org repo (organizer pre-configured)
- GitHub Copilot license assigned

> **Branch workflow (not fork):** This module uses a shared org repository. Do **not** fork.
> Clone directly and work on a personal branch. Use `team-{your-team-name}/challenge-work`
> for teams, or `participant/{your-name}` for individual participants.

---

## Option A: GitHub Codespaces (Recommended)

The fastest path — nothing to install locally.

1. Open the org repository your event organizer shared with you on github.com.
2. Click **Code → Codespaces → Create codespace on main**.
3. Wait ~30–60 seconds for the dev container to build and dependencies to install.
4. When the terminal appears, continue to **Create your branch** below.

---

## Option B: Local Dev Container

If you prefer working locally with VS Code and Docker.

1. Install [VS Code](https://code.visualstudio.com/) and the
   [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers).
2. Clone the org repo (do **not** fork it):
   ```bash
   git clone https://github.com/<org>/<repo>.git
   cd <repo>
   ```
3. Open VS Code in the cloned folder. When prompted, click **Dev Containers: Reopen in Container**
   (requires Docker Desktop running).
4. Wait for the container to build, then continue below.

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

## Start Juice Shop

All GHAS challenges work against the OWASP Juice Shop application.

```bash
cd app && npm start
```

Juice Shop will be available at **port 3000**. In Codespaces, GitHub automatically
port-forwards it — click the **Ports** tab and open the forwarded URL. Locally, open
`http://localhost:3000` in your browser.

Confirm you see the Juice Shop storefront before moving on.

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
