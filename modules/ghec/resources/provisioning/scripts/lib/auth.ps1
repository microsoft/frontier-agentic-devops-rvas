# auth.ps1 — authentication checks. NEVER handles raw tokens.
# Tokens enter only via `gh auth login` (device flow) or the GH_TOKEN env var.

function Test-WthAuth {
  gh auth status 2>$null | Out-Null
  return ($LASTEXITCODE -eq 0)
}

function Show-WthAuthHint {
  Write-Host @"
  Not authenticated. Authenticate WITHOUT leaking a token to shell history:
      gh auth login                 # interactive device flow (recommended)
      # or:  `$env:GH_TOKEN = '...'  # set in your environment, never as a flag
"@ -ForegroundColor Yellow
}

function Get-WthLogin {
  $login = gh api user --jq '.login' 2>$null
  if ($LASTEXITCODE -eq 0) { return $login }
  return ''
}
