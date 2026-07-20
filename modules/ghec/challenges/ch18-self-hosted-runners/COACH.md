# Ch18 — Self-Hosted & Larger Runners — Delivery Assurance Guide

> Audience: delivery assurance leads and authorized customer implementation owners. Pair with the corresponding customer implementation `README.md`.
> Customer authorization and rollout boundary: Apply changes in a customer-owned tenant or repository only after the named customer owner authorizes the scope. A fallback is a sample test repository or environment, not the destination: record its evidence, risks and controls, accountable owner, handover, and the explicit tenant adoption, cutover, or rollout decision.


## Customer adoption decision

Required delivery assurance check: before implementation is accepted, confirm the authorized tenant scope, implementation evidence, risk controls, accountable owner, handover, and next adoption action.

Decision prompt: what build or test job in your current CI pipeline is bottlenecked on GitHub-hosted runner constraints (network, hardware, compliance, cost), and what would a self-hosted runner in your own infrastructure unlock for that job? Record the accountable owner, implementation evidence, risk or blocker, and next customer adoption action.

> Customer implementation preference: prioritize an authorized customer tenant or artifact over the `ghec-ch18-self-hosted-runners` sample. If a sample is necessary, record the target tenant scope, accountable owner, authorization blocker, evidence to carry forward, and the adoption, cutover, or rollout decision. The sample is a safe fallback, not the destination.

Use these prompts to verify customer ownership and the next action:
- Name the specific workflow and the constraint — is it network egress, memory, GPUs, a license, or a compliance boundary?
- What is the operational cost (maintenance, scaling, security patching) of owning that runner fleet, and who on your team would own it?
- What is the single job you'd migrate first, and what success metric would tell you the migration paid off?

## Delivery assurance notes
- Customer adoption outcome: the customer implementation owner registers a self-hosted runner through an org runner group, targets it with labels, and — the key outcome — hardens it (least-privilege, ephemeral, fork-PR risk) rather than just getting a green build.
- Implementation risks to verify:
  - Registration token vs PAT. The runner config needs a short-lived registration token (`actions/runners/registration-token`), not their PAT. They paste the wrong one.
  - `runs-on` label matching. A job needs all listed labels present on a runner. `[self-hosted, ghec-ch18]` requires both; a runner missing `ghec-ch18` won't pick it up — the job sits Queued with no error.
  - Runner never goes idle. They configured it but didn't start `run.sh` (or the service). Status stays offline.
  - Hardening hand-waved. The temptation is to run as root and call it done. Hold them to the least-privilege account and a demonstrated ephemeral run.
- Delivery lead prompts: ask "which credential does `config.sh` want, and how long does it live?" (→ registration token), and "what labels does the job require vs what labels does your runner advertise?" (→ exact set match).
- Org-scoped note: runs with an org + org-owner token. `admin:org` covers runner-group and runner management. Enterprise runner groups are awareness-only here — do not require an enterprise owner.

## Implementation acceptance evidence
| Criterion | Assurance weight | Customer-owned evidence |
|---|---:|---|
| Org runner group (scoped) | 15 | `ghec-ch18-group` exists, selected repos only, scoped to the one repo |
| Runner registration | 20 | Runner online/Idle in the group with custom labels |
| Targeting + label routing | 20 | `self-hosted.yml` ran on the customer implementation owner's runner; mis-labeled job stays Queued (shown) |
| Hosted vs self-hosted contrast | 10 | Both run; customer implementation owner articulates latency/env/cost tradeoffs |
| Hardening | 25 | Least-privilege account + ephemeral run demonstrated; fork-PR risk + egress documented |
| Scaling + enterprise awareness | 10 | Decision matrix + autoscaling sketch + org-vs-enterprise runner-group note |
| Assurance coverage | 100 | |

## Implementation verification evidence
```bash
ORG=<org>; REPO=ghec-ch18-self-hosted-runners   # swap REPO for the customer implementation owner's own repo if they brought one

# Runner group exists and is repo-scoped
gh api orgs/$ORG/actions/runner-groups --jq '.runner_groups[] | {name, visibility}'
GID=$(gh api orgs/$ORG/actions/runner-groups --jq '.runner_groups[] | select(.name=="ghec-ch18-group") | .id')
gh api orgs/$ORG/actions/runner-groups/$GID/repositories --jq '.repositories[].name'

# Runner is online with the expected labels
gh api orgs/$ORG/actions/runners --jq '.runners[] | {name, status, labels: [.labels[].name]}'

# The self-hosted workflow actually ran on a self-hosted runner
gh run list --repo $ORG/$REPO --workflow self-hosted.yml --json databaseId,conclusion,headBranch --limit 5
RUN=$(gh run list --repo $ORG/$REPO --workflow self-hosted.yml --limit 1 --json databaseId --jq '.[0].databaseId')
gh api repos/$ORG/$REPO/actions/runs/$RUN/jobs --jq '.jobs[] | {name, runner_name, labels}'
```
- The truth source is `jobs[].runner_name` — it must match the customer implementation owner's runner (`ghec-ch18-runner`), not a GitHub-hosted name.
- For ephemeral, have the customer implementation owner show the runner disappearing from `actions/runners` after a single job, then re-registering for the next.
- For label routing, have them show a run stuck in Queued when the workflow requires a label no runner advertises.

## Common pitfalls
- Wrong token at `config.sh` — must be a registration token, which expires fast; re-mint if it 404s.
- Partial label match — `runs-on` needs every listed label on one runner; missing one → silent Queued.
- Runner left running as root — dock hardening points; require a dedicated non-admin account.
- Fork-PR setting left open on a self-hosted runner — this is the dangerous default to fix; do not skip.
- Runner not unregistered at teardown — deleting the repo does not remove the runner from the org or the host; use `./config.sh remove` (see Teardown).
- Token scope — `admin:org` required for runner-group and runner endpoints.

## References for delivery leads

- [About self-hosted runners](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/about-self-hosted-runners), [Runner groups and access](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/managing-access-to-self-hosted-runners-using-groups).

## Teardown
```bash
bash modules/ghec/resources/provisioning/scripts/setup.sh teardown ch18 --org <org> --yes   # Bash
modules/ghec/resources/provisioning/scripts/setup.ps1 teardown ch18 --org <org> --yes  # PowerShell
```
- Removes only `ghec-ch18-*` artifacts (prefix-guarded): the repo and the `ghec-ch18-group` org runner group.
- Manual cleanup (required): unregister the runner on the host before/after teardown — `./config.sh remove --token <removal-token>` (get one via `gh api -X POST orgs/<org>/actions/runners/remove-token`). If you installed it as a service, stop and uninstall the service. Delete the disposable VM/container if you used one.

## Time budget
- Setup + read: ~30 min
- Parts A–B (runner group + registration): ~1.5 hrs
- Part C (targeting + label routing): ~1 hr
- Part D (hardening): ~1.5 hrs
- Parts E–F (scaling + enterprise awareness write-ups): ~1 hr
- Indicative implementation effort: ~5–6 hrs across sessions.
