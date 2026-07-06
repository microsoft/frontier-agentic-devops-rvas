# juice-shop-import.ps1 — import OWASP Juice Shop at a pinned tag into a fresh,
# history-stripped, PUBLIC repo. NEVER vendored — pulled from upstream at runtime.
# Juice Shop is MIT; its LICENSE travels with the clone and is preserved.

$Global:GhecJuiceShopUpstream = 'https://github.com/juice-shop/juice-shop.git'

# Import-GhecJuiceShop -Org <string> -Repo <string> -Ref <string>
# Requires $Global:GhecChid (namespace guard) and $Global:GhecDryRun.
function Import-GhecJuiceShop {
  param([string]$Org, [string]$Repo, [string]$Ref)

  if (-not (Confirm-GhecPrefix -Name $Repo -Chid $Global:GhecChid)) { return }

  if (Test-GhecRepoExists -Org $Org -Repo $Repo) {
    Write-GhecOk "juice-shop repo $Org/$Repo already exists (skip import)"; return
  }

  if ($Global:GhecDryRun) {
    Write-GhecPlan "would shallow-clone $Global:GhecJuiceShopUpstream @ $Ref"
    Write-GhecPlan "would strip history, fresh init, push to $Org/$Repo (public, MIT preserved)"
    return
  }

  if (-not (Get-Command git -ErrorAction SilentlyContinue)) { Stop-Ghec 'git is required for the Juice Shop import' }

  $work = Join-Path ([System.IO.Path]::GetTempPath()) ("ghec-js-" + [guid]::NewGuid().ToString('N'))
  New-Item -ItemType Directory -Path $work | Out-Null
  try {
    $src = Join-Path $work 'src'
    Write-GhecStep "cloning Juice Shop @ $Ref (shallow, single tag)"
    git clone --depth 1 --branch $Ref $Global:GhecJuiceShopUpstream $src 2>$null
    if ($LASTEXITCODE -ne 0) { Stop-Ghec "failed to clone Juice Shop at ref '$Ref' — verify the tag exists upstream" }

    if (-not (Test-Path (Join-Path $src 'LICENSE'))) { Write-GhecWarn 'upstream LICENSE not found — verify MIT attribution manually' }

    Write-GhecStep 'stripping history and re-initialising'
    Remove-Item -Recurse -Force (Join-Path $src '.git')
    Push-Location $src
    try {
      git init -q
      git symbolic-ref HEAD refs/heads/main
      git add -A
      git -c user.name='ghec-bot' -c user.email='ghec-bot@users.noreply.github.com' commit -q -m "Import OWASP Juice Shop $Ref (MIT) for ghec challenge"

      Write-GhecStep "creating public repo $Org/$Repo and pushing"
      if (-not (Invoke-GhecRepoCreateWithFallback -Org $Org -Repo $Repo -Visibility public -Description "OWASP Juice Shop $Ref (MIT) — ghec challenge target, safe to delete")) {
        exit 1
      }
      git remote add origin "https://github.com/$Org/$Repo.git"
      git push -u origin main 2>$null | Out-Null
    } finally { Pop-Location }

    Write-GhecOk "imported Juice Shop $Ref -> $Org/$Repo (LICENSE preserved)"
  } finally {
    Remove-Item -Recurse -Force $work -ErrorAction SilentlyContinue
  }
}
