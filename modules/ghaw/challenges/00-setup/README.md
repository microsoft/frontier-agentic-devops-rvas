# Activity 00: Environment setup

**Session outcome:** You can access the GHAW delivery session repository from a Codespace or local dev container. Your GitHub CLI is authenticated, and `gh-aw` is installed and verified so you can compile agentic workflows.

## Required outcome

Before continuing, confirm you have:

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

Follow the [GHAW setup guide](../../setup.md) to open a Codespace or local dev container. Both options install `gh-aw` automatically via `postCreate.sh`.

---

## Authenticate the GitHub CLI

Authenticate the CLI with your GitHub account:

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

`--logical-repo` tells `gh-aw` which repository to simulate instead of using your local Git remote. This helps when your clone uses an SSH host alias. See the [GHAW setup guide](../../setup.md) for trial mode's write-access requirements.
