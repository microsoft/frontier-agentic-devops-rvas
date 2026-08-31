# Ch03 — Codespaces & Dev Containers

> Deliver a reproducible cloud development environment with `devcontainer.json`, Codespaces policy, port controls, and prebuilds.

| | |
|---|---|
| Track | Developer Flow |
| Difficulty | Intermediate *(per-track ramp)* |
| Duration | 180 min |
| Minimum input | An org + an org-owner token. *(All activities are org-scoped — no enterprise owner required.)* |
| App | Provisioned starter repository (created by setup) |
| EMU compatible | yes |

## Prerequisites
- An organization you own (or org-owner rights) on GitHub Enterprise Cloud.
- A token with the scopes listed by `modules/ghec/resources/provisioning/scripts/setup.sh doctor ch03 --org <org>` (least-privilege; for this activity: `repo` + `codespace` + `admin:org` for org policy).
- Local tooling: `gh >= 2.x` (with the Codespaces extension available), `git`, `jq`.
- Cost note: Codespaces is a metered product. This activity consumes Codespaces minutes/storage on the participant account. Use the smallest machine type (2-core) and stop codespaces when idle. `modules/ghec/resources/provisioning/scripts/setup.sh doctor` warns about cost-bearing activities.

## What you will deliver
- Author a `devcontainer.json` that pins a base image, installs features, and runs setup commands.
- Launch a Codespace from the UI and the CLI, and understand the create/stop/delete lifecycle.
- Use prebuild-aware lifecycle scripts (`onCreateCommand`, `postStartCommand`) and dev-container Features.
- Forward and label ports, set port visibility, and run the seeded app inside the Codespace.
- Apply personalization (dotfiles) vs project config, and understand the precedence.
- Configure org-level Codespaces policy (machine-type limits, retention) and create a prebuild to cut start time.

## Scenario
A GHEC customer onboards new engineers slowly — each spends a day fighting local toolchains before they can run the app. You've been asked to make "clone and code in 60 seconds" real: a committed dev container that gives everyone the identical environment, a prebuild so it starts fast, and an org policy that keeps spend sane. You'll prove it on a seeded Node service.

> [!IMPORTANT]
> Use an approved customer target first. If you have a candidate repository, use it everywhere this guide says `ghec-ch03-codespaces-dev-containers` and skip Setup. Otherwise use the fallback seeded repo below for testing, then move the validated configuration to an approved customer target.
>
> Record the selected target, adoption owner, and next action.

## Sample test repository or environment
Skip if you brought your own repo.

```bash
# Bash
bash modules/ghec/resources/provisioning/scripts/setup.sh provision ch03 --org <org>
```
```powershell
# PowerShell
modules/ghec/resources/provisioning/scripts/setup.ps1 provision ch03 --org <org>
```

Setup creates these resources (all names use the `ghec-ch03-*` prefix, and teardown is prefix-guarded):
- A seeded repo `ghec-ch03-codespaces-dev-containers` with a small Node/Express app, a `package.json`, and a deliberately minimal `.devcontainer/devcontainer.json` so you can extend it.
- A `README` describing how to run the app *locally* (so the contrast with Codespaces is obvious).
- A printed Next steps block telling you where to start.

## Tasks
> `ghec-ch03-codespaces-dev-containers` is the fallback sample name; substitute your own artifact's name if you brought one.

### Part A — Author the dev container
1. Inspect and extend `.devcontainer/devcontainer.json`. The fallback sample includes a minimal baseline with a pinned Node image, dependency install, and port 3000 forwarding. Keep the pinned base image suitable for the app (e.g., `mcr.microsoft.com/devcontainers/javascript-node:22`) and improve it.
2. Add Features. Include at least two dev-container Features, e.g. `ghcr.io/devcontainers/features/github-cli:1` and `ghcr.io/devcontainers/features/node:1`. Understand Features vs baking tools into a custom Dockerfile.
3. Add lifecycle commands. Keep deterministic shared setup in `onCreateCommand` (`npm install` for the seeded app) and add `postStartCommand` to print a ready message. Prebuilds run `onCreateCommand`, but not `postCreateCommand`, so do not put the dependency install in `postCreateCommand`. Add a `customizations.vscode.extensions` list with at least one extension.

### Part B — Launch & run
4. Open a Codespace from the repo's Code → Codespaces menu *and* from the CLI: `gh codespace create -R <org>/ghec-ch03-codespaces-dev-containers -m basicLinux32gb` (use the smallest available). List it with `gh codespace list`.
5. Verify the environment inside the Codespace: `node -v` matches the pinned image, `gh --version` works (proves the Feature installed), and `node_modules/express` exists (proves `onCreateCommand` installed dependencies).
6. Run the app (`npm start`). Confirm it boots.

### Part C — Ports
7. Forward the app port. In the Ports panel, confirm the app's port is auto-forwarded; label it (e.g., `web`). Add a `forwardPorts` and `portsAttributes` entry to `devcontainer.json` so the label and behavior are committed, not ad-hoc.
8. Set visibility. Change the forwarded port to Private to org (or Public, then back), and note who can reach the URL at each setting.

### Part D — Personalization vs project config
9. Enable dotfiles personalization in your personal Codespaces settings (point it at a dotfiles repo or skip if none) and explain — in `docs/devcontainer-notes.md` — the difference between personal dotfiles (per-user) and the committed `devcontainer.json` (per-project), and which wins.

### Part E — Org policy & prebuilds
10. Set an org Codespaces policy. In Org settings → Codespaces, restrict the allowed machine types (e.g., disallow the largest) and set a retention period. Confirm the policy is visible via `gh api /orgs/<org>/codespaces` or the settings UI.
11. Design the prebuild before creating it. In `docs/prebuild-decision.md`, record the repository branch and `devcontainer.json` you are targeting; the developer regions; the trigger you choose; the number of versions to retain; the owner for failed-prebuild notifications; and the rationale. Select the settings for this customer:
   - **Every push** keeps dependencies current but consumes more Actions minutes.
   - **On configuration change** reduces Actions usage but may leave dependencies stale until a developer updates them.
   - **Scheduled** suits a deliberate refresh cadence, with the same freshness trade-off.
   - Limit regions to where the delivery team works. Each enabled region and retained version consumes prebuild storage.
   - Retain only the number of versions needed for rollback or investigation (1–5). Decide whether developers should be blocked from a fallback when the latest prebuild is running or failed.
12. Create the prebuild from the recorded decision (Settings → Codespaces → Set up prebuild). Select the branch and configuration file, trigger, regions, retained versions, failure-notification owner, and advanced freshness behavior. Wait for the GitHub Actions prebuild workflow to succeed.
13. Validate the result. Create a *new* Codespace for the configured branch and configuration. Confirm the machine picker shows **Prebuild ready**, `node_modules/express` is already present, and the repository settings show the successful configuration and its next update trigger. Record the workflow URL or run ID in `docs/prebuild-decision.md`.
14. Clean up running Codespaces with `gh codespace delete` to stop billing.

## Reference links
- Introduction to dev containers — https://docs.github.com/en/codespaces/setting-up-your-project-for-codespaces/adding-a-dev-container-configuration/introduction-to-dev-containers
- devcontainer.json reference — https://containers.dev/implementors/json_reference/
- About Codespaces — https://docs.github.com/en/codespaces/overview
- Forwarding ports in your codespace — https://docs.github.com/en/codespaces/developing-in-a-codespace/forwarding-ports-in-your-codespace
- Managing Codespaces for your organization — https://docs.github.com/en/codespaces/managing-codespaces-for-your-organization/managing-repository-access-for-your-organizations-codespaces
- Configuring prebuilds — https://docs.github.com/en/codespaces/prebuilding-your-codespaces/configuring-prebuilds
- About Codespaces prebuilds — https://docs.github.com/en/codespaces/prebuilding-your-codespaces/about-github-codespaces-prebuilds
- Personalizing Codespaces with dotfiles — https://docs.github.com/en/codespaces/customizing-your-codespace/personalizing-github-codespaces-for-your-account
- `gh codespace` CLI manual — https://cli.github.com/manual/gh_codespace
