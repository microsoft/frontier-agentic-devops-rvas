#!/usr/bin/env pwsh
#
# setup.ps1 — provisioning entrypoint (PowerShell, Windows / cross-platform pwsh).
#
#   ./setup.ps1 <doctor|provision|status|teardown> <ch##|ghas-##> -Org <org> `
#       [-Enterprise <slug>] [-Ref <juiceShopRef>] [-DryRun] [-Yes]
#
# One challenge per invocation. Everything created is namespaced ghec-<chid>-*.
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
  [switch]$Force,
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
setup.ps1 — provisioning entrypoint (v$Global:GhecVersion)

USAGE:
  ./setup.ps1 <command> <ch##|ghas-##> -Org <org> [options]

COMMANDS:
  doctor      Preflight: tooling, auth, required scopes/capabilities (no changes)
  provision   Create all ghec-<chid>-* starting state (idempotent)
              (alias: setup)
  status      Report what ghec-<chid>-* artifacts currently exist
  teardown    Delete ONLY ghec-<chid>-* artifacts (confirmation required)

OPTIONS:
  -Org <org>          Target org (required for provision/status/teardown)
  -Enterprise <slug>  Enterprise slug (only for enterprise-tier challenges)
  -Ref <ref>          Override Juice Shop ref (default: pinned v20.0.0)
  -DryRun             Print the mutation plan; change nothing
  -Force              Reconcile overwrite-safe seeded resources where supported
  -Yes                Skip the teardown confirmation prompt

EXAMPLES:
  ./setup.ps1 doctor ch01 -Org acme-co
  ./setup.ps1 provision ghas-00 -Org acme-co
  ./setup.ps1 provision ch01 -Org acme-co -DryRun
  ./setup.ps1 provision ch01 -Org acme-co
  ./setup.ps1 teardown ch01 -Org acme-co
"@
}

if (-not $Command) { Show-Usage; exit 1 }
if ($Command -in @('-h', '--help', 'help')) { Show-Usage; exit 0 }
# `setup` is a friendly alias for `provision` (the verb used throughout the docs).
if ($Command -eq 'setup') { $Command = 'provision' }
if ($Command -notin @('doctor', 'provision', 'status', 'teardown')) {
  Stop-Ghec "unknown command '$Command' (expected doctor|provision|setup|status|teardown)"
}
if (-not $Chid) { Stop-Ghec 'missing challenge id (e.g. ch01 or ghas-00)' }
if ($Chid -notmatch '^(ch\d\d|ghas-\d\d)$') {
  Stop-Ghec "invalid challenge id '$Chid' (expected ch## or ghas-##)"
}

# ---- globals consumed by lib + per-challenge provisioners ------------------
$Global:GhecDryRun    = [bool]$DryRun
$Global:GhecAssumeYes = [bool]$Yes
$Global:GhecForce     = [bool]$Force
$Global:GhecChid      = $Chid
$Global:GhecOrg       = $Org
$Global:GhecEnterprise = $Enterprise

# ---- resolve challenge + meta ---------------------------------------------
$ChDir = Resolve-GhecChallengeDir -Chid $Chid -Base $ChallengesDir
if (-not $ChDir) { Stop-Ghec "no challenge folder found for '$Chid' under $ChallengesDir" }
$Meta = Join-Path $ChDir 'meta.yml'
if (-not (Test-Path -LiteralPath $Meta)) {
  $ChFolder = Split-Path -Leaf $ChDir
  $ModuleRoot = Split-Path -Parent (Split-Path -Parent $RepoRoot)
  $CanonicalMeta = Join-Path (Join-Path (Join-Path $ModuleRoot 'challenges') $ChFolder) 'meta.yml'
  if (-not (Test-Path -LiteralPath $CanonicalMeta)) {
    Stop-Ghec "missing meta.yml at $Meta (also checked $CanonicalMeta)"
  }
  $Meta = $CanonicalMeta
}

$Slug = Get-GhecMetaScalar -File $Meta -Key 'slug'
if (-not $Slug) {
  if (-not $ChFolder) { $ChFolder = Split-Path -Leaf $ChDir }
  $Slug = $ChFolder -replace "^$([regex]::Escape($Chid))-", ''
}
$App  = Get-GhecMetaScalar -File $Meta -Key 'app'
if (-not $App) { $App = Get-GhecMetaScalar -File $Meta -Key 'app_dependency' }
$EmuCompat = Get-GhecMetaScalar -File $Meta -Key 'emu_compatible'

# Juice Shop ref precedence: -Ref > meta.yml > versions.lock
$VL = Import-GhecVersionsLock -File (Join-Path $ScriptDir 'versions.lock')
$JuiceShopRef = $Ref
if (-not $JuiceShopRef) { $JuiceShopRef = Get-GhecMetaScalar -File $Meta -Key 'juice_shop_ref' }
if (-not $JuiceShopRef) { $JuiceShopRef = $VL.JUICE_SHOP_REF }

$Global:GhecSlug         = $Slug
$Global:GhecApp          = $App
$Global:GhecJuiceShopRef = $JuiceShopRef
$Global:GhecNamespace    = "ghec-$Chid-"
$Global:GhecRepo         = "ghec-$Chid-$Slug"
$Global:GhecMeta         = $Meta

function Require-Org { if (-not $Org) { Stop-Ghec "-Org <org> is required for '$Command'" } }

function Get-ChallengeRequires {
  $explicit = @(Get-GhecMetaList -File $Meta -Key 'requires')
  if ($explicit.Count -gt 0) { return $explicit }

  $caps = @(Get-GhecMetaList -File $Meta -Key 'prerequisite_capabilities')
  $tags = @(Get-GhecMetaList -File $Meta -Key 'tags')
  $title = Get-GhecMetaScalar -File $Meta -Key 'title'
  $reqs = New-Object System.Collections.Generic.List[string]
  $reqs.Add('org')
  $capText = (($caps + $tags) -join "`n")
  if ($capText -match '(?i)advanced security|ghas|code scanning|secret scanning|dependabot') {
    $reqs.Add('ghas')
  }
  $copilotText = (($caps + $tags + @($title)) -join "`n")
  if ($copilotText -match '(?i)copilot') { $reqs.Add('copilot') }
  return @($reqs | Select-Object -Unique)
}

function Import-Challenge {
  $pf = Join-Path $ChDir 'provision.ps1'
  if (-not (Test-Path -LiteralPath $pf)) { Stop-Ghec "no provision.ps1 for $Chid — author must add $pf" }
  . $pf
  foreach ($fn in @('Invoke-GhecProvision', 'Invoke-GhecTeardown', 'Invoke-GhecStatus')) {
    if (-not (Get-Command $fn -ErrorAction SilentlyContinue)) {
      Stop-Ghec "$pf does not define required function $fn"
    }
  }
}

# ---- doctor ----------------------------------------------------------------
function Show-MinScopes {
  Write-GhecStep "minimum token scopes for $Chid"
  $scopes = @('repo', 'read:org')
  if ((Get-GhecMetaList -File $Meta -Key 'provision_creates') -match 'project') {
    $scopes += @('project', 'read:project')
  }
  if ($App -eq 'juice-shop') { $scopes += 'workflow' }
  Write-GhecInfo ("classic PAT scopes:   " + ($scopes -join ', '))
  Write-GhecInfo "fine-grained PAT:     Administration:RW, Contents:RW, Issues:RW, Metadata:R (org '$Org')"
  $reqs = Get-ChallengeRequires
  if ($reqs -contains 'copilot') { Write-GhecWarn 'Copilot cannot be enabled via a PAT — an org owner must enable it.' }
  if ($reqs -contains 'ghas')    { Write-GhecInfo 'GHAS: no extra PAT scope on PUBLIC repos; ensure Actions + code scanning are enabled.' }
}

function Invoke-Doctor {
  $fail = $false
  Write-GhecStep "doctor — preflight for $Chid ($Slug)"
  foreach ($tool in @('gh', 'git', 'jq')) {
    if (Get-Command $tool -ErrorAction SilentlyContinue) { Write-GhecOk "$tool present" }
    else { Write-GhecErr "$tool NOT found — install it before provisioning"; $fail = $true }
  }

  if (Test-GhecAuth) { Write-GhecOk "gh authenticated as '$(Get-GhecLogin)'" }
  else { Write-GhecErr 'gh not authenticated'; Show-GhecAuthHint; $fail = $true }

  Write-GhecStep 'required capabilities'
  foreach ($cap in (Get-ChallengeRequires)) {
    switch ($cap) {
      'org'     { Write-GhecInfo "org-owner access on '$Org'" }
      'ghas'    { Write-GhecWarn 'GHAS — FREE on PUBLIC repos; private/internal needs Code Security/Secret Protection' }
      'copilot' { Write-GhecWarn 'Copilot must be enabled at org level by an org owner' }
      default   { Write-GhecInfo "capability: $cap" }
    }
  }

  Show-MinScopes

  if ($Chid -eq 'ch19' -or $EmuCompat -eq 'false') {
    Write-GhecWarn 'EMU: Copilot cloud agent is NOT available on EMU repos — ch19 needs a non-EMU org.'
  }
  if ($App -eq 'juice-shop') { Write-GhecWarn 'metered: scanning workflows consume Actions minutes (free on public repos).' }
  if ($Chid -match '^ch(03|04|05|18)$') { Write-GhecWarn 'metered: may consume Actions/Codespaces minutes.' }

  Write-Host ''
  if (-not $fail) { Write-GhecOk "DOCTOR PASS — ready to provision $Chid" }
  else { Write-GhecErr 'DOCTOR FAIL — resolve the items above first'; exit 1 }
}

function Invoke-TeardownFlow {
  Write-GhecWarn "About to DELETE all $($Global:GhecNamespace)* artifacts in org '$Org'."
  if ($Global:GhecDryRun) {
    Write-GhecInfo 'dry-run: nothing will be deleted.'
  } elseif (-not (Confirm-GhecDestructive -Prompt "Confirm teardown of $Chid in '$Org'" -Chid $Chid)) {
    Stop-Ghec 'teardown aborted by user.'
  }
  Invoke-GhecTeardown
  Write-GhecOk "teardown of $Chid complete."
}

# ---- dispatch --------------------------------------------------------------
switch ($Command) {
  'doctor' { Invoke-Doctor }
  'provision' {
    Require-Org
    if (-not (Test-GhecAuth)) { Show-GhecAuthHint; Stop-Ghec "authenticate first (run: ./setup.ps1 doctor $Chid -Org $Org)" }
    Import-Challenge
    Write-GhecStep "provision $Chid -> org '$Org' (dry-run=$($Global:GhecDryRun))"
    Invoke-GhecProvision
    Write-GhecOk "provision of $Chid complete."
  }
  'status' {
    Require-Org
    Import-Challenge
    Invoke-GhecStatus
  }
  'teardown' {
    Require-Org
    if (-not (Test-GhecAuth)) { Show-GhecAuthHint; Stop-Ghec 'authenticate first' }
    Import-Challenge
    Invoke-TeardownFlow
  }
}
