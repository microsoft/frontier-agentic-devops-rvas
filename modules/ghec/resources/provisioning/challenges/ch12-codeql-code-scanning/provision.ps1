# challenges/ch12-codeql-code-scanning/provision.ps1
#
# PowerShell twin of ch12.

$Global:WthJsRepo = "wth-$($Global:WthChid)-juice-shop"

function _Ch12-JsFull { "$($Global:WthOrg)/$($Global:WthJsRepo)" }

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
  Write-WthStep 'seeding advanced-setup CodeQL workflow'
  Set-WthFile -Org $Global:WthOrg -Repo $Global:WthJsRepo -Path '.github/workflows/codeql.yml' `
    -Message 'Add CodeQL advanced setup (javascript-typescript)' -Content (_Ch12-CodeqlWorkflow)
}

function _Ch12-SeedInsecureBranch {
  Write-WthStep 'seeding feature/insecure-endpoint (deliberately vulnerable change)'
  New-WthBranch -Org $Global:WthOrg -Repo $Global:WthJsRepo -Branch 'feature/insecure-endpoint' -Base 'main'
  $code = @'
// wth-ch12 SEED — deliberately vulnerable. Do NOT ship.
// Open as a PR against main so CodeQL flags it on the diff (SQLi + XSS).
const sqlite3 = require('sqlite3')
module.exports = function wthInsecureLookup () {
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
  Set-WthFile -Org $Global:WthOrg -Repo $Global:WthJsRepo -Path 'routes/wthInsecureLookup.js' `
    -Message 'Add insecure lookup endpoint (seed, for CodeQL PR gating)' -Content $code -Branch 'feature/insecure-endpoint'
}

# ===========================================================================
function Invoke-WthProvision {
  Import-WthJuiceShop -Org $Global:WthOrg -Repo $Global:WthJsRepo -Ref $Global:WthJuiceShopRef
  if ((-not $Global:WthDryRun) -and (-not (Test-WthRepoExists -Org $Global:WthOrg -Repo $Global:WthJsRepo))) {
    Stop-Wth "repo $(_Ch12-JsFull) missing after import — aborting seed"
  }
  _Ch12-SeedWorkflow
  _Ch12-SeedInsecureBranch
  Write-Host ''
  Write-WthInfo 'Next steps for the participant:'
  Write-WthInfo '  - confirm code scanning runs (default or the seeded advanced workflow)'
  Write-WthInfo '  - open a PR from feature/insecure-endpoint and watch CodeQL gate it'
  Write-WthInfo '  - triage alerts and try Copilot Autofix on a finding'
}

function Invoke-WthTeardown {
  if (-not (Confirm-WthPrefix -Name $Global:WthJsRepo -Chid $Global:WthChid)) { return }
  Remove-WthRepo -Org $Global:WthOrg -Repo $Global:WthJsRepo
}

function Invoke-WthStatus {
  Write-WthStep "status — $($Global:WthChid) in '$($Global:WthOrg)'"
  if (Test-WthRepoExists -Org $Global:WthOrg -Repo $Global:WthJsRepo) {
    $wf = if (Test-WthFileExists -Org $Global:WthOrg -Repo $Global:WthJsRepo -Path '.github/workflows/codeql.yml') { 'present' } else { 'MISSING' }
    $branch = if (Test-WthBranchExists -Org $Global:WthOrg -Repo $Global:WthJsRepo -Branch 'feature/insecure-endpoint') { 'present' } else { 'MISSING' }
    Write-WthOk "repo $(_Ch12-JsFull) present — codeql.yml $wf, feature/insecure-endpoint $branch"
  } else {
    Write-WthInfo "repo $(_Ch12-JsFull) not provisioned"
  }
}
