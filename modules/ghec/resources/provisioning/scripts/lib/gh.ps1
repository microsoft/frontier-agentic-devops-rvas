# gh.ps1 — thin, idempotent wrappers over the gh CLI.

function Test-WthRepoExists {
  param([string]$Org, [string]$Repo)
  gh repo view "$Org/$Repo" 2>$null | Out-Null
  return ($LASTEXITCODE -eq 0)
}

function Invoke-WthRepoCreateWithFallback {
  param([string]$Org, [string]$Repo, [string]$Visibility, [string]$Description)
  if ($Global:WthDryRun) {
    Write-WthPlan "would run: gh repo create $Org/$Repo --$Visibility --description $Description"
    return $true
  }

  $output = gh repo create "$Org/$Repo" "--$Visibility" --description $Description 2>&1
  if ($LASTEXITCODE -eq 0) {
    if ($output) { $output | Write-Host }
    return $true
  }

  if ($Visibility -eq 'public' -and ($output -join "`n") -match 'Public repositories are not permitted for Enterprise Managed Users') {
    Write-WthWarn "org '$Org' does not permit public repos (EMU); creating private repo instead"
    $output = gh repo create "$Org/$Repo" --private --description $Description 2>&1
    if ($LASTEXITCODE -eq 0) {
      if ($output) { $output | Write-Host }
      return $true
    }
  }

  if ($output) { $output | Write-Host }
  return $false
}

function New-WthRepo {
  param([string]$Org, [string]$Repo, [string]$Visibility = 'public')
  if (Test-WthRepoExists -Org $Org -Repo $Repo) {
    Write-WthOk "repo $Org/$Repo already exists (skip)"; return
  }
  if (-not (Invoke-WthRepoCreateWithFallback -Org $Org -Repo $Repo -Visibility $Visibility -Description 'wth challenge artifact — safe to delete via teardown')) {
    exit 1
  }
}

function Remove-WthRepo {
  param([string]$Org, [string]$Repo)
  if (-not (Test-WthRepoExists -Org $Org -Repo $Repo)) {
    Write-WthOk "repo $Org/$Repo absent (skip)"; return
  }
  Invoke-WthMutation -Plan "gh repo delete $Org/$Repo --yes" -Action {
    gh repo delete "$Org/$Repo" --yes
  }
}

# Test-WthFileExists -Org -Repo -Path [-Ref] -> $true if the file exists on that ref.
function Test-WthFileExists {
  param([string]$Org, [string]$Repo, [string]$Path, [string]$Ref)
  $url = "repos/$Org/$Repo/contents/$Path"
  if ($Ref) { $url = "$url`?ref=$Ref" }
  gh api $url 2>$null | Out-Null
  return ($LASTEXITCODE -eq 0)
}

# Set-WthFile — create-if-absent commit via the Contents API. dry-run aware.
function Set-WthFile {
  param([string]$Org, [string]$Repo, [string]$Path, [string]$Message,
        [string]$Content, [string]$Branch)
  if (Test-WthFileExists -Org $Org -Repo $Repo -Path $Path -Ref $Branch) {
    $where = if ($Branch) { " on $Branch" } else { '' }
    Write-WthOk "file '$Path'$where exists (skip)"; return
  }
  $b64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($Content))
  $a = @('api', '-X', 'PUT', "repos/$Org/$Repo/contents/$Path", '-f', "message=$Message", '-f', "content=$b64")
  if ($Branch) { $a += @('-f', "branch=$Branch") }
  Invoke-WthMutation -Plan "gh api PUT contents/$Path" -Action { gh @a }
}

# Test-WthBranchExists -> $true if the branch ref exists.
function Test-WthBranchExists {
  param([string]$Org, [string]$Repo, [string]$Branch)
  gh api "repos/$Org/$Repo/git/ref/heads/$Branch" 2>$null | Out-Null
  return ($LASTEXITCODE -eq 0)
}

# New-WthBranch — create-if-absent; cuts $Branch from $Base's tip. dry-run aware.
function New-WthBranch {
  param([string]$Org, [string]$Repo, [string]$Branch, [string]$Base = 'main')
  if (Test-WthBranchExists -Org $Org -Repo $Repo -Branch $Branch) {
    Write-WthOk "branch '$Branch' exists (skip)"; return
  }
  $sha = gh api "repos/$Org/$Repo/git/ref/heads/$Base" --jq '.object.sha' 2>$null
  if (-not $sha) {
    if ($Global:WthDryRun) { Write-WthPlan "would create branch '$Branch' from '$Base'"; return }
    Write-WthWarn "cannot resolve '$Base' tip — skipping branch '$Branch'"; return
  }
  Invoke-WthMutation -Plan "gh api POST git/refs $Branch" -Action {
    gh api -X POST "repos/$Org/$Repo/git/refs" -f ref="refs/heads/$Branch" -f sha=$sha
  }
}

# Edit-WthFile — create-OR-update a file on $Branch (fetches blob sha when the
# path already exists). Used to engineer divergence/conflicts. dry-run aware.
function Edit-WthFile {
  param([string]$Org, [string]$Repo, [string]$Path, [string]$Message,
        [string]$Content, [string]$Branch)
  $b64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($Content))
  $sha = gh api "repos/$Org/$Repo/contents/$Path`?ref=$Branch" --jq '.sha' 2>$null
  $hasSha = ($LASTEXITCODE -eq 0 -and $sha)
  $a = @('api', '-X', 'PUT', "repos/$Org/$Repo/contents/$Path", '-f', "message=$Message", '-f', "content=$b64", '-f', "branch=$Branch")
  if ($hasSha) { $a += @('-f', "sha=$sha") }
  Invoke-WthMutation -Plan "gh api PUT contents/$Path (upsert on $Branch)" -Action { gh @a }
}

# Test-WthFileContains -> $true if <Needle> is in the file (read-only).
function Test-WthFileContains {
  param([string]$Org, [string]$Repo, [string]$Path, [string]$Needle, [string]$Ref)
  $url = "repos/$Org/$Repo/contents/$Path"
  if ($Ref) { $url = "$url`?ref=$Ref" }
  $b64 = gh api $url --jq '.content' 2>$null
  if ($LASTEXITCODE -ne 0 -or -not $b64) { return $false }
  $text = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String(($b64 -replace '\s', '')))
  return ($text -like "*$Needle*")
}

# New-WthPr — create-if-absent; skips when a PR already exists for $Head. dry-run aware.
function New-WthPr {
  param([string]$Org, [string]$Repo, [string]$Head, [string]$Base,
        [string]$Title, [string]$Body, [switch]$Draft)
  $n = gh pr list --repo "$Org/$Repo" --head $Head --state all --json number --jq 'length' 2>$null
  if ($n -and $n -ne '0') { Write-WthOk "PR for head '$Head' exists (skip)"; return }
  $a = @('pr', 'create', '--repo', "$Org/$Repo", '--head', $Head, '--base', $Base, '--title', $Title, '--body', $Body)
  if ($Draft) { $a += '--draft' }
  Invoke-WthMutation -Plan "gh pr create $Head -> $Base" -Action { gh @a }
}

# New-WthRepoSoft — like New-WthRepo but TOLERATES failure (e.g. --internal
# needs an enterprise-owned org). Emits a manual-step warning, never aborts.
function New-WthRepoSoft {
  param([string]$Org, [string]$Repo, [string]$Visibility = 'public')
  if (Test-WthRepoExists -Org $Org -Repo $Repo) {
    Write-WthOk "repo $Org/$Repo already exists (skip)"; return
  }
  if ($Global:WthDryRun) {
    Invoke-WthRepoCreateWithFallback -Org $Org -Repo $Repo -Visibility $Visibility -Description 'wth challenge artifact — safe to delete via teardown' | Out-Null
    return
  }
  if (Invoke-WthRepoCreateWithFallback -Org $Org -Repo $Repo -Visibility $Visibility -Description 'wth challenge artifact — safe to delete via teardown') { Write-WthOk "created $Visibility repo $Org/$Repo" }
  else { Write-WthWarn "could not create '$Visibility' repo $Org/$Repo — visibility may require an enterprise-owned org (MANUAL STEP)" }
}

# ---- teams -----------------------------------------------------------------
function Test-WthTeamExists {
  param([string]$Org, [string]$Team)
  gh api "orgs/$Org/teams/$Team" 2>$null | Out-Null
  return ($LASTEXITCODE -eq 0)
}

function New-WthTeam {
  param([string]$Org, [string]$Name, [string]$Description = 'wth challenge team — safe to delete via teardown')
  if (Test-WthTeamExists -Org $Org -Team $Name) { Write-WthOk "team '$Name' exists (skip)"; return }
  Invoke-WthMutation -Plan "gh api POST teams $Name" -Action {
    gh api -X POST "orgs/$Org/teams" -f name="$Name" -f description="$Description" -f privacy=closed
  }
}

function Remove-WthTeam {
  param([string]$Org, [string]$Name)
  if (-not (Test-WthTeamExists -Org $Org -Team $Name)) { Write-WthOk "team '$Name' absent (skip)"; return }
  Invoke-WthMutation -Plan "gh api DELETE teams/$Name" -Action {
    gh api -X DELETE "orgs/$Org/teams/$Name"
  }
}

function Add-WthTeamRepo {
  param([string]$Org, [string]$Team, [string]$Repo, [string]$Permission = 'pull')
  Invoke-WthMutation -Plan "team $Team += repo $Repo ($Permission)" -Action {
    gh api -X PUT "orgs/$Org/teams/$Team/repos/$Org/$Repo" -f permission="$Permission"
  }
}

function Add-WthTeamMember {
  param([string]$Org, [string]$Team, [string]$User, [string]$Role = 'member')
  Invoke-WthMutation -Plan "team $Team += member $User" -Action {
    gh api -X PUT "orgs/$Org/teams/$Team/memberships/$User" -f role="$Role"
  }
}
