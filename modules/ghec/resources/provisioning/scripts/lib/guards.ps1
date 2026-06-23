# guards.ps1 — namespace + destructive-action guard rails.

# Confirm-WthPrefix -Name <string> -Chid <string> -> $true only if inside wth-<chid>-*
function Confirm-WthPrefix {
  param([string]$Name, [string]$Chid)
  $expect = "wth-$Chid-"
  if ($Name.StartsWith($expect)) { return $true }
  Write-WthErr "refusing to touch '$Name' — outside namespace '$expect*'"
  return $false
}

# Confirm-WthDestructive -Prompt <string> -Chid <string> -> $true if confirmed
function Confirm-WthDestructive {
  param([string]$Prompt, [string]$Chid)
  if ($Global:WthAssumeYes) { return $true }
  $reply = Read-Host "$Prompt`n  type '$Chid' to confirm"
  return ($reply -eq $Chid)
}
