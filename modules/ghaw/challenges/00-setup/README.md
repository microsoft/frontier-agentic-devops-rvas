# Activity 00 — Environment Setup

Estimated time: 30 minutes

## Required outcome

Complete this activity with:

- A working development environment (GitHub Codespaces or local dev container)
- An authenticated `gh` CLI session
- `gh-aw` installed and verified
- Access confirmed to the GHAW delivery session repository

---

## Prerequisites

- GitHub account
- Basic Git and CLI usage

---

## Choose your environment

Follow the [GHAW setup guide](../../setup.md) to open a Codespace or local dev container. Both options install `gh-aw` automatically via `postCreate.sh`. Once your terminal is ready, continue below.

---

## Authenticate the GitHub CLI

Your container does not have your GitHub credentials pre-loaded. Run:

```bash
gh auth login
```

Choose HTTPS, follow the device-code prompt in your browser, and grant the requested permissions.

---

## Verify the setup

Run each command and confirm it exits successfully:

```bash
# 1. CLI version
gh --version

# 2. Authentication
gh auth status

# 3. gh-aw version check
gh aw --version

# 4. Dry-run smoke test
gh aw trial modules/ghaw/resources/examples/hello-world.md --logical-repo microsoft/frontier-agentic-devops-rvas --dry-run --yes
```

> All four commands must succeed before you move on. If `gh aw --version` fails, reinstall it with the command in the [GHAW setup guide](../../setup.md).

`--logical-repo` tells `gh-aw` which repository to simulate, so it doesn't need to infer one from your local Git remote (useful if your clone uses an SSH host alias). See the [GHAW setup guide](../../setup.md) for what trial mode does with write access.
