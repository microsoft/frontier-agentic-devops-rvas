# Ch18: Self-hosted and larger runners

Use this optional session when a CI job needs a different runner. Choose self-hosting only for a real network, hardware, or isolation requirement.

**Session outcome:** The customer's CI job runs on the approved runner type and meets its runtime and access needs. A self-hosted choice also passes the runner-group and host-isolation checks.

## Prerequisites
- An organization you own (or org-owner rights) on GitHub Enterprise Cloud.
- A token with the scopes listed by `modules/ghec/resources/provisioning/scripts/setup.sh doctor ch18 --org <org>` (least-privilege; for this activity: `repo` + `admin:org` for runner-group + runner management).
- Local tooling: `gh >= 2.x`, `git`, `jq`.
- Only for self-hosting: an approved disposable VM. Do not attach a personal workstation or shared production host.
- This activity configures org-level runners and runner groups. Review enterprise runner groups without configuring them. No enterprise owner is required.
- Use the customer's approved organization and repository scope for Part F.

## What you'll do
- Register a self-hosted runner at the org level and bring it online.
- Organize runners with a runner group and control which repos may use it.
- Target the runner from a workflow with `runs-on` labels (custom + default).
- Harden the runner: least-privilege service account, ephemeral/just-in-time runners, and the public-repo fork risk.
- Compare self-hosted vs GitHub-hosted vs larger runners and know when each fits.
- Understand how org runner groups relate to enterprise runner groups (awareness).

## Scenario
A GHEC customer needs CI on hardware GitHub doesn't host, such as a GPU box, a license-locked toolchain, or a network-isolated build host. Register a self-hosted runner in an org runner group, limit it to the repositories that need it, route jobs with labels, and harden it against untrusted pull requests. Then compare its operational cost with GitHub-hosted and larger runners.

> [!IMPORTANT]
> Default to an authorised customer CI job or repository that needs a self-hosted runner for network, hardware, compliance, or cost reasons.
>
> If you have an approved target, use it wherever this guide says `ghec-ch18-self-hosted-runners` and skip Setup below. Otherwise, use the seeded sample for validation only, then hand the validated runner design to the approved owner.

## Sample test repository or environment
Skip if you brought your own runner target.

```bash
# Bash
bash modules/ghec/resources/provisioning/scripts/setup.sh provision ch18 --org <org>
```
```powershell
# PowerShell
modules/ghec/resources/provisioning/scripts/setup.ps1 provision ch18 --org <org>
```

What setup creates (all artifacts namespaced `ghec-ch18-*`, idempotent, prefix-guarded teardown):
- A seeded repo `ghec-ch18-self-hosted-runners` with a small build and two workflows: `hosted.yml` runs on `ubuntu-latest`; `self-hosted.yml` targets your runner by label and queues until the runner exists.
- A `RUNNER-SETUP.md` with the exact registration + hardening walkthrough for Linux/macOS/Windows.
- A `HARDENING.md` checklist (service account, ephemeral runners, fork-PR risk, network egress).
- A printed Next steps block telling you where to start.

## Choose and test the runner type

Run the existing customer job on a standard GitHub-hosted runner first when its
access requirements permit it. If it meets the job's requirements, keep that
configuration and stop; self-hosting adds nothing.

For an approved larger runner, create or select it under **Organization settings
→ Actions → Runners**, restrict its runner group to the intended repository,
and set the job's `runs-on` to the configured runner name. Run the same job and
check its result, duration, and cost with the owner. The
[larger-runner guide](https://docs.github.com/en/actions/using-github-hosted-runners/using-larger-runners/about-larger-runners)
lists availability and supported configurations.

Continue below only when self-hosting is the approved choice. Keep the working
configuration and run result in the existing CI change record.

## Configure the self-hosted pilot

### Part A: Create an org runner group
1. Create a runner group scoped to your org: Org Settings → Actions → Runner groups → New, name it `ghec-ch18-group`. (Or by API: `gh api orgs/<org>/actions/runner-groups -f name='ghec-ch18-group' -f visibility='selected'`.)
2. Scope it to one repo. Restrict the group to selected repositories and add only `ghec-ch18-self-hosted-runners`. Confirm no other repo can use it.

### Part B: Register the runner
3. Get a registration token. `gh api -X POST orgs/<org>/actions/runners/registration-token --jq '.token'`.
4. Download & configure the runner on your host following `RUNNER-SETUP.md`: run `./config.sh --url https://github.com/<org> --token <reg-token> --runnergroup ghec-ch18-group --labels ghec-ch18,self-hosted --name ghec-ch18-runner` (use `config.cmd` on Windows).
5. Bring it online. Start it with `./run.sh` (interactive) or install it as a service. Confirm Idle status: `gh api orgs/<org>/actions/runners --jq '.runners[] | {name, status, labels: [.labels[].name]}'`.

### Part C: Target the runner
6. Trigger `self-hosted.yml`. It uses `runs-on: [self-hosted, ghec-ch18]`. Push or `workflow_dispatch` and confirm the job lands on your runner (check the run's runner name).
7. Trigger `hosted.yml` and confirm it runs on a GitHub-hosted runner. Compare its start latency and environment with your self-hosted runner.
8. Label routing. Add a second label (e.g., `gpu`) to your runner config, update the workflow's `runs-on`, and prove a mis-labeled job stays queued (no eligible runner).

### Part D: Harden the runner
9. Least-privilege account. Run the runner under a dedicated non-admin service account, not your personal/root user. Document the account and its limited permissions.
10. Register with `--ephemeral` and verify the runner deregisters after one job. **Ephemeral registration does not erase the host.** Destroy and recreate its VM before the next job, then check that the prior workspace is absent. Just-in-time registration is a separate mechanism. Neither registration method alone cleans the host.
11. Keep untrusted fork code off this runner. Check repository visibility and workflow triggers alongside runner-group access and fork approval policy. No single self-hosted-only fork setting covers them all. Cancel the Part C job that has no eligible runner and remove the runner and VM after validation.
12. Constrain egress (document). List the network egress the runner actually needs and note how you'd restrict the rest (firewall/proxy) in a real deployment.

### Part E: Scaling and runner types
13. Record why the tested runner meets the job's requirements and who maintains it. Link the run result; a separate runner comparison document is unnecessary.
14. Discuss autoscaling only when the observed queue requires it. Do not add a controller or an architecture exercise to a single-runner pilot.

### Part F: Review enterprise runner groups
15. Use an organization runner group for the selected organization. Consider an enterprise runner group only when the same approved runners must serve several organizations; it requires enterprise-owner access. Record the chosen scope in `docs/RUNNER-CHOICES.md`. No enterprise changes are required.

### Part G: Inspect the effective runner policy

16. Verify the runner-group repository scope, labels, routing, host privilege, ephemeral lifecycle, egress, and fork pull-request boundary. If enterprise runner policy is authorized and visible, confirm it's compatible with your runner group and host-hardening model. Do not change it without enterprise-owner approval. If not visible, record `enterprise runner policy not available / not applicable`.

## Reference links
- [About self-hosted runners](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/about-self-hosted-runners)
- [Adding self-hosted runners](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/adding-self-hosted-runners)
- [Managing access with runner groups](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/managing-access-to-self-hosted-runners-using-groups)
- [Security hardening for self-hosted runners](https://docs.github.com/en/actions/reference/security/secure-use#hardening-for-self-hosted-runners)
- [Autoscaling with self-hosted runners](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/autoscaling-with-self-hosted-runners)
- [About larger runners](https://docs.github.com/en/actions/using-github-hosted-runners/using-larger-runners/about-larger-runners)
- [`gh api` CLI manual](https://cli.github.com/manual/gh_api)
