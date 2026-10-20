$Ch20IntegrationDir = Join-Path $PSScriptRoot '../../../integration'

function _Ch20-SeedRepo {
  $org = $Global:GhecOrg
  $repo = $Global:GhecRepo
  foreach ($file in @('handler.cjs', 'handler.test.cjs')) {
    if (-not (Test-Path (Join-Path $Ch20IntegrationDir $file) -PathType Leaf)) {
      Stop-Ghec "missing Ch20 integration starter: $file"
    }
  }
  $readme = @'
# Ch20 integration test repository

Use the approved integration gap from the activity guide. Native Actions or a
Projects workflow may already solve it.

The optional App example receives signed issue webhooks and adds one triage
label. Configure the App and approved HTTPS receiver before running it.
Keep the private key and webhook secret outside this repository.

Run `npm test` for local checks and `npm start` for the configured HTTP receiver.
'@
  Set-GhecFile -Org $org -Repo $repo -Path 'README.md' -Message 'Add integration overview' -Content $readme
  $package = @'
{
  "name": "ghec-ch20-automation-capstone",
  "private": true,
  "engines": { "node": ">=22" },
  "scripts": {
    "start": "node src/handler.cjs",
    "test": "node --test src/handler.test.cjs"
  }
}
'@
  Set-GhecFile -Org $org -Repo $repo -Path 'package.json' -Message 'Add integration commands' -Content $package
  foreach ($file in @('handler.cjs', 'handler.test.cjs')) {
    $content = Get-Content -LiteralPath (Join-Path $Ch20IntegrationDir $file) -Raw
    Set-GhecFile -Org $org -Repo $repo -Path "src/$file" -Message "Add integration $file" -Content $content
  }
}

function Invoke-GhecProvision {
  New-GhecRepo -Org $Global:GhecOrg -Repo $Global:GhecRepo -Visibility 'private'
  if ((-not $Global:GhecDryRun) -and (-not (Test-GhecRepoExists -Org $Global:GhecOrg -Repo $Global:GhecRepo))) {
    Stop-Ghec "repo $($Global:GhecOrg)/$($Global:GhecRepo) missing after create"
  }
  _Ch20-SeedRepo
  Write-GhecInfo 'Next: follow Ch20 to test native automation or configure the approved App receiver.'
}

function Invoke-GhecTeardown {
  if (-not (Confirm-GhecPrefix -Name $Global:GhecRepo -Chid $Global:GhecChid)) { return }
  Remove-GhecRepo -Org $Global:GhecOrg -Repo $Global:GhecRepo
}

function Invoke-GhecStatus {
  if (Test-GhecRepoExists -Org $Global:GhecOrg -Repo $Global:GhecRepo) {
    if (Test-GhecFileExists -Org $Global:GhecOrg -Repo $Global:GhecRepo -Path 'src/handler.cjs') {
      Write-GhecOk "repo $($Global:GhecOrg)/$($Global:GhecRepo) has the HTTP receiver"
    } else {
      Write-GhecWarn "repo $($Global:GhecOrg)/$($Global:GhecRepo) is missing src/handler.cjs"
    }
  } else {
    Write-GhecInfo "repo $($Global:GhecOrg)/$($Global:GhecRepo) not provisioned"
  }
}
