# ch34 only provisions a private, namespaced decision-package workspace when an
# enterprise slug is not supplied. It never creates .github-private or changes
# AI Controls: those are customer-approved enterprise-owner actions in README.md.

$Global:GhecCh34FallbackRepo = "ghec-$($Global:GhecChid)-enterprise-agent-configuration"

function _Ch34-SeedFallback {
  $org = $Global:GhecOrg
  $repo = $Global:GhecCh34FallbackRepo

  Set-GhecFile -Org $org -Repo $repo -Path 'README.md' -Message 'Add Ch34 decision-package workspace' -Content @"
# Ch34 decision-package workspace

This private, namespaced repository is a fallback workspace for an
approval-ready Enterprise Agent Configuration package.

It is **not** ``.github-private``, is not an AI Controls configuration source,
and does not activate an enterprise custom agent. Move the reviewed files to
the approved customer ``.github-private`` source only after enterprise-owner
approval.
"@

  Set-GhecFile -Org $org -Repo $repo -Path 'proposed/CODEOWNERS' -Message 'Add proposed CODEOWNERS baseline' -Content @"
/agents/ @customer/enterprise-ai-controls
/CODEOWNERS @customer/enterprise-ai-controls
"@

  Set-GhecFile -Org $org -Repo $repo -Path 'proposed/agents/agentic-devsecops.agent.md' -Message 'Add proposed Agentic DevSecOps agent' -Content @"
---
name: Agentic DevSecOps
description: Reviews proposed changes for secure delivery practices and produces evidence-backed recommendations.
tools: [read, search]
disable-model-invocation: true
---

# Agentic DevSecOps

Review the supplied repository context and identify secure-delivery risks,
missing tests, and evidence gaps. Explain recommendations and affected files.

Do not execute commands, edit files, access secrets, add integrations, or
approve exceptions. Escalate policy conflicts to the named customer owner.
"@

  Set-GhecFile -Org $org -Repo $repo -Path 'proposed/organization-custom-instructions.txt' -Message 'Add proposed organization instructions' -Content @"
Follow approved secure-delivery standards and explain material security risks.
Do not request, expose, or place secrets in code, logs, or examples.
Escalate policy exceptions to the repository security owner; do not approve them.
"@
}

function Invoke-GhecProvision {
  if ($Global:GhecEnterprise) {
    Write-GhecInfo "enterprise '$($Global:GhecEnterprise)' supplied; no fallback is created"
    Write-GhecInfo 'complete the approved .github-private and AI Controls actions in Ch34 README'
    return
  }

  $org = $Global:GhecOrg
  $repo = $Global:GhecCh34FallbackRepo
  New-GhecRepo -Org $org -Repo $repo -Visibility private
  if ((-not $Global:GhecDryRun) -and (-not (Test-GhecRepoExists -Org $org -Repo $repo))) {
    Stop-Ghec "fallback repository $org/$repo missing after create"
  }

  _Ch34-SeedFallback
  Write-GhecWarn "$org/$repo is a decision-package workspace only; it is not enterprise configuration."
}

function Invoke-GhecTeardown {
  $repo = $Global:GhecCh34FallbackRepo
  if (-not (Confirm-GhecPrefix -Name $repo -Chid $Global:GhecChid)) { return }
  Remove-GhecRepo -Org $Global:GhecOrg -Repo $repo
}

function Invoke-GhecStatus {
  $org = $Global:GhecOrg
  $repo = $Global:GhecCh34FallbackRepo
  Write-GhecStep "status — $($Global:GhecChid) in '$org'"
  if (Test-GhecRepoExists -Org $org -Repo $repo) {
    Write-GhecOk "fallback decision-package workspace $org/$repo present"
  } else {
    Write-GhecInfo "fallback decision-package workspace $org/$repo absent"
  }
  Write-GhecInfo 'AI Controls and .github-private status require enterprise-owner evidence; see Ch34 README.'
}
