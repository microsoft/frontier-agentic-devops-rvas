# Ch03: Codespaces and dev containers

Use this optional session when the Ch00 repository needs a shared development image or prebuild. Reuse that repository and delete unused Codespaces after testing.

**Session outcome:** A new team member's Codespace builds from the committed `devcontainer.json` and runs the application's checks without manual tool installation. Port access follows the approved policy.

## Prerequisites
- An organization you own (or org-owner rights) on GitHub Enterprise Cloud.
- A token with the scopes listed by `modules/ghec/resources/provisioning/scripts/setup.sh doctor ch03 --org <org>` (least-privilege; for this activity: `repo` + `codespace` + `admin:org` for org policy).
- Local tooling: `gh >= 2.x` (with the Codespaces extension available), `git`, `jq`.
- Cost note: Codespaces is a metered product. This activity consumes Codespaces minutes/storage on the participant account. Use the smallest machine type (2-core) and stop codespaces when idle. `modules/ghec/resources/provisioning/scripts/setup.sh doctor` warns about cost-bearing activities.

## What you will deliver
- Author a `devcontainer.json` that pins a base image, installs features, and runs setup commands.
- Launch one Codespace and run the application and its checks.
- Use prebuild-aware lifecycle scripts (`onCreateCommand`, `postStartCommand`) and dev-container Features.
- Forward and label ports, set port visibility, and run the seeded app inside the Codespace.
- Reuse approved machine-type and retention policy. Add a prebuild only when startup time warrants it.

## Scenario
New engineers at a GHEC customer spend a day configuring local tools before they can run the app. Configure a committed dev container and a prebuild to shorten setup. Set an org policy to control costs, then test the environment on a seeded Node service.

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
- A `README` describing how to run the app locally.
- A printed Next steps block telling you where to start.

## Tasks
> `ghec-ch03-codespaces-dev-containers` is the fallback sample name; substitute your own artifact's name if you brought one.

### Part A: Author the dev container
1. Inspect and extend `.devcontainer/devcontainer.json`. The fallback sample includes a minimal baseline with a pinned Node image, dependency install, and port 3000 forwarding. Keep the pinned base image suitable for the app (e.g., `mcr.microsoft.com/devcontainers/javascript-node:22`) and improve it.
2. Add only missing tools, for example `ghcr.io/devcontainers/features/github-cli:1` when the base image lacks `gh`. Do not install a second Node runtime over the image's runtime or add Features merely to meet a count.
3. Keep shared dependency setup in `onCreateCommand` (`npm install` for the seeded app). Prebuilds run `onCreateCommand`, but not `postCreateCommand`. Add editor extensions only when the team needs them; a ready-message command is unnecessary.

### Part B: Launch and run
4. Open one Codespace from the repo's **Code → Codespaces** menu, or use `gh codespace create -R <org>/ghec-ch03-codespaces-dev-containers` and choose the smallest allowed machine. List it with `gh codespace list`.
5. Verify the environment inside the Codespace: `node -v` matches the pinned image, `gh --version` works (proves the Feature installed), and `node_modules/express` exists (proves `onCreateCommand` installed dependencies).
6. Run the app (`npm start` in the sample) and the repository's documented test command. Have a teammate repeat the setup in a fresh Codespace. Fix any manual setup they still need.

### Part C: Ports
7. Forward the app port. In the Ports panel, confirm the app's port is auto-forwarded; label it (e.g., `web`). Add a `forwardPorts` and `portsAttributes` entry to `devcontainer.json` so the label and behavior are committed, not ad-hoc.
8. Keep the forwarded port private. With approval, test organization visibility using an intended user and a user outside that audience. Do not expose customer code or services publicly for this exercise.

### Part D: Check cost policy
9. Inspect the existing policy under **Organization settings → Codespaces**. With organization-owner approval, change machine types or retention only when they do not meet the team's needs. Keep the owner and agreed cost limit in the existing setup PR.

### Optional: Add a prebuild when startup is slow
10. Measure the fresh Codespace's startup time. If it is acceptable to the team, skip this section. Otherwise agree on the branch, configuration, regions, update trigger, retained versions, and failure-notification owner in the same setup PR:
   - **Every push** keeps dependencies current but consumes more Actions minutes.
   - **On configuration change** reduces Actions usage but may leave dependencies stale until a developer updates them.
   - **Scheduled** suits a deliberate refresh cadence, with the same freshness trade-off.
   - Limit regions to where the delivery team works. Each enabled region and retained version consumes prebuild storage.
   - Retain only the number of versions needed for rollback or investigation (1–5). Decide whether developers should be blocked from a fallback when the latest prebuild is running or failed.
11. Create the approved prebuild under **Settings → Codespaces → Set up prebuild**. Wait for its GitHub Actions workflow to succeed.
12. Create a *new* Codespace for that branch and configuration. Confirm **Prebuild ready**, run the same application checks, and compare startup time. Link the workflow result in the setup PR.

### Finish
13. Merge the tested configuration through normal review. Delete only the temporary Codespaces with `gh codespace delete -c <name>` to stop their compute and storage charges.

## Reference links
- [Introduction to dev containers](https://docs.github.com/en/codespaces/setting-up-your-project-for-codespaces/adding-a-dev-container-configuration/introduction-to-dev-containers)
- [devcontainer.json reference](https://containers.dev/implementors/json_reference/)
- [About Codespaces](https://docs.github.com/en/codespaces/overview)
- [Forwarding ports in your codespace](https://docs.github.com/en/codespaces/developing-in-a-codespace/forwarding-ports-in-your-codespace)
- [Managing Codespaces for your organization](https://docs.github.com/en/codespaces/managing-codespaces-for-your-organization/managing-repository-access-for-your-organizations-codespaces)
- [Configuring prebuilds](https://docs.github.com/en/codespaces/prebuilding-your-codespaces/configuring-prebuilds)
- [About Codespaces prebuilds](https://docs.github.com/en/codespaces/prebuilding-your-codespaces/about-github-codespaces-prebuilds)
- [Personalizing Codespaces with dotfiles](https://docs.github.com/en/codespaces/customizing-your-codespace/personalizing-github-codespaces-for-your-account)
- [`gh codespace` CLI manual](https://cli.github.com/manual/gh_codespace)
