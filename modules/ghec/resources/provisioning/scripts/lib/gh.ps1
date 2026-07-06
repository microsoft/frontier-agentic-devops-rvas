# gh.ps1 — thin, idempotent wrappers over the gh CLI.

function Test-GhecRepoExists {
  param([string]$Org, [string]$Repo)
  gh repo view "$Org/$Repo" 2>$null | Out-Null
  return ($LASTEXITCODE -eq 0)
}

function Invoke-GhecRepoCreateWithFallback {
  param([string]$Org, [string]$Repo, [string]$Visibility, [string]$Description)
  if ($Global:GhecDryRun) {
    Write-GhecPlan "would run: gh repo create $Org/$Repo --$Visibility --description $Description"
    return $true
  }

  $output = gh repo create "$Org/$Repo" "--$Visibility" --description $Description 2>&1
  if ($LASTEXITCODE -eq 0) {
    if ($output) { $output | Write-Host }
    return $true
  }

  if ($Visibility -eq 'public' -and ($output -join "`n") -match 'Public repositories are not permitted for Enterprise Managed Users') {
    Write-GhecWarn "org '$Org' does not permit public repos (EMU); creating private repo instead"
    $output = gh repo create "$Org/$Repo" --private --description $Description 2>&1
    if ($LASTEXITCODE -eq 0) {
      if ($output) { $output | Write-Host }
      return $true
    }
  }

  if ($output) { $output | Write-Host }
  return $false
}

function New-GhecRepo {
  param([string]$Org, [string]$Repo, [string]$Visibility = 'public')
  if (Test-GhecRepoExists -Org $Org -Repo $Repo) {
    Write-GhecOk "repo $Org/$Repo already exists (skip)"; return
  }
  if (-not (Invoke-GhecRepoCreateWithFallback -Org $Org -Repo $Repo -Visibility $Visibility -Description 'ghec challenge artifact — safe to delete via teardown')) {
    exit 1
  }
}

function Remove-GhecRepo {
  param([string]$Org, [string]$Repo)
  if (-not (Test-GhecRepoExists -Org $Org -Repo $Repo)) {
    Write-GhecOk "repo $Org/$Repo absent (skip)"; return
  }
  Invoke-GhecMutation -Plan "gh repo delete $Org/$Repo --yes" -Action {
    gh repo delete "$Org/$Repo" --yes
  }
}

# Test-GhecFileExists -Org -Repo -Path [-Ref] -> $true if the file exists on that ref.
function Test-GhecFileExists {
  param([string]$Org, [string]$Repo, [string]$Path, [string]$Ref)
  $url = "repos/$Org/$Repo/contents/$Path"
  if ($Ref) { $url = "$url`?ref=$Ref" }
  gh api $url 2>$null | Out-Null
  return ($LASTEXITCODE -eq 0)
}

# Set-GhecFile — create-if-absent commit via the Contents API. dry-run aware.
function Set-GhecFile {
  param([string]$Org, [string]$Repo, [string]$Path, [string]$Message,
        [string]$Content, [string]$Branch)
  if (Test-GhecFileExists -Org $Org -Repo $Repo -Path $Path -Ref $Branch) {
    $where = if ($Branch) { " on $Branch" } else { '' }
    Write-GhecOk "file '$Path'$where exists (skip)"; return
  }
  $b64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($Content))
  $a = @('api', '-X', 'PUT', "repos/$Org/$Repo/contents/$Path", '-f', "message=$Message", '-f', "content=$b64")
  if ($Branch) { $a += @('-f', "branch=$Branch") }
  Invoke-GhecMutation -Plan "gh api PUT contents/$Path" -Action { gh @a }
}

# Test-GhecBranchExists -> $true if the branch ref exists.
function Test-GhecBranchExists {
  param([string]$Org, [string]$Repo, [string]$Branch)
  gh api "repos/$Org/$Repo/git/ref/heads/$Branch" 2>$null | Out-Null
  return ($LASTEXITCODE -eq 0)
}

# New-GhecBranch — create-if-absent; cuts $Branch from $Base's tip. dry-run aware.
function New-GhecBranch {
  param([string]$Org, [string]$Repo, [string]$Branch, [string]$Base = 'main')
  if (Test-GhecBranchExists -Org $Org -Repo $Repo -Branch $Branch) {
    Write-GhecOk "branch '$Branch' exists (skip)"; return
  }
  $sha = gh api "repos/$Org/$Repo/git/ref/heads/$Base" --jq '.object.sha' 2>$null
  if (-not $sha) {
    if ($Global:GhecDryRun) { Write-GhecPlan "would create branch '$Branch' from '$Base'"; return }
    Write-GhecWarn "cannot resolve '$Base' tip — skipping branch '$Branch'"; return
  }
  Invoke-GhecMutation -Plan "gh api POST git/refs $Branch" -Action {
    gh api -X POST "repos/$Org/$Repo/git/refs" -f ref="refs/heads/$Branch" -f sha=$sha
  }
}

# Edit-GhecFile — create-OR-update a file on $Branch (fetches blob sha when the
# path already exists). Used to engineer divergence/conflicts. dry-run aware.
function Edit-GhecFile {
  param([string]$Org, [string]$Repo, [string]$Path, [string]$Message,
        [string]$Content, [string]$Branch)
  $b64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($Content))
  $sha = gh api "repos/$Org/$Repo/contents/$Path`?ref=$Branch" --jq '.sha' 2>$null
  $hasSha = ($LASTEXITCODE -eq 0 -and $sha)
  $a = @('api', '-X', 'PUT', "repos/$Org/$Repo/contents/$Path", '-f', "message=$Message", '-f', "content=$b64", '-f', "branch=$Branch")
  if ($hasSha) { $a += @('-f', "sha=$sha") }
  Invoke-GhecMutation -Plan "gh api PUT contents/$Path (upsert on $Branch)" -Action { gh @a }
}

# Test-GhecFileContains -> $true if <Needle> is in the file (read-only).
function Test-GhecFileContains {
  param([string]$Org, [string]$Repo, [string]$Path, [string]$Needle, [string]$Ref)
  $url = "repos/$Org/$Repo/contents/$Path"
  if ($Ref) { $url = "$url`?ref=$Ref" }
  $b64 = gh api $url --jq '.content' 2>$null
  if ($LASTEXITCODE -ne 0 -or -not $b64) { return $false }
  $text = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String(($b64 -replace '\s', '')))
  return ($text -like "*$Needle*")
}

# New-GhecPr — create-if-absent; skips when a PR already exists for $Head. dry-run aware.
function New-GhecPr {
  param([string]$Org, [string]$Repo, [string]$Head, [string]$Base,
        [string]$Title, [string]$Body, [switch]$Draft)
  $n = gh pr list --repo "$Org/$Repo" --head $Head --state all --json number --jq 'length' 2>$null
  if ($n -and $n -ne '0') { Write-GhecOk "PR for head '$Head' exists (skip)"; return }
  $a = @('pr', 'create', '--repo', "$Org/$Repo", '--head', $Head, '--base', $Base, '--title', $Title, '--body', $Body)
  if ($Draft) { $a += '--draft' }
  Invoke-GhecMutation -Plan "gh pr create $Head -> $Base" -Action { gh @a }
}

# New-GhecRepoSoft — like New-GhecRepo but TOLERATES failure (e.g. --internal
# needs an enterprise-owned org). Emits a manual-step warning, never aborts.
function New-GhecRepoSoft {
  param([string]$Org, [string]$Repo, [string]$Visibility = 'public')
  if (Test-GhecRepoExists -Org $Org -Repo $Repo) {
    Write-GhecOk "repo $Org/$Repo already exists (skip)"; return
  }
  if ($Global:GhecDryRun) {
    Invoke-GhecRepoCreateWithFallback -Org $Org -Repo $Repo -Visibility $Visibility -Description 'ghec challenge artifact — safe to delete via teardown' | Out-Null
    return
  }
  if (Invoke-GhecRepoCreateWithFallback -Org $Org -Repo $Repo -Visibility $Visibility -Description 'ghec challenge artifact — safe to delete via teardown') { Write-GhecOk "created $Visibility repo $Org/$Repo" }
  else { Write-GhecWarn "could not create '$Visibility' repo $Org/$Repo — visibility may require an enterprise-owned org (MANUAL STEP)" }
}

# ---- teams -----------------------------------------------------------------
function Test-GhecTeamExists {
  param([string]$Org, [string]$Team)
  gh api "orgs/$Org/teams/$Team" 2>$null | Out-Null
  return ($LASTEXITCODE -eq 0)
}

function New-GhecTeam {
  param([string]$Org, [string]$Name, [string]$Description = 'ghec challenge team — safe to delete via teardown')
  if (Test-GhecTeamExists -Org $Org -Team $Name) { Write-GhecOk "team '$Name' exists (skip)"; return }
  Invoke-GhecMutation -Plan "gh api POST teams $Name" -Action {
    gh api -X POST "orgs/$Org/teams" -f name="$Name" -f description="$Description" -f privacy=closed
  }
}

function Remove-GhecTeam {
  param([string]$Org, [string]$Name)
  if (-not (Test-GhecTeamExists -Org $Org -Team $Name)) { Write-GhecOk "team '$Name' absent (skip)"; return }
  Invoke-GhecMutation -Plan "gh api DELETE teams/$Name" -Action {
    gh api -X DELETE "orgs/$Org/teams/$Name"
  }
}

function Add-GhecTeamRepo {
  param([string]$Org, [string]$Team, [string]$Repo, [string]$Permission = 'pull')
  Invoke-GhecMutation -Plan "team $Team += repo $Repo ($Permission)" -Action {
    gh api -X PUT "orgs/$Org/teams/$Team/repos/$Org/$Repo" -f permission="$Permission"
  }
}

function Add-GhecTeamMember {
  param([string]$Org, [string]$Team, [string]$User, [string]$Role = 'member')
  Invoke-GhecMutation -Plan "team $Team += member $User" -Action {
    gh api -X PUT "orgs/$Org/teams/$Team/memberships/$User" -f role="$Role"
  }
}
