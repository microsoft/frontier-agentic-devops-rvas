# challenges/ch14-sso-saml-scim/provision.ps1
#
# PowerShell twin of ch14. No Juice Shop; seeds an identity runbook repo and
# prints staged identity-settings references. SSO/SCIM are NOT auto-enabled.

$Global:WthRunbookRepo = "wth-$($Global:WthChid)-identity-runbook"

function _Ch14-RepoFull { "$($Global:WthOrg)/$($Global:WthRunbookRepo)" }

function _Ch14-SeedRunbook {
  Write-WthStep 'seeding identity runbook content'
  $org = $Global:WthOrg
  $repo = $Global:WthRunbookRepo

  $readme = @"
# wth-ch14 — Identity Runbook

Working notes for wiring **SAML SSO** and **SCIM** provisioning for the
``$org`` organization. Nothing here changes live settings; it is the plan you
execute by hand in the org identity settings.

- ``SAML-RUNBOOK.md`` — IdP SAML app settings + GitHub SSO configuration order
- ``SCIM-CHECKLIST.md`` — SCIM rollout checklist
- ``scripts/join-leave-test.sh`` — manual join/leave provisioning test

> SSO is intentionally NOT enabled by setup — enabling it is the exercise.
"@
  Set-WthFile -Org $org -Repo $repo -Path 'README.md' -Message 'Add identity runbook overview' -Content $readme

  $saml = @"
# SAML SSO Runbook — $org

## IdP side (Entra ID / Okta / etc.)
1. Create a new SAML application.
2. Set the **Entity ID** to ``https://github.com/orgs/$org``.
3. Set the **ACS URL** to ``https://github.com/orgs/$org/saml/consume``.
4. Map ``NameID`` to the user primary email.

## GitHub side
1. Open the org **Authentication security** page:
   ``https://github.com/organizations/$org/settings/security``
2. Enable SAML SSO, paste the IdP **Sign-on URL**, **Issuer**, and **certificate**.
3. **Test** the configuration before requiring it.
4. Require SAML SSO only after a successful test.
"@
  Set-WthFile -Org $org -Repo $repo -Path 'SAML-RUNBOOK.md' -Message 'Add SAML configuration runbook' -Content $saml

  $scim = @"
# SCIM Rollout Checklist — $org

- [ ] SAML SSO enabled and tested first (SCIM rides on top of SAML).
- [ ] Generate a SCIM provisioning token for the IdP.
- [ ] SCIM API base: ``https://api.github.com/scim/v2/organizations/$org``
- [ ] Configure provisioning in the IdP and assign a pilot group.
- [ ] Verify a provisioned user appears under org members.
- [ ] Verify de-provisioning (leave) removes access.
- [ ] Expand from pilot group to all users.
"@
  Set-WthFile -Org $org -Repo $repo -Path 'SCIM-CHECKLIST.md' -Message 'Add SCIM rollout checklist' -Content $scim

  $script = @'
#!/usr/bin/env bash
# wth-ch14 — manual join/leave provisioning test (read-only helper).
# Run AFTER SCIM is configured. Replace USER with a pilot account login.
set -euo pipefail
ORG="${1:?usage: join-leave-test.sh <org> <user>}"
USER="${2:?usage: join-leave-test.sh <org> <user>}"
echo "Checking SCIM-provisioned identity for $USER in $ORG ..."
gh api "scim/v2/organizations/$ORG/Users?filter=userName eq \"$USER\"" \
  --jq '.Resources[] | {id, userName, active}'
echo "De-provision the user in your IdP, then re-run to confirm 'active: false'."
'@
  Set-WthFile -Org $org -Repo $repo -Path 'scripts/join-leave-test.sh' -Message 'Add join/leave provisioning test script' -Content $script
}

# ===========================================================================
function Invoke-WthProvision {
  New-WthRepo -Org $Global:WthOrg -Repo $Global:WthRunbookRepo -Visibility 'public'
  _Ch14-SeedRunbook
  Write-Host ''
  Write-WthInfo 'Staged identity settings reference (act on these by hand):'
  Write-WthInfo "  - Authentication security page: https://github.com/organizations/$($Global:WthOrg)/settings/security"
  Write-WthInfo "  - SCIM API base: https://api.github.com/scim/v2/organizations/$($Global:WthOrg)"
  Write-WthWarn 'manual: SSO/SAML and SCIM are NOT auto-enabled — configuring them is the challenge.'
}

function Invoke-WthTeardown {
  if (-not (Confirm-WthPrefix -Name $Global:WthRunbookRepo -Chid $Global:WthChid)) { return }
  Remove-WthRepo -Org $Global:WthOrg -Repo $Global:WthRunbookRepo
  Write-WthWarn 'manual: if you enabled SSO/SCIM in org settings, disable them by hand — teardown does not touch identity settings.'
}

function Invoke-WthStatus {
  Write-WthStep "status — $($Global:WthChid) in '$($Global:WthOrg)'"
  if (Test-WthRepoExists -Org $Global:WthOrg -Repo $Global:WthRunbookRepo) {
    $runbook = if (Test-WthFileExists -Org $Global:WthOrg -Repo $Global:WthRunbookRepo -Path 'SAML-RUNBOOK.md') { 'present' } else { 'MISSING' }
    $checklist = if (Test-WthFileExists -Org $Global:WthOrg -Repo $Global:WthRunbookRepo -Path 'SCIM-CHECKLIST.md') { 'present' } else { 'MISSING' }
    Write-WthOk "repo $(_Ch14-RepoFull) present — SAML-RUNBOOK.md $runbook, SCIM-CHECKLIST.md $checklist"
  } else {
    Write-WthInfo "repo $(_Ch14-RepoFull) not provisioned"
  }
}
