# Ch00 — Customer Delivery Readiness

> Verify the customer-delivery environment, authenticate the GitHub CLI, and confirm approved organisation access before selecting the first implementation target.

| | |
|---|---|
| **Track** | Developer Flow |
| **Difficulty** | Beginner |
| **Duration** | ~25 min |
| **Minimum input** | A GitHub account + approved access to the customer delivery organisation |
| **App** | none |
| **EMU compatible** | yes |

## Customer delivery target

- **Customer objective:** establish delivery readiness before any tenant change.
- **Customer-tenant target:** the authorised customer organisation, repository, access path, and first adoption target—not a production configuration change.
- **Approval and safety boundary:** verify only the access the customer owner has approved; do not create, change, or elevate tenant resources during this readiness guide.
- **Enduring evidence:** retain the verification summary, selected first target, named customer owner, and any access blockers in the delivery record.
- **Adoption owner / handover:** the customer owner confirms the target and ownership boundary; the delivery team hands over verified access and blockers.
- **Accountable next action:** the named owner authorises and schedules the first customer-tenant implementation guide.

## Objectives

Delivery readiness is complete when you have:

- A working development environment (GitHub Codespaces or local dev container)
- An authenticated `gh` CLI session pointing at your GitHub account
- Confirmed access approved for the customer delivery organisation
- Access verified to the agreed delivery or customer repository

---

## Prerequisites

- GitHub account
- Basic Git and CLI usage
- Access approved by the customer owner for the agreed delivery or customer organisation

> **Branch workflow (not fork):** This module uses a shared org repository. Do **not** fork. Clone directly and work on a personal branch:
> ```bash
> git checkout -b setup/<your-github-handle>
> ```

---

## Option A: GitHub Codespaces (Recommended)

1. Open the agreed delivery or customer repository in your browser (the delivery lead or customer owner supplies the URL, e.g. `https://github.com/<org>/<repo>`).
2. Click **Code → Codespaces → Create codespace on main**.
3. Wait ~30 seconds for the dev container to build. The terminal opens automatically when the container is ready.
4. Continue to **Authenticate the GitHub CLI** below.

> **Tip:** Codespaces pre-installs `gh`, `git`, and `jq` — no local tooling required.

---

## Option B: Local Dev Container

1. Install [VS Code](https://code.visualstudio.com/) and the [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers).
2. Clone the repository:
   ```bash
   git clone https://github.com/<org>/<repo>
   cd <repo>
   ```
3. Open VS Code in the cloned folder (`code .`) and choose **Dev Containers: Reopen in Container** from the Command Palette (`Ctrl+Shift+P`).
4. Wait for the container to build, then continue below.

> **Windows note:** PowerShell users can also run `modules/ghec/resources/provisioning/scripts/setup.ps1 doctor --org <org>` to verify tooling instead of the Bash equivalent.

---

## Authenticate the GitHub CLI

Your container does not have your GitHub credentials pre-loaded. Run:

```bash
gh auth login
```

Choose **GitHub.com**, then **HTTPS**, and follow the device-code prompt in your browser. Grant the requested permissions (at minimum: `repo`, `read:org`).

> Some later delivery guides (Projects v2 automation, including ch16) also need `project` and `read:project`. You can add missing scopes later without re-login: `gh auth refresh -h github.com -s project,read:project`.

Verify the session is active:

```bash
gh auth status
```

Expected output includes your username and `Logged in to github.com`.

---

## Verify Your Setup

Run each command and confirm it succeeds before moving on:

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

### Verification summary

| Check | Command | Expected output |
|---|---|---|
| CLI installed | `gh --version` | `gh version 2.x.x` |
| Authenticated | `gh auth status` | Shows your username |
| Org visible | `gh org list` | Lists the approved target org |
| Repo accessible | `gh repo view <org>/<repo>` | Returns repository metadata |

---

## Provisioning preflight (optional)

The GHEC delivery environment ships provisioning scripts (`setup.sh` / `setup.ps1`) that set up controlled starting state for each guide.
The scripts live in-tree at `modules/ghec/resources/provisioning/`. You do not need them for this
guide, but you can run a preflight check now (from the repo root):

```bash
# Bash
bash modules/ghec/resources/provisioning/scripts/setup.sh doctor ch01 --org <org>

# PowerShell
modules/ghec/resources/provisioning/scripts/setup.ps1 doctor ch01 --org <org>
```

A clean `doctor` output confirms that your token scopes and tooling are ready for the selected delivery guides.
