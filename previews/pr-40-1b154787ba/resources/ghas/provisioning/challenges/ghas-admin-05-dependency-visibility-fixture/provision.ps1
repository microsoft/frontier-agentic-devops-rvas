#!/usr/bin/env pwsh

[CmdletBinding()]
param(
  [Parameter(Position = 0, Mandatory)]
  [ValidateSet('provision', 'status', 'teardown')]
  [string]$Command,

  [Parameter(Mandatory)]
  [string]$Org,

  [string]$Repo = 'ghas-admin-05-dependency-visibility-fixture',
  [string]$Ref = 'v20.0.0',
  [switch]$DryRun,
  [switch]$Yes
)

$ErrorActionPreference = 'Stop'
$Upstream = 'https://github.com/juice-shop/juice-shop.git'
$FullRepo = "$Org/$Repo"

if (-not $Repo.StartsWith('ghas-admin-05-')) {
  throw 'Repository name must start with ghas-admin-05-.'
}

function Write-Log {
  param([string]$Level, [string]$Message)
  Write-Host "[$Level] $Message"
}

function Invoke-Mutation {
  param([string]$Plan, [scriptblock]$Action)
  if ($DryRun) {
    Write-Log plan $Plan
    return
  }
  & $Action
  if ($LASTEXITCODE -ne 0) {
    throw "Command failed: $Plan"
  }
}

function Test-Repo {
  gh repo view $FullRepo 2>$null | Out-Null
  return ($LASTEXITCODE -eq 0)
}

function Test-RemoteFile {
  param([string]$Path, [string]$Branch = 'main')
  gh api "repos/$FullRepo/contents/$Path`?ref=$Branch" 2>$null | Out-Null
  return ($LASTEXITCODE -eq 0)
}

function Set-RemoteFile {
  param(
    [string]$Path,
    [string]$Message,
    [string]$Content,
    [string]$Branch = 'main'
  )
  if (Test-RemoteFile -Path $Path -Branch $Branch) {
    Write-Log ok "$Path already exists on $Branch"
    return
  }
  $Encoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($Content))
  Invoke-Mutation "create $Path on $Branch" {
    gh api --method PUT "repos/$FullRepo/contents/$Path" `
      -f "message=$Message" -f "content=$Encoded" -f "branch=$Branch" | Out-Null
  }
}

function Test-Branch {
  param([string]$Branch)
  gh api "repos/$FullRepo/git/ref/heads/$Branch" 2>$null | Out-Null
  return ($LASTEXITCODE -eq 0)
}

function New-FixtureBranch {
  param([string]$Branch)
  if (Test-Branch -Branch $Branch) {
    Write-Log ok "$Branch already exists"
    return
  }
  if ($DryRun) {
    Write-Log plan "create $Branch from main"
    return
  }
  $Sha = gh api "repos/$FullRepo/git/ref/heads/main" --jq '.object.sha'
  if ($LASTEXITCODE -ne 0 -or -not $Sha) {
    throw 'Could not resolve the main branch.'
  }
  gh api --method POST "repos/$FullRepo/git/refs" `
    -f "ref=refs/heads/$Branch" -f "sha=$Sha" | Out-Null
  if ($LASTEXITCODE -ne 0) {
    throw "Could not create $Branch."
  }
}

function New-FixtureRepo {
  if ($DryRun) {
    Write-Log plan "create public repository $FullRepo"
    return
  }
  gh repo create $FullRepo --public `
    --description 'GHAS dependency visibility fixture; safe to delete'
  if ($LASTEXITCODE -eq 0) {
    return
  }
  gh repo create $FullRepo --private `
    --description 'GHAS dependency visibility fixture; safe to delete'
  if ($LASTEXITCODE -ne 0) {
    throw "Could not create public or private repository $FullRepo."
  }
  Write-Log warn 'Public repository creation failed; created a private repository.'
  Write-Log warn 'Private dependency review requires GitHub Code Security.'
}

function Import-JuiceShop {
  if (Test-Repo) {
    Write-Log ok "$FullRepo already exists"
    return
  }
  if ($DryRun) {
    Write-Log plan "import Juice Shop $Ref from $Upstream into $FullRepo"
    New-FixtureRepo
    return
  }

  $Work = Join-Path ([IO.Path]::GetTempPath()) ("ghas-admin-05-" + [guid]::NewGuid().ToString('N'))
  $Source = Join-Path $Work 'src'
  New-Item -ItemType Directory -Path $Work | Out-Null
  try {
    git clone --depth 1 --branch $Ref $Upstream $Source
    if ($LASTEXITCODE -ne 0) {
      throw "Could not clone Juice Shop at $Ref."
    }
    if (-not (Test-Path (Join-Path $Source 'LICENSE'))) {
      throw 'Upstream Juice Shop license is missing.'
    }

    Remove-Item -Recurse -Force (Join-Path $Source '.git')
    Push-Location $Source
    try {
      git init -q
      git symbolic-ref HEAD refs/heads/main
      git add -A
      git -c user.name='ghas-fixture' `
        -c user.email='ghas-fixture@users.noreply.github.com' `
        commit -q -m "Import OWASP Juice Shop $Ref for GHAS lab"
      if ($LASTEXITCODE -ne 0) {
        throw 'Could not create the fixture import commit.'
      }

      New-FixtureRepo
      gh auth setup-git
      git remote add origin "https://github.com/$FullRepo.git"
      git push --set-upstream origin main
      if ($LASTEXITCODE -ne 0) {
        throw "Could not push the imported repository to $FullRepo."
      }
    }
    finally {
      Pop-Location
    }
  }
  finally {
    Remove-Item -Recurse -Force $Work -ErrorAction SilentlyContinue
  }
  Write-Log ok "Imported Juice Shop $Ref into $FullRepo"
}

function Get-VulnerablePackageJson {
@'
{
  "name": "ghas-admin-05-vulnerable-dependencies",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "build": "bash ./build.sh"
  },
  "dependencies": {
    "lodash": "4.17.4",
    "marked": "0.3.6",
    "minimist": "0.0.8"
  }
}
'@
}

function Get-VulnerableLockJson {
@'
{
  "name": "ghas-admin-05-vulnerable-dependencies",
  "version": "1.0.0",
  "lockfileVersion": 3,
  "requires": true,
  "packages": {
    "": {
      "name": "ghas-admin-05-vulnerable-dependencies",
      "version": "1.0.0",
      "dependencies": {
        "lodash": "4.17.4",
        "marked": "0.3.6",
        "minimist": "0.0.8"
      }
    },
    "node_modules/lodash": {
      "version": "4.17.4",
      "resolved": "https://registry.npmjs.org/lodash/-/lodash-4.17.4.tgz",
      "integrity": "sha512-6X37Sq9KCpLSXEh8uM12AKYlviHPNNk4RxiGBn4cmKGJinbXBneWIV7iE/nXkM928O7ytHcHb6+X6Svl0f4hXg=="
    },
    "node_modules/marked": {
      "version": "0.3.6",
      "resolved": "https://registry.npmjs.org/marked/-/marked-0.3.6.tgz",
      "integrity": "sha512-gE75oL01YUIxaBqgeGBuNNd8u0L+H1N6xeW/s+O57o5EC31aPX1M1lD4W9eGyHFJGTwOgMkqzYODZ4yp5w20gQ==",
      "bin": {
        "marked": "bin/marked"
      }
    },
    "node_modules/minimist": {
      "version": "0.0.8",
      "resolved": "https://registry.npmjs.org/minimist/-/minimist-0.0.8.tgz",
      "integrity": "sha512-miQKw5Hv4NS1Psg2517mV4e4dYNaO3++hjAvLOAzKqZ61rH8NS1SK+vbfBWZ5PY/Me/bEWhUwqMghEW5Fb9T7Q=="
    }
  }
}
'@
}

function Get-RiskyPackageJson {
@'
{
  "name": "ghas-admin-05-risky-change",
  "version": "1.0.0",
  "private": true,
  "dependencies": {
    "lodash": "4.17.4"
  }
}
'@
}

function Get-RiskyLockJson {
@'
{
  "name": "ghas-admin-05-risky-change",
  "version": "1.0.0",
  "lockfileVersion": 3,
  "requires": true,
  "packages": {
    "": {
      "name": "ghas-admin-05-risky-change",
      "version": "1.0.0",
      "dependencies": {
        "lodash": "4.17.4"
      }
    },
    "node_modules/lodash": {
      "version": "4.17.4",
      "resolved": "https://registry.npmjs.org/lodash/-/lodash-4.17.4.tgz",
      "integrity": "sha512-6X37Sq9KCpLSXEh8uM12AKYlviHPNNk4RxiGBn4cmKGJinbXBneWIV7iE/nXkM928O7ytHcHb6+X6Svl0f4hXg=="
    }
  }
}
'@
}

function Add-Fixture {
  Set-RemoteFile -Path 'dependency-lab/package.json' `
    -Message 'Add vulnerable dependency fixture' `
    -Content (Get-VulnerablePackageJson)
  Set-RemoteFile -Path 'dependency-lab/package-lock.json' `
    -Message 'Lock vulnerable dependency fixture' `
    -Content (Get-VulnerableLockJson)
  Set-RemoteFile -Path 'dependency-lab/build.sh' `
    -Message 'Add build-resolved dependency' `
    -Content "#!/usr/bin/env bash`nset -euo pipefail`nnpx --yes cowsay@1.6.0 `"GHAS dependency fixture build`"`n"
  Set-RemoteFile -Path 'dependency-lab/build-resolved-components.json' `
    -Message 'Record build-resolved dependency' `
    -Content @'
{
  "components": [
    {
      "name": "cowsay",
      "version": "1.6.0",
      "package_url": "pkg:npm/cowsay@1.6.0",
      "scope": "development"
    }
  ]
}
'@

  New-FixtureBranch -Branch 'feature/risky-dependency'
  Set-RemoteFile -Path 'risky-dependency/package.json' `
    -Message 'Add risky dependency for dependency review' `
    -Content (Get-RiskyPackageJson) `
    -Branch 'feature/risky-dependency'
  Set-RemoteFile -Path 'risky-dependency/package-lock.json' `
    -Message 'Lock risky dependency for dependency review' `
    -Content (Get-RiskyLockJson) `
    -Branch 'feature/risky-dependency'
}

function Test-Fixture {
  if (-not (Test-Repo)) {
    Write-Log fail "$FullRepo is missing"
    return $false
  }

  $Passed = $true
  foreach ($Path in @(
    'dependency-lab/package.json',
    'dependency-lab/package-lock.json',
    'dependency-lab/build.sh',
    'dependency-lab/build-resolved-components.json'
  )) {
    if (Test-RemoteFile -Path $Path) {
      Write-Log ok "$Path is present"
    }
    else {
      Write-Log fail "$Path is missing"
      $Passed = $false
    }
  }

  if (
    (Test-Branch -Branch 'feature/risky-dependency') -and
    (Test-RemoteFile -Path 'risky-dependency/package.json' -Branch 'feature/risky-dependency') -and
    (Test-RemoteFile -Path 'risky-dependency/package-lock.json' -Branch 'feature/risky-dependency')
  ) {
    Write-Log ok 'feature/risky-dependency is ready'
  }
  else {
    Write-Log fail 'feature/risky-dependency is incomplete'
    $Passed = $false
  }
  return $Passed
}

foreach ($Tool in @('gh', 'git')) {
  if (-not (Get-Command $Tool -ErrorAction SilentlyContinue)) {
    throw "$Tool is required."
  }
}

switch ($Command) {
  'provision' {
    if (-not $DryRun) {
      gh auth status 2>$null | Out-Null
      if ($LASTEXITCODE -ne 0) {
        throw 'Authenticate GitHub CLI first.'
      }
    }
    Import-JuiceShop
    Add-Fixture
    if ($DryRun) {
      Write-Log ok "Dry-run complete for $FullRepo"
      break
    }
    if (-not (Test-Fixture)) {
      throw 'Fixture provisioning is incomplete.'
    }
    Write-Log ok "Fixture ready: $FullRepo"
  }
  'status' {
    if (-not (Test-Fixture)) {
      exit 1
    }
  }
  'teardown' {
    if (-not (Test-Repo)) {
      Write-Log ok "$FullRepo is already absent"
      break
    }
    if (-not $Yes) {
      throw 'Teardown requires -Yes.'
    }
    Invoke-Mutation "delete $FullRepo" {
      gh repo delete $FullRepo --yes
    }
  }
}
