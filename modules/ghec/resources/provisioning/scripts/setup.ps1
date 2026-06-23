#!/usr/bin/env pwsh
#
# setup.ps1 — wth provisioning CLI (PowerShell entrypoint, Windows / cross-platform pwsh).
#
#   ./setup.ps1 <doctor|provision|status|teardown> <ch##> -Org <org> `
#       [-Enterprise <slug>] [-Ref <juiceShopRef>] [-DryRun] [-Yes]
#
# One challenge per invocation. Everything created is namespaced wth-<chid>-*.
# Runs against a CUSTOMER-OWNED org: idempotent, prefix-guarded, dry-run aware.
#
[CmdletBinding()]
param(
  [Parameter(Position = 0)][string]$Command,
  [Parameter(Position = 1)][string]$Chid,
  [string]$Org,
  [string]$Enterprise,
  [string]$Ref,
  [switch]$DryRun,
  [switch]$Yes
)

$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot  = Split-Path -Parent $ScriptDir
$ChallengesDir = Join-Path $RepoRoot 'challenges'

. (Join-Path $ScriptDir 'lib/log.ps1')
. (Join-Path $ScriptDir 'lib/common.ps1')
. (Join-Path $ScriptDir 'lib/auth.ps1')
. (Join-Path $ScriptDir 'lib/guards.ps1')
. (Join-Path $ScriptDir 'lib/gh.ps1')
. (Join-Path $ScriptDir 'lib/juice-shop-import.ps1')

function Show-Usage {
  Write-Host @"
wth provisioning CLI (v$Global:WthVersion)

USAGE:
  ./setup.ps1 <command> <ch##> -Org <org> [options]

COMMANDS:
  doctor      Preflight: tooling, auth, required scopes/capabilities (no changes)
  provision   Create all wth-<chid>-* starting state (idempotent)
  status      Report what wth-<chid>-* artifacts currently exist
  teardown    Delete ONLY wth-<chid>-* artifacts (confirmation required)

OPTIONS:
  -Org <org>          Target org (required for provision/status/teardown)
  -Enterprise <slug>  Enterprise slug (only for enterprise-tier challenges)
  -Ref <ref>          Override Juice Shop ref (default: pinned v20.0.0)
  -DryRun             Print the mutation plan; change nothing
  -Yes                Skip the teardown confirmation prompt

EXAMPLES:
  ./setup.ps1 doctor ch01 -Org acme-co
  ./setup.ps1 provision ch01 -Org acme-co -DryRun
  ./setup.ps1 provision ch01 -Org acme-co
  ./setup.ps1 teardown ch01 -Org acme-co
"@
}

if (-not $Command) { Show-Usage; exit 1 }
if ($Command -in @('-h', '--help', 'help')) { Show-Usage; exit 0 }
if ($Command -notin @('doctor', 'provision', 'status', 'teardown')) {
  Stop-Wth "unknown command '$Command' (expected doctor|provision|status|teardown)"
}
if (-not $Chid) { Stop-Wth 'missing challenge id (e.g. ch01)' }

# ---- globals consumed by lib + per-challenge provisioners ------------------
$Global:WthDryRun    = [bool]$DryRun
$Global:WthAssumeYes = [bool]$Yes
$Global:WthChid      = $Chid
$Global:WthOrg       = $Org
$Global:WthEnterprise = $Enterprise

# ---- resolve challenge + meta ---------------------------------------------
$ChDir = Resolve-WthChallengeDir -Chid $Chid -Base $ChallengesDir
if (-not $ChDir) { Stop-Wth "no challenge folder found for '$Chid' under $ChallengesDir" }
$Meta = Join-Path $ChDir 'meta.yml'
if (-not (Test-Path -LiteralPath $Meta)) { Stop-Wth "missing meta.yml at $Meta" }

$Slug = Get-WthMetaScalar -File $Meta -Key 'slug'
$App  = Get-WthMetaScalar -File $Meta -Key 'app'
$EmuCompat = Get-WthMetaScalar -File $Meta -Key 'emu_compatible'

# Juice Shop ref precedence: -Ref > meta.yml > versions.lock
$VL = Import-WthVersionsLock -File (Join-Path $ScriptDir 'versions.lock')
$JuiceShopRef = $Ref
if (-not $JuiceShopRef) { $JuiceShopRef = Get-WthMetaScalar -File $Meta -Key 'juice_shop_ref' }
if (-not $JuiceShopRef) { $JuiceShopRef = $VL.JUICE_SHOP_REF }

$Global:WthSlug         = $Slug
$Global:WthApp          = $App
$Global:WthJuiceShopRef = $JuiceShopRef
$Global:WthNamespace    = "wth-$Chid-"
$Global:WthRepo         = "wth-$Chid-$Slug"
$Global:WthMeta         = $Meta

function Require-Org { if (-not $Org) { Stop-Wth "-Org <org> is required for '$Command'" } }

function Import-Challenge {
  $pf = Join-Path $ChDir 'provision.ps1'
  if (-not (Test-Path -LiteralPath $pf)) { Stop-Wth "no provision.ps1 for $Chid — author must add $pf" }
  . $pf
  foreach ($fn in @('Invoke-WthProvision', 'Invoke-WthTeardown', 'Invoke-WthStatus')) {
    if (-not (Get-Command $fn -ErrorAction SilentlyContinue)) {
      Stop-Wth "$pf does not define required function $fn"
    }
  }
}

# ---- doctor ----------------------------------------------------------------
function Show-MinScopes {
  Write-WthStep "minimum token scopes for $Chid"
  $scopes = @('repo', 'read:org')
  if ((Get-WthMetaList -File $Meta -Key 'provision_creates') -match 'project') { $scopes += 'project' }
  if ($App -eq 'juice-shop') { $scopes += 'workflow' }
  Write-WthInfo ("classic PAT scopes:   " + ($scopes -join ', '))
  Write-WthInfo "fine-grained PAT:     Administration:RW, Contents:RW, Issues:RW, Metadata:R (org '$Org')"
  $reqs = Get-WthMetaList -File $Meta -Key 'requires'
  if ($reqs -contains 'copilot') { Write-WthWarn 'Copilot cannot be enabled via a PAT — an org owner must enable it.' }
  if ($reqs -contains 'ghas')    { Write-WthInfo 'GHAS: no extra PAT scope on PUBLIC repos; ensure Actions + code scanning are enabled.' }
}

function Invoke-Doctor {
  $fail = $false
  Write-WthStep "doctor — preflight for $Chid ($Slug)"
  foreach ($tool in @('gh', 'git', 'jq')) {
    if (Get-Command $tool -ErrorAction SilentlyContinue) { Write-WthOk "$tool present" }
    else { Write-WthErr "$tool NOT found — install it before provisioning"; $fail = $true }
  }

  if (Test-WthAuth) { Write-WthOk "gh authenticated as '$(Get-WthLogin)'" }
  else { Write-WthErr 'gh not authenticated'; Show-WthAuthHint; $fail = $true }

  Write-WthStep 'required capabilities'
  foreach ($cap in (Get-WthMetaList -File $Meta -Key 'requires')) {
    switch ($cap) {
      'org'     { Write-WthInfo "org-owner access on '$Org'" }
      'ghas'    { Write-WthWarn 'GHAS — FREE on PUBLIC repos; private/internal needs Code Security/Secret Protection' }
      'copilot' { Write-WthWarn 'Copilot must be enabled at org level by an org owner' }
      default   { Write-WthInfo "capability: $cap" }
    }
  }

  Show-MinScopes

  if ($Chid -eq 'ch19' -or $EmuCompat -eq 'false') {
    Write-WthWarn 'EMU: Copilot cloud agent is NOT available on EMU repos — ch19 needs a non-EMU org.'
  }
  if ($App -eq 'juice-shop') { Write-WthWarn 'metered: scanning workflows consume Actions minutes (free on public repos).' }
  if ($Chid -match '^ch(03|04|05|18)$') { Write-WthWarn 'metered: may consume Actions/Codespaces minutes.' }

  Write-Host ''
  if (-not $fail) { Write-WthOk "DOCTOR PASS — ready to provision $Chid" }
  else { Write-WthErr 'DOCTOR FAIL — resolve the items above first'; exit 1 }
}

function Invoke-TeardownFlow {
  Write-WthWarn "About to DELETE all $($Global:WthNamespace)* artifacts in org '$Org'."
  if ($Global:WthDryRun) {
    Write-WthInfo 'dry-run: nothing will be deleted.'
  } elseif (-not (Confirm-WthDestructive -Prompt "Confirm teardown of $Chid in '$Org'" -Chid $Chid)) {
    Stop-Wth 'teardown aborted by user.'
  }
  Invoke-WthTeardown
  Write-WthOk "teardown of $Chid complete."
}

# ---- dispatch --------------------------------------------------------------
switch ($Command) {
  'doctor' { Invoke-Doctor }
  'provision' {
    Require-Org
    if (-not (Test-WthAuth)) { Show-WthAuthHint; Stop-Wth "authenticate first (run: ./setup.ps1 doctor $Chid -Org $Org)" }
    Import-Challenge
    Write-WthStep "provision $Chid -> org '$Org' (dry-run=$($Global:WthDryRun))"
    Invoke-WthProvision
    Write-WthOk "provision of $Chid complete."
  }
  'status' {
    Require-Org
    Import-Challenge
    Invoke-WthStatus
  }
  'teardown' {
    Require-Org
    if (-not (Test-WthAuth)) { Show-WthAuthHint; Stop-Wth 'authenticate first' }
    Import-Challenge
    Invoke-TeardownFlow
  }
}
