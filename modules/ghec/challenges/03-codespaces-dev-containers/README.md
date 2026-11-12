# Ch03: Codespaces and dev containers

Use this optional session when the Ch00 repository needs a shared dev image or prebuild. Reuse that repository and delete unused Codespaces afterward.

**Session outcome:** A new team member's Codespace builds from the committed `devcontainer.json` and runs the app's checks with no manual tool installs. Port access follows policy.

## Prerequisites
- An organization you own (or org-owner rights) on GitHub Enterprise Cloud.
- A token with the scopes listed by `modules/ghec/resources/provisioning/scripts/setup.sh doctor ch03 --org <org>` (least privilege; here: `repo` + `codespace` + `admin:org` for org policy).
- Local tooling: `gh >= 2.x` (with the Codespaces extension available), `git`, `jq`.
- **Cost:** Codespaces minutes and storage are metered on the participant account. Use the smallest machine type (2-core) and stop Codespaces when idle. `modules/ghec/resources/provisioning/scripts/setup.sh doctor` warns about costs.

## What you will deliver
- Author a `devcontainer.json` that pins a base image, installs features, and runs setup commands.
- Launch one Codespace and run the application and its checks.
- Use prebuild-aware lifecycle scripts (`onCreateCommand`, `postStartCommand`) and dev-container Features.
- Forward and label ports, set port visibility, and run the seeded app inside the Codespace.
- Reuse the approved machine-type and retention policy. Add a prebuild only if startup is slow.

## Scenario
New engineers at a GHEC customer spend a day configuring local tools before they can run the app. Commit a dev container, check the org's cost policy, and test the environment. Add a prebuild only if startup is slow.

> [!IMPORTANT]
> Use a customer repository if you have one: use it wherever this guide says `ghec-ch03-codespaces-dev-containers` and skip Setup. Otherwise test in the seeded repo below, then apply the configuration to a customer repository.
>
> Record the target, who adopts it, and the next action.

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

## Tasks
> `ghec-ch03-codespaces-dev-containers` is the fallback sample name; use your own repository's name if you brought one.

### Part A: Author the dev container
1. Inspect and extend `.devcontainer/devcontainer.json`. The fallback sample includes a minimal baseline with a pinned Node image, dependency install, and port 3000 forwarding. Keep a pinned base image that fits the app (e.g., `mcr.microsoft.com/devcontainers/javascript-node:22`) and improve the file from there.
2. Add only missing tools, for example `ghcr.io/devcontainers/features/github-cli:1` when the base image lacks `gh`. Don't install a second Node runtime over the image's, and don't add Features for their own sake.
3. Keep shared dependency setup in `onCreateCommand` (`npm install` for the seeded app). Prebuilds run `onCreateCommand`, but not `postCreateCommand`. Add editor extensions only if the team needs them. Skip ready-message commands.

### Part B: Launch and run
4. Open one Codespace from the repo's **Code → Codespaces** menu, or use `gh codespace create -R <org>/ghec-ch03-codespaces-dev-containers` and choose the smallest allowed machine. List it with `gh codespace list`.
5. Check the environment inside the Codespace: `node -v` matches the pinned image, `gh --version` works (proves the Feature installed), and `node_modules/express` exists (proves `onCreateCommand` installed dependencies).
6. Run the app (`npm start` in the sample) and the repository's documented test command. Have a teammate repeat the setup in a fresh Codespace. Fix any manual setup they still need.

### Part C: Ports
7. Forward the app port. In the Ports panel, confirm the app's port is auto-forwarded and label it (e.g., `web`). Add `forwardPorts` and `portsAttributes` entries to `devcontainer.json` so the label and behavior are committed, not set by hand.
8. Keep the forwarded port private. With approval, test organization visibility with one user inside the audience and one outside it. Never expose customer code or services publicly.

### Part D: Check cost policy
9. Read the existing policy under **Organization settings → Codespaces**. With organization-owner approval, change machine types or retention only if they don't meet the team's needs. Record the owner and the agreed cost limit in the setup PR.

### Optional: Add a prebuild when startup is slow
10. Measure startup time in a fresh Codespace. If the team is fine with it, skip this section. Otherwise agree on the branch, configuration, regions, update trigger, retained versions, and who gets failure notifications, and record them in the setup PR:
   - **Every push** keeps dependencies current but consumes more Actions minutes.
   - **On configuration change** uses fewer Actions minutes but can leave dependencies stale until a developer updates them.
   - **Scheduled** refreshes on a fixed cadence, with the same staleness trade-off.
   - Limit regions to where the delivery team works. Each enabled region and retained version consumes prebuild storage.
   - Keep only as many versions as you need for rollback or investigation (1–5). Decide whether developers can fall back to an older prebuild while the latest one is running or has failed.
11. Create the prebuild under **Settings → Codespaces → Set up prebuild**. Wait for its GitHub Actions workflow to succeed.
12. Create a *new* Codespace for that branch and configuration. Confirm **Prebuild ready**, run the same application checks, and compare startup time. Link the workflow result in the setup PR.

### Finish
13. Merge the tested configuration through normal review. Delete the temporary Codespaces with `gh codespace delete -c <name>` to stop compute and storage charges. Delete only those.

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
