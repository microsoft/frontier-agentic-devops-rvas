# Challenge 00 — Environment Setup

## Objectives

By the end of this challenge you will have:

**Environment setup:**
- A working development environment (GitHub Codespaces or local dev container)
- An authenticated `gh` CLI session
- An authenticated Azure CLI session with Contributor access confirmed
- The Contoso Claims baseline app running and passing tests

**Team launch:**
- A shared understanding of the Contoso Claims scenario and the one-day arc
- Named human accountability roles: architect, reviewer, escalation handler, and operator
- A starter context artifact capturing roles, review rules, and safety boundaries

---

## Prerequisites

- GitHub account
- Basic Git and CLI usage
- Azure subscription with **Contributor** role on the hackathon resource group
- Access to the shared org repository (branch workflow — do **not** fork)

> **Branch workflow (not fork):** This module uses a shared org repository. Do **not** fork. Clone directly and work on a personal branch:
> ```bash
> git checkout -b setup/<your-github-handle>
> ```

---

## Option A: GitHub Codespaces (Recommended)

1. Open **this repository** (`microsoft/frontier-agenticdevops-hackathon`) on GitHub.
2. Click **Code → Codespaces → Create codespace on main**.
3. Wait ~30 seconds for the dev container to build (Node 22, Bicep extension, port 3000 forwarded).
4. When the terminal appears, dependencies install automatically via `postCreateCommand`. Continue to **Verify your setup** below.

---

## Option B: Local Dev Container

1. Install [VS Code](https://code.visualstudio.com/) and the [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers).
2. Clone this repository (if you haven't already):
   ```bash
   git clone https://github.com/microsoft/frontier-agenticdevops-hackathon.git
   cd frontier-agenticdevops-hackathon
   ```
3. Open VS Code in the cloned folder and choose **Dev Containers: Reopen in Container**.
4. Wait for the container to build, then continue below.

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

## Authenticate the Azure CLI

```bash
az login
```

Follow the device-code prompt. Once logged in, confirm your subscription:

```bash
az account show
```

You should see your subscription name and a `state: Enabled` field. If the wrong subscription is selected:

```bash
az account set --subscription "<your-subscription-name-or-id>"
az account show
```

---

## Verify Your Setup

Run each command and confirm it exits successfully:

```bash
# 1. GitHub CLI auth
gh auth status

# 2. Azure subscription
az account show

# 3. Baseline app tests (sample app is vendored in this repo)
cd modules/sre-agent/resources/sample-app && npm install && npm test
```

> All three checks must succeed before you move to Challenge 01. If any fail, see **Common Blockers** in the coach guide.

---

---

## Team Launch & Scenario

### The Contoso Claims Story

Your product team has inherited a customer-facing service called **Contoso Claims**. The service works, but the engineering system around it is uneven: backlog items are vague, pull requests are inconsistent, automation is incomplete, and operational evidence is scattered.

Today your team will modernize how this service moves from idea to production signal. You will use GitHub as the system of record, GitHub Copilot and agent workflows as engineering accelerators, Azure as the deployment target, and Azure SRE Agent practices to close the loop from incident evidence back to a reviewed fix.

The first lesson is simple: **do not ask agents to infer your team's operating model from scattered chat.** Before autonomy increases, make enough team knowledge explicit that a new teammate or agent can find it in the repo.

### Team Roles

Choose one person for each accountability role:

| Role | Responsibility |
|---|---|
| **Architect** | Owns design decisions, review gates, and safety boundaries |
| **Reviewer** | Approves pull requests and agent-generated changes |
| **Escalation handler** | Decides when to pause and escalate vs. continue |
| **Operator** | Monitors deployments, runs baseline checks, handles incidents |

### Team Tasks

1. Confirm everyone can open the repository and has a working environment (see above).
2. Review the service README and known issues in the repository.
3. Create or identify your team board, issue list, or project view for the day.
4. Create a short team context note using the [Agentic SDLC Starter Kit](../../resources/Agentic-SDLC-Starter-Kit.md). Include:
   - Human roles and merge authority
   - Safety boundaries (what agents may and may not do autonomously)
   - Where decisions will be recorded
5. Capture any unresolved setup blockers as GitHub issues — not chat messages.

### Working Agreements

- If Copilot is not enabled for everyone, pair up so every team still practices prompt-review-validation loops.
- If Azure access is not ready, keep moving. Coaches can provide deployment logs, incident packets, and SRE response artifacts for later challenges.
- Keep the starter context small. Progressive disclosure beats one giant instruction file.
- Treat setup governance as a working draft — you will improve it as agents reveal missing assumptions.

### Deliverables

- Team context artifact with roles, boundaries, and decision location (issue, project note, or repo file).
- Setup blocker issue for each unresolved access problem.
- Confirmed environment path: Codespaces, dev container, local, or coach fallback.

---

## Next Step

Environment confirmed and team launched → proceed to **[Challenge 01 — GitHub SDLC Baseline](../01-github-sdlc/README.md)**.
