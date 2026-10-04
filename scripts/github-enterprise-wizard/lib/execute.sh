wizard_write_json() {
  local target="$1" data="$2" temporary
  [[ ! -L "$target" ]] || wizard_die "Refusing symlink: $target"
  temporary="$(mktemp "$(dirname "$target")/.wizard.XXXXXX")" || return 2
  printf '%s\n' "$data" | jq . >"$temporary" || { rm -f "$temporary"; return 2; }
  mv "$temporary" "$target" || { rm -f "$temporary"; return 2; }
}

wizard_doctor() {
  local file="$1" config
  wizard_validate_config "$file" || return 2
  config="$(wizard_effective_config "$file")" || return 2
  wizard_set_host "$(printf '%s' "$config" | jq -r .host)"
  wizard_auth "$(printf '%s' "$config" | jq -r .actor)" || return 2
  wizard_enterprise "$(printf '%s' "$config" | jq -r .enterprise.slug)" || return 2
  wizard_log "Authenticated on $WIZARD_HOST; enterprise access verified."
  if [[ "$(printf '%s' "$config" | jq -r .enterprise.identity)" == emu ]]; then
    wizard_log "EMU selected: IdP membership and public-content restrictions apply."
  fi
  # A declared type is not proof of tenancy; operations are still checked against the host.
  wizard_log "Confirm the declared identity type in enterprise settings before approving the plan."
}

wizard_org_actions() {
  local config="$1" org login exists create adopt body desired
  while IFS= read -r org; do
    login="$(printf '%s' "$org" | jq -r .login)"
    exists=false
    if printf '%s' "$WIZARD_ENTERPRISE_ORGS" | jq -e --arg login "$login" 'index($login)!=null' >/dev/null; then exists=true; fi
    create="$(printf '%s' "$org" | jq -r '.create // false')"
    adopt="$(printf '%s' "$org" | jq -r '.adopt // false')"
    if [[ "$exists" == true ]]; then
      jq -cn --arg org "$login" --argjson adopt "$adopt" \
        '{id:($org+":workspace:organization"),org:$org,package:"workspace",kind:"ensure",read_path:("/orgs/"+$org),desired:{login:$org},adopt:$adopt,depends_on:[]}'
    elif [[ "$create" == true ]]; then
      body="$(printf '%s' "$org" | jq -c --arg eid "$WIZARD_ENTERPRISE_ID" '{query:"mutation($input:CreateEnterpriseOrganizationInput!){createEnterpriseOrganization(input:$input){organization{login} enterprise{id}}}",variables:{input:{enterpriseId:$eid,login:.login,profileName:(.profile_name//.login),billingEmail:.billing_email,adminLogins:.owners}}}')"
      jq -cn --arg org "$login" --argjson body "$body" \
        '{id:($org+":workspace:organization"),org:$org,package:"workspace",kind:"organization",apply:$body,desired:{login:$org},depends_on:[]}'
    else
      jq -cn --arg org "$login" \
        '{id:($org+":workspace:organization"),org:$org,package:"workspace",kind:"manual",owner:"enterprise-owner",message:"Organization is not visible in the enterprise. Resolve access/membership, or explicitly select creation.",depends_on:[]}'
    fi
  done < <(printf '%s' "$config" | jq -c '.organizations[]')
}

wizard_generate_actions() {
  wizard_org_actions "$1" || return 2
  wizard_workspace_actions "$1" || return 2
  wizard_actions_actions "$1" || return 2
  wizard_capabilities_actions "$1" || return 2
}

wizard_check_actions() {
  local actions="$1" config="$2" enterprise_id="${3:-${WIZARD_ENTERPRISE_ID:-}}"
  jq -e --argjson config "$config" '
    . as $all |
    (map(.id)|length)==(map(.id)|unique|length) and
    all(.[]; (.id|type)=="string" and (.package|type)=="string" and
      (.org as $o | any($config.organizations[]; .login==$o)) and
      (.kind|IN("ensure","organization","files","workflow","manual","purchase","report","ghaw","request","analysis","setup_run")) and
      ((.depends_on//[])|type)=="array" and
      all((.depends_on//[])[]; . as $id | any($all[]; .id==$id)) and
      (if .kind=="ensure" then (.read_path|type)=="string" and (.desired|type)=="object" and (.desired|length)>0
       elif .kind=="files" or .kind=="ghaw" then (.repo|type)=="string" and (.files|type)=="array" and all(.files[]; (.path|type)=="string" and (.content|type)=="string" and (.path|test("(^/|(^|/)\\.\\.(/|$)|[\\r\\n]|[?#%])")|not))
       elif .kind=="manual" then (.message|type)=="string"
       else true end))' <<<"$actions" >/dev/null || { wizard_log "Invalid package action graph."; return 2; }
  local action path org write enterprise
  enterprise="$(printf '%s' "$config" | jq -r .enterprise.slug)"
  while IFS= read -r action; do
    org="$(printf '%s' "$action" | jq -r .org)"
    if [[ "$(printf '%s' "$action" | jq -r .kind)" == organization ]]; then
      jq -e --arg org "$org" --arg enterprise "$enterprise_id" \
        '.apply.query=="mutation($input:CreateEnterpriseOrganizationInput!){createEnterpriseOrganization(input:$input){organization{login} enterprise{id}}}" and .apply.variables.input.login==$org and .apply.variables.input.enterpriseId==$enterprise and ($enterprise|length)>0' <<<"$action" >/dev/null ||
        { wizard_log "Invalid organization mutation."; return 2; }
    fi
    if printf '%s' "$action" | jq -e '.repo!=null' >/dev/null; then
      [[ "$(printf '%s' "$action" | jq -r .repo)" == "$org/"* ]] || { wizard_log "Repository action escapes organization scope."; return 2; }
    fi
    while IFS= read -r path; do
      case "$path" in
        "/orgs/$org"|"/orgs/$org/"*|"/repos/$org/"*|"/organizations/$org/"*|"/enterprises/$enterprise/"*) ;;
        *) wizard_log "Read endpoint escapes approved scope."; return 2 ;;
      esac
      case "$path" in *'..'*|*$'\r'*|*$'\n'*) wizard_log "Unsafe API path."; return 2 ;; esac
    done < <(printf '%s' "$action" | jq -r '[.read_path,.lookup.detail_path]|map(select(.!=null))[]')
    while IFS= read -r write; do
      path="$(printf '%s' "$write" | jq -r .path)"
      case "$path" in
        "/orgs/$org"|"/orgs/$org/"*|"/repos/$org/"*|"/organizations/$org/"*|"/enterprises/$enterprise/"*) ;;
        /repos/*/generate)
          [[ "$(printf '%s' "$write" | jq -r .body.owner)" == "$org" ]] || { wizard_log "Template generation escapes organization scope."; return 2; } ;;
        *) wizard_log "Write endpoint escapes approved scope."; return 2 ;;
      esac
      [[ "$(printf '%s' "$write" | jq -r .method)" =~ ^(POST|PUT|PATCH)$ ]] || { wizard_log "Unsupported write method."; return 2; }
    done < <(printf '%s' "$action" | jq -c '[.create,.update,(if .kind=="purchase" or .kind=="request" then .apply else null end)]|map(select(.!=null))[]')
  done < <(printf '%s' "$actions" | jq -c '.[]')
  local remaining="$actions" ready ids='[]' rounds=0
  while [[ "$(printf '%s' "$remaining" | jq length)" -gt 0 ]]; do
    ready="$(jq -cn --argjson all "$remaining" --argjson done "$ids" '$all|map(select(all((.depends_on//[])[]; . as $id | $done|index($id)!=null)))')"
    [[ "$(printf '%s' "$ready" | jq length)" -gt 0 ]] || { wizard_log "Package dependencies contain a cycle."; return 2; }
    ids="$(jq -cn --argjson done "$ids" --argjson ready "$ready" '$done+[$ready[].id]')"
    remaining="$(jq -cn --argjson all "$remaining" --argjson done "$ids" '$all|map(select(.id as $id|$done|index($id)==null))')"
    rounds=$((rounds+1)); [[ "$rounds" -le 1000 ]] || return 2
  done
  WIZARD_SORTED_IDS="$ids"
}

wizard_inspect_ensure() {
  local action="$1" desired path actual
  desired="$(printf '%s' "$action" | jq -c .desired)"
  path="$(printf '%s' "$action" | jq -r .read_path)"
  INSPECT_RESOURCE_ID='' INSPECT_CURRENT='{}'
  if wizard_read_ensure "$action"; then
    actual="$API_JSON"
    INSPECT_CURRENT="$actual"
    INSPECT_BEFORE="$(jq -cn --argjson actual "$actual" --argjson desired "$desired" '$desired | with_entries(.value=$actual[.key])')"
    if wizard_matches "$actual" "$desired"; then INSPECT_OPERATION=none
    elif { [[ "$(printf '%s' "$action" | jq -r '.adopt // false')" == true ]] || wizard_action_owned "$action"; } && printf '%s' "$action" | jq -e '.update != null' >/dev/null; then INSPECT_OPERATION=update
    else INSPECT_OPERATION=blocked; fi
  elif [[ "$API_STATUS" == 404 ]] && printf '%s' "$action" | jq -e '.create != null' >/dev/null; then
    INSPECT_BEFORE=null; INSPECT_OPERATION=create
  else
    INSPECT_BEFORE=null; INSPECT_OPERATION=blocked
  fi
}

wizard_read_ensure() {
  local a="$1" path matches count detail projection
  path="$(printf '%s' "$a" | jq -r .read_path)"
  if printf '%s' "$a" | jq -e '.lookup!=null' >/dev/null; then
    wizard_api_pages "$path" "$(printf '%s' "$a" | jq -c '.lookup.items_path//[]')" || return 2
    matches="$(jq -cn --argjson data "$API_JSON" --argjson match "$(printf '%s' "$a" | jq -c .lookup.match)" \
      '$data|map(select(. as $item|all($match|to_entries[]; . as $entry|$item[$entry.key]==$entry.value)))')"
    count="$(printf '%s' "$matches" | jq length)"
    if [[ "$count" == 0 ]]; then API_STATUS=404; API_ERROR=not_found; return 2; fi
    [[ "$count" == 1 ]] || { API_ERROR=ambiguous_resource; wizard_log "Multiple resources match $path."; return 2; }
    API_JSON="$(printf '%s' "$matches" | jq -c '.[0]')"
    INSPECT_RESOURCE_ID="$(printf '%s' "$API_JSON" | jq -r .id)"
    [[ "$INSPECT_RESOURCE_ID" =~ ^[0-9]+$ ]] || { API_ERROR=invalid_resource_id; return 2; }
    detail="$(printf '%s' "$a" | jq -r '.lookup.detail_path//empty')"
    if [[ -n "$detail" ]]; then wizard_api GET "${detail//\{id\}/$INSPECT_RESOURCE_ID}" || return 2; fi
  else wizard_api GET "$path" || return 2; fi
  if printf '%s' "$API_JSON" | jq -e '.id|type=="number"' >/dev/null 2>&1; then
    INSPECT_RESOURCE_ID="$(printf '%s' "$API_JSON" | jq -r .id)"
  fi
  projection="$(printf '%s' "$a" | jq -r '.read_projection//empty')"
  case "$projection" in
    properties) API_JSON="$(printf '%s' "$API_JSON" | jq -c '{properties:.}')" ;;
    environment)
      API_JSON="$(printf '%s' "$API_JSON" | jq -c \
        '{name,wait_timer:([.protection_rules[]?|select(.type=="wait_timer")|.wait_timer][0]//0),
          reviewers:([.protection_rules[]?|select(.type=="required_reviewers")|.reviewers[]?|{type,id:.reviewer.id}]),
          prevent_self_review:([.protection_rules[]?|select(.type=="required_reviewers")|.prevent_self_review][0]//false),
          deployment_branch_policy}')" ;;
  esac
}

wizard_action_owned() {
  local a="$1" dependency
  [[ -n "${WIZARD_RUN:-}" && -f "$WIZARD_RUN/ledger.json" ]] || return 1
  if wizard_ledger_data "$(printf '%s' "$a" | jq -r .id)" | jq -e '.owned==true' >/dev/null; then return 0; fi
  # Intrinsic settings of a resource created by this run may be updated.
  printf '%s' "$a" | jq -e '.create==null' >/dev/null || return 1
  while IFS= read -r dependency; do
    if wizard_ledger_data "$dependency" | jq -e '.owned==true' >/dev/null; then return 0; fi
  done < <(printf '%s' "$a" | jq -r '(.depends_on//[])[]')
  return 1
}

wizard_plan() {
  local file="$1" output="$2" config actions plan_data action operation before prepared='[]' digest
  [[ ! -e "$output" && ! -L "$output" ]] || wizard_die "Plan output already exists."
  wizard_doctor "$file" || return 2
  config="$(wizard_effective_config "$file")"
  actions="$(wizard_generate_actions "$config" | jq -s .)" || return 2
  wizard_check_actions "$actions" "$config" || return 2
  local id deps parent_new
  while IFS= read -r id; do
    action="$(printf '%s' "$actions" | jq -c --arg id "$id" '.[]|select(.id==$id)')"
    operation="$(printf '%s' "$action" | jq -r .kind)"; before=null
    if [[ "$operation" == ghaw ]]; then
      if wizard_compile_ghaw "$action"; then
        action="$COMPILED_GHAW_ACTION"; operation=files
      else
        action="$(jq -cn --argjson a "$action" '$a|.kind="manual"|.owner="repository-maintainer"|.message="Install/review a supported gh-aw release, resolve compiler prerequisites, and re-plan. No workflow was deployed."')"
        operation=manual
      fi
    fi
    if [[ "$operation" == files ]]; then
      wizard_pin_actions "$action" || return 2
      action="$PINNED_CONTENT_ACTION"
    fi
    if [[ "$operation" == ensure ]]; then
      if [[ "$(printf '%s' "$action" | jq -r '.create.path//empty')" == /repos/*/generate ]]; then
        wizard_template_snapshot "$action" || return 2
        action="$(jq -cn --argjson a "$action" --argjson source "$TEMPLATE_SNAPSHOT" '$a+{template_source:$source}')"
      fi
      deps="$(printf '%s' "$action" | jq -c '.depends_on//[]')"
      parent_new="$(jq -cn --argjson prior "$prepared" --argjson deps "$deps" 'any($prior[]; .id as $id | ($deps|index($id)!=null) and (.operation=="create" or .operation=="deferred" or .kind=="organization"))')"
      if [[ "$parent_new" == true ]]; then operation=deferred
      else
        wizard_inspect_ensure "$action"; operation="$INSPECT_OPERATION"; before="$INSPECT_BEFORE"
        if [[ -n "$INSPECT_RESOURCE_ID" ]]; then action="$(jq -cn --argjson a "$action" --arg id "$INSPECT_RESOURCE_ID" '$a+{resource_id:$id}')"; fi
      fi
    fi
    if [[ "$operation" == files ]]; then
      local repo repo_creation
      repo="$(printf '%s' "$action" | jq -r .repo)"
      repo_creation="$(jq -cn --argjson prior "$prepared" --arg repo "$repo" \
        'any($prior[]; .id==(($repo|split("/")[0])+":workspace:repo:"+($repo|split("/")[1])) and (.operation=="create" or .operation=="deferred"))')"
      if [[ "$repo_creation" != true ]] && wizard_files_snapshot "$action"; then
        action="$(jq -cn --argjson a "$action" --argjson snapshot "$FILES_SNAPSHOT" \
          --arg repository_id "$FILES_REPOSITORY_ID" '$a+{file_snapshot:$snapshot,file_repository_id:$repository_id,repository_existed:true}')"
      elif [[ "$repo_creation" != true ]]; then
        # Missing or inaccessible parents are handled by the dependency ledger.
        action="$(jq -cn --argjson a "$action" '$a+{repository_existed:true}')"
      fi
    fi
    action="$(jq -cn --argjson a "$action" --arg op "$operation" --argjson before "$before" '$a+{operation:$op,before:$before}')"
    prepared="$(jq -cn --argjson all "$prepared" --argjson a "$action" '$all+[$a]')"
    if [[ "$(printf '%s' "$action" | jq -r '.compiler_version//empty')" != '' && "$(printf '%s' "$action" | jq -r '.run//true')" == true ]]; then
      local live_action
      live_action="$(printf '%s' "$action" | jq -c '{id:(.id+":live"),org,package,kind:"workflow",repo,workflow,ref:(.ref//"main"),inputs:(.inputs//{}),depends_on:[.id],operation:"workflow",before:null,cost}')"
      prepared="$(jq -cn --argjson all "$prepared" --argjson a "$live_action" '$all+[$a]')"
    fi
  done < <(printf '%s' "$WIZARD_SORTED_IDS" | jq -r '.[]')
  wizard_check_actions "$prepared" "$config" || return 2
  plan_data="$(jq -cn --argjson config "$config" --argjson actions "$prepared" --arg eid "$WIZARD_ENTERPRISE_ID" \
    --arg implementation "$(wizard_code_hash)" \
    '{schema_version:1,host:$config.host,actor:$config.actor,enterprise_id:$eid,config:$config,implementation_digest:$implementation,
      warnings:["Identity type must be confirmed in enterprise settings.","Selected purchases and live runs may incur unknown costs. Review all payloads before approving."],
      actions:$actions}')"
  digest="$(printf '%s' "$plan_data" | wizard_json_hash)"
  wizard_write_json "$output" "$(jq -cn --argjson p "$plan_data" --arg digest "$digest" '$p+{digest:$digest}')"
  wizard_log "Plan saved: $output"
  wizard_log "Approval digest: $digest"
  jq -r '.actions[] | [.id,.operation,(.message//"")] | @tsv' "$output"
}

wizard_plan_integrity() {
  local file="$1" expected actual
  [[ -f "$file" && ! -L "$file" ]] || { wizard_log "Missing or unsafe plan file."; return 2; }
  expected="$(jq -r '.digest//empty' "$file")"
  actual="$(jq 'del(.digest)' "$file" | wizard_json_hash)"
  [[ -n "$expected" && "$expected" == "$actual" ]] || { wizard_log "Plan digest mismatch."; return 2; }
  [[ "$(jq -r .implementation_digest "$file")" == "$(wizard_code_hash)" ]] || { wizard_log "Wizard changed; generate a new plan."; return 2; }
  local temporary
  temporary="$(mktemp "${TMPDIR:-/tmp}/github-wizard-config.XXXXXX")"
  jq .config "$file" >"$temporary"
  if ! wizard_validate_config "$temporary"; then rm -f "$temporary"; return 2; fi
  rm -f "$temporary"
  jq -e '.host==.config.host and .actor==.config.actor' "$file" >/dev/null || { wizard_log "Plan identity differs from its configuration."; return 2; }
  wizard_check_actions "$(jq -c .actions "$file")" "$(jq -c .config "$file")" "$(jq -r .enterprise_id "$file")"
}

wizard_approve() {
  local file="$1" approval="$2" digest answer
  digest="$(jq -r .digest "$file")"
  if [[ -n "$approval" ]]; then
    [[ "$approval" == "$digest" ]] || { wizard_log "Approval must match the exact plan digest."; return 2; }
    return 0
  fi
  jq '{host,actor,warnings,actions:[.actions[]|{id,operation,kind,apply,create,update,cost,message}]}' "$file" >&2
  [[ -t 0 ]] || { wizard_log "Non-interactive apply requires --approve $digest"; return 2; }
  wizard_log "Review the complete plan file, including content and purchase recipients."
  printf 'Type the plan digest to approve: ' >&2
  IFS= read -r answer || return 2
  [[ "$answer" == "$digest" ]] || { wizard_log "Plan not approved."; return 2; }
}

wizard_ledger_set() {
  local id="$1" state="$2" detail="$3" data="${4:-}" updated
  [[ -n "$data" ]] || data='{}'
  updated="$(jq --arg id "$id" --arg status "$state" --arg detail "$detail" --argjson data "$data" \
    '.actions[$id]=((.actions[$id]//{})+{status:$status,detail:$detail,data:$data})' "$WIZARD_RUN/ledger.json")" ||
    wizard_die "Cannot read run state; stopping before further changes."
  wizard_write_json "$WIZARD_RUN/ledger.json" "$updated" ||
    wizard_die "Cannot persist run state; stopping before further changes."
}

wizard_ledger_state() { jq -r --arg id "$1" '.actions[$id].status//"planned"' "$WIZARD_RUN/ledger.json"; }
wizard_ledger_data() { jq -c --arg id "$1" '.actions[$id].data//{}' "$WIZARD_RUN/ledger.json"; }

wizard_lock() {
  [[ -d "$WIZARD_RUN" && ! -L "$WIZARD_RUN" ]] || wizard_die "Missing or unsafe run directory."
  mkdir "$WIZARD_RUN/.lock" 2>/dev/null || wizard_die "Run is locked. Check for an active process before removing .lock."
  trap 'rmdir "$WIZARD_RUN/.lock" 2>/dev/null || true' EXIT
}

wizard_run_auth() {
  wizard_set_host "$(jq -r .host "$WIZARD_RUN/plan.json")"
  wizard_auth "$(jq -r .actor "$WIZARD_RUN/plan.json")" || return 2
  wizard_enterprise "$(jq -r .config.enterprise.slug "$WIZARD_RUN/plan.json")" || return 2
  [[ "$WIZARD_ENTERPRISE_ID" == "$(jq -r .enterprise_id "$WIZARD_RUN/plan.json")" ]] || { wizard_log "Enterprise identity changed."; return 2; }
  local org_action org id
  while IFS= read -r org_action; do
    org="$(printf '%s' "$org_action" | jq -r .org)"; id="$(printf '%s' "$org_action" | jq -r .id)"
    if [[ "$(printf '%s' "$org_action" | jq -r .kind)" == ensure ]] || wizard_ledger_data "$id" | jq -e '.owned==true' >/dev/null; then
      if ! printf '%s' "$WIZARD_ENTERPRISE_ORGS" | jq -e --arg org "$org" 'index($org)!=null' >/dev/null; then
        wizard_log "Approved organization '$org' is no longer visible in this enterprise."; return 2
      fi
    fi
  done < <(jq -c '.actions[]|select(.id==(.org+":workspace:organization"))' "$WIZARD_RUN/plan.json")
}

wizard_apply() {
  local file="$1" directory="$2" approval="$3"
  wizard_plan_integrity "$file" || return 2
  wizard_approve "$file" "$approval" || return 2
  [[ ! -e "$directory" && ! -L "$directory" ]] || wizard_die "Run directory exists; use resume."
  mkdir "$directory" || return 2
  WIZARD_RUN="$(cd "$directory" && pwd)"
  cp "$file" "$WIZARD_RUN/plan.json"
  wizard_write_json "$WIZARD_RUN/ledger.json" '{"schema_version":1,"actions":{}}'
  wizard_lock
  wizard_run_auth || return 2
  wizard_execute false
}

wizard_resume() {
  [[ ! -L "$1" ]] || wizard_die "Refusing a symlink run directory."
  WIZARD_RUN="$(cd "$1" && pwd)" || return 2
  wizard_plan_integrity "$WIZARD_RUN/plan.json" || return 2
  wizard_approve "$WIZARD_RUN/plan.json" "$2" || return 2
  wizard_lock
  wizard_run_auth || return 2
  wizard_execute false
}

wizard_verify_run() {
  [[ ! -L "$1" ]] || wizard_die "Refusing a symlink run directory."
  WIZARD_RUN="$(cd "$1" && pwd)" || return 2
  wizard_plan_integrity "$WIZARD_RUN/plan.json" || return 2
  wizard_lock
  wizard_run_auth || return 2
  wizard_execute true
}

wizard_execute() {
  local verify_only="$1" id action state deps dependency blocked=false kind data result
  while IFS= read -r id; do
    action="$(jq -c --arg id "$id" '.actions[]|select(.id==$id)' "$WIZARD_RUN/plan.json")"
    state="$(wizard_ledger_state "$id")"
    if [[ "$state" == attested || ( "$state" == ready && "$verify_only" != true ) ]]; then continue; fi
    blocked=false
    while IFS= read -r dependency; do
      case "$(wizard_ledger_state "$dependency")" in ready|attested) ;; *) blocked=true ;; esac
    done < <(printf '%s' "$action" | jq -r '(.depends_on//[])[]')
    if [[ "$blocked" == true ]]; then wizard_ledger_set "$id" pending "A dependency is incomplete."; continue; fi
    kind="$(printf '%s' "$action" | jq -r .kind)"
    data="$(wizard_ledger_data "$id")"
    ACTION_STATE=failed ACTION_DETAIL='Operation failed.' ACTION_DATA="$data"
    if wizard_dispatch_action "$action" "$verify_only" "$state"; then result=0; else result=$?; fi
    if [[ "$result" -ne 0 && "$(wizard_ledger_state "$id")" == dispatching ]]; then
      ACTION_STATE=unverified; ACTION_DETAIL="Write response uncertain; reconcile the resource before retrying."
      ACTION_DATA="$(wizard_ledger_data "$id")"
    fi
    if [[ "$result" -ne 0 && "$ACTION_STATE" == ready ]]; then ACTION_STATE=failed; fi
    wizard_ledger_set "$id" "$ACTION_STATE" "$ACTION_DETAIL" "$ACTION_DATA"
    wizard_log "$id: $ACTION_STATE ($ACTION_DETAIL)"
  done < <(printf '%s' "$WIZARD_SORTED_IDS" | jq -r '.[]')
  wizard_status "$WIZARD_RUN"
}

wizard_dispatch_action() {
  local action="$1" verify_only="$2" previous="$3" kind
  kind="$(printf '%s' "$action" | jq -r .kind)"
  case "$kind" in
    manual) ACTION_STATE=pending; ACTION_DETAIL="$(printf '%s' "$action" | jq -r .message)" ;;
    organization) wizard_apply_organization "$action" "$verify_only" ;;
    ensure) wizard_apply_ensure "$action" "$verify_only" ;;
    files) wizard_apply_files "$action" "$verify_only" ;;
    workflow) wizard_apply_workflow "$action" "$verify_only" "$previous" ;;
    purchase) wizard_apply_purchase "$action" "$verify_only" "$previous" ;;
    report) wizard_apply_report "$action" ;;
    analysis) wizard_apply_analysis "$action" ;;
    setup_run) wizard_apply_setup_run "$action" ;;
    ghaw) wizard_apply_ghaw "$action" "$verify_only" ;;
    request) ACTION_STATE=unsupported; ACTION_DETAIL="No verified executor for this request; no write attempted." ;;
    *) ACTION_STATE=unsupported; ACTION_DETAIL="Unsupported action kind." ;;
  esac
}

wizard_apply_analysis() {
  local a="$1" attempt=0 head match
  wizard_api GET "/repos/$(printf '%s' "$a" | jq -r .repo)/commits/$(printf '%s' "$a" | jq -r '.ref//"main"')" || return 2
  head="$(printf '%s' "$API_JSON" | jq -r .sha)"
  match="$(printf '%s' "$a" | jq -c '.match//{tool:{name:"CodeQL"}}')"
  while [[ "$attempt" -lt 6 ]]; do
    wizard_api_pages "$(printf '%s' "$a" | jq -r .read_path)" || return 2
    local analysis
    while IFS= read -r analysis; do
      if wizard_matches "$analysis" "$match" &&
        [[ "$(printf '%s' "$analysis" | jq -r .commit_sha)" == "$head" ]] &&
        [[ -z "$(printf '%s' "$analysis" | jq -r '.error//empty')" ]]; then
        ACTION_STATE=ready; ACTION_DETAIL="CodeQL analysis completed for the selected commit."
        ACTION_DATA="$(printf '%s' "$analysis" | jq -c '{id,commit_sha}')"; return 0
      fi
    done < <(printf '%s' "$API_JSON" | jq -c '.[]')
    attempt=$((attempt+1)); [[ "$attempt" -ge 6 ]] || sleep 5
  done
  ACTION_STATE=unverified; ACTION_DETAIL="No successful analysis yet for the selected commit; resume after scanning."
}

wizard_apply_organization() {
  local a="$1" verify_only="$2" org
  org="$(printf '%s' "$a" | jq -r .org)"
  if printf '%s' "$WIZARD_ENTERPRISE_ORGS" | jq -e --arg org "$org" 'index($org)!=null' >/dev/null; then
    if ! printf '%s' "$ACTION_DATA" | jq -e '.owned==true' >/dev/null; then
      ACTION_STATE=pending; ACTION_DETAIL="Organization appeared after planning; explicitly adopt it in a new plan."; return 0
    fi
  else
    [[ "$verify_only" != true ]] || { ACTION_STATE=pending; ACTION_DETAIL="Organization has not been created."; return 0; }
    local id
    id="$(printf '%s' "$a" | jq -r .id)"
    wizard_ledger_set "$id" dispatching "Organization creation started; uncertain results need explicit adoption." "$ACTION_DATA"
    wizard_api POST graphql "$(printf '%s' "$a" | jq -c .apply)" || return 2
    ACTION_DATA='{"owned":true}'
    wizard_ledger_set "$id" unverified "Organization created; verifying membership and owners." "$ACTION_DATA"
    wizard_enterprise "$(jq -r .config.enterprise.slug "$WIZARD_RUN/plan.json")" || return 2
  fi
  if ! printf '%s' "$WIZARD_ENTERPRISE_ORGS" | jq -e --arg org "$org" 'index($org)!=null' >/dev/null; then
    ACTION_STATE=pending; ACTION_DETAIL="Enterprise organization creation is not yet visible."; return 0
  fi
  wizard_api GET "/orgs/$org" || return 2
  local owner
  while IFS= read -r owner; do
    wizard_api GET "/orgs/$org/memberships/$owner" || { ACTION_STATE=pending; ACTION_DETAIL="An owner invitation is outstanding."; return 0; }
    if ! printf '%s' "$API_JSON" | jq -e '.state=="active" and .role=="admin"' >/dev/null; then
      ACTION_STATE=pending; ACTION_DETAIL="An owner invitation is outstanding."; return 0
    fi
  done < <(printf '%s' "$a" | jq -r '.apply.variables.input.adminLogins[]')
  ACTION_STATE=ready; ACTION_DETAIL="Organization and requested owners verified."
}

wizard_apply_ensure() {
  local a="$1" verify_only="$2" operation planned before write method path body actual
  if [[ "$(printf '%s' "$a" | jq -r .id)" == "$(printf '%s' "$a" | jq -r .org):workspace:organization" ]]; then
    if ! printf '%s' "$WIZARD_ENTERPRISE_ORGS" | jq -e --arg org "$(printf '%s' "$a" | jq -r .org)" 'index($org)!=null' >/dev/null; then
      ACTION_STATE=failed; ACTION_DETAIL="Organization is no longer visible in the approved enterprise."; return 2
    fi
  fi
  wizard_inspect_ensure "$a"
  operation="$INSPECT_OPERATION"; before="$INSPECT_BEFORE"
  if printf '%s' "$API_JSON" | jq -e '.id|type=="number"' >/dev/null 2>&1; then
    ACTION_DATA="$(jq -cn --argjson data "$ACTION_DATA" --argjson id "$(printf '%s' "$API_JSON" | jq .id)" '$data+{resource_id:$id}')"
  fi
  if printf '%s' "$a" | jq -e '.resource_id!=null' >/dev/null && [[ "$INSPECT_RESOURCE_ID" != "$(printf '%s' "$a" | jq -r .resource_id)" ]]; then
    ACTION_STATE=failed; ACTION_DETAIL="Resource identity changed after planning; create a new plan."; return 2
  fi
  if [[ "$operation" == none ]]; then
    if [[ "$(printf '%s' "$a" | jq -r .operation)" == create ]] && ! printf '%s' "$ACTION_DATA" | jq -e '.owned==true' >/dev/null; then
      ACTION_STATE=pending; ACTION_DETAIL="Resource appeared after planning; create a new adoption plan."; return 0
    fi
    ACTION_STATE=ready; ACTION_DETAIL="Desired settings verified."; return 0
  fi
  if [[ "$verify_only" == true ]]; then ACTION_STATE=unverified; ACTION_DETAIL="Desired settings are not verified."; return 0; fi
  planned="$(printf '%s' "$a" | jq -r .operation)"
  if [[ "$operation" == blocked || "$planned" == blocked ]]; then
    ACTION_STATE=pending; ACTION_DETAIL="Access, adoption approval, or a supported write is missing."; return 0
  fi
  if [[ "$operation" == update ]]; then
    if [[ "$planned" == deferred ]] && wizard_action_owned "$a"; then :
    elif [[ "$planned" != update ]] || ! jq -en --argjson current "$before" \
      --argjson planned "$(printf '%s' "$a" | jq -c .before)" '$current==$planned' >/dev/null; then
      ACTION_STATE=failed; ACTION_DETAIL="Managed settings changed after planning; create a new plan."; return 2
    fi
    write="$(printf '%s' "$a" | jq -c .update)"
  else
    if [[ "$planned" != create && "$planned" != deferred ]]; then
      ACTION_STATE=failed; ACTION_DETAIL="Resource disappeared after planning; creation was not approved."; return 2
    fi
    write="$(printf '%s' "$a" | jq -c .create)"
  fi
  [[ "$write" != null ]] || { ACTION_STATE=pending; ACTION_DETAIL="No approved creation operation."; return 0; }
  if [[ "$operation" == create ]] && printf '%s' "$a" | jq -e '.template_source!=null' >/dev/null; then
    wizard_template_snapshot "$a" || return 2
    if ! jq -en --argjson current "$TEMPLATE_SNAPSHOT" --argjson planned \
      "$(printf '%s' "$a" | jq -c .template_source)" '$current==$planned' >/dev/null; then
      ACTION_STATE=failed; ACTION_DETAIL="Template changed after planning; create a new plan."; return 2
    fi
  fi
  method="$(printf '%s' "$write" | jq -r .method)"
  path="$(printf '%s' "$write" | jq -r .path)"
  if [[ "$path" == *'{id}'* ]]; then
    [[ -n "$INSPECT_RESOURCE_ID" ]] || { ACTION_DETAIL="Resource ID is not verified."; return 2; }
    path="${path//\{id\}/$INSPECT_RESOURCE_ID}"
  fi
  body="$(printf '%s' "$write" | jq -c '.body//{}')"
  if [[ "$(printf '%s' "$a" | jq -r '.merge_update//false')" == true && "$operation" == update ]]; then
    body="$(jq -cn --argjson current "$INSPECT_CURRENT" --argjson desired "$body" \
      '($current|{wait_timer,reviewers,prevent_self_review,deployment_branch_policy}|with_entries(select(.value!=null)))+$desired')"
  fi
  if [[ "$operation" == create ]]; then
    wizard_ledger_set "$(printf '%s' "$a" | jq -r .id)" dispatching "Creation started; ambiguous responses need explicit adoption." "$ACTION_DATA"
  fi
  wizard_api "$method" "$path" "$body" || return 2
  if printf '%s' "$API_JSON" | jq -e '.id|type=="number"' >/dev/null; then
    ACTION_DATA="$(jq -cn --argjson data "$ACTION_DATA" --argjson id "$(printf '%s' "$API_JSON" | jq .id)" '$data+{resource_id:$id}')"
  fi
  if printf '%s' "$API_JSON" | jq -e '.run_id!=null' >/dev/null; then
    ACTION_DATA="$(jq -cn --argjson data "$ACTION_DATA" --argjson run "$(printf '%s' "$API_JSON" | jq -c .run_id)" '$data+{setup_run_id:$run}')"
    wizard_ledger_set "$(printf '%s' "$a" | jq -r .id)" unverified "Setup run accepted; verifying configuration." "$ACTION_DATA"
  fi
  if [[ "$operation" == create ]]; then
    ACTION_DATA="$(jq -cn --argjson data "$ACTION_DATA" '$data+{owned:true}')"
    wizard_ledger_set "$(printf '%s' "$a" | jq -r .id)" unverified "Creation accepted; verifying resource." "$ACTION_DATA"
  fi
  local attempt=0
  while [[ "$attempt" -lt 3 ]]; do
    if wizard_read_ensure "$a" && wizard_matches "$API_JSON" "$(printf '%s' "$a" | jq -c .desired)"; then
      ACTION_STATE=ready; ACTION_DETAIL="Applied and verified."; return 0
    fi
    if [[ "$attempt" == 0 && "$operation" == create ]] && printf '%s' "$a" | jq -e '.update!=null' >/dev/null; then
      # Template generation applies fewer settings than repository creation.
      write="$(printf '%s' "$a" | jq -c .update)"
      path="$(printf '%s' "$write" | jq -r .path)"
      if [[ "$path" != *'{id}'* ]]; then
        wizard_api "$(printf '%s' "$write" | jq -r .method)" "$path" "$(printf '%s' "$write" | jq -c .body)" || return 2
      fi
    fi
    attempt=$((attempt+1)); [[ "$attempt" -ge 3 ]] || sleep 1
  done
  ACTION_STATE=unverified; ACTION_DETAIL="Write accepted; read-back is not yet verified."
}

wizard_apply_setup_run() {
  local a="$1" source run_id attempt=0
  source="$(printf '%s' "$a" | jq -r .source_action)"
  run_id="$(wizard_ledger_data "$source" | jq -r '.setup_run_id//empty')"
  if [[ -z "$run_id" ]]; then
    ACTION_STATE=pending; ACTION_DETAIL="No setup run ID was returned. Run the native analysis, then attest its completion with a credential-free evidence URL."; return 0
  fi
  while [[ "$attempt" -lt 12 ]]; do
    wizard_api GET "/repos/$(printf '%s' "$a" | jq -r .repo)/actions/runs/$run_id" || return 2
    if [[ "$(printf '%s' "$API_JSON" | jq -r .status)" == completed ]]; then
      ACTION_DATA="$(jq -cn --arg run_id "$run_id" '{run_id:$run_id}')"
      if [[ "$(printf '%s' "$API_JSON" | jq -r .conclusion)" == success ]]; then
        ACTION_STATE=ready; ACTION_DETAIL="Setup-triggered analysis succeeded."
      else ACTION_STATE=failed; ACTION_DETAIL="Setup-triggered analysis failed."; fi
      return 0
    fi
    attempt=$((attempt+1)); [[ "$attempt" -ge 12 ]] || sleep 5
  done
  ACTION_STATE=unverified; ACTION_DETAIL="Setup-triggered analysis is running; resume without starting another run."
}

wizard_apply_report() {
  local a="$1" filename
  if [[ "$(printf '%s' "$a" | jq -r '.paginate//false')" == true ]]; then
    wizard_api_pages "$(printf '%s' "$a" | jq -r .read_path)" || return 2
  else wizard_api GET "$(printf '%s' "$a" | jq -r .read_path)" || return 2; fi
  filename="$(printf '%s' "$a" | jq -r .id | wizard_hash)"
  # Reports may contain customer data, but never save authentication or API headers.
  wizard_write_json "$WIZARD_RUN/report-$filename.json" "$API_JSON"
  ACTION_DATA="$(jq -cn --arg file "report-$filename.json" '{file:$file}')"
  ACTION_STATE=ready; ACTION_DETAIL="Report exported to the private run directory."
}

wizard_status() {
  local directory="$1" file="$1/ledger.json"
  [[ -f "$file" && ! -L "$file" ]] || { wizard_log "Missing run ledger."; return 2; }
  jq -r '.actions|to_entries[]|[.key,.value.status,.value.detail]|@tsv' "$file"
  if jq -e '.actions|to_entries|any(.value.status=="failed")' "$file" >/dev/null; then return 2; fi
  local planned recorded
  planned="$(jq '.actions|length' "$directory/plan.json")"; recorded="$(jq '.actions|length' "$file")"
  if [[ "$planned" != "$recorded" ]] || jq -e '.actions|to_entries|any(.value.status!="ready" and .value.status!="attested")' "$file" >/dev/null; then return 3; fi
}

wizard_attest() {
  local directory="$1" id="$2" evidence="$3" approval="$4" action data
  [[ ! -L "$directory" ]] || wizard_die "Refusing a symlink run directory."
  WIZARD_RUN="$(cd "$directory" && pwd)" || return 2
  wizard_plan_integrity "$WIZARD_RUN/plan.json" || return 2
  [[ "$approval" == "$(jq -r .digest "$WIZARD_RUN/plan.json")" ]] || wizard_die "Attestation requires the exact plan digest."
  [[ "$evidence" == https://* && "$evidence" != *$'\n'* && "$evidence" != *$'\r'* ]] || wizard_die "Provide a credential-free HTTPS evidence URL."
  [[ "$evidence" != *'@'* && "$evidence" != *'?'* ]] || wizard_die "Evidence URLs must not contain credentials or query strings."
  action="$(jq -c --arg id "$id" '.actions[]|select(.id==$id and (.kind=="manual" or .kind=="setup_run"))' "$WIZARD_RUN/plan.json")"
  [[ -n "$action" ]] || wizard_die "Only manual handoffs or unidentified setup runs can be attested."
  wizard_lock; wizard_run_auth || return 2
  if [[ "$(printf '%s' "$action" | jq -r .kind)" == setup_run ]]; then
    local source
    source="$(printf '%s' "$action" | jq -r .source_action)"
    [[ "$(wizard_ledger_state "$source")" == ready ]] &&
      [[ -z "$(wizard_ledger_data "$source" | jq -r '.setup_run_id//empty')" ]] ||
      wizard_die "Setup-run evidence requires verified configuration and no automatically tracked run."
  fi
  data="$(jq -cn --arg actor "$(jq -r .actor "$WIZARD_RUN/plan.json")" --arg evidence "$evidence" '{attested_by:$actor,evidence:$evidence}')"
  wizard_ledger_set "$id" attested "Operator supplied external completion evidence; not API-verified." "$data"
}
