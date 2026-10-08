#!/usr/bin/env bash

# Discovery functions only read from the selected GitHub host. A result has this shape:
# {kind,host,scope,state,data,detail,cached}
# state is verified, missing, insufficient_permission, unavailable, unverified, or
# manual_prerequisite.

WIZARD_DISCOVERY_MEMORY="${WIZARD_DISCOVERY_MEMORY:-[]}"
WIZARD_DISCOVERY_RESULT="${WIZARD_DISCOVERY_RESULT:-}"

wizard_discovery_stop() {
  if [[ -n "${WIZARD_DISCOVERY_PID:-}" ]]; then
    kill "$WIZARD_DISCOVERY_PID" 2>/dev/null || true
    wait "$WIZARD_DISCOVERY_PID" 2>/dev/null || true
    WIZARD_DISCOVERY_PID=''
  fi
}

wizard_discovery_hash() {
  if type wizard_hash >/dev/null 2>&1; then wizard_hash
  elif command -v shasum >/dev/null 2>&1; then shasum -a 256 | awk '{print $1}'
  else cksum | awk '{print $1}'; fi
}

wizard_discovery_key() {
  printf '%s\n' "$1" "$2" "$3" | wizard_discovery_hash
}

wizard_discovery_valid_host() {
  case "$1" in github.com|[a-z0-9]*.ghe.com) return 0 ;; *) return 1 ;; esac
}

wizard_discovery_valid_owner() {
  [[ "$1" =~ ^[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?$ && ${#1} -le 100 && "$1" != *--* ]]
}

wizard_discovery_valid_repo() {
  local owner="${1%%/*}" repo="${1#*/}"
  [[ "$owner" != "$1" ]] && wizard_discovery_valid_owner "$owner" &&
    [[ "$repo" =~ ^[A-Za-z0-9_.-]+$ && ${#repo} -le 100 && "$repo" != "." && "$repo" != *..* ]]
}

wizard_discovery_result_json() {
  local kind="$1" host="$2" scope="$3" state="$4" data="$5" detail="$6" cached="${7:-false}"
  printf '%s\n' "$data" | jq -c --arg kind "$kind" --arg host "$host" --arg scope "$scope" \
    --arg state "$state" --arg detail "$detail" --argjson cached "$cached" \
    '. as $data | {kind:$kind,host:$host,scope:$scope,state:$state,data:$data,detail:$detail,cached:$cached}'
}

wizard_discovery_cache_file() {
  local key
  [[ -n "${WIZARD_INTERVIEW_DIR:-}" && -d "$WIZARD_INTERVIEW_DIR" ]] || return 1
  key="$(wizard_discovery_key "$1" "$2" "$3")" || return 1
  printf '%s/discovery-inventory-%s.json\n' "$WIZARD_INTERVIEW_DIR" "$key"
}

wizard_discovery_cached() {
  local kind="$1" host="$2" scope="$3" key result cache
  key="$(wizard_discovery_key "$kind" "$host" "$scope")" || return 1
  result="$(jq -ce --arg key "$key" \
    '[.[]|select(.key==$key)|.result][0] // empty' <<<"$WIZARD_DISCOVERY_MEMORY" 2>/dev/null)" || result=''
  if [[ -n "$result" ]]; then
    WIZARD_DISCOVERY_RESULT="$(jq -c '.cached=true' <<<"$result")"
    return 0
  fi
  cache="$(wizard_discovery_cache_file "$kind" "$host" "$scope" 2>/dev/null)" || return 1
  [[ -f "$cache" ]] || return 1
  result="$(jq -ce --arg kind "$kind" --arg host "$host" --arg scope "$scope" '
    select(.kind==$kind and .host==$host and .scope==$scope and
      (.state=="verified" or .state=="missing")) | .cached=true' "$cache" 2>/dev/null)" || return 1
  WIZARD_DISCOVERY_RESULT="$result"
}

wizard_discovery_remember() {
  local result="$1" state key cache
  state="$(jq -r .state <<<"$result")"
  [[ "$state" == verified || "$state" == missing ]] || return 0
  key="$(wizard_discovery_key "$(jq -r .kind <<<"$result")" \
    "$(jq -r .host <<<"$result")" "$(jq -r .scope <<<"$result")")" || return 1
  WIZARD_DISCOVERY_MEMORY="$(printf '%s\n%s\n' "$WIZARD_DISCOVERY_MEMORY" "$result" |
    jq -sc --arg key "$key" '.[0] as $all | .[1] as $result |
      [$all[]|select(.key!=$key)]+[{key:$key,result:$result}]')" || return 1
  cache="$(wizard_discovery_cache_file "$(jq -r .kind <<<"$result")" \
    "$(jq -r .host <<<"$result")" "$(jq -r .scope <<<"$result")" 2>/dev/null)" || return 0
  printf '%s\n' "$result" >"$cache"
}

wizard_discovery_classify_failure() {
  local output="$1"
  if printf '%s' "$output" | grep -Eqi 'HTTP[^0-9]*404|"status"[[:space:]]*:[[:space:]]*"?404|not found'; then
    printf 'missing'
  elif printf '%s' "$output" | grep -Eqi 'HTTP[^0-9]*(401|403)|INSUFFICIENT_SCOPES|insufficient scope|forbidden|resource not accessible|requires authentication'; then
    printf 'insufficient_permission'
  elif printf '%s' "$output" | grep -Eqi 'HTTP[^0-9]*(429|5[0-9][0-9])|timed out|timeout|could not resolve|connection|network|service unavailable|rate limit'; then
    printf 'unavailable'
  else
    printf 'unverified'
  fi
}

wizard_discovery_api() {
  local host="$1" endpoint="$2" mode="${3:-array}" output status state data query previous_host="${WIZARD_HOST:-}"
  if [[ -n "${WIZARD_INTERVIEW_DIR:-}" ]]; then
    if output="$(GH_HOST="$host" gh api --hostname "$host" --method GET \
        -H 'Accept: application/vnd.github+json' "$endpoint" --paginate --slurp 2>&1)"; then
      status=0
    else
      status=$?
    fi
    if [[ "$status" -ne 0 ]]; then
      WIZARD_DISCOVERY_API_STATE="$(wizard_discovery_classify_failure "$output")"
      WIZARD_DISCOVERY_API_DATA='null'
      return 0
    fi
    case "$mode" in
      array) query='if type=="array" then [ .[] | if type=="array" then .[] else . end ] else error("invalid response") end' ;;
      object) query='if (type=="array" and length==1 and (.[0]|type)=="object") then .[0] else error("invalid response") end' ;;
      runner_groups) query='[.[]|.runner_groups[]?]' ;;
      seats) query='[.[]|.seats[]?]' ;;
      installations) query='[.[]|.installations[]?]' ;;
      workflows) query='[.[]|.workflows[]?]' ;;
      *) WIZARD_DISCOVERY_API_STATE=unverified; WIZARD_DISCOVERY_API_DATA=null; return 0 ;;
    esac
    if data="$(jq -ce "$query" <<<"$output" 2>/dev/null)"; then
      WIZARD_DISCOVERY_API_STATE=verified
      WIZARD_DISCOVERY_API_DATA="$data"
    else
      WIZARD_DISCOVERY_API_STATE=unverified
      WIZARD_DISCOVERY_API_DATA=null
    fi
    return 0
  fi
  WIZARD_HOST="$host"
  case "$mode" in
    array)
      if wizard_api_pages "$endpoint"; then status=0; else status=$?; fi ;;
    runner_groups)
      if wizard_api_pages "$endpoint" '["runner_groups"]'; then status=0; else status=$?; fi ;;
    seats)
      if wizard_api_pages "$endpoint" '["seats"]'; then status=0; else status=$?; fi ;;
    installations)
      if wizard_api_pages "$endpoint" '["installations"]'; then status=0; else status=$?; fi ;;
    workflows)
      if wizard_api_pages "$endpoint" '["workflows"]'; then status=0; else status=$?; fi ;;
    object)
      if wizard_api GET "$endpoint"; then status=0; else status=$?; fi ;;
    *) status=2; API_ERROR=invalid_response ;;
  esac
  if [[ -n "$previous_host" ]]; then WIZARD_HOST="$previous_host"; else unset WIZARD_HOST; fi
  if [[ "$status" -ne 0 ]]; then
    case "${API_ERROR:-}" in
      not_found_or_inaccessible) state=missing ;;
      unauthenticated|forbidden_or_rate_limited|insufficient_scopes) state=insufficient_permission ;;
      unavailable|rate_limited|transport_error) state=unavailable ;;
      *) state=unverified ;;
    esac
    WIZARD_DISCOVERY_API_STATE="$state"
    WIZARD_DISCOVERY_API_DATA='null'
    return 0
  fi
  case "$mode" in
    array|runner_groups|seats|installations|workflows) query='if type=="array" then . else error("invalid response") end' ;;
    object) query='if type=="object" then . else error("invalid response") end' ;;
    *) WIZARD_DISCOVERY_API_STATE=unverified; WIZARD_DISCOVERY_API_DATA=null; return 0 ;;
  esac
  if data="$(jq -ce "$query" <<<"$API_JSON" 2>/dev/null)"; then
    WIZARD_DISCOVERY_API_STATE=verified
    WIZARD_DISCOVERY_API_DATA="$data"
  else
    WIZARD_DISCOVERY_API_STATE=unverified
    WIZARD_DISCOVERY_API_DATA=null
  fi
}

wizard_discovery_graphql_enterprises() {
  local host="$1" output status data query input cursor='' page nodes page_info all='[]' pages=0
  query='query($endCursor:String){viewer{enterprises(first:100,after:$endCursor){nodes{id slug name}pageInfo{hasNextPage endCursor}}}}'
  while :; do
    input="$(mktemp "${TMPDIR:-/tmp}/github-wizard-discovery.XXXXXX")" || return 1
    jq -cn --arg query "$query" --arg cursor "$cursor" \
      '{query:$query,variables:{endCursor:(if $cursor=="" then null else $cursor end)}}' >"$input" ||
      { rm -f "$input"; return 1; }
    if output="$(GH_HOST="$host" gh api --hostname "$host" --method POST graphql \
        --input "$input" 2>&1)"; then status=0; else status=$?; fi
    rm -f "$input"
    if [[ "$status" -ne 0 ]]; then
      WIZARD_DISCOVERY_API_STATE="$(wizard_discovery_classify_failure "$output")"
      WIZARD_DISCOVERY_API_DATA=null
      return 0
    fi
    page="$(jq -ce '
      (if type=="array" and length==1 then .[0] else . end) |
      if (.errors//[]|length)>0 then error("graphql") else . end' <<<"$output" 2>/dev/null)" || {
        if printf '%s' "$output" | grep -Eqi 'INSUFFICIENT_SCOPES|forbidden|resource not accessible'; then
          WIZARD_DISCOVERY_API_STATE=insufficient_permission
        else
          WIZARD_DISCOVERY_API_STATE=unverified
        fi
        WIZARD_DISCOVERY_API_DATA=null
        return 0
      }
    nodes="$(jq -c '.data.viewer.enterprises.nodes // []' <<<"$page")" || return 1
    all="$(jq -cn --argjson all "$all" --argjson nodes "$nodes" '$all+$nodes')" || return 1
    page_info="$(jq -c '.data.viewer.enterprises.pageInfo // {hasNextPage:false,endCursor:null}' <<<"$page")" || return 1
    [[ "$(jq -r '.hasNextPage // false' <<<"$page_info")" == true ]] || break
    cursor="$(jq -r '.endCursor // empty' <<<"$page_info")"
    [[ -n "$cursor" ]] || { WIZARD_DISCOVERY_API_STATE=unverified; WIZARD_DISCOVERY_API_DATA=null; return 0; }
    pages=$((pages+1))
    [[ "$pages" -lt 1000 ]] || { WIZARD_DISCOVERY_API_STATE=unverified; WIZARD_DISCOVERY_API_DATA=null; return 0; }
  done
  data="$(jq -cn --argjson all "$all" '$all|unique_by(.slug|ascii_downcase)')" || return 1
  WIZARD_DISCOVERY_API_STATE=verified
  WIZARD_DISCOVERY_API_DATA="$data"
}

wizard_discovery_graphql_organizations() {
  local host="$1" enterprise="$2" output status data query input cursor='' page nodes page_info all='[]' pages=0
  query='query($slug:String!,$endCursor:String){enterprise(slug:$slug){organizations(first:100,after:$endCursor){nodes{id login name}pageInfo{hasNextPage endCursor}}}}'
  while :; do
    input="$(mktemp "${TMPDIR:-/tmp}/github-wizard-discovery.XXXXXX")" || return 1
    jq -cn --arg query "$query" --arg slug "$enterprise" --arg cursor "$cursor" \
      '{query:$query,variables:{slug:$slug,endCursor:(if $cursor=="" then null else $cursor end)}}' >"$input" ||
      { rm -f "$input"; return 1; }
    if output="$(GH_HOST="$host" gh api --hostname "$host" --method POST graphql \
        --input "$input" 2>&1)"; then status=0; else status=$?; fi
    rm -f "$input"
    if [[ "$status" -ne 0 ]]; then
      WIZARD_DISCOVERY_API_STATE="$(wizard_discovery_classify_failure "$output")"
      WIZARD_DISCOVERY_API_DATA=null
      return 0
    fi
    page="$(jq -ce '
      (if type=="array" and length==1 then .[0] else . end) |
      if (.errors//[]|length)>0 then error("graphql") else . end' <<<"$output" 2>/dev/null)" || {
        if printf '%s' "$output" | grep -Eqi 'INSUFFICIENT_SCOPES|forbidden|resource not accessible'; then
          WIZARD_DISCOVERY_API_STATE=insufficient_permission
        else
          WIZARD_DISCOVERY_API_STATE=unverified
        fi
        WIZARD_DISCOVERY_API_DATA=null
        return 0
      }
    if [[ "$(jq -r '.data.enterprise == null' <<<"$page")" == true ]]; then
      WIZARD_DISCOVERY_API_STATE=missing
      WIZARD_DISCOVERY_API_DATA=null
      return 0
    fi
    nodes="$(jq -c '.data.enterprise.organizations.nodes // []' <<<"$page")" || return 1
    all="$(jq -cn --argjson all "$all" --argjson nodes "$nodes" '$all+$nodes')" || return 1
    page_info="$(jq -c '.data.enterprise.organizations.pageInfo // {hasNextPage:false,endCursor:null}' <<<"$page")" || return 1
    [[ "$(jq -r '.hasNextPage // false' <<<"$page_info")" == true ]] || break
    cursor="$(jq -r '.endCursor // empty' <<<"$page_info")"
    [[ -n "$cursor" ]] || { WIZARD_DISCOVERY_API_STATE=unverified; WIZARD_DISCOVERY_API_DATA=null; return 0; }
    pages=$((pages+1))
    [[ "$pages" -lt 1000 ]] || { WIZARD_DISCOVERY_API_STATE=unverified; WIZARD_DISCOVERY_API_DATA=null; return 0; }
  done
  data="$(jq -cn --argjson all "$all" '$all|unique_by(.login|ascii_downcase)')" || return 1
  WIZARD_DISCOVERY_API_STATE=verified
  WIZARD_DISCOVERY_API_DATA="$data"
}

wizard_discovery_graphql() {
  local host="$1" body="$2" projection="$3" status data previous_host="${WIZARD_HOST:-}"
  WIZARD_HOST="$host"
  if wizard_api POST graphql "$body"; then status=0; else status=$?; fi
  if [[ -n "$previous_host" ]]; then WIZARD_HOST="$previous_host"; else unset WIZARD_HOST; fi
  if [[ "$status" -ne 0 ]]; then
    case "${API_ERROR:-}" in
      not_found_or_inaccessible) WIZARD_DISCOVERY_API_STATE=missing ;;
      unauthenticated|forbidden_or_rate_limited|insufficient_scopes) WIZARD_DISCOVERY_API_STATE=insufficient_permission ;;
      unavailable|rate_limited|transport_error) WIZARD_DISCOVERY_API_STATE=unavailable ;;
      *) WIZARD_DISCOVERY_API_STATE=unverified ;;
    esac
    WIZARD_DISCOVERY_API_DATA=null
  elif data="$(jq -ce "$projection" <<<"$API_JSON" 2>/dev/null)"; then
    if [[ "$data" == null ]]; then
      WIZARD_DISCOVERY_API_STATE=missing
      WIZARD_DISCOVERY_API_DATA=null
    else
      WIZARD_DISCOVERY_API_STATE=verified
      WIZARD_DISCOVERY_API_DATA="$data"
    fi
  else
    WIZARD_DISCOVERY_API_STATE=unverified
    WIZARD_DISCOVERY_API_DATA=null
  fi
}

wizard_discovery_accounts() {
  local host="$1" output status data
  if output="$(GH_HOST="$host" gh auth status --hostname "$host" --json hosts \
      --jq '[.hosts[][]|{login,active,state}]' 2>&1)"; then status=0; else status=$?; fi
  if [[ "$status" -eq 0 ]] && data="$(jq -ce '[.[]|select((.login|type)=="string" and (.active|type)=="boolean")|
      {login,active,state:(if .state=="success" then "success" else "unverified" end)}]' \
      <<<"$output" 2>/dev/null)"; then
    WIZARD_DISCOVERY_API_STATE=verified
    WIZARD_DISCOVERY_API_DATA="$data"
  else
    WIZARD_DISCOVERY_API_STATE="$(wizard_discovery_classify_failure "$output")"
    WIZARD_DISCOVERY_API_DATA=null
  fi
}

wizard_discovery_scopes() {
  local host="$1" output status headers scopes
  if output="$(GH_HOST="$host" gh api --hostname "$host" --method GET --include /user 2>&1)"; then
    status=0
  else
    status=$?
  fi
  if [[ "$status" -ne 0 ]]; then
    WIZARD_DISCOVERY_API_STATE="$(wizard_discovery_classify_failure "$output")"
    WIZARD_DISCOVERY_API_DATA=null
    return 0
  fi
  headers="$(printf '%s\n' "$output" | awk '
    tolower($0) ~ /^x-oauth-scopes:/ {
      sub(/^[^:]*:[[:space:]]*/, ""); value=$0
    }
    END {print value}' | tr -d '\r')"
  if [[ -n "$headers" ]]; then
    scopes="$(printf '%s\n' "$headers" | jq -Rsc 'split(",")|map(gsub("^\\s+|\\s+$";""))|map(select(length>0))|unique')"
  else
    scopes='[]'
  fi
  WIZARD_DISCOVERY_API_STATE=verified
  WIZARD_DISCOVERY_API_DATA="$(jq -cn --argjson scopes "$scopes" \
    '{scopes:$scopes,note:(if ($scopes|length)==0 then "The host did not report classic token scopes; fine-grained permissions still require endpoint checks." else "" end)}')"
}

wizard_discovery_ghaw() {
  local output status version help=false
  if ! command -v gh >/dev/null 2>&1; then
    WIZARD_DISCOVERY_API_STATE=manual_prerequisite
    WIZARD_DISCOVERY_API_DATA='{"installed":false}'
    return 0
  fi
  if output="$(gh aw --version 2>&1)"; then status=0; else status=$?; fi
  if [[ "$status" -ne 0 ]]; then
    WIZARD_DISCOVERY_API_STATE=manual_prerequisite
    WIZARD_DISCOVERY_API_DATA='{"installed":false}'
    return 0
  fi
  version="$(printf '%s\n' "$output" | head -1 | tr -d '\r')"
  if gh aw compile --help >/dev/null 2>&1; then help=true; fi
  WIZARD_DISCOVERY_API_STATE=verified
  WIZARD_DISCOVERY_API_DATA="$(jq -cn --arg version "$version" --argjson compile "$help" \
    '{installed:true,version:$version,compile_command:$compile}')"
}

wizard_discovery_graphql_enterprise_governance() {
  local host="$1" enterprise="$2" body
  body="$(jq -cn --arg slug "$enterprise" '{
    query:"query($slug:String!){enterprise(slug:$slug){slug ownerInfo{ipAllowListEnabledSetting ipAllowListForInstalledAppsEnabledSetting}}}",
    variables:{slug:$slug}
  }')"
  wizard_discovery_graphql "$host" "$body" '
    .data.enterprise |
    if . == null then null else {
      slug,
      ip_allow_list_enabled:.ownerInfo.ipAllowListEnabledSetting,
      installed_apps_enabled:.ownerInfo.ipAllowListForInstalledAppsEnabledSetting
    } end'
}

wizard_discovery_graphql_projects() {
  local host="$1" organization="$2" body
  body="$(jq -cn --arg login "$organization" '{
    query:"query($login:String!){organization(login:$login){projectsV2(first:100){nodes{id number title closed}}}}",
    variables:{login:$login}
  }')"
  wizard_discovery_graphql "$host" "$body" '.data.organization.projectsV2.nodes'
}

wizard_discovery_actions_cache() {
  local host="$1" scope="$2" level="$3" base retention storage retention_state retention_data
  if [[ "$level" == organization ]]; then base="/organizations/$scope/actions/cache"
  else base="/repos/$scope/actions/cache"
  fi
  wizard_discovery_api "$host" "$base/retention-limit" object
  retention_state="$WIZARD_DISCOVERY_API_STATE"
  retention_data="$WIZARD_DISCOVERY_API_DATA"
  [[ "$retention_state" == verified ]] || return 0
  wizard_discovery_api "$host" "$base/storage-limit" object
  [[ "$WIZARD_DISCOVERY_API_STATE" == verified ]] || return 0
  storage="$WIZARD_DISCOVERY_API_DATA"
  WIZARD_DISCOVERY_API_DATA="$(jq -cn --argjson retention "$retention_data" --argjson storage "$storage" \
    '{retention:$retention,storage:$storage}')"
}

wizard_discovery_inventory() {
  local kind="$1" host="${2:-}" scope="${3:-}" endpoint mode detail state data result owner repo
  WIZARD_DISCOVERY_RESULT=''
  if [[ "$kind" != ghaw-readiness ]] && ! wizard_discovery_valid_host "$host"; then
    WIZARD_DISCOVERY_RESULT="$(wizard_discovery_result_json "$kind" "$host" "$scope" \
      unverified null 'Unsupported GitHub host.' false)"
    printf '%s\n' "$WIZARD_DISCOVERY_RESULT"
    return 0
  fi
  if wizard_discovery_cached "$kind" "$host" "$scope"; then
    printf '%s\n' "$WIZARD_DISCOVERY_RESULT"
    return 0
  fi
  detail=''
  case "$kind" in
    accounts) wizard_discovery_accounts "$host" ;;
    current-account) wizard_discovery_api "$host" /user object ;;
    scopes) wizard_discovery_scopes "$host" ;;
    enterprises) wizard_discovery_graphql_enterprises "$host" ;;
    organizations)
      if ! wizard_discovery_valid_owner "$scope"; then
        WIZARD_DISCOVERY_API_STATE=unverified; WIZARD_DISCOVERY_API_DATA=null
      else wizard_discovery_graphql_organizations "$host" "$scope"; fi ;;
    repositories|teams|members|owners|outside-collaborators|organization-settings|organization-rulesets|actions-runner-groups|copilot-billing|copilot-seats|code-security-configurations|installations|templates)
      if ! wizard_discovery_valid_owner "$scope"; then
        WIZARD_DISCOVERY_API_STATE=unverified; WIZARD_DISCOVERY_API_DATA=null
      else
        case "$kind" in
          repositories) endpoint="/orgs/$scope/repos?type=all&sort=full_name"; mode=array ;;
          teams) endpoint="/orgs/$scope/teams"; mode=array ;;
          members) endpoint="/orgs/$scope/members?role=all"; mode=array ;;
          owners) endpoint="/orgs/$scope/members?role=admin"; mode=array ;;
          outside-collaborators) endpoint="/orgs/$scope/outside_collaborators"; mode=array ;;
          organization-settings) endpoint="/orgs/$scope"; mode=object ;;
          organization-rulesets) endpoint="/orgs/$scope/rulesets?includes_parents=true"; mode=array ;;
          actions-runner-groups) endpoint="/orgs/$scope/actions/runner-groups"; mode=runner_groups ;;
          copilot-billing) endpoint="/orgs/$scope/copilot/billing"; mode=object ;;
          copilot-seats) endpoint="/orgs/$scope/copilot/billing/seats"; mode=seats ;;
          code-security-configurations) endpoint="/orgs/$scope/code-security/configurations"; mode=array ;;
          installations) endpoint="/orgs/$scope/installations"; mode=installations ;;
          templates) endpoint="/orgs/$scope/repos?type=all&sort=full_name"; mode=array ;;
        esac
        wizard_discovery_api "$host" "$endpoint" "$mode"
        if [[ "$kind" == templates && "$WIZARD_DISCOVERY_API_STATE" == verified ]]; then
          WIZARD_DISCOVERY_API_DATA="$(jq -c '[.[]|select(.is_template==true)]' <<<"$WIZARD_DISCOVERY_API_DATA")"
        fi
      fi ;;
    actions-workflows|code-quality-setup|repository-collaborators|repository-rulesets)
      if ! wizard_discovery_valid_repo "$scope"; then
        WIZARD_DISCOVERY_API_STATE=unverified; WIZARD_DISCOVERY_API_DATA=null
      else
        owner="${scope%%/*}"; repo="${scope#*/}"
        if [[ "$kind" == actions-workflows ]]; then
          endpoint="/repos/$owner/$repo/actions/workflows"; mode=workflows
        elif [[ "$kind" == code-quality-setup ]]; then
          endpoint="/repos/$owner/$repo/code-quality/setup"; mode=object
        elif [[ "$kind" == repository-collaborators ]]; then
          endpoint="/repos/$owner/$repo/collaborators?affiliation=direct"; mode=array
        else
          endpoint="/repos/$owner/$repo/rulesets?includes_parents=true"; mode=array
        fi
        wizard_discovery_api "$host" "$endpoint" "$mode"
      fi ;;
    enterprise-governance)
      if ! wizard_discovery_valid_owner "$scope"; then
        WIZARD_DISCOVERY_API_STATE=unverified; WIZARD_DISCOVERY_API_DATA=null
      else wizard_discovery_graphql_enterprise_governance "$host" "$scope"
      fi ;;
    projects-v2)
      if ! wizard_discovery_valid_owner "$scope"; then
        WIZARD_DISCOVERY_API_STATE=unverified; WIZARD_DISCOVERY_API_DATA=null
      else wizard_discovery_graphql_projects "$host" "$scope"
      fi ;;
    audit-streams)
      if ! wizard_discovery_valid_owner "$scope"; then
        WIZARD_DISCOVERY_API_STATE=unverified; WIZARD_DISCOVERY_API_DATA=null
      else wizard_discovery_api "$host" "/enterprises/$scope/audit-log/streams" array
      fi ;;
    actions-cache-organization)
      if ! wizard_discovery_valid_owner "$scope"; then
        WIZARD_DISCOVERY_API_STATE=unverified; WIZARD_DISCOVERY_API_DATA=null
      else wizard_discovery_actions_cache "$host" "$scope" organization
      fi ;;
    actions-cache-repository)
      if ! wizard_discovery_valid_repo "$scope"; then
        WIZARD_DISCOVERY_API_STATE=unverified; WIZARD_DISCOVERY_API_DATA=null
      else wizard_discovery_actions_cache "$host" "$scope" repository
      fi ;;
    ghaw-readiness) wizard_discovery_ghaw ;;
    *)
      WIZARD_DISCOVERY_API_STATE=manual_prerequisite
      WIZARD_DISCOVERY_API_DATA=null
      detail='This inventory is not supported by the discovery adapter.'
      ;;
  esac
  state="$WIZARD_DISCOVERY_API_STATE"
  data="$WIZARD_DISCOVERY_API_DATA"
  case "$state" in
    verified) detail="${detail:-Read-only discovery completed.}" ;;
    missing) detail="${detail:-The resource was not found or is not visible.}" ;;
    insufficient_permission) detail="${detail:-The active account cannot read this inventory.}" ;;
    unavailable) detail="${detail:-The host or API is temporarily unavailable.}" ;;
    unverified) detail="${detail:-The response could not be verified.}" ;;
    manual_prerequisite) detail="${detail:-Complete this prerequisite outside the wizard.}" ;;
    *) state=unverified; data=null; detail='The discovery state was invalid.' ;;
  esac
  result="$(wizard_discovery_result_json "$kind" "$host" "$scope" "$state" "$data" "$detail" false)"
  WIZARD_DISCOVERY_RESULT="$result"
  wizard_discovery_remember "$result" || return 1
  printf '%s\n' "$result"
}

wizard_discover_current_account() { wizard_discovery_inventory current-account "$1"; }
wizard_discover_scopes() { wizard_discovery_inventory scopes "$1"; }
wizard_discover_enterprises() { wizard_discovery_inventory enterprises "$1"; }
wizard_discover_organizations() { wizard_discovery_inventory organizations "$1" "$2"; }
wizard_discover_repositories() { wizard_discovery_inventory repositories "$1" "$2"; }
wizard_discover_teams() { wizard_discovery_inventory teams "$1" "$2"; }
wizard_discover_members() { wizard_discovery_inventory members "$1" "$2"; }
wizard_discover_owners() { wizard_discovery_inventory owners "$1" "$2"; }
wizard_discover_outside_collaborators() { wizard_discovery_inventory outside-collaborators "$1" "$2"; }
wizard_discover_organization_settings() { wizard_discovery_inventory organization-settings "$1" "$2"; }
wizard_discover_organization_rulesets() { wizard_discovery_inventory organization-rulesets "$1" "$2"; }
wizard_discover_actions_workflows() { wizard_discovery_inventory actions-workflows "$1" "$2"; }
wizard_discover_actions_runner_groups() { wizard_discovery_inventory actions-runner-groups "$1" "$2"; }
wizard_discover_actions_cache_organization() { wizard_discovery_inventory actions-cache-organization "$1" "$2"; }
wizard_discover_actions_cache_repository() { wizard_discovery_inventory actions-cache-repository "$1" "$2"; }
wizard_discover_repository_collaborators() { wizard_discovery_inventory repository-collaborators "$1" "$2"; }
wizard_discover_repository_rulesets() { wizard_discovery_inventory repository-rulesets "$1" "$2"; }
wizard_discover_enterprise_governance() { wizard_discovery_inventory enterprise-governance "$1" "$2"; }
wizard_discover_audit_streams() { wizard_discovery_inventory audit-streams "$1" "$2"; }
wizard_discover_projects_v2() { wizard_discovery_inventory projects-v2 "$1" "$2"; }
wizard_discover_copilot_billing() { wizard_discovery_inventory copilot-billing "$1" "$2"; }
wizard_discover_copilot_seats() { wizard_discovery_inventory copilot-seats "$1" "$2"; }
wizard_discover_code_security_configurations() { wizard_discovery_inventory code-security-configurations "$1" "$2"; }
wizard_discover_code_quality_setup() { wizard_discovery_inventory code-quality-setup "$1" "$2"; }
wizard_discover_installations() { wizard_discovery_inventory installations "$1" "$2"; }
wizard_discover_templates() { wizard_discovery_inventory templates "$1" "$2"; }
wizard_discover_ghaw_readiness() { wizard_discovery_inventory ghaw-readiness "${1:-local}"; }

# Keep the interview contract: DISCOVERED is an array, failures fall back to manual
# entry, and only successful responses are cached.
wizard_discover() {
  local kind="$1" host="$2" scope="${3:-}" key cache result_file result state data tick=0 status
  DISCOVERED='[]'
  if ! wizard_guided || [[ "${WIZARD_NO_DISCOVERY:-false}" == true || -z "${WIZARD_INTERVIEW_DIR:-}" ]]; then return 0; fi
  key="$(printf '%s\n' "$kind" "$host" "$scope" | wizard_discovery_hash)"
  cache="$WIZARD_INTERVIEW_DIR/discovery-$key.json"
  if [[ -f "$cache" ]] && data="$(jq -ce 'if type=="array" then . else error("invalid") end' "$cache" 2>/dev/null)"; then
    DISCOVERED="$data"
    return 0
  fi
  printf 'Looking up %s on %s (read-only)...' "$kind" "$host" >&2
  result_file="$WIZARD_INTERVIEW_DIR/discovery-result-$key"
  rm -f "$result_file"
  wizard_discovery_inventory "$kind" "$host" "$scope" >"$result_file" &
  WIZARD_DISCOVERY_PID=$!
  while kill -0 "$WIZARD_DISCOVERY_PID" 2>/dev/null; do
    if [[ "$tick" -ge 80 ]]; then
      wizard_discovery_stop
      rm -f "$cache" "$result_file"
      printf ' timed out. Enter the value manually; doctor will check access.\n' >&2
      WIZARD_PAGE_NOTICE="The $kind lookup timed out. Enter manually; doctor will check access."
      return 0
    fi
    sleep 0.1
    tick=$((tick+1))
  done
  if wait "$WIZARD_DISCOVERY_PID"; then status=0; else status=$?; fi
  WIZARD_DISCOVERY_PID=''
  if [[ "$status" -ne 0 ]] || ! result="$(jq -ce . "$result_file" 2>/dev/null)"; then
    rm -f "$cache" "$result_file"
    printf ' unavailable. Enter the value manually; doctor will check access.\n' >&2
    WIZARD_PAGE_NOTICE="The $kind lookup failed. Enter manually; doctor will check access."
    return 0
  fi
  rm -f "$result_file"
  state="$(jq -r .state <<<"$result")"
  if [[ "$state" != verified ]]; then
    rm -f "$cache"
    printf ' unavailable. Enter the value manually; doctor will check access.\n' >&2
    WIZARD_PAGE_NOTICE="The $kind lookup could not be verified. Enter manually; doctor will check access."
    return 0
  fi
  case "$kind" in
    accounts)
      data="$(jq -c '.data' <<<"$result")" ;;
    enterprises)
      data="$(jq -c '[.data[]|{value:.slug,label:.slug,resource_id:(.id//null),description:"Enterprise visible to the active account."}]' <<<"$result")" ;;
    organizations)
      data="$(jq -c '[.data[]|{value:.login,label:.login,resource_id:(.id//null),description:"Organization in the selected enterprise."}]' <<<"$result")" ;;
    repositories)
      data="$(jq -c '[.data[]|{value:.name,label:.name,resource_id:(.id//null),description:"Existing repository. Adoption still requires approval."}]' <<<"$result")" ;;
    *) data='[]' ;;
  esac
  case "$kind" in
    enterprises)
      data="$(jq -c '[.[]|select((.value|type)=="string" and (.value|length)<=100 and
        (.value|test("^[A-Za-z0-9][A-Za-z0-9_-]*$")))]|unique_by(.value|ascii_downcase)' <<<"$data")" ;;
    organizations)
      data="$(jq -c '[.[]|select((.value|type)=="string" and (.value|length)<=39 and
        (.value|test("^[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?$")) and
        (.value|contains("--")|not))]|unique_by(.value|ascii_downcase)' <<<"$data")" ;;
    repositories)
      data="$(jq -c '[.[]|select((.value|type)=="string" and (.value|length)<=100 and
        (.value|test("^[A-Za-z0-9_.-]+$")) and .value!="." and
        (.value|contains("..")|not))]|unique_by(.value|ascii_downcase)' <<<"$data")" ;;
  esac
  DISCOVERED="$data"
  printf '%s\n' "$data" >"$cache" || return 1
  printf ' done.\n' >&2
}

wizard_verification_evidence() {
  local value="$1" items="${2:-${DISCOVERED:-[]}}" checked_at row
  checked_at="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  row="$(jq -c --arg value "$value" '
    [.[]|if type=="string" then {value:.,label:.} else . end|
      select((.value|ascii_downcase)==($value|ascii_downcase))][0] // null' <<<"$items")" || return 1
  if [[ "$row" != null ]]; then
    jq -cn --arg checked_at "$checked_at" --argjson row "$row" '
      {status:"verified",source:"github",checked_at:$checked_at}
      + (if $row.resource_id==null then {} else {resource_id:$row.resource_id} end)'
  else
    jq -cn --arg checked_at "$checked_at" \
      '{status:"unverified",source:"manual",checked_at:$checked_at,message:"Doctor must verify this value before planning."}'
  fi
}

wizard_suggest_value() {
  local title="$1" kind="$2" host="$3" scope="$4" help="$5" existing="${6:-[]}" options default
  if [[ "${WIZARD_DISCOVERY_ACCOUNT_READY:-false}" == true ]]; then
    wizard_discover "$kind" "$host" "$scope" || return 1
  else DISCOVERED='[]'; fi
  DISCOVERED="$(jq -c '
    [.[]|if type=="string" then
      {value:.,label:.,description:"Resource returned by read-only discovery."}
    else . end]' <<<"$DISCOVERED")" || return 1
  DISCOVERED="$(jq -c --argjson existing "$existing" '
    ($existing|map(ascii_downcase)) as $seen |
    [.[]|select(.value|ascii_downcase|. as $value|$seen|index($value)==null)]' <<<"$DISCOVERED")" || return 1
  if [[ "$(jq length <<<"$DISCOVERED")" -gt 0 ]]; then
    default="$(jq -r '.[0].value' <<<"$DISCOVERED")"
    options="$(jq -c '.+[{value:"__manual__",label:"Enter a different name",description:"Use a name not shown here. Access is checked later."}]' <<<"$DISCOVERED")"
    wizard_choose "$title" "$default" "$help" "$options" || return 1
    [[ "$WIZARD_REPLY" == __manual__ ]] || return 0
  fi
  if [[ "$kind" == repositories ]]; then kind=repo
  elif [[ "$kind" == enterprises ]]; then kind=enterprise
  else kind=organization; fi
  wizard_prompt_identifier "$kind" "$title: " '' "$help" "$existing"
}

wizard_suggest_account() {
  local host="$1" active options chosen
  wizard_discover accounts "$host" || return 1
  active="$(jq -r '[.[]|select(.active==true and .state=="success")|.login][0]//empty' <<<"$DISCOVERED")"
  WIZARD_DISCOVERY_ACCOUNT_READY=false
  if [[ "$(jq length <<<"$DISCOVERED")" -gt 1 ]]; then
    options="$(jq -c '[.[]|{value:.login,label:(.login+if .active then " (active)" else " (inactive)" end),
      description:(if .state!="success" then "Authentication needs attention." elif .active then "Used by gh on this host." else "Requires an explicit gh auth switch before doctor/apply." end)}]
      +[{value:"__manual__",label:"Enter a different login",description:"No account is switched automatically."}]' <<<"$DISCOVERED")"
    [[ -n "$active" ]] || active=__manual__
    wizard_choose 'GitHub account' "$active" 'Use the active account, or choose the account you intend to authenticate. The wizard never switches accounts.' "$options" || return 1
    chosen="$WIZARD_REPLY"
  else chosen=__manual__; fi
  if [[ "$chosen" == __manual__ ]]; then
    local help="Enter your GitHub username, not your email. No active authenticated account was found; doctor will check it."
    if [[ "${WIZARD_NO_DISCOVERY:-false}" == true ]]; then help="Enter your GitHub username, not your email. Discovery is disabled."; fi
    if [[ -n "$active" ]]; then help="Suggested from gh authentication on $host. You can override it; doctor will verify the exact account."; fi
    wizard_prompt_identifier user 'Expected authenticated GitHub login: ' "$active" \
      "$help" || return 1
    chosen="$WIZARD_REPLY"
  fi
  if [[ -n "$active" && "$chosen" == "$active" ]]; then WIZARD_DISCOVERY_ACCOUNT_READY=true
  elif [[ -n "$active" ]]; then
    printf 'The active account differs. Before doctor, run: gh auth switch --hostname %s --user %s\n' "$host" "$chosen" >&2
  fi
  WIZARD_REPLY="$chosen"
}
