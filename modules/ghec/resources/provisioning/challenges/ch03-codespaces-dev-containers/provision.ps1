# challenges/ch03-codespaces-dev-containers/provision.ps1
#
# Dot-sourced by scripts/setup.ps1. CONTRACT:
#   Invoke-WthProvision / Invoke-WthTeardown / Invoke-WthStatus
#
# ch03: seeded Node/Express app + package.json + local-run README + a minimal
# .devcontainer/ baseline participants extend during the challenge.

function _Ch03-Full { "$($Global:WthOrg)/$($Global:WthRepo)" }

function _Ch03-Seed {
  Write-WthStep 'seeding Node/Express app on main'
  $o = $Global:WthOrg; $r = $Global:WthRepo; $ch = $Global:WthChid

  Set-WthFile -Org $o -Repo $r -Path 'README.md' -Message "seed README (wth-$ch)" -Content @"
# wth-$ch — Codespaces & Dev Containers

A tiny Node/Express app. Today it only runs if you install the right Node
version locally — your job is to make it reproducible in a Codespace.

## Run locally (the painful path)
1. Install Node 20+ and npm yourself.
2. ``npm install``
3. ``npm start``  -> serves http://localhost:3000
4. Forward/expose the port manually.

## Your task
- Inspect the seeded ``.devcontainer/devcontainer.json`` baseline.
- Extend it with dev-container Features, lifecycle polish, and port settings.
- Bonus: configure a prebuild.

> The seeded ``.devcontainer/`` is intentionally minimal — improve it as part of the challenge.
"@

  Set-WthFile -Org $o -Repo $r -Path 'package.json' -Message "seed package.json (wth-$ch)" -Content @"
{
  "name": "wth-$ch-app",
  "version": "1.0.0",
  "private": true,
  "engines": { "node": ">=20" },
  "scripts": { "start": "node src/index.js" },
  "dependencies": { "express": "^4.19.2" }
}
"@

  Set-WthFile -Org $o -Repo $r -Path 'src/index.js' -Message "seed src/index.js (wth-$ch)" -Content @"
const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

app.get('/', (_req, res) => {
  res.json({ ok: true, app: 'wth-$ch', node: process.version });
});

app.listen(port, () => {
  console.log('wth-$ch listening on http://localhost:' + port);
});
"@

  Set-WthFile -Org $o -Repo $r -Path '.gitignore' -Message "seed .gitignore (wth-$ch)" -Content @"
node_modules/
npm-debug.log
.env
"@

  Set-WthFile -Org $o -Repo $r -Path '.devcontainer/devcontainer.json' -Message "seed minimal devcontainer (wth-$ch)" -Content @"
{
  "name": "wth-$ch",
  "image": "mcr.microsoft.com/devcontainers/javascript-node:22",
  "postCreateCommand": "npm install",
  "forwardPorts": [3000],
  "portsAttributes": {
    "3000": {
      "label": "web",
      "onAutoForward": "notify"
    }
  }
}
"@
}

# ===========================================================================
function Invoke-WthProvision {
  New-WthRepo -Org $Global:WthOrg -Repo $Global:WthRepo -Visibility public
  if ((-not $Global:WthDryRun) -and (-not (Test-WthRepoExists -Org $Global:WthOrg -Repo $Global:WthRepo))) {
    Stop-Wth "repo $(_Ch03-Full) missing after create — aborting seed"
  }
  _Ch03-Seed
  Write-Host ''
  Write-WthInfo 'Next steps for the participant:'
  Write-WthInfo '  - inspect the seeded .devcontainer/devcontainer.json baseline'
  Write-WthInfo '  - add dev-container Features, postStartCommand, and VS Code customizations'
  Write-WthInfo "  - open the repo in a Codespace and run 'npm start'"
  Write-WthInfo '  - configure a prebuild for faster boots'
}

function Invoke-WthTeardown {
  if (-not (Confirm-WthPrefix -Name $Global:WthRepo -Chid $Global:WthChid)) { return }
  Remove-WthRepo -Org $Global:WthOrg -Repo $Global:WthRepo
}

function Invoke-WthStatus {
  Write-WthStep "status — $($Global:WthChid) in '$($Global:WthOrg)'"
  if (Test-WthRepoExists -Org $Global:WthOrg -Repo $Global:WthRepo) {
    if (Test-WthFileExists -Org $Global:WthOrg -Repo $Global:WthRepo -Path '.devcontainer/devcontainer.json') {
      Write-WthOk "repo $(_Ch03-Full) present — minimal devcontainer present"
    } else {
      Write-WthWarn "repo $(_Ch03-Full) present — .devcontainer/devcontainer.json missing"
    }
  } else {
    Write-WthInfo "repo $(_Ch03-Full) not provisioned"
  }
}
