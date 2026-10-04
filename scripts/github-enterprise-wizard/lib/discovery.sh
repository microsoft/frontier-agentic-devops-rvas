#!/usr/bin/env bash

wizard_discovery_stop() {
  if [[ -n "${WIZARD_DISCOVERY_PID:-}" ]]; then
    kill "$WIZARD_DISCOVERY_PID" 2>/dev/null || true
    wait "$WIZARD_DISCOVERY_PID" 2>/dev/null || true
    WIZARD_DISCOVERY_PID=''
  fi
}

wizard_discover() {
  local kind="$1" host="$2" scope="${3:-}" key cache raw error body endpoint query tick=0 status data
  DISCOVERED='[]'
  if ! wizard_guided || [[ "${WIZARD_NO_DISCOVERY:-false}" == true || -z "${WIZARD_INTERVIEW_DIR:-}" ]]; then return 0; fi
  key="$(printf '%s\n' "$kind" "$host" "$scope" | wizard_hash)"
  cache="$WIZARD_INTERVIEW_DIR/discovery-$key.json"
  if [[ -f "$cache" ]]; then DISCOVERED="$(cat "$cache")"; return 0; fi
  raw="$WIZARD_INTERVIEW_DIR/discovery-response" error="$WIZARD_INTERVIEW_DIR/discovery-error"
  body="$WIZARD_INTERVIEW_DIR/discovery-query"
  case "$kind" in
    accounts)
      GH_HOST="$host" gh auth status --hostname "$host" --json hosts \
        --jq '[.hosts[][]|{login,active,state}]' >"$raw" 2>"$error" & ;;
    enterprises|organizations)
      if [[ "$kind" == enterprises ]]; then
        query='query($endCursor:String){viewer{enterprises(first:100,after:$endCursor){nodes{slug}pageInfo{hasNextPage endCursor}}}}'
      else
        query='query($slug:String!,$endCursor:String){enterprise(slug:$slug){organizations(first:100,after:$endCursor){nodes{login}pageInfo{hasNextPage endCursor}}}}'
      fi
      jq -cn --arg query "$query" --arg slug "$scope" \
        '{query:$query,variables:{endCursor:null}} | if $slug!="" then .variables.slug=$slug else . end' >"$body" || return 1
      GH_HOST="$host" gh api --hostname "$host" --method POST graphql --paginate --slurp \
        --input "$body" >"$raw" 2>"$error" & ;;
    repositories)
      endpoint="/orgs/$scope/repos"
      GH_HOST="$host" gh api --hostname "$host" --method GET "$endpoint?per_page=100" \
        --paginate --slurp >"$raw" 2>"$error" & ;;
    *) printf 'Unsupported discovery lookup.\n' >&2; return 1 ;;
  esac
  WIZARD_DISCOVERY_PID=$!
  printf 'Looking up %s on %s (read-only)...' "$kind" "$host" >&2
  while kill -0 "$WIZARD_DISCOVERY_PID" 2>/dev/null; do
    if [[ "$tick" -ge 80 ]]; then
      wizard_discovery_stop
      printf ' timed out. Enter the value manually; doctor will check access.\n' >&2
      WIZARD_PAGE_NOTICE="The $kind lookup timed out. Enter manually; doctor will check access."
      printf '[]\n' >"$cache" || return 1
      rm -f "$raw" "$error" "$body"; return 0
    fi
    sleep 0.1
    tick=$((tick+1))
  done
  if wait "$WIZARD_DISCOVERY_PID"; then status=0; else status=$?; fi
  WIZARD_DISCOVERY_PID=''
  if [[ "$status" -ne 0 ]]; then
    printf ' unavailable. Check gh authentication and access, or enter manually.\n' >&2
    WIZARD_PAGE_NOTICE="The $kind lookup failed. Check gh authentication and access, or enter manually."
    printf '[]\n' >"$cache" || return 1
    rm -f "$raw" "$error" "$body"; return 0
  fi
  case "$kind" in
    accounts) query='[.[]|select((.login|type)=="string" and (.active|type)=="boolean")|
      select(.login|length<=100 and test("^[A-Za-z0-9][A-Za-z0-9_-]*$") and (contains("--")|not))|
      {login,active,state:(if .state=="success" then "success" else "unverified" end)}]' ;;
    enterprises) query='if any(.[]; (.errors//[]|length)>0) then error("GraphQL lookup failed") else [.[].data.viewer.enterprises.nodes[]|{value:.slug,label:.slug,description:"Enterprise visible to the active account."}] end' ;;
    organizations) query='if any(.[]; (.errors//[]|length)>0) then error("GraphQL lookup failed") else [.[].data.enterprise.organizations.nodes[]|{value:.login,label:.login,description:"Organization in the selected enterprise."}] end' ;;
    repositories) query='[.[][]|{value:.name,label:.name,description:"Existing repository. Adoption still requires approval."}]' ;;
  esac
  if data="$(jq -ce "$query" "$raw" 2>"$error")"; then
    if [[ "$kind" != accounts ]]; then
      case "$kind" in
        enterprises) query='length<=100 and test("^[A-Za-z0-9][A-Za-z0-9_-]*$")' ;;
        organizations) query='length<=39 and test("^[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?$") and (contains("--")|not)' ;;
        repositories) query='length<=100 and test("^[A-Za-z0-9_.-]+$") and .!="." and (contains("..")|not)' ;;
      esac
      data="$(jq -c "[.[]|select(.value|type==\"string\" and ($query))]|unique_by(.value|ascii_downcase)" <<<"$data")" || return 1
    fi
    DISCOVERED="$data"
    printf '%s\n' "$data" >"$cache" || return 1
    printf ' done.\n' >&2
  else
    printf ' response unavailable. Enter manually; doctor will check access.\n' >&2
    WIZARD_PAGE_NOTICE="The $kind response could not be read. Enter manually; doctor will check access."
    printf '[]\n' >"$cache" || return 1
  fi
  rm -f "$raw" "$error" "$body"
}

wizard_suggest_value() {
  local title="$1" kind="$2" host="$3" scope="$4" help="$5" existing="${6:-[]}" options default
  if [[ "${WIZARD_DISCOVERY_ACCOUNT_READY:-false}" == true ]]; then
    wizard_discover "$kind" "$host" "$scope" || return 1
  else DISCOVERED='[]'; fi
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
