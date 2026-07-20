# Ch03 — Codespaces & Dev Containers

> Deliver a reproducible cloud development environment with `devcontainer.json`, Codespaces policy, port controls, and prebuilds.

| | |
|---|---|
| **Track** | Developer Flow |
| **Difficulty** | Intermediate *(per-track ramp)* |
| **Duration** | ~4–5 hrs total, multi-session |
| **Minimum input** | An **org** + an **org-owner token**. *(All activities are org-scoped — no enterprise owner required.)* |
| **App** | Provisioned starter repository (created by setup) |
| **EMU compatible** | yes |

## Customer delivery target

- **Customer objective:** reduce customer developer onboarding time while governing Codespaces spend.
- **Customer-tenant target:** a customer repository’s committed dev-container configuration, Codespaces policy, and prebuild.
- **Approval and safety boundary:** create or change Codespaces configurations and billing-bearing resources only with the repository and organisation owner’s approval; use the sample as a controlled proving ground when approval is constrained.
- **Enduring evidence:** retain the committed `.devcontainer` configuration, policy settings, prebuild result, and cost/retention decision.
- **Adoption owner / handover:** the repository maintainer and platform owner accept the configuration and operating limits.
- **Accountable next action:** the owner authorises a production repository rollout or records the approved rollout proposal.

## Prerequisites
- An organization you own (or org-owner rights) on GitHub Enterprise Cloud.
- A token with the scopes listed by `modules/ghec/resources/provisioning/scripts/setup.sh doctor ch03 --org <org>` (least-privilege; for this activity: `repo` + `codespace` + `admin:org` for org policy).
- Local tooling: `gh >= 2.x` (with the **Codespaces** extension available), `git`, `jq`.
- **Cost note:** Codespaces is a **metered** product. This activity consumes Codespaces minutes/storage on the participant account. Use the smallest machine type (2-core) and **stop** codespaces when idle. `modules/ghec/resources/provisioning/scripts/setup.sh doctor` warns about cost-bearing activities.

## Customer delivery objectives
This delivery engagement establishes:
- Author a **`devcontainer.json`** that pins a base image, installs features, and runs setup commands.
- **Launch a Codespace** from the UI and the CLI, and understand the create/stop/delete lifecycle.
- Add **lifecycle scripts** (`postCreateCommand`, `postStartCommand`) and **dev-container Features**.
- **Forward and label ports**, set port visibility, and run the seeded app inside the Codespace.
- Apply **personalization** (dotfiles) vs **project config**, and understand the precedence.
- Configure **org-level Codespaces policy** (machine-type limits, retention) and create a **prebuild** to cut start time.

## Scenario
A GHEC customer onboards new engineers slowly — each spends a day fighting local toolchains before they can run the app. You've been asked to make "clone and code in 60 seconds" real: a committed dev container that gives everyone the identical environment, a prebuild so it starts fast, and an org policy that keeps spend sane. You'll prove it on a seeded Node service.

> [!IMPORTANT]
> **Bring your own outcome (do this first)**
>
> Default to an authorised customer repository whose onboarding or local setup needs improvement. Complete the work on **that** artifact and retain the evidence, guardrails, or automation.
>
> - **Have a candidate?** Use it everywhere this guide says `ghec-ch03-codespaces-dev-containers`. Skip the Setup step below entirely.
> - **No suitable one?** Use the fallback below: a seeded sample repo ready for a devcontainer and Codespace.
>
> Record the selected target, customer adoption owner, and accountable next action. The sample is only a controlled proving ground; move the validated configuration to an approved customer target.

## Controlled proving ground (when tenant delivery is constrained)
Skip this if you brought your own repo. Otherwise run the provisioning entrypoint (Bash or PowerShell — both supported).

```bash
# Bash
bash modules/ghec/resources/provisioning/scripts/setup.sh provision ch03 --org <org>
```
```powershell
# PowerShell
modules/ghec/resources/provisioning/scripts/setup.ps1 provision ch03 --org <org>
```

**What setup creates** (all artifacts namespaced `ghec-ch03-*`, idempotent, prefix-guarded teardown):
- A seeded repo **`ghec-ch03-codespaces-dev-containers`** with a small **Node/Express** app, a `package.json`, and a deliberately **minimal `.devcontainer/devcontainer.json`** so you can extend it.
- A `README` describing how to run the app *locally* (so the contrast with Codespaces is obvious).
- A printed **Next steps** block telling you where to start.


## Tasks
> Throughout, **`ghec-ch03-codespaces-dev-containers` is the fallback sample**. If you brought your own artifact, substitute its name in every command and use your real history, teams, settings, or data as the material to work from.

### Part A — Author the dev container
1. **Inspect and extend `.devcontainer/devcontainer.json`.** The fallback sample includes a minimal baseline with a pinned Node image, dependency install, and port 3000 forwarding. Keep the pinned base image suitable for the app (e.g., `mcr.microsoft.com/devcontainers/javascript-node:22`) and improve it.
2. **Add Features.** Include at least two dev-container **Features**, e.g. `ghcr.io/devcontainers/features/github-cli:1` and `ghcr.io/devcontainers/features/node:1`. Understand Features vs baking tools into a custom Dockerfile.
3. **Add lifecycle commands.** Set `postCreateCommand` to install dependencies (`npm ci`) and `postStartCommand` to print a ready message. Add a `customizations.vscode.extensions` list with at least one extension.

### Part B — Launch & run
4. **Open a Codespace** from the repo's **Code → Codespaces** menu *and* from the CLI: `gh codespace create -R <org>/ghec-ch03-codespaces-dev-containers -m basicLinux32gb` (use the smallest available). List it with `gh codespace list`.
5. **Verify the environment** inside the Codespace: `node -v` matches the pinned image, `gh --version` works (proves the Feature installed), and `npm ci` already ran (proves `postCreateCommand`).
6. **Run the app** (`npm start`). Confirm it boots.

### Part C — Ports
7. **Forward the app port.** In the **Ports** panel, confirm the app's port is auto-forwarded; **label** it (e.g., `web`). Add a `forwardPorts` and `portsAttributes` entry to `devcontainer.json` so the label and behavior are committed, not ad-hoc.
8. **Set visibility.** Change the forwarded port to **Private to org** (or Public, then back), and note who can reach the URL at each setting.

### Part D — Personalization vs project config
9. **Enable dotfiles personalization** in your personal Codespaces settings (point it at a dotfiles repo or skip if none) and explain — in `docs/devcontainer-notes.md` — the difference between **personal dotfiles** (per-user) and the **committed `devcontainer.json`** (per-project), and which wins.

### Part E — Org policy & prebuilds
10. **Set an org Codespaces policy.** In **Org settings → Codespaces**, restrict the **allowed machine types** (e.g., disallow the largest) and set a **retention period**. Confirm the policy is visible via `gh api /orgs/<org>/codespaces` or the settings UI.
11. **Create a prebuild.** Configure a **Codespaces prebuild** for the repo's default branch (Settings → Codespaces → Set up prebuild). Trigger it, wait for the prebuild Action run to succeed, then create a *new* Codespace and confirm it reports "**prebuilt**" and starts noticeably faster.
12. **Clean up running Codespaces** with `gh codespace delete` to stop billing.

## Validation / Definition of Done
You are done when ALL of the following are true:
- [ ] `.devcontainer/devcontainer.json` exists, **pins a base image**, includes **≥2 Features**, and sets `postCreateCommand` + `postStartCommand`.
- [ ] A Codespace was launched from **both** the UI and the CLI (`gh codespace list` showed it).
- [ ] Inside the Codespace, the pinned **Node version**, the **gh CLI Feature**, and the **post-create install** are all verifiable.
- [ ] The app **runs** and its port is **forwarded + labeled**, with `forwardPorts`/`portsAttributes` committed to config.
- [ ] `docs/devcontainer-notes.md` explains **dotfiles vs devcontainer.json** precedence.
- [ ] An **org Codespaces policy** restricts machine types and sets retention.
- [ ] A **prebuild** is configured and a new Codespace reports **prebuilt**.
- [ ] All your Codespaces are **stopped/deleted** at the end.
- [ ] Real-outcome check — if you brought your own repo, it now has a Codespace/devcontainer path that reduces real onboarding friction; if you used the sample, you can name the repo whose setup you will standardize next.
- [ ] **Adoption handover** — name the repository owner, onboarding bottleneck, approved dev-container change, and next rollout action.

> Coaches verify these via the automated hints in `COACH.md`.

## Operational extensions
- Replace the base image with a **custom `Dockerfile`** referenced from `devcontainer.json` and reproduce the same environment.
- Add a **`docker-compose.yml`** dev container that runs the app + a database service together.
- Add a **secret** via Codespaces org secrets and read it inside the environment (`echo $MY_SECRET`) without committing it.

## Reference links
- Introduction to dev containers — https://docs.github.com/en/codespaces/setting-up-your-project-for-codespaces/adding-a-dev-container-configuration/introduction-to-dev-containers
- devcontainer.json reference — https://containers.dev/implementors/json_reference/
- About Codespaces — https://docs.github.com/en/codespaces/overview
- Forwarding ports in your codespace — https://docs.github.com/en/codespaces/developing-in-a-codespace/forwarding-ports-in-your-codespace
- Managing Codespaces for your organization — https://docs.github.com/en/codespaces/managing-codespaces-for-your-organization/managing-repository-access-for-your-organizations-codespaces
- Configuring prebuilds — https://docs.github.com/en/codespaces/prebuilding-your-codespaces/configuring-prebuilds
- Personalizing Codespaces with dotfiles — https://docs.github.com/en/codespaces/customizing-your-codespace/personalizing-github-codespaces-for-your-account
- `gh codespace` CLI manual — https://cli.github.com/manual/gh_codespace
