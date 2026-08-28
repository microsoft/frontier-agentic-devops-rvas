# challenges/ch03-codespaces-dev-containers/provision.ps1
#
# Dot-sourced by scripts/setup.ps1. CONTRACT:
#   Invoke-GhecProvision / Invoke-GhecTeardown / Invoke-GhecStatus
#
# ch03: seeded Node/Express app + package.json + local-run README + a minimal
# .devcontainer/ baseline participants extend during the challenge.

function _Ch03-Full { "$($Global:GhecOrg)/$($Global:GhecRepo)" }

function _Ch03-Seed {
  Write-GhecStep 'seeding Node/Express app on main'
  $o = $Global:GhecOrg; $r = $Global:GhecRepo; $ch = $Global:GhecChid

  Set-GhecFile -Org $o -Repo $r -Path 'README.md' -Message "seed README (ghec-$ch)" -Content @"
# ghec-$ch — Codespaces & Dev Containers

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

  Set-GhecFile -Org $o -Repo $r -Path 'package.json' -Message "seed package.json (ghec-$ch)" -Content @"
{
  "name": "ghec-$ch-app",
  "version": "1.0.0",
  "private": true,
  "engines": { "node": ">=20" },
  "scripts": { "start": "node src/index.js" },
  "dependencies": { "express": "^4.19.2" }
}
"@

  Set-GhecFile -Org $o -Repo $r -Path 'src/index.js' -Message "seed src/index.js (ghec-$ch)" -Content @"
const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

app.get('/', (_req, res) => {
  res.json({ ok: true, app: 'ghec-$ch', node: process.version });
});

app.listen(port, () => {
  console.log('ghec-$ch listening on http://localhost:' + port);
});
"@

  Set-GhecFile -Org $o -Repo $r -Path '.gitignore' -Message "seed .gitignore (ghec-$ch)" -Content @"
node_modules/
npm-debug.log
.env
"@

  Set-GhecFile -Org $o -Repo $r -Path '.devcontainer/devcontainer.json' -Message "seed minimal devcontainer (ghec-$ch)" -Content @"
{
  "name": "ghec-$ch",
  "image": "mcr.microsoft.com/devcontainers/javascript-node:22",
  "onCreateCommand": "npm install",
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
function Invoke-GhecProvision {
  New-GhecRepo -Org $Global:GhecOrg -Repo $Global:GhecRepo -Visibility public
  if ((-not $Global:GhecDryRun) -and (-not (Test-GhecRepoExists -Org $Global:GhecOrg -Repo $Global:GhecRepo))) {
    Stop-Ghec "repo $(_Ch03-Full) missing after create — aborting seed"
  }
  _Ch03-Seed
  Write-Host ''
  Write-GhecInfo 'Next steps for the participant:'
  Write-GhecInfo '  - inspect the seeded .devcontainer/devcontainer.json baseline'
  Write-GhecInfo '  - add dev-container Features, postStartCommand, and VS Code customizations'
  Write-GhecInfo "  - open the repo in a Codespace and run 'npm start'"
  Write-GhecInfo '  - tune a prebuild for freshness, cost, and developer regions'
}

function Invoke-GhecTeardown {
  if (-not (Confirm-GhecPrefix -Name $Global:GhecRepo -Chid $Global:GhecChid)) { return }
  Remove-GhecRepo -Org $Global:GhecOrg -Repo $Global:GhecRepo
}

function Invoke-GhecStatus {
  Write-GhecStep "status — $($Global:GhecChid) in '$($Global:GhecOrg)'"
  if (Test-GhecRepoExists -Org $Global:GhecOrg -Repo $Global:GhecRepo) {
    if (Test-GhecFileExists -Org $Global:GhecOrg -Repo $Global:GhecRepo -Path '.devcontainer/devcontainer.json') {
      Write-GhecOk "repo $(_Ch03-Full) present — minimal devcontainer present"
    } else {
      Write-GhecWarn "repo $(_Ch03-Full) present — .devcontainer/devcontainer.json missing"
    }
  } else {
    Write-GhecInfo "repo $(_Ch03-Full) not provisioned"
  }
}
