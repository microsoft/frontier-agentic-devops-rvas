#!/usr/bin/env bash

# The evaluator is read-only. It returns an array of checks that use the same
# states as discovery: verified, missing, insufficient_permission, unavailable,
# unverified, and manual_prerequisite.

wizard_readiness_check() {
  local package="$1" name="$2" subject="$3" required="$4" result="$5" message="$6"
  printf '%s\n' "$result" | jq -c --arg package "$package" --arg name "$name" --arg subject "$subject" \
    --argjson required "$required" --arg message "$message" '
    . as $result |
    ($result.state |
      if .=="verified" then "ready"
      elif .=="manual_prerequisite" then "manual"
      elif .=="unavailable" then "blocked"
      else . end) as $state |
    {id:($package+":"+$name+":"+$subject),package:$package,subject:$subject,required:$required,
     state:$state,message:$message,discovery:$result}'
}

wizard_readiness_add() {
  local checks="$1" check="$2"
  printf '%s\n%s\n' "$checks" "$check" | jq -sc '.[0]+[.[1]]'
}

wizard_readiness_match_account() {
  local result="$1" expected="$2"
  jq -c --arg expected "$expected" '
    if .state=="verified" and ((.data.login//"")|ascii_downcase)!=($expected|ascii_downcase)
    then .state="unverified" |
      .detail=("The active account is "+(.data.login//"unknown")+"; expected "+$expected+".")
    else . end' <<<"$result"
}

wizard_readiness_require_item() {
  local result="$1" field="$2" expected="$3"
  jq -c --arg field "$field" --arg expected "$expected" '
    if .state!="verified" then .
    elif any(.data[]?; ((.[$field]//"")|tostring|ascii_downcase)==($expected|ascii_downcase)) then .
    else .state="missing" | .detail=($expected+" was not found in the inventory.") end' <<<"$result"
}

wizard_readiness_repository() {
  local result="$1" repository="$2"
  jq -c --argjson repository "$repository" '
    if .state!="verified" then .
    else
      ([.data[]?|select(((.name//"")|ascii_downcase)==($repository.name|ascii_downcase))][0] // null) as $found |
      if ($repository.adopt//false) then
        if $found==null then
          .state="missing" | .detail=($repository.name+" was not found in the organization repository inventory.")
        elif ($repository.verification.resource_id//null)!=null and ($found.id//null)!=null and
             (($repository.verification.resource_id|tostring)!=($found.id|tostring)) then
          .state="unverified" | .detail=($repository.name+" now resolves to a different repository ID.")
        else .data=$found end
      elif $found!=null then
        .state="unverified" | .detail=($repository.name+" already exists; select repository adoption or choose another name.")
      else
        .detail=($repository.name+" is available for creation.")
      end
    end' <<<"$result"
}

wizard_readiness_package_selected() {
  local packages="$1" package="$2"
  jq -e --arg package "$package" 'index($package)!=null' <<<"$packages" >/dev/null
}

wizard_readiness_evaluate() {
  local config="$1" host actor enterprise checks='[]' result organizations_result check org packages login repo governance
  local ghaw_checked=false org_pending_creation=false
  jq -e 'type=="object" and (.host|type)=="string" and (.actor|type)=="string" and
    (.enterprise.slug|type)=="string" and (.organizations|type)=="array"' <<<"$config" >/dev/null || return 2
  host="$(jq -r .host <<<"$config")"
  actor="$(jq -r .actor <<<"$config")"
  enterprise="$(jq -r .enterprise.slug <<<"$config")"

  if [[ "${WIZARD_READINESS_PRIMED:-false}" == true ]]; then
    result="$(wizard_discovery_result_json current-account "$host" "$actor" verified \
      "$(jq -cn --arg login "$actor" '{login:$login}')" 'Authenticated account verified.' false)"
  else
    result="$(wizard_discover_current_account "$host")" || return 2
    result="$(wizard_readiness_match_account "$result" "$actor")" || return 2
  fi
  check="$(wizard_readiness_check identity account "$actor" true "$result" \
    'The active GitHub account must match the configured actor.')" || return 2
  checks="$(wizard_readiness_add "$checks" "$check")" || return 2

  result="$(wizard_discover_scopes "$host")" || return 2
  check="$(wizard_readiness_check identity scopes "$host" true "$result" \
    'Endpoint checks decide access; classic token scopes are supporting evidence.')" || return 2
  checks="$(wizard_readiness_add "$checks" "$check")" || return 2

  if [[ "${WIZARD_READINESS_PRIMED:-false}" == true ]]; then
    result="$(wizard_discovery_result_json enterprises "$host" "$enterprise" verified \
      "$(jq -cn --arg slug "$enterprise" '[{slug:$slug}]')" 'Enterprise access verified.' false)"
  else
    result="$(wizard_discover_enterprises "$host")" || return 2
    result="$(wizard_readiness_require_item "$result" slug "$enterprise")" || return 2
  fi
  check="$(wizard_readiness_check enterprise enterprise "$enterprise" true "$result" \
    'The configured enterprise must be visible to the active account.')" || return 2
  checks="$(wizard_readiness_add "$checks" "$check")" || return 2

  result="$(wizard_discover_enterprise_governance "$host" "$enterprise")" || return 2
  check="$(wizard_readiness_check enterprise governance "$enterprise" false "$result" \
    'Enterprise governance inventory supports IP allow-list and policy-lock review.')" || return 2
  checks="$(wizard_readiness_add "$checks" "$check")" || return 2
  result="$(wizard_discover_audit_streams "$host" "$enterprise")" || return 2
  check="$(wizard_readiness_check audit streams "$enterprise" false "$result" \
    'Audit stream inventory supports adoption and receiver review.')" || return 2
  checks="$(wizard_readiness_add "$checks" "$check")" || return 2

  if [[ "${WIZARD_READINESS_PRIMED:-false}" == true ]]; then
    organizations_result="$(wizard_discovery_result_json organizations "$host" "$enterprise" verified \
      "$(jq -cn --argjson orgs "${WIZARD_ENTERPRISE_ORGS:-[]}" '$orgs|map({login:.})')" \
      'Enterprise organization membership verified.' false)"
  else
    organizations_result="$(wizard_discover_organizations "$host" "$enterprise")" || return 2
  fi
  while IFS= read -r org; do
    login="$(jq -r .login <<<"$org")"
    packages="$(jq -c --argjson defaults "$(jq -c '.defaults.packages // []' <<<"$config")" \
      '.packages // $defaults' <<<"$org")" || return 2

    local org_result
    org_result="$(wizard_readiness_require_item "$organizations_result" login "$login")" || return 2
    if [[ "$(jq -r '.create // false' <<<"$org")" == true && "$(jq -r .state <<<"$org_result")" == missing ]]; then
      org_result="$(jq -c '.state="verified" |
        .detail="The organization is absent and is configured for creation after plan approval."' <<<"$org_result")"
      org_pending_creation=true
    else
      org_pending_creation=false
    fi
    check="$(wizard_readiness_check workspace organization "$login" true "$org_result" \
      'The organization must exist or be explicitly configured for creation.')" || return 2
    checks="$(wizard_readiness_add "$checks" "$check")" || return 2
    while IFS= read -r manual; do
      local manual_state manual_required manual_control
      manual_control="$(jq -r .control <<<"$manual")"
      if [[ "$(jq -r .accepted <<<"$manual")" == true ]]; then
        manual_state=manual_prerequisite; manual_required=false
      else
        manual_state=unverified; manual_required=true
      fi
      result="$(wizard_discovery_result_json manual-prerequisite "$host" "$login" "$manual_state" \
        null "$(jq -r .message <<<"$manual")" false)"
      check="$(wizard_readiness_check workspace "$manual_control" "$login" "$manual_required" "$result" \
        'The named owner must accept this manual handoff before planning.')" || return 2
      checks="$(wizard_readiness_add "$checks" "$check")" || return 2
    done < <(jq -c '.manual_handoffs[]?' <<<"$org")
    if [[ "$org_pending_creation" == true ]]; then
      continue
    fi

    if wizard_readiness_package_selected "$packages" workspace; then
      result="$(wizard_discover_organization_settings "$host" "$login")" || return 2
      check="$(wizard_readiness_check workspace organization-settings "$login" true "$result" \
        'Organization settings are required to compute effective repository governance.')" || return 2
      checks="$(wizard_readiness_add "$checks" "$check")" || return 2
      result="$(wizard_discover_repositories "$host" "$login")" || return 2
      check="$(wizard_readiness_check workspace repositories "$login" true "$result" \
        'Repository inventory supports adoption and name checks.')" || return 2
      checks="$(wizard_readiness_add "$checks" "$check")" || return 2
      while IFS= read -r repo; do
        local repository_result repository_name
        repository_name="$(jq -r .name <<<"$repo")"
        repository_result="$(wizard_readiness_repository "$result" "$repo")" || return 2
        check="$(wizard_readiness_check workspace repository "$login/$repository_name" true "$repository_result" \
          'Existing repositories must resolve to the same resource; new names must be available.')" || return 2
        checks="$(wizard_readiness_add "$checks" "$check")" || return 2
      done < <(jq -c '.repositories[]?' <<<"$org")
      result="$(wizard_discover_teams "$host" "$login")" || return 2
      check="$(wizard_readiness_check workspace teams "$login" true "$result" \
        'Team inventory supports membership and repository access checks.')" || return 2
      checks="$(wizard_readiness_add "$checks" "$check")" || return 2
      result="$(wizard_discover_members "$host" "$login")" || return 2
      check="$(wizard_readiness_check workspace members "$login" true "$result" \
        'Member inventory supports owner and team readiness checks.')" || return 2
      checks="$(wizard_readiness_add "$checks" "$check")" || return 2
      result="$(wizard_discover_owners "$host" "$login")" || return 2
      check="$(wizard_readiness_check workspace owners "$login" true "$result" \
        'Owner inventory confirms administrative coverage.')" || return 2
      checks="$(wizard_readiness_add "$checks" "$check")" || return 2
      result="$(wizard_discover_outside_collaborators "$host" "$login")" || return 2
      check="$(wizard_readiness_check workspace outside-collaborators "$login" false "$result" \
        'Outside-collaborator inventory supports teams-first and vendor-access review.')" || return 2
      checks="$(wizard_readiness_add "$checks" "$check")" || return 2
      result="$(wizard_discover_organization_rulesets "$host" "$login")" || return 2
      check="$(wizard_readiness_check workspace organization-rulesets "$login" false "$result" \
        'Ruleset inventory supports stacked-enforcement warnings.')" || return 2
      checks="$(wizard_readiness_add "$checks" "$check")" || return 2
      result="$(wizard_discover_templates "$host" "$login")" || return 2
      check="$(wizard_readiness_check workspace templates "$login" false "$result" \
        'Template inventory is needed only when a configured repository uses a template.')" || return 2
      checks="$(wizard_readiness_add "$checks" "$check")" || return 2
      if [[ "$(jq '.projects // [] | length' <<<"$org")" -gt 0 ]]; then
        result="$(wizard_discover_projects_v2 "$host" "$login")" || return 2
        check="$(wizard_readiness_check workspace projects "$login" true "$result" \
          'Projects v2 inventory supports explicit project adoption and creation.')" || return 2
        checks="$(wizard_readiness_add "$checks" "$check")" || return 2
      fi
      while IFS= read -r repo; do
        local governance_repo
        governance_repo="$login/$(jq -r .name <<<"$repo")"
        result="$(wizard_discover_repository_collaborators "$host" "$governance_repo")" || return 2
        check="$(wizard_readiness_check workspace direct-collaborators "$governance_repo" false "$result" \
          'Direct collaborator inventory supports teams-first policy review.')" || return 2
        checks="$(wizard_readiness_add "$checks" "$check")" || return 2
        result="$(wizard_discover_repository_rulesets "$host" "$governance_repo")" || return 2
        check="$(wizard_readiness_check workspace repository-rulesets "$governance_repo" false "$result" \
          'Repository ruleset inventory supports overlap and inherited-policy review.')" || return 2
        checks="$(wizard_readiness_add "$checks" "$check")" || return 2
      done < <(jq -c '.repositories[]?' <<<"$org")
    fi

    if wizard_readiness_package_selected "$packages" actions; then
      result="$(wizard_discover_actions_cache_organization "$host" "$login")" || return 2
      check="$(wizard_readiness_check actions cache-policy "$login" false "$result" \
        'Cache policy inventory supports inherited-limit validation.')" || return 2
      checks="$(wizard_readiness_add "$checks" "$check")" || return 2
      local runner_groups_required
      runner_groups_required="$(jq '(.actions.runner_groups // [] | length) > 0' <<<"$org")" || return 2
      result="$(wizard_discover_actions_runner_groups "$host" "$login")" || return 2
      check="$(wizard_readiness_check actions runner-groups "$login" "$runner_groups_required" "$result" \
        'Runner-group inventory supports Actions runner planning.')" || return 2
      checks="$(wizard_readiness_add "$checks" "$check")" || return 2
      while IFS= read -r repo; do
        local actions_repo
        actions_repo="$login/$(jq -r .name <<<"$repo")"
        result="$(wizard_discover_actions_workflows "$host" "$actions_repo")" || return 2
        check="$(wizard_readiness_check actions workflows \
          "$actions_repo" false "$result" \
          'Workflow inventory supports adoption and required-check review.')" || return 2
        checks="$(wizard_readiness_add "$checks" "$check")" || return 2
        result="$(wizard_discover_actions_cache_repository "$host" "$actions_repo")" || return 2
        check="$(wizard_readiness_check actions repository-cache "$actions_repo" false "$result" \
          'Repository cache policy supports inherited-limit and drift checks.')" || return 2
        checks="$(wizard_readiness_add "$checks" "$check")" || return 2
      done < <(jq -c '.repositories[]?' <<<"$org")
    fi

    if wizard_readiness_package_selected "$packages" copilot; then
      result="$(wizard_discover_copilot_billing "$host" "$login")" || return 2
      check="$(wizard_readiness_check copilot billing "$login" true "$result" \
        'Copilot billing inventory confirms subscription and policy visibility.')" || return 2
      checks="$(wizard_readiness_add "$checks" "$check")" || return 2
      result="$(wizard_discover_copilot_seats "$host" "$login")" || return 2
      check="$(wizard_readiness_check copilot seats "$login" true "$result" \
        'Copilot seat inventory supports assignment and cost review.')" || return 2
      checks="$(wizard_readiness_add "$checks" "$check")" || return 2
    fi

    if wizard_readiness_package_selected "$packages" security; then
      result="$(wizard_discover_code_security_configurations "$host" "$login")" || return 2
      check="$(wizard_readiness_check security configurations "$login" true "$result" \
        'Code security configuration inventory supports safe selection and attachment.')" || return 2
      checks="$(wizard_readiness_add "$checks" "$check")" || return 2
    fi

    if wizard_readiness_package_selected "$packages" quality; then
      while IFS= read -r repo; do
        result="$(wizard_discover_code_quality_setup "$host" "$login/$(jq -r .name <<<"$repo")")" || return 2
        if [[ "$(jq -r .state <<<"$result")" == missing ]]; then
          result="$(jq -c '
            .state="verified" |
            .detail="Code Quality is not configured; the approved plan can create the setup."
          ' <<<"$result")" || return 2
        fi
        check="$(wizard_readiness_check quality setup \
          "$login/$(jq -r .name <<<"$repo")" true "$result" \
          'Code Quality setup must be readable before readiness can be proven.')" || return 2
        checks="$(wizard_readiness_add "$checks" "$check")" || return 2
      done < <(jq -c '.repositories[]?' <<<"$org")
    fi

    if wizard_readiness_package_selected "$packages" integrations; then
      result="$(wizard_discover_installations "$host" "$login")" || return 2
      check="$(wizard_readiness_check integrations installations "$login" true "$result" \
        'Installation inventory supports application review.')" || return 2
      checks="$(wizard_readiness_add "$checks" "$check")" || return 2
    fi

    if [[ "$ghaw_checked" == false ]] && wizard_readiness_package_selected "$packages" ghaw; then
      result="$(wizard_discover_ghaw_readiness "$host")" || return 2
      check="$(wizard_readiness_check ghaw local-gh-aw local true "$result" \
        'A working local gh-aw compiler is required before workflow compilation.')" || return 2
      checks="$(wizard_readiness_add "$checks" "$check")" || return 2
      ghaw_checked=true
    fi
  done < <(jq -c '.organizations[]' <<<"$config")

  governance="$(wizard_governance_effective_config "$config")" || return 2
  WIZARD_READINESS_REPORT="$(printf '%s\n%s\n' "$checks" "$governance" |
    jq -sc --arg host "$host" --arg actor "$actor" --arg enterprise "$enterprise" '
    .[0] as $checks | .[1] as $governance |
    {schema_version:1,host:$host,actor:$actor,enterprise:$enterprise,
     ready:all($checks[]; (.required|not) or .state=="ready"),
     counts:($checks|group_by(.state)|map({key:.[0].state,value:length})|from_entries),
     checks:$checks,governance:$governance}')"
  printf '%s\n' "$WIZARD_READINESS_REPORT"
}

wizard_readiness_format_json() {
  local report="${1:-${WIZARD_READINESS_REPORT:-}}"
  [[ -n "$report" ]] || return 2
  jq . <<<"$report"
}

wizard_readiness_format_text() {
  local report="${1:-${WIZARD_READINESS_REPORT:-}}"
  [[ -n "$report" ]] || return 2
  jq -r '
    (.checks[] |
    (if .state=="ready" then "READY"
     elif .state=="manual" then "MANUAL"
     elif .state=="missing" then "MISSING"
     elif .state=="insufficient_permission" then "PERMISSION"
     elif .state=="blocked" then "BLOCKED"
     else "UNVERIFIED" end) as $label |
    "["+$label+"] "+.package+" / "+.subject+": "+.message+
    (if .discovery.detail=="" then "" else " "+.discovery.detail end)),
    (.governance[] | . as $control | .warnings[]? |
      "[WARNING] governance / "+$control.subject+": "+.)'
    <<<"$report"
}

wizard_readiness_is_ready() {
  local report="${1:-${WIZARD_READINESS_REPORT:-}}"
  [[ -n "$report" ]] || return 2
  jq -e '.ready==true' <<<"$report" >/dev/null
}
