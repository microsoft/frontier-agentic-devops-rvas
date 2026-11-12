# Ch00: Environment setup

**Session outcome:** You can clone the customer repository and run its baseline checks with an authenticated GitHub CLI.

Use **the same repository through Ch01, Ch02, and Ch04**. Record its URL and owner once. Classify your results with [completion evidence](../../../README.md#completion-evidence). If setup fails, record the blocker.

## Objectives

You are done when you have:

- A working development environment (GitHub Codespaces or local dev container)
- An authenticated `gh` CLI session pointing at your GitHub account
- Access to the customer delivery organisation
- Access to the agreed repository

---

## Prerequisites

- GitHub account
- Basic Git and CLI usage
- Access to the customer organisation, approved by the customer owner

> Branch workflow (not fork): This module uses a shared org repository. Do not fork. Clone directly and work on a personal branch:
> ```bash
> git checkout -b setup/<your-github-handle>
> ```

---

## Option A: GitHub Codespaces

1. Open the agreed repository in your browser. The delivery lead or customer owner gives you the URL, e.g. `https://github.com/<org>/<repo>`.
2. Click Code → Codespaces → Create codespace on main.
3. Wait for the dev container to build. The terminal opens when it's ready.
4. Then authenticate the GitHub CLI below.

> Check that the image includes `gh` and `git`.

---

## Option B: Local dev container

1. Install [VS Code](https://code.visualstudio.com/) and the [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers).
2. Clone the repository:
   ```bash
   git clone https://github.com/<org>/<repo>
   cd <repo>
   ```
3. Open VS Code in the cloned folder (`code .`) and choose Dev Containers: Reopen in Container from the Command Palette (`Ctrl+Shift+P`).
4. Wait for the container to build.

> Windows note: PowerShell users can also run `modules/ghec/resources/provisioning/scripts/setup.ps1 doctor --org <org>` to verify tooling instead of the Bash equivalent.

---

## Authenticate the GitHub CLI

Your container does not have your GitHub credentials pre-loaded. Run:

```bash
gh auth login
```

Choose the customer's GitHub host, then HTTPS, and follow the device-code prompt. Use the approved credential, with only the permissions this repository needs. Authorize SSO when required.

> Projects v2 automation may also need `project` and `read:project`. Add these scopes only if your task needs them: `gh auth refresh -h github.com -s project,read:project`.

Verify the session is active:

```bash
gh auth status
```

Expected output includes your username and `Logged in to github.com`.

---

## Verify your setup

Run each command. All four must succeed before you continue:

```bash
# 1. CLI version — must be >= 2.x
gh --version

# 2. Authentication
gh auth status

# 3. Org access — must list the approved target org
gh org list

# 4. Repository access
gh repo view <org>/<repo>
```

> Record any failure as an access blocker and tell the customer owner or delivery lead.

## Provisioning preflight (optional)

Run a preflight check for the next guide from the repo root. The scripts live in `modules/ghec/resources/provisioning/`.

```bash
# Bash
bash modules/ghec/resources/provisioning/scripts/setup.sh doctor ch01 --org <org>

# PowerShell
modules/ghec/resources/provisioning/scripts/setup.ps1 doctor ch01 --org <org>
```

`doctor` checks sample tooling, not customer authorization. Clone the customer repository and run its documented test command. Keep the result for Ch02. Contributors only need repository access.
