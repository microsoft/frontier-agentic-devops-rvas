# challenges/ch12-codeql-code-scanning/provision.ps1
#
# PowerShell twin of ch12.

$Global:GhecJsRepo = "ghec-$($Global:GhecChid)-juice-shop"

function _Ch12-JsFull { "$($Global:GhecOrg)/$($Global:GhecJsRepo)" }

function _Ch12-CodeqlWorkflow {
@'
name: CodeQL
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  schedule:
    - cron: "0 6 * * 1"
permissions:
  contents: read
  security-events: write
jobs:
  analyze:
    name: Analyze (javascript-typescript)
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Initialize CodeQL
        uses: github/codeql-action/init@v3
        with:
          languages: javascript-typescript
      - name: Perform CodeQL Analysis
        uses: github/codeql-action/analyze@v3
'@
}

function _Ch12-SeedWorkflow {
  Write-GhecStep 'seeding advanced-setup CodeQL workflow'
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecJsRepo -Path '.github/workflows/codeql.yml' `
    -Message 'Add CodeQL advanced setup (javascript-typescript)' -Content (_Ch12-CodeqlWorkflow)
}

function _Ch12-SeedInsecureBranch {
  Write-GhecStep 'seeding feature/insecure-endpoint (deliberately vulnerable change)'
  New-GhecBranch -Org $Global:GhecOrg -Repo $Global:GhecJsRepo -Branch 'feature/insecure-endpoint' -Base 'main'
  $code = @'
// ghec-ch12 SEED — deliberately vulnerable. Do NOT ship.
// Open as a PR against main so CodeQL flags it on the diff (SQLi + XSS).
const sqlite3 = require('sqlite3')
module.exports = function ghecInsecureLookup () {
  return (req, res) => {
    const db = new sqlite3.Database(':memory:')
    // SQL injection: untrusted input concatenated straight into the query.
    const q = "SELECT * FROM Products WHERE name = '" + req.query.name + "'"
    db.all(q, (err, rows) => {
      // Reflected XSS: untrusted input echoed into the HTML response.
      res.send('<h1>Results for ' + req.query.name + '</h1>' + JSON.stringify(rows || err))
    })
  }
}
'@
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecJsRepo -Path 'routes/ghecInsecureLookup.js' `
    -Message 'Add insecure lookup endpoint (seed, for CodeQL PR gating)' -Content $code -Branch 'feature/insecure-endpoint'
}

# ===========================================================================
function Invoke-GhecProvision {
  Import-GhecJuiceShop -Org $Global:GhecOrg -Repo $Global:GhecJsRepo -Ref $Global:GhecJuiceShopRef
  if ((-not $Global:GhecDryRun) -and (-not (Test-GhecRepoExists -Org $Global:GhecOrg -Repo $Global:GhecJsRepo))) {
    Stop-Ghec "repo $(_Ch12-JsFull) missing after import — aborting seed"
  }
  _Ch12-SeedWorkflow
  _Ch12-SeedInsecureBranch
  Write-Host ''
  Write-GhecInfo 'Next steps for the participant:'
  Write-GhecInfo '  - confirm code scanning runs (default or the seeded advanced workflow)'
  Write-GhecInfo '  - open a PR from feature/insecure-endpoint and watch CodeQL gate it'
  Write-GhecInfo '  - triage alerts and try Copilot Autofix on a finding'
}

function Invoke-GhecTeardown {
  if (-not (Confirm-GhecPrefix -Name $Global:GhecJsRepo -Chid $Global:GhecChid)) { return }
  Remove-GhecRepo -Org $Global:GhecOrg -Repo $Global:GhecJsRepo
}

function Invoke-GhecStatus {
  Write-GhecStep "status — $($Global:GhecChid) in '$($Global:GhecOrg)'"
  if (Test-GhecRepoExists -Org $Global:GhecOrg -Repo $Global:GhecJsRepo) {
    $wf = if (Test-GhecFileExists -Org $Global:GhecOrg -Repo $Global:GhecJsRepo -Path '.github/workflows/codeql.yml') { 'present' } else { 'MISSING' }
    $branch = if (Test-GhecBranchExists -Org $Global:GhecOrg -Repo $Global:GhecJsRepo -Branch 'feature/insecure-endpoint') { 'present' } else { 'MISSING' }
    Write-GhecOk "repo $(_Ch12-JsFull) present — codeql.yml $wf, feature/insecure-endpoint $branch"
  } else {
    Write-GhecInfo "repo $(_Ch12-JsFull) not provisioned"
  }
}
