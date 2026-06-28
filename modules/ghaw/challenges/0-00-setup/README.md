# Challenge 00 — Environment Setup

## Objectives

By the end of this challenge you will have:

- A working development environment (GitHub Codespaces or local dev container)
- An authenticated `gh` CLI session
- `gh-aw` installed and verified
- Access confirmed to the GHAW hackathon repository

---

## Prerequisites

- GitHub account
- Basic Git and CLI usage

---

## Option A: GitHub Codespaces (Recommended)

1. Open **this repository** (`microsoft/frontier-agenticdevops-hackathon`) on GitHub.
2. Click **Code → Codespaces → Create codespace on main**.
3. Wait ~30 seconds for the dev container to build.
   The `postCreate.sh` script installs `gh-aw` automatically.
4. When the terminal appears, continue to **Authenticate the GitHub CLI** below.

---

## Option B: Local Dev Container

1. Install [VS Code](https://code.visualstudio.com/) and the [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers).
2. Clone this repository (if you haven't already):
   ```bash
   git clone https://github.com/microsoft/frontier-agenticdevops-hackathon.git
   cd frontier-agenticdevops-hackathon
   ```
3. Open VS Code in the cloned folder and choose **Dev Containers: Reopen in Container**.
4. Wait for the container to build — `postCreate.sh` installs `gh-aw` automatically.
5. Continue below.

---

## Authenticate the GitHub CLI

Your container does not have your GitHub credentials pre-loaded. Run:

```bash
gh auth login
```

Choose **HTTPS**, follow the device-code prompt in your browser, and grant the requested permissions.

Verify:
```bash
gh auth status
```

---

## Verify Your Setup

Run each command and confirm it exits successfully:

```bash
# 1. CLI version
gh --version

# 2. Authentication
gh auth status

# 3. gh-aw version check
gh aw --version

# 4. Dry-run smoke test
gh aw trial modules/ghaw/resources/examples/hello-world.md --dry-run
```

> All four commands must succeed before you move on. If any fail, see **Common Blockers** in the coach guide.

### Per-module verification

| Command | Expected output |
|---|---|
| `gh aw --version` | Returns a version string (e.g., `gh-aw version 1.x.x`) |
| `gh aw trial modules/ghaw/resources/examples/hello-world.md --dry-run` | Previews the workflow without executing it; exits 0 |

---

## Next Step

Environment confirmed → proceed to **[Challenge 1-01 — Morning Briefing](../1-01-morning-briefing/README.md)**.
