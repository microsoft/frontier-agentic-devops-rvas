# Ch00: Environment setup

**Session outcome:** You can clone the approved customer repository and run its baseline checks with an authenticated GitHub CLI.

Use **the same repository through Ch01, Ch02, and Ch04**. Record its URL and owner once. Classify the results using [completion evidence](../../../README.md#completion-evidence). If setup fails, record the blocker.

## Objectives

You are ready when you have:

- A working development environment (GitHub Codespaces or local dev container)
- An authenticated `gh` CLI session pointing at your GitHub account
- Confirmed access approved for the customer delivery organisation
- Access verified to the agreed delivery or customer repository

---

## Prerequisites

- GitHub account
- Basic Git and CLI usage
- Access approved by the customer owner for the agreed delivery or customer organisation

> Branch workflow (not fork): This module uses a shared org repository. Do not fork. Clone directly and work on a personal branch:
> ```bash
> git checkout -b setup/<your-github-handle>
> ```

---

## Option A: GitHub Codespaces

1. Open the agreed delivery or customer repository in your browser (the delivery lead or customer owner supplies the URL, e.g. `https://github.com/<org>/<repo>`).
2. Click Code → Codespaces → Create codespace on main.
3. Wait for the dev container to build. The terminal opens when it is ready.
4. Continue to Authenticate the GitHub CLI below.

> Check that the selected image includes `gh` and `git`; images and build times vary.

---

## Option B: Local dev container

1. Install [VS Code](https://code.visualstudio.com/) and the [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers).
2. Clone the repository:
   ```bash
   git clone https://github.com/<org>/<repo>
   cd <repo>
   ```
3. Open VS Code in the cloned folder (`code .`) and choose Dev Containers: Reopen in Container from the Command Palette (`Ctrl+Shift+P`).
4. Wait for the container to build, then continue below.

> Windows note: PowerShell users can also run `modules/ghec/resources/provisioning/scripts/setup.ps1 doctor --org <org>` to verify tooling instead of the Bash equivalent.

---

## Authenticate the GitHub CLI

Your container does not have your GitHub credentials pre-loaded. Run:

```bash
gh auth login
```

Choose the customer's GitHub host, then HTTPS, and follow the device-code prompt. Use the approved credential and only the permissions this repository needs. Authorize SSO when required.

> Projects v2 automation may also need `project` and `read:project`. Add these scopes only if your task needs them: `gh auth refresh -h github.com -s project,read:project`.

Verify the session is active:

```bash
gh auth status
```

Expected output includes your username and `Logged in to github.com`.

---

## Verify your setup

Run each command. Do not continue until all four succeed:

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

> All four commands must succeed. Record any failure as an access blocker for the customer owner or delivery lead.

## Provisioning preflight (optional)

Run a preflight check for the next guide from the repo root. Scripts live at `modules/ghec/resources/provisioning/`.

```bash
# Bash
bash modules/ghec/resources/provisioning/scripts/setup.sh doctor ch01 --org <org>

# PowerShell
modules/ghec/resources/provisioning/scripts/setup.ps1 doctor ch01 --org <org>
```

The `doctor` command checks sample tooling, not customer authorization. Clone the approved customer repository and run its documented test command. Keep the result for Ch02. Repository access is sufficient for contributors.
