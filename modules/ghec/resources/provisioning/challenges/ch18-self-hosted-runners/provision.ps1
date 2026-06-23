# challenges/ch18-self-hosted-runners/provision.ps1
#
# PowerShell twin of ch18 — runner workflows, docs, and an org runner group.

$Global:WthRunnerGroup = "wth-$($Global:WthChid)-runners"

function _Ch18-RepoFull { "$($Global:WthOrg)/$($Global:WthRepo)" }

function _Ch18-RunnerGroupId {
  $id = gh api "orgs/$($Global:WthOrg)/actions/runner-groups" `
    --jq ".runner_groups[]? | select(.name==`"$($Global:WthRunnerGroup)`") | .id" 2>$null
  if ($id) { return ($id -split '\r?\n')[0] }
  return $null
}

function _Ch18-SeedRepo {
  Write-WthStep 'seeding runner workflows + setup/hardening guides'
  $org = $Global:WthOrg
  $repo = $Global:WthRepo
  $grp = $Global:WthRunnerGroup

  $readme = @"
# wth-ch18 — Self-Hosted Runners

Practice repo for self-hosted runner setup, targeting, and hardening.

- ``.github/workflows/hosted.yml`` — baseline job on GitHub-hosted runners
- ``.github/workflows/self-hosted.yml`` — job targeted at a ``self-hosted`` label
- ``RUNNER-SETUP.md`` — register a runner into the ``$grp`` group
- ``HARDENING.md`` — runner security hardening checklist

Registering a runner requires a real machine + token — that is the manual step.
"@
  Set-WthFile -Org $org -Repo $repo -Path 'README.md' -Message 'Add self-hosted runners overview' -Content $readme

  $hosted = @'
name: Hosted Baseline
on:
  workflow_dispatch:
  push:
    branches: [main]
permissions:
  contents: read
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: echo "running on a GitHub-hosted runner"
'@
  Set-WthFile -Org $org -Repo $repo -Path '.github/workflows/hosted.yml' -Message 'Add GitHub-hosted baseline workflow' -Content $hosted

  $self = @'
name: Self-Hosted Job
on:
  workflow_dispatch:
permissions:
  contents: read
jobs:
  build:
    # Targets your registered self-hosted runner. Add custom labels as needed.
    runs-on: [self-hosted, linux, x64]
    steps:
      - uses: actions/checkout@v4
      - run: echo "running on a self-hosted runner: $(hostname)"
'@
  Set-WthFile -Org $org -Repo $repo -Path '.github/workflows/self-hosted.yml' -Message 'Add self-hosted (label-targeted) workflow' -Content $self

  $setup = @"
# Runner Setup — wth-ch18

Register a self-hosted runner into the ``$grp`` org runner group.

1. Org Settings → Actions → Runners → **New runner** (or use a registration token).
2. On the runner host:
   ``````
   ./config.sh --url https://github.com/$org --token <REGISTRATION_TOKEN> \
     --runnergroup "$grp" --labels linux,x64
   ./run.sh
   ``````
3. Trigger ``.github/workflows/self-hosted.yml`` and confirm it lands on your runner.
"@
  Set-WthFile -Org $org -Repo $repo -Path 'RUNNER-SETUP.md' -Message 'Add runner registration guide' -Content $setup

  $hard = @'
# Runner Hardening Checklist — wth-ch18

- [ ] Use ephemeral runners (`--ephemeral`) so each job starts clean.
- [ ] Never run self-hosted runners on public repos with untrusted PRs.
- [ ] Run as a low-privilege, dedicated user — not root.
- [ ] Restrict the runner group to specific repositories.
- [ ] Keep the runner host patched; rotate registration tokens.
- [ ] Isolate the host (network egress controls, no long-lived cloud creds).
'@
  Set-WthFile -Org $org -Repo $repo -Path 'HARDENING.md' -Message 'Add runner hardening checklist' -Content $hard
}

function _Ch18-SeedRunnerGroup {
  Write-WthStep "seeding org runner group: $($Global:WthRunnerGroup)"
  $id = _Ch18-RunnerGroupId
  if ($id) { Write-WthOk "runner group '$($Global:WthRunnerGroup)' exists (#$id, skip)"; return }
  Invoke-WthMutation -Plan "gh api POST runner-groups $($Global:WthRunnerGroup)" -Action {
    gh api -X POST "orgs/$($Global:WthOrg)/actions/runner-groups" -f name="$($Global:WthRunnerGroup)" -f visibility=all
  }
}

# ===========================================================================
function Invoke-WthProvision {
  New-WthRepo -Org $Global:WthOrg -Repo $Global:WthRepo -Visibility 'public'
  if ((-not $Global:WthDryRun) -and (-not (Test-WthRepoExists -Org $Global:WthOrg -Repo $Global:WthRepo))) {
    Stop-Wth "repo $(_Ch18-RepoFull) missing after create — aborting seed"
  }
  _Ch18-SeedRepo
  _Ch18-SeedRunnerGroup
  Write-Host ''
  Write-WthInfo 'Next steps for the participant:'
  Write-WthInfo "  - register a self-hosted runner into the '$($Global:WthRunnerGroup)' group"
  Write-WthInfo '  - run the self-hosted workflow and review HARDENING.md'
  Write-WthWarn 'manual: runner registration needs a real machine + token — not automated.'
}

function Invoke-WthTeardown {
  if (-not (Confirm-WthPrefix -Name $Global:WthRepo -Chid $Global:WthChid)) { return }
  Remove-WthRepo -Org $Global:WthOrg -Repo $Global:WthRepo

  $id = _Ch18-RunnerGroupId
  if ($id) {
    if (-not (Confirm-WthPrefix -Name $Global:WthRunnerGroup -Chid $Global:WthChid)) { return }
    Invoke-WthMutation -Plan "gh api DELETE runner-groups/$id" -Action {
      gh api -X DELETE "orgs/$($Global:WthOrg)/actions/runner-groups/$id"
    }
  } else {
    Write-WthOk "runner group '$($Global:WthRunnerGroup)' absent (skip)"
  }
  Write-WthWarn 'manual: de-register any self-hosted runner you connected — teardown does not touch runner hosts.'
}

function Invoke-WthStatus {
  Write-WthStep "status — $($Global:WthChid) in '$($Global:WthOrg)'"
  if (Test-WthRepoExists -Org $Global:WthOrg -Repo $Global:WthRepo) {
    $id = _Ch18-RunnerGroupId
    $grp = if ($id) { "present (#$id)" } else { 'MISSING' }
    Write-WthOk "repo $(_Ch18-RepoFull) present — runner group $grp"
  } else {
    Write-WthInfo "repo $(_Ch18-RepoFull) not provisioned"
  }
}
