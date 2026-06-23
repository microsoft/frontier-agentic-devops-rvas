# juice-shop-import.ps1 — import OWASP Juice Shop at a pinned tag into a fresh,
# history-stripped, PUBLIC repo. NEVER vendored — pulled from upstream at runtime.
# Juice Shop is MIT; its LICENSE travels with the clone and is preserved.

$Global:WthJuiceShopUpstream = 'https://github.com/juice-shop/juice-shop.git'

# Import-WthJuiceShop -Org <string> -Repo <string> -Ref <string>
# Requires $Global:WthChid (namespace guard) and $Global:WthDryRun.
function Import-WthJuiceShop {
  param([string]$Org, [string]$Repo, [string]$Ref)

  if (-not (Confirm-WthPrefix -Name $Repo -Chid $Global:WthChid)) { return }

  if (Test-WthRepoExists -Org $Org -Repo $Repo) {
    Write-WthOk "juice-shop repo $Org/$Repo already exists (skip import)"; return
  }

  if ($Global:WthDryRun) {
    Write-WthPlan "would shallow-clone $Global:WthJuiceShopUpstream @ $Ref"
    Write-WthPlan "would strip history, fresh init, push to $Org/$Repo (public, MIT preserved)"
    return
  }

  if (-not (Get-Command git -ErrorAction SilentlyContinue)) { Stop-Wth 'git is required for the Juice Shop import' }

  $work = Join-Path ([System.IO.Path]::GetTempPath()) ("wth-js-" + [guid]::NewGuid().ToString('N'))
  New-Item -ItemType Directory -Path $work | Out-Null
  try {
    $src = Join-Path $work 'src'
    Write-WthStep "cloning Juice Shop @ $Ref (shallow, single tag)"
    git clone --depth 1 --branch $Ref $Global:WthJuiceShopUpstream $src 2>$null
    if ($LASTEXITCODE -ne 0) { Stop-Wth "failed to clone Juice Shop at ref '$Ref' — verify the tag exists upstream" }

    if (-not (Test-Path (Join-Path $src 'LICENSE'))) { Write-WthWarn 'upstream LICENSE not found — verify MIT attribution manually' }

    Write-WthStep 'stripping history and re-initialising'
    Remove-Item -Recurse -Force (Join-Path $src '.git')
    Push-Location $src
    try {
      git init -q
      git symbolic-ref HEAD refs/heads/main
      git add -A
      git -c user.name='wth-bot' -c user.email='wth-bot@users.noreply.github.com' commit -q -m "Import OWASP Juice Shop $Ref (MIT) for wth challenge"

      Write-WthStep "creating public repo $Org/$Repo and pushing"
      gh repo create "$Org/$Repo" --public --description "OWASP Juice Shop $Ref (MIT) — wth challenge target, safe to delete" | Out-Null
      git remote add origin "https://github.com/$Org/$Repo.git"
      git push -u origin main 2>$null | Out-Null
    } finally { Pop-Location }

    Write-WthOk "imported Juice Shop $Ref -> $Org/$Repo (LICENSE preserved)"
  } finally {
    Remove-Item -Recurse -Force $work -ErrorAction SilentlyContinue
  }
}
