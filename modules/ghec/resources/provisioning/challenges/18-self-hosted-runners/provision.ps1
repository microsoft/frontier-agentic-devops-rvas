# challenges/ch18-self-hosted-runners/provision.ps1
#
# PowerShell twin of ch18 — runner workflows, docs, and an org runner group.

$Global:GhecRunnerGroup = "ghec-$($Global:GhecChid)-runners"

function _Ch18-RepoFull { "$($Global:GhecOrg)/$($Global:GhecRepo)" }

function _Ch18-RunnerGroupId {
  $id = gh api "orgs/$($Global:GhecOrg)/actions/runner-groups" `
    --jq ".runner_groups[]? | select(.name==`"$($Global:GhecRunnerGroup)`") | .id" 2>$null
  if ($id) { return ($id -split '\r?\n')[0] }
  return $null
}

function _Ch18-SeedRepo {
  Write-GhecStep 'seeding runner workflows + setup/hardening guides'
  $org = $Global:GhecOrg
  $repo = $Global:GhecRepo
  $grp = $Global:GhecRunnerGroup

  $readme = @"
# ghec-ch18 — Self-Hosted Runners

Practice repo for self-hosted runner setup, targeting, and hardening.

- ``.github/workflows/hosted.yml`` — baseline job on GitHub-hosted runners
- ``.github/workflows/self-hosted.yml`` — job targeted at a ``self-hosted`` label
- ``RUNNER-SETUP.md`` — register a runner into the ``$grp`` group
- ``HARDENING.md`` — runner security hardening checklist

Registering a runner requires a real machine + token — that is the manual step.
"@
  Set-GhecFile -Org $org -Repo $repo -Path 'README.md' -Message 'Add self-hosted runners overview' -Content $readme

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
  Set-GhecFile -Org $org -Repo $repo -Path '.github/workflows/hosted.yml' -Message 'Add GitHub-hosted baseline workflow' -Content $hosted

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
  Set-GhecFile -Org $org -Repo $repo -Path '.github/workflows/self-hosted.yml' -Message 'Add self-hosted (label-targeted) workflow' -Content $self

  $setup = @"
# Runner Setup — ghec-ch18

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
  Set-GhecFile -Org $org -Repo $repo -Path 'RUNNER-SETUP.md' -Message 'Add runner registration guide' -Content $setup

  $hard = @'
# Runner Hardening Checklist — ghec-ch18

- [ ] Use ephemeral runners (`--ephemeral`) so each job starts clean.
- [ ] Never run self-hosted runners on public repos with untrusted PRs.
- [ ] Run as a low-privilege, dedicated user — not root.
- [ ] Restrict the runner group to specific repositories.
- [ ] Keep the runner host patched; rotate registration tokens.
- [ ] Isolate the host (network egress controls, no long-lived cloud creds).
'@
  Set-GhecFile -Org $org -Repo $repo -Path 'HARDENING.md' -Message 'Add runner hardening checklist' -Content $hard
}

function _Ch18-SeedRunnerGroup {
  Write-GhecStep "seeding org runner group: $($Global:GhecRunnerGroup)"
  $id = _Ch18-RunnerGroupId
  if ($id) { Write-GhecOk "runner group '$($Global:GhecRunnerGroup)' exists (#$id, skip)"; return }
  Invoke-GhecMutation -Plan "gh api POST runner-groups $($Global:GhecRunnerGroup)" -Action {
    gh api -X POST "orgs/$($Global:GhecOrg)/actions/runner-groups" -f name="$($Global:GhecRunnerGroup)" -f visibility=all
  }
}

# ===========================================================================
function Invoke-GhecProvision {
  New-GhecRepo -Org $Global:GhecOrg -Repo $Global:GhecRepo -Visibility 'public'
  if ((-not $Global:GhecDryRun) -and (-not (Test-GhecRepoExists -Org $Global:GhecOrg -Repo $Global:GhecRepo))) {
    Stop-Ghec "repo $(_Ch18-RepoFull) missing after create — aborting seed"
  }
  _Ch18-SeedRepo
  _Ch18-SeedRunnerGroup
  Write-Host ''
  Write-GhecInfo 'Next steps for the participant:'
  Write-GhecInfo "  - register a self-hosted runner into the '$($Global:GhecRunnerGroup)' group"
  Write-GhecInfo '  - run the self-hosted workflow and review HARDENING.md'
  Write-GhecWarn 'manual: runner registration needs a real machine + token — not automated.'
}

function Invoke-GhecTeardown {
  if (-not (Confirm-GhecPrefix -Name $Global:GhecRepo -Chid $Global:GhecChid)) { return }
  Remove-GhecRepo -Org $Global:GhecOrg -Repo $Global:GhecRepo

  $id = _Ch18-RunnerGroupId
  if ($id) {
    if (-not (Confirm-GhecPrefix -Name $Global:GhecRunnerGroup -Chid $Global:GhecChid)) { return }
    Invoke-GhecMutation -Plan "gh api DELETE runner-groups/$id" -Action {
      gh api -X DELETE "orgs/$($Global:GhecOrg)/actions/runner-groups/$id"
    }
  } else {
    Write-GhecOk "runner group '$($Global:GhecRunnerGroup)' absent (skip)"
  }
  Write-GhecWarn 'manual: de-register any self-hosted runner you connected — teardown does not touch runner hosts.'
}

function Invoke-GhecStatus {
  Write-GhecStep "status — $($Global:GhecChid) in '$($Global:GhecOrg)'"
  if (Test-GhecRepoExists -Org $Global:GhecOrg -Repo $Global:GhecRepo) {
    $id = _Ch18-RunnerGroupId
    $grp = if ($id) { "present (#$id)" } else { 'MISSING' }
    Write-GhecOk "repo $(_Ch18-RepoFull) present — runner group $grp"
  } else {
    Write-GhecInfo "repo $(_Ch18-RepoFull) not provisioned"
  }
}
