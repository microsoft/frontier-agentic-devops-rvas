# guards.ps1 — namespace + destructive-action guard rails.

# Confirm-GhecPrefix -Name <string> -Chid <string> -> $true only if inside ghec-<chid>-*
function Confirm-GhecPrefix {
  param([string]$Name, [string]$Chid)
  $expect = "ghec-$Chid-"
  if ($Name.StartsWith($expect)) { return $true }
  Write-GhecErr "refusing to touch '$Name' — outside namespace '$expect*'"
  return $false
}

# Confirm-GhecDestructive -Prompt <string> -Chid <string> -> $true if confirmed
function Confirm-GhecDestructive {
  param([string]$Prompt, [string]$Chid)
  if ($Global:GhecAssumeYes) { return $true }
  $reply = Read-Host "$Prompt`n  type '$Chid' to confirm"
  return ($reply -eq $Chid)
}
