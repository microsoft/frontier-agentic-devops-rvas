[CmdletBinding()]
param(
  [Parameter(Position = 0, Mandatory = $true)]
  [ValidateSet('provision', 'status', 'teardown')]
  [string]$Command,

  [Parameter(Mandatory = $true)]
  [string]$Org,

  [string]$Repo = 'ghas-admin-02-secret-operations',

  [ValidateSet('private', 'internal', 'public')]
  [string]$Visibility = 'private',

  [string]$Ref = 'v20.0.0',

  [switch]$DryRun,

  [switch]$Yes
)

$ErrorActionPreference = 'Stop'
$Upstream = 'https://github.com/juice-shop/juice-shop.git'
$IssueTitle = 'GHAS Admin 02: secret protection operations evidence'

if ($Repo -notlike 'ghas-admin-02-*') {
  throw 'Repository name must start with ghas-admin-02-.'
}

function Test-Command {
  param([string]$Name)
  return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Assert-Tools {
  foreach ($tool in @('gh', 'git')) {
    if (-not (Test-Command -Name $tool)) {
      throw "$tool is required."
    }
  }
  gh auth status 2>$null | Out-Null
  if ($LASTEXITCODE -ne 0) {
    throw 'Authenticate GitHub CLI before provisioning.'
  }
}

function Test-RepoExists {
  gh repo view "$Org/$Repo" 2>$null | Out-Null
  return ($LASTEXITCODE -eq 0)
}

function Test-FileExists {
  param([string]$Path, [string]$GitRef = 'main')
  gh api "repos/$Org/$Repo/contents/$Path`?ref=$GitRef" 2>$null | Out-Null
  return ($LASTEXITCODE -eq 0)
}

function Test-BranchExists {
  param([string]$Branch)
  gh api "repos/$Org/$Repo/git/ref/heads/$Branch" 2>$null | Out-Null
  return ($LASTEXITCODE -eq 0)
}

function Test-IssueExists {
  $title = gh issue list --repo "$Org/$Repo" --state all --search "$IssueTitle in:title" `
    --json title --jq ".[] | select(.title == `"$IssueTitle`") | .title" 2>$null
  return ($LASTEXITCODE -eq 0 -and $title -contains $IssueTitle)
}

function Assert-Fixture {
  $missing = [System.Collections.Generic.List[string]]::new()
  if (-not (Test-RepoExists)) {
    $missing.Add("repository $Org/$Repo")
  } else {
    if (-not (Test-FileExists -Path 'SECRETS-MANIFEST.md')) {
      $missing.Add('SECRETS-MANIFEST.md')
    }
    if (-not (Test-FileExists -Path 'config/aws-legacy.ini')) {
      $missing.Add('config/aws-legacy.ini')
    }
    if (-not (Test-FileExists -Path 'config/aws-build.ini')) {
      $missing.Add('config/aws-build.ini')
    }
    if (-not (Test-FileExists -Path 'fixtures/internal-token.txt')) {
      $missing.Add('fixtures/internal-token.txt')
    }
    if (-not (Test-BranchExists -Branch 'seed/push-protection-history')) {
      $missing.Add('seed/push-protection-history')
    }
    if (-not (Test-FileExists -Path 'config/aws-branch.ini' -GitRef 'seed/push-protection-history')) {
      $missing.Add('config/aws-branch.ini on seed/push-protection-history')
    }
    if (-not (Test-IssueExists)) {
      $missing.Add('evidence issue')
    }
  }

  if ($missing.Count -gt 0) {
    throw "Fixture is incomplete: $($missing -join ', ')"
  }
  Write-Host "fixture ready: $Org/$Repo"
}

function Invoke-GitCommit {
  param([string]$Message)
  git -c user.name='ghas-admin-02-fixture' `
    -c user.email='ghas-admin-02-fixture@users.noreply.github.com' `
    commit -q -m $Message
  if ($LASTEXITCODE -ne 0) {
    throw "Git commit failed: $Message"
  }
}

function Write-SeedHistory {
  param([string]$Source)

  $awsIdOne = 'AKIA' + 'IOSFODNN7EXAMPLE'
  $awsSecretOne = 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLE' + 'KEY'
  $awsIdTwo = 'AKIA' + 'ADMIN02SEED00001'
  $awsSecretTwo = 'Admin02SeedSecretValue000000000000000000'
  $awsIdBranch = 'AKIA' + 'ADMIN02BRANCH001'
  $awsSecretBranch = 'Admin02BranchSecretValue0000000000000000'

  Push-Location $Source
  try {
    git init -q
    git symbolic-ref HEAD refs/heads/main
    git add -A
    Invoke-GitCommit -Message "Import OWASP Juice Shop $Ref for GHAS Admin 02"

    New-Item -ItemType Directory -Path 'config' -Force | Out-Null
    @"
; Synthetic GHAS Admin 02 fixture. Never issued.
[legacy-uploader]
aws_access_key_id = $awsIdOne
aws_secret_access_key = $awsSecretOne
"@ | Set-Content -Path 'config/aws-legacy.ini' -Encoding utf8
    git add config/aws-legacy.ini
    Invoke-GitCommit -Message 'Seed legacy credential history for GHAS Admin 02'

    @"
; Synthetic GHAS Admin 02 fixture. Never issued.
[build-publisher]
aws_access_key_id = $awsIdTwo
aws_secret_access_key = $awsSecretTwo
"@ | Set-Content -Path 'config/aws-build.ini' -Encoding utf8
    git add config/aws-build.ini
    Invoke-GitCommit -Message 'Seed build credential history for GHAS Admin 02'

    New-Item -ItemType Directory -Path 'fixtures' -Force | Out-Null
    'RVAS_DEMO_ADMIN02HISTORYSEED01' |
      Set-Content -Path 'fixtures/internal-token.txt' -Encoding utf8
    git add fixtures/internal-token.txt
    Invoke-GitCommit -Message 'Seed custom pattern candidate for GHAS Admin 02'

    @'
# GHAS Admin 02 secrets manifest

All values are synthetic and were never issued. Reconcile each row with GitHub.

| Row | Location | Expected detection | Ref | Closure |
| --- | --- | --- | --- | --- |
| 1 | `config/aws-legacy.ini` | AWS credential pair | `main` history | `used_in_tests` |
| 2 | `config/aws-build.ini` | AWS credential pair | `main` history | `used_in_tests` |
| 3 | `fixtures/internal-token.txt` | `RVAS Admin 02 demo token` after publication | `main` | `used_in_tests` |
| 4 | `config/aws-branch.ini` | AWS credential pair | `seed/push-protection-history` | `used_in_tests` |

Do not copy detected values into issues, chat, or incident records.
'@ | Set-Content -Path 'SECRETS-MANIFEST.md' -Encoding utf8
    git add SECRETS-MANIFEST.md
    Invoke-GitCommit -Message 'Add GHAS Admin 02 secrets manifest'

    git switch -q -c seed/push-protection-history
    @"
; Synthetic GHAS Admin 02 fixture. Never issued.
[branch-uploader]
aws_access_key_id = $awsIdBranch
aws_secret_access_key = $awsSecretBranch
"@ | Set-Content -Path 'config/aws-branch.ini' -Encoding utf8
    git add config/aws-branch.ini
    Invoke-GitCommit -Message 'Seed branch credential history for GHAS Admin 02'
    git switch -q main
  } finally {
    Pop-Location
  }
}

function Invoke-Provision {
  Assert-Tools
  if (Test-RepoExists) {
    Write-Host 'repository exists; checking the fixture instead of changing it'
    Assert-Fixture
    return
  }

  if ($DryRun) {
    Write-Host "would import Juice Shop $Ref into $Org/$Repo ($Visibility)"
    Write-Host 'would seed provider-pattern history, manifest, custom-pattern candidate, branch, and evidence issue'
    return
  }

  $work = Join-Path ([System.IO.Path]::GetTempPath()) ("ghas-admin-02-" + [guid]::NewGuid().ToString('N'))
  New-Item -ItemType Directory -Path $work | Out-Null
  try {
    $source = Join-Path $work 'src'
    Write-Host "cloning Juice Shop $Ref"
    git clone --quiet --depth 1 --branch $Ref $Upstream $source
    if ($LASTEXITCODE -ne 0) {
      throw "Failed to clone Juice Shop at $Ref."
    }
    if (-not (Test-Path -LiteralPath (Join-Path $source 'LICENSE'))) {
      throw 'Upstream LICENSE is missing.'
    }

    $sourceGit = Join-Path $source '.git'
    if (Test-Path -LiteralPath $sourceGit) {
      Remove-Item -LiteralPath $sourceGit -Recurse -Force
    }
    Write-SeedHistory -Source $source

    Push-Location $source
    try {
      $visibilityFlag = "--$Visibility"
      gh repo create "$Org/$Repo" $visibilityFlag `
        --description 'Synthetic GHAS Admin 02 secret protection lab; safe to delete' `
        --source=. --remote=origin --push
      if ($LASTEXITCODE -ne 0) {
        throw 'Repository creation or main push failed.'
      }
      git push origin seed/push-protection-history
      if ($LASTEXITCODE -ne 0) {
        throw 'Fixture branch push failed.'
      }
    } finally {
      Pop-Location
    }

    $issueBody = @'
Record evidence without pasting secret values.

- [ ] Secret scanning and push protection enabled
- [ ] SECRETS-MANIFEST.md reconciled to alert numbers
- [ ] Seeded alerts resolved with explicit reasons
- [ ] Clean push accepted
- [ ] Synthetic provider-pattern push blocked
- [ ] Delegated bypass reviewed by a different account
- [ ] Bypass alert verified through the API
- [ ] Custom pattern published and live alert verified
- [ ] Final UI and API alert state agree
- [ ] Real credential rotation, revocation, or incident handoff complete, if required

Mark a licensed feature blocked when GitHub does not make it available. A tabletop does not satisfy that item.
'@
    gh issue create --repo "$Org/$Repo" --title $IssueTitle --body $issueBody
    if ($LASTEXITCODE -ne 0) {
      throw 'Evidence issue creation failed.'
    }

    Assert-Fixture
  } finally {
    Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
  }
}

function Invoke-Status {
  Assert-Tools
  Assert-Fixture
}

function Invoke-Teardown {
  Assert-Tools
  if (-not (Test-RepoExists)) {
    Write-Host "repository already absent: $Org/$Repo"
    return
  }
  if (-not $Yes) {
    throw 'Teardown requires -Yes.'
  }
  if ($DryRun) {
    Write-Host "would delete $Org/$Repo"
    return
  }
  gh repo delete "$Org/$Repo" --yes
  if ($LASTEXITCODE -ne 0) {
    throw 'Repository deletion failed.'
  }
}

switch ($Command) {
  'provision' { Invoke-Provision }
  'status' { Invoke-Status }
  'teardown' { Invoke-Teardown }
}
