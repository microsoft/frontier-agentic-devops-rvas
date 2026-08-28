# shellcheck shell=bash
#
# ch34 only provisions a private, namespaced decision-package workspace when an
# enterprise slug is not supplied. It never creates .github-private or changes
# AI Controls: those are customer-approved enterprise-owner actions in README.md.

FALLBACK_REPO="ghec-${CHID}-enterprise-agent-configuration"

_ch34_seed_fallback() {
  gh_put_file "$ORG" "$FALLBACK_REPO" "README.md" \
    "Add Ch34 decision-package workspace" \
"# Ch34 decision-package workspace

This private, namespaced repository is a fallback workspace for an
approval-ready Enterprise Agent Configuration package.

It is **not** \`.github-private\`, is not an AI Controls configuration source,
and does not activate an enterprise custom agent. Move the reviewed files to
the approved customer \`.github-private\` source only after enterprise-owner
approval."

  gh_put_file "$ORG" "$FALLBACK_REPO" "proposed/CODEOWNERS" \
    "Add proposed CODEOWNERS baseline" \
"/agents/ @customer/enterprise-ai-controls
/CODEOWNERS @customer/enterprise-ai-controls
"

  gh_put_file "$ORG" "$FALLBACK_REPO" "proposed/agents/agentic-devsecops.agent.md" \
    "Add proposed Agentic DevSecOps agent" \
"---
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
"

  gh_put_file "$ORG" "$FALLBACK_REPO" "proposed/organization-custom-instructions.txt" \
    "Add proposed organization instructions" \
"Follow approved secure-delivery standards and explain material security risks.
Do not request, expose, or place secrets in code, logs, or examples.
Escalate policy exceptions to the repository security owner; do not approve them.
"
}

ghec_provision() {
  if [[ -n "${ENTERPRISE:-}" ]]; then
    log_info "enterprise '$ENTERPRISE' supplied; no fallback is created"
    log_info "complete the approved .github-private and AI Controls actions in Ch34 README"
    return 0
  fi

  gh_create_repo "$ORG" "$FALLBACK_REPO" private
  if [[ "$DRY_RUN" != "true" ]] && ! gh_repo_exists "$ORG" "$FALLBACK_REPO"; then
    die "fallback repository $ORG/$FALLBACK_REPO missing after create"
  fi

  _ch34_seed_fallback
  log_warn "$ORG/$FALLBACK_REPO is a decision-package workspace only; it is not enterprise configuration."
}

ghec_teardown() {
  guard_prefix "$FALLBACK_REPO" "$CHID" || return 1
  gh_delete_repo "$ORG" "$FALLBACK_REPO"
}

ghec_status() {
  log_step "status — $CHID in '$ORG'"
  if gh_repo_exists "$ORG" "$FALLBACK_REPO"; then
    log_ok "fallback decision-package workspace $ORG/$FALLBACK_REPO present"
  else
    log_info "fallback decision-package workspace $ORG/$FALLBACK_REPO absent"
  fi
  log_info "AI Controls and .github-private status require enterprise-owner evidence; see Ch34 README."
}
