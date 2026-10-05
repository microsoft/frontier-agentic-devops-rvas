source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/diagnostics.sh"

wizard_log() { printf '%s\n' "$*" >&2; }
wizard_die() { wizard_diagnostic command 2 "Error: $*"; exit 2; }

wizard_require_tools() {
  local tool
  for tool in gh jq git; do
    command -v "$tool" >/dev/null 2>&1 || wizard_die "Install $tool first."
  done
  if ! command -v shasum >/dev/null 2>&1 && ! command -v sha256sum >/dev/null 2>&1; then
    wizard_die "Install shasum or sha256sum for plan integrity checks."
  fi
}

wizard_hash() {
  if command -v shasum >/dev/null 2>&1; then shasum -a 256 | awk '{print $1}'
  else sha256sum | awk '{print $1}'; fi
}

wizard_json_hash() { jq -cS . | wizard_hash; }

wizard_code_hash() {
  local file
  {
    cat "$WIZARD_HOME/../github-enterprise-wizard.sh"
    for file in "$WIZARD_HOME"/lib/*.sh "$WIZARD_HOME"/lib/*.jq "$WIZARD_HOME"/packages/*.sh "$WIZARD_HOME"/catalog.json "$WIZARD_HOME"/validate.jq; do
      [[ -f "$file" ]] && cat "$file"
    done
  } | wizard_hash
}

wizard_set_host() {
  WIZARD_HOST="$1"
  case "$WIZARD_HOST" in
    github.com|[a-z0-9]*.ghe.com) ;;
    *) wizard_die "Only github.com and a customer subdomain.ghe.com are supported." ;;
  esac
}

wizard_api_report_error() {
  local method="$1" endpoint="${2%%\?*}" attempts="$3"
  wizard_diagnostic_text "API $method $endpoint: $API_ERROR (${API_STATUS:-no HTTP response})" >&2
  if [[ "$API_STATUS" != 404 ]]; then
    wizard_diagnostic api 2 "Request: $method $endpoint
Host: ${WIZARD_HOST:-not set}
HTTP status: ${API_STATUS:-no HTTP response}
Classification: $API_ERROR
Attempts: $attempts
Response bodies and credentials are omitted."
  fi
}

# API errors are classified without recording response bodies or credential-bearing stderr.
wizard_api() {
  local method="$1" path="$2" body="${3:-}" attempt=0 result error status
  API_STATUS='' API_JSON='' API_ERROR='' API_NEXT=''
  case "$path" in
    /*|graphql) ;;
    *) API_ERROR='invalid_endpoint'; wizard_api_report_error "$method" "$path" 0; return 2 ;;
  esac
  case "$path" in *'..'*|*://*|*$'\n'*|*$'\r'*) API_ERROR='invalid_endpoint'; wizard_api_report_error "$method" "$path" 0; return 2 ;; esac
  while :; do
    result="$(mktemp "${TMPDIR:-/tmp}/github-wizard-response.XXXXXX")"
    error="$(mktemp "${TMPDIR:-/tmp}/github-wizard-error.XXXXXX")"
    if [[ -n "$body" ]]; then
      if printf '%s' "$body" | GH_HOST="$WIZARD_HOST" gh api --hostname "$WIZARD_HOST" --method "$method" \
        --include -H 'Accept: application/vnd.github+json' "$path" --input - >"$result" 2>"$error"; then status=0; else status=$?; fi
    else
      if GH_HOST="$WIZARD_HOST" gh api --hostname "$WIZARD_HOST" --method "$method" --include \
        -H 'Accept: application/vnd.github+json' "$path" >"$result" 2>"$error"; then status=0; else status=$?; fi
    fi
    API_STATUS="$(sed -n 's/^HTTP[^ ]* \([0-9][0-9][0-9]\).*/\1/p' "$result" | tail -1)"
    if [[ -z "$API_STATUS" ]]; then
      API_STATUS="$(sed -n 's/.*(HTTP \([0-9][0-9][0-9]\)).*/\1/p' "$error" | tail -1)"
    fi
    API_JSON="$(awk 'body {print} /^[[:space:]]*$/ {body=1}' "$result")"
    API_NEXT="$(awk 'tolower($0) ~ /^link:/ {print}' "$result" | tr ',' '\n' | sed -n 's/.*<\([^>]*\)>; rel="next".*/\1/p' | head -1)"
    rm -f "$result" "$error"
    if [[ "$status" -eq 0 ]]; then
      [[ -n "$API_JSON" ]] || API_JSON='{}'
      if ! printf '%s' "$API_JSON" | jq -e . >/dev/null 2>&1; then
        API_ERROR='invalid_response'; wizard_api_report_error "$method" "$path" "$((attempt + 1))"; return 2
      fi
      if [[ "$path" == graphql ]] && printf '%s' "$API_JSON" | jq -e '.errors | length > 0' >/dev/null; then
        API_ERROR='graphql_error'; wizard_api_report_error "$method" "$path" "$((attempt + 1))"; return 2
      fi
      API_STATUS="${API_STATUS:-200}"; return 0
    fi
    case "$API_STATUS" in
      401) API_ERROR='unauthenticated' ;;
      403) API_ERROR='forbidden_or_rate_limited' ;;
      404) API_ERROR='not_found_or_inaccessible' ;;
      409) API_ERROR='conflict' ;;
      422) API_ERROR='invalid_or_unsupported' ;;
      429) API_ERROR='rate_limited' ;;
      5??) API_ERROR='unavailable' ;;
      *) API_ERROR='transport_error' ;;
    esac
    # Only retry safe reads; a lost write response requires reconciliation.
    if [[ "$method" == GET && "$API_STATUS" == 5?? && "$attempt" -lt 2 ]]; then
      attempt=$((attempt + 1)); sleep "$attempt"; continue
    fi
    wizard_api_report_error "$method" "$path" "$((attempt + 1))"
    return 2
  done
}

wizard_api_pages() {
  local path="$1" items_path="${2:-}" page=1 separator='?' collected='[]' chunk next
  [[ -n "$items_path" ]] || items_path='[]'
  [[ "$path" == *'?'* ]] && separator='&'
  next="${path}${separator}per_page=100"
  while [[ "$page" -le 100 ]]; do
    wizard_api GET "$next" || return 2
    chunk="$(printf '%s' "$API_JSON" | jq -c --argjson path "$items_path" 'if ($path|length)>0 then getpath($path) elif type=="array" then . elif has("seats") then .seats elif has("workflow_runs") then .workflow_runs elif has("installations") then .installations else error("Expected paginated array") end | if type=="array" then . else error("Expected paginated array") end')" || return 2
    collected="$(jq -cn --argjson all "$collected" --argjson chunk "$chunk" '$all + $chunk')" || return 2
    if [[ -z "$API_NEXT" ]]; then API_JSON="$collected"; return 0; fi
    case "$API_NEXT" in
      "https://api.$WIZARD_HOST/"*) next="/${API_NEXT#https://api.$WIZARD_HOST/}" ;;
      "https://$WIZARD_HOST/"*) next="/${API_NEXT#https://$WIZARD_HOST/}" ;;
      *) API_ERROR='unsafe_pagination_host'; wizard_log "Pagination link escapes the authenticated host."; return 2 ;;
    esac
    page=$((page + 1))
  done
  API_ERROR='pagination_limit'; wizard_log "Pagination limit reached for $path"; return 2
}

wizard_matches() {
  jq -en --argjson actual "$1" --argjson desired "$2" '
    def matches($a; $d):
      if ($d|type)=="object" then ($a|type)=="object" and all($d|keys[]; . as $k | matches($a[$k];$d[$k]))
      elif ($d|type)=="array" then ($a|type)=="array" and
        (if ($d|length)==0 then ($a|length)==0 else all($d[]; . as $v | any($a[]; matches(.;$v))) end)
      else $a==$d end;
    matches($actual;$desired)' >/dev/null
}

wizard_auth() {
  local actor="$1"
  wizard_api GET /user || return 2
  if [[ "$(printf '%s' "$API_JSON" | jq -r .login)" != "$actor" ]]; then
    wizard_log "Authenticated identity does not match actor '$actor' on $WIZARD_HOST."; return 2
  fi
}

wizard_enterprise() {
  local slug="$1" body
  body="$(jq -cn --arg slug "$slug" '{query:"query($slug:String!){viewer{login} enterprise(slug:$slug){id slug organizations(first:100){nodes{login} pageInfo{hasNextPage endCursor}}}}",variables:{slug:$slug}}')"
  wizard_api POST graphql "$body" || return 2
  WIZARD_ENTERPRISE_ID="$(printf '%s' "$API_JSON" | jq -r '.data.enterprise.id // empty')"
  [[ -n "$WIZARD_ENTERPRISE_ID" ]] || { wizard_log "Enterprise '$slug' is unavailable to this identity."; return 2; }
  WIZARD_ENTERPRISE_ORGS="$(printf '%s' "$API_JSON" | jq -c '[.data.enterprise.organizations.nodes[].login]')"
  local cursor
  while printf '%s' "$API_JSON" | jq -e '.data.enterprise.organizations.pageInfo.hasNextPage' >/dev/null; do
    cursor="$(printf '%s' "$API_JSON" | jq -r '.data.enterprise.organizations.pageInfo.endCursor')"
    body="$(jq -cn --arg slug "$slug" --arg cursor "$cursor" '{query:"query($slug:String!,$cursor:String){enterprise(slug:$slug){organizations(first:100,after:$cursor){nodes{login} pageInfo{hasNextPage endCursor}}}}",variables:{slug:$slug,cursor:$cursor}}')"
    wizard_api POST graphql "$body" || return 2
    WIZARD_ENTERPRISE_ORGS="$(jq -cn --argjson all "$WIZARD_ENTERPRISE_ORGS" --argjson data "$API_JSON" '$all + [$data.data.enterprise.organizations.nodes[].login]')"
  done
}
