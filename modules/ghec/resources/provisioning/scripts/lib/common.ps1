# common.ps1 — dry-run gating, minimal meta.yml reader, challenge resolution.

$Global:GhecVersion = '0.1.0'

# Invoke-GhecMutation -Plan <string> -Action <scriptblock>
# Runs a mutating action, or prints the plan under -DryRun and changes nothing.
function Invoke-GhecMutation {
  param([Parameter(Mandatory)][string]$Plan,
        [Parameter(Mandatory)][scriptblock]$Action)
  if ($Global:GhecDryRun) {
    Write-GhecPlan "would run: $Plan"
    return
  }
  & $Action
}

function Get-GhecMetaScalar {
  param([string]$File, [string]$Key)
  foreach ($line in Get-Content -LiteralPath $File) {
    if ($line -match ("^" + [regex]::Escape($Key) + ":\s*(.*)$")) {
      return (($Matches[1] -replace '\s*#.*$', '').Trim())
    }
  }
  return ''
}

function Get-GhecMetaList {
  param([string]$File, [string]$Key)
  $items = @(); $inKey = $false
  foreach ($line in Get-Content -LiteralPath $File) {
    if ($line -match ("^" + [regex]::Escape($Key) + ":\s*$")) { $inKey = $true; continue }
    if ($inKey) {
      if ($line -match '^\s*-\s*(.+?)\s*(#.*)?$') { $items += $Matches[1].Trim() }
      elseif ($line -match '^\S') { break }
    }
  }
  return $items
}

function Resolve-GhecChallengeDir {
  param([string]$Chid, [string]$Base)
  $m = Get-ChildItem -LiteralPath $Base -Directory -Filter "$Chid-*" | Select-Object -First 1
  if ($m) { return $m.FullName }
  return $null
}

function Import-GhecVersionsLock {
  param([string]$File)
  $result = @{ JUICE_SHOP_REF = 'v20.0.0'; GH_MIN_VERSION = '2.0.0' }
  if (Test-Path -LiteralPath $File) {
    foreach ($l in Get-Content -LiteralPath $File) {
      if ($l -match '^\s*JUICE_SHOP_REF\s*=\s*(\S+)') { $result.JUICE_SHOP_REF = $Matches[1] }
      if ($l -match '^\s*GH_MIN_VERSION\s*=\s*(\S+)') { $result.GH_MIN_VERSION = $Matches[1] }
    }
  }
  return $result
}
