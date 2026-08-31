# Ch18 — Self-Hosted & Larger Runners

> Deliver a hardened, scoped self-hosted runner capability with organisation runner groups, label routing, and an operating model.

| | |
|---|---|
| Track | Automation & AI |
| Difficulty | Advanced *(per-track ramp)* |
| Duration | ~5–6 hrs total, multi-session |
| Minimum input | An org + an org-owner token. *(All activities are org-scoped — no enterprise owner required.)* |
| App | Provisioned starter repository (created by setup) |
| EMU compatible | yes |

## Delivery target

- Delivery target: an approved organisation runner group, selected repositories, runner-host design, workflow labels, and hardening controls.
- Safety boundary: register and expose runners in the customer tenant only with platform and security owner approval and an agreed host risk model; otherwise use a disposable test environment.
- Evidence: runner-group scope, host hardening checklist, workflow evidence, egress decision, and runner-type decision matrix.
- Owner: the platform owner accepts host operations; repository owners accept runner use and fork pull-request boundaries.

## Prerequisites
- An organization you own (or org-owner rights) on GitHub Enterprise Cloud.
- A token with the scopes listed by `modules/ghec/resources/provisioning/scripts/setup.sh doctor ch18 --org <org>` (least-privilege; for this activity: `repo` + `admin:org` for runner-group + runner management).
- Local tooling: `gh >= 2.x`, `git`, `jq`.
- A machine to host the runner — your laptop, a VM, or a throwaway container. Linux/macOS/Windows all work; a disposable VM is recommended for controlled hardening validation and clean teardown.
- Org-scoped framing: this activity configures runners at the org level (org runner group). Enterprise runner groups are covered as *awareness* only — no enterprise owner required to complete it.
- If `ghec-ch52` (Enterprise Landing Zone & Organization Strategy) already established this customer's organization topology, use its scope decision as input for Part F instead of re-deriving it.

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
> Have a candidate? Use it everywhere this guide says `ghec-ch18-self-hosted-runners`, and skip Setup below. Otherwise use the seeded sample below for validation only, then hand the validated runner design off to the risk-approved owner.

## Sample test repository or environment
Skip this if you brought your own runner target. Otherwise run the provisioning entrypoint (Bash or PowerShell — both supported).

```bash
# Bash
bash modules/ghec/resources/provisioning/scripts/setup.sh provision ch18 --org <org>
```
```powershell
# PowerShell
modules/ghec/resources/provisioning/scripts/setup.ps1 provision ch18 --org <org>
```

What setup creates (all artifacts namespaced `ghec-ch18-*`, idempotent, prefix-guarded teardown):
- A seeded repo `ghec-ch18-self-hosted-runners` with a small build and two workflows: `hosted.yml` (runs on `ubuntu-latest`) and `self-hosted.yml` (targets your runner by label — initially queued until your runner exists).
- A `RUNNER-SETUP.md` with the exact registration + hardening walkthrough for Linux/macOS/Windows.
- A `HARDENING.md` checklist (service account, ephemeral runners, fork-PR risk, network egress).
- A printed Next steps block telling you where to start.

## Tasks
> Throughout, `ghec-ch18-self-hosted-runners` is the fallback sample. If you brought your own artifact, substitute its name in every command and use your real history, teams, settings, or data as the material to work from.

### Part A — Create an org runner group
1. Create a runner group scoped to your org: Org Settings → Actions → Runner groups → New, name it `ghec-ch18-group`. (Or by API: `gh api orgs/<org>/actions/runner-groups -f name='ghec-ch18-group' -f visibility='selected'`.)
2. Scope it to one repo. Restrict the group to selected repositories and add only `ghec-ch18-self-hosted-runners`. Confirm no other repo can use it.

### Part B — Register the runner
3. Get a registration token. `gh api -X POST orgs/<org>/actions/runners/registration-token --jq '.token'`.
4. Download & configure the runner on your host following `RUNNER-SETUP.md`: run `./config.sh --url https://github.com/<org> --token <reg-token> --runnergroup ghec-ch18-group --labels ghec-ch18,self-hosted --name ghec-ch18-runner` (use `config.cmd` on Windows).
5. Bring it online. Start it with `./run.sh` (interactive) or install it as a service. Confirm Idle status: `gh api orgs/<org>/actions/runners --jq '.runners[] | {name, status, labels: [.labels[].name]}'`.

### Part C — Target the runner
6. Trigger `self-hosted.yml`. It uses `runs-on: [self-hosted, ghec-ch18]`. Push or `workflow_dispatch` and confirm the job lands on your runner (check the run's runner name).
7. Contrast with hosted. Trigger `hosted.yml` and confirm it runs on a GitHub-hosted runner. Side-by-side, articulate the difference in start latency and environment.
8. Label routing. Add a second label (e.g., `gpu`) to your runner config, update the workflow's `runs-on`, and prove a mis-labeled job stays queued (no eligible runner).

### Part D — Harden the runner
9. Least-privilege account. Run the runner under a dedicated non-admin service account, not your personal/root user. Document the account and its limited permissions.
10. Go ephemeral. Reconfigure the runner with `--ephemeral` (just-in-time: it de-registers after one job) and confirm a fresh registration is required per job. Explain why this defeats job-to-job contamination.
11. Close the fork-PR hole. In repo/org Actions settings, ensure "Run workflows from fork pull requests" on self-hosted runners is restricted, and document why running untrusted fork code on a self-hosted runner is dangerous.
12. Constrain egress (document). List the network egress the runner actually needs and note how you'd restrict the rest (firewall/proxy) in a real deployment.

### Part E — Scaling & runner types (analysis)
13. Compare options. In `docs/RUNNER-CHOICES.md`, write a short decision matrix: GitHub-hosted vs larger runners vs self-hosted — covering cost, isolation, start latency, custom hardware, and maintenance burden.
14. Sketch autoscaling. Describe (don't implement) how you'd scale self-hosted runners with ephemeral, just-in-time registration (e.g., a controller that registers a fresh runner per queued job).

### Part F — Enterprise awareness (read + write-up)
15. Map org → enterprise. In `docs/RUNNER-CHOICES.md`, add a short note: how an org runner group differs from an enterprise runner group (enterprise groups span multiple orgs; require enterprise-owner), and when you'd reach for each. Use `ghec-ch52`'s scope decision if available; otherwise record your own recommendation. No enterprise actions required.

### Part G — Inspect the effective runner policy

16. Verify the runner-group repository scope, labels, routing, host privilege, ephemeral lifecycle, egress, and fork pull-request boundary. If enterprise runner policy is authorized and visible, confirm it's compatible with your runner group and host-hardening model — do not change it without enterprise-owner approval. If not visible, record `enterprise runner policy not available / not applicable`.

## Reference links
- About self-hosted runners — https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/about-self-hosted-runners
- Adding self-hosted runners — https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/adding-self-hosted-runners
- Managing access with runner groups — https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/managing-access-to-self-hosted-runners-using-groups
- Security hardening for self-hosted runners — https://docs.github.com/en/actions/reference/security/secure-use#hardening-for-self-hosted-runners
- Autoscaling with self-hosted runners — https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/autoscaling-with-self-hosted-runners
- About larger runners — https://docs.github.com/en/actions/using-github-hosted-runners/using-larger-runners/about-larger-runners
- `gh api` CLI manual — https://cli.github.com/manual/gh_api
