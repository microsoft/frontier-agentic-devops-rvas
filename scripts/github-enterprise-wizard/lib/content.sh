wizard_template_snapshot() {
  local a="$1" path repo branch
  path="$(printf '%s' "$a" | jq -r .create.path)"
  repo="${path#/repos/}"; repo="${repo%/generate}"
  wizard_api GET "/repos/$repo" || return 2
  printf '%s' "$API_JSON" | jq -e '.is_template==true and (.default_branch|type)=="string"' >/dev/null ||
    { wizard_log "The selected source is not a visible repository template."; return 2; }
  branch="$(printf '%s' "$API_JSON" | jq -r .default_branch)"
  wizard_api GET "/repos/$repo/commits/$(jq -nr --arg branch "$branch" '$branch|@uri')" || return 2
  printf '%s' "$API_JSON" | jq -e '.sha|test("^[0-9a-fA-F]{40}$")' >/dev/null ||
    { wizard_log "Template commit is not verified."; return 2; }
  TEMPLATE_SNAPSHOT="$(jq -cn --arg repo "$repo" --arg branch "$branch" \
    --arg sha "$(printf '%s' "$API_JSON" | jq -r .sha)" '{repo:$repo,default_branch:$branch,sha:$sha}')"
}

wizard_files_snapshot() {
  local a="$1" repo branch file path snapshot='[]' sha encoded expected_id
  repo="$(printf '%s' "$a" | jq -r .repo)"
  wizard_api GET "/repos/$repo" || return 2
  FILES_REPOSITORY_ID="$(printf '%s' "$API_JSON" | jq -r '.id//empty')"
  expected_id="$(printf '%s' "$a" | jq -r '.file_repository_id//empty')"
  if [[ -z "$expected_id" && -n "${WIZARD_RUN:-}" && -f "$WIZARD_RUN/ledger.json" ]]; then
    expected_id="$(wizard_ledger_data "${repo%%/*}:workspace:repo:${repo#*/}" | jq -r '.resource_id//empty')"
  fi
  if [[ -n "$expected_id" && "$expected_id" != "$FILES_REPOSITORY_ID" ]]; then
    wizard_log "Repository identity changed; generate a new plan."; return 2
  fi
  FILES_DEFAULT_BRANCH="$(printf '%s' "$API_JSON" | jq -r .default_branch)"
  branch="$(printf '%s' "$a" | jq -r --arg fallback "$FILES_DEFAULT_BRANCH" '.ref//$fallback')"
  encoded="$(jq -nr --arg value "$branch" '$value|@uri')"
  while IFS= read -r file; do
    path="$(printf '%s' "$file" | jq -r .path)"
    if wizard_api GET "/repos/$repo/contents/$path?ref=$encoded"; then
      [[ "$(printf '%s' "$API_JSON" | jq -r .type)" == file ]] || { wizard_log "Expected a regular file: $path"; return 2; }
      sha="$(printf '%s' "$API_JSON" | jq -r .sha)"
    elif [[ "$API_STATUS" == 404 ]]; then sha=''
    else return 2; fi
    snapshot="$(jq -cn --argjson all "$snapshot" --arg path "$path" --arg sha "$sha" '$all+[{path:$path,sha:$sha}]')"
  done < <(printf '%s' "$a" | jq -c '.files[]')
  FILES_SNAPSHOT="$snapshot"; FILES_BRANCH="$branch"
}

wizard_pin_actions() {
  local a="$1" reference action_ref revision source sha host="$WIZARD_HOST" pins='[]'
  local content="$a" response
  while IFS= read -r reference; do
    action_ref="$(printf '%s' "$reference" | jq -r '.[0]')"
    revision="$(printf '%s' "$reference" | jq -r '.[1]')"
    [[ "$revision" =~ ^[0-9a-fA-F]{40}$ ]] && continue
    source="$(printf '%s' "$action_ref" | cut -d/ -f1,2)"
    # Standard actions originate on github.com, including for data-residency tenants.
    case "$source" in actions/*|github/*|docker/*) WIZARD_HOST=github.com ;; *) WIZARD_HOST="$host" ;; esac
    if ! wizard_api GET "/repos/$source/commits/$(jq -nr --arg ref "$revision" '$ref|@uri')"; then
      WIZARD_HOST="$host"; wizard_log "Cannot resolve action $action_ref@$revision; no unpinned workflow was approved."; return 2
    fi
    sha="$(printf '%s' "$API_JSON" | jq -r .sha)"
    WIZARD_HOST="$host"
    [[ "$sha" =~ ^[0-9a-fA-F]{40}$ ]] || { wizard_log "Invalid action commit SHA."; return 2; }
    content="$(jq -cn --argjson a "$content" --arg from "$action_ref@$revision" --arg to "$action_ref@$sha" \
      '$a | .files |= map(if .path|test("\\.ya?ml$") then .content |=
        (split("\n")|map(. as $line |
          [capture("^(?<prefix>[ \\t]*-?[ \\t]*uses:[ \\t]*[\\x27\"]?)(?<ref>[A-Za-z0-9_.-]+/[A-Za-z0-9_./-]+@[A-Za-z0-9_./-]+)(?<suffix>[\\x27\"]?[ \\t]*(?:#.*)?)$")] as $match |
          if ($match|length)>0 and $match[0].ref==$from then
            $match[0].prefix+$to+$match[0].suffix
          else $line end)|join("\n"))
        else . end)')"
    pins="$(jq -cn --argjson all "$pins" --arg source "$action_ref" --arg revision "$revision" --arg sha "$sha" '$all+[{action:$source,original_ref:$revision,sha:$sha}]')"
  done < <(printf '%s' "$a" | jq -c '[.files[]|select(.path|test("\\.ya?ml$"))|.content|scan("(?m)^[ \\t]*-?[ \\t]*uses:[ \\t]*[\\x27\"]?([A-Za-z0-9_.-]+/[A-Za-z0-9_./-]+)@([A-Za-z0-9_./-]+)[\\x27\"]?[ \\t]*(?:#[^\\r\\n]*)?$")]|unique[]')
  PINNED_CONTENT_ACTION="$(jq -cn --argjson a "$content" --argjson pins "$pins" '$a+{resolved_actions:$pins}')"
}

wizard_files_match() {
  local a="$1" file path expected actual
  wizard_files_snapshot "$a" || return 2
  while IFS= read -r file; do
    path="$(printf '%s' "$file" | jq -r .path)"
    expected="$(printf '%s' "$file" | jq -j .content | git hash-object --stdin)"
    actual="$(printf '%s' "$FILES_SNAPSHOT" | jq -r --arg path "$path" '.[]|select(.path==$path)|.sha')"
    [[ "$expected" == "$actual" ]] || return 1
  done < <(printf '%s' "$a" | jq -c '.files[]')
}

wizard_apply_files() {
  local a="$1" verify_only="$2" id repo adopted branch base encoded payload file blob tree entries='[]' commit result pr status
  id="$(printf '%s' "$a" | jq -r .id)"; repo="$(printf '%s' "$a" | jq -r .repo)"
  if wizard_files_match "$a"; then
    ACTION_STATE=ready; ACTION_DETAIL="Default-branch content verified."; return 0
  else status=$?; [[ "$status" == 1 ]] || return 2; fi
  if [[ "$verify_only" == true ]]; then ACTION_STATE=unverified; ACTION_DETAIL="Selected content is not on the default branch."; return 0; fi
  if printf '%s' "$ACTION_DATA" | jq -e '.pull_request != null' >/dev/null; then
    ACTION_STATE=pending; ACTION_DETAIL="Approved content pull request must be reviewed and merged."; return 0
  fi
  if printf '%s' "$a" | jq -e '.file_snapshot != null' >/dev/null; then
    if ! wizard_matches "$FILES_SNAPSHOT" "$(printf '%s' "$a" | jq -c .file_snapshot)"; then
      ACTION_STATE=failed; ACTION_DETAIL="Repository content changed after planning; create a new plan."; return 2
    fi
  fi
  adopted="$(printf '%s' "$a" | jq -r '.adopt//false')"
  if [[ "$adopted" != true ]] && ! wizard_ledger_data "${repo%%/*}:workspace:repo:${repo#*/}" | jq -e '.owned==true' >/dev/null; then
    ACTION_STATE=pending; ACTION_DETAIL="Repository content requires explicit adoption or creation by this run."; return 0
  fi
  encoded="$(jq -nr --arg value "$FILES_BRANCH" '$value|@uri')"
  local new_ref=false
  if ! wizard_api GET "/repos/$repo/git/ref/heads/$encoded"; then
    if [[ "$API_STATUS" == 404 && "$adopted" != true ]] && wizard_ledger_data "${repo%%/*}:workspace:repo:${repo#*/}" | jq -e '.owned==true' >/dev/null; then
      wizard_api GET "/repos/$repo/git/ref/heads/$(jq -nr --arg value "$FILES_DEFAULT_BRANCH" '$value|@uri')" || return 2
      new_ref=true
    else return 2; fi
  fi
  base="$(printf '%s' "$API_JSON" | jq -r .object.sha)"
  wizard_api GET "/repos/$repo/git/commits/$base" || return 2
  tree="$(printf '%s' "$API_JSON" | jq -r .tree.sha)"
  while IFS= read -r file; do
    payload="$(printf '%s' "$file" | jq -c '{content:.content,encoding:"utf-8"}')"
    wizard_api POST "/repos/$repo/git/blobs" "$payload" || return 2
    blob="$(printf '%s' "$API_JSON" | jq -r .sha)"
    entries="$(jq -cn --argjson all "$entries" --argjson file "$file" --arg blob "$blob" '$all+[{path:$file.path,mode:"100644",type:"blob",sha:$blob}]')"
  done < <(printf '%s' "$a" | jq -c '.files[]')
  payload="$(jq -cn --arg tree "$tree" --argjson entries "$entries" '{base_tree:$tree,tree:$entries}')"
  wizard_api POST "/repos/$repo/git/trees" "$payload" || return 2
  tree="$(printf '%s' "$API_JSON" | jq -r .sha)"
  payload="$(jq -cn --arg tree "$tree" --arg base "$base" --arg id "$id" '{message:("Configure "+$id),tree:$tree,parents:[$base]}')"
  wizard_api POST "/repos/$repo/git/commits" "$payload" || return 2
  commit="$(printf '%s' "$API_JSON" | jq -r .sha)"
  if [[ "$adopted" == true ]]; then
    branch="wizard/$(jq -r .digest "$WIZARD_RUN/plan.json" | cut -c1-12)/$(printf '%s' "$id" | wizard_hash | cut -c1-12)"
    if wizard_api GET "/repos/$repo/git/ref/heads/$branch"; then
      [[ "$(printf '%s' "$API_JSON" | jq -r .object.sha)" == "$commit" ]] || {
        ACTION_STATE=pending; ACTION_DETAIL="Wizard branch already exists; inspect it before retrying."; return 0;
      }
    elif [[ "$API_STATUS" == 404 ]]; then
      payload="$(jq -cn --arg ref "refs/heads/$branch" --arg sha "$commit" '{ref:$ref,sha:$sha}')"
      wizard_api POST "/repos/$repo/git/refs" "$payload" || return 2
    else return 2; fi
    payload="$(jq -cn --arg head "$branch" --arg base "$FILES_BRANCH" --arg id "$id" '{title:("Configure "+$id),head:$head,base:$base,body:"Review the approved wizard configuration. Merge only after required checks and an independent review."}')"
    wizard_api GET "/repos/$repo/pulls?state=open&head=$(jq -nr --arg h "${repo%%/*}:$branch" '$h|@uri')" || return 2
    pr="$(printf '%s' "$API_JSON" | jq -r '.[0].number//empty')"
    if [[ -z "$pr" ]]; then
      wizard_api POST "/repos/$repo/pulls" "$payload" || return 2
      pr="$(printf '%s' "$API_JSON" | jq -r .number)"
    fi
    ACTION_DATA="$(jq -cn --arg branch "$branch" --arg pr "$pr" '{branch:$branch,pull_request:$pr}')"
    # Persist before returning so an interruption cannot create another PR.
    wizard_ledger_set "$id" pending "Content PR awaits review." "$ACTION_DATA"
    ACTION_STATE=pending; ACTION_DETAIL="Content PR #$pr awaits review and merge."
  else
    # Non-forced update rejects concurrent commits on the default branch.
    payload="$(jq -cn --arg sha "$commit" '{sha:$sha,force:false}')"
    if [[ "$new_ref" == true ]]; then
      payload="$(jq -cn --arg ref "refs/heads/$FILES_BRANCH" --arg sha "$commit" '{ref:$ref,sha:$sha}')"
      wizard_api POST "/repos/$repo/git/refs" "$payload" || return 2
    else wizard_api PATCH "/repos/$repo/git/refs/heads/$encoded" "$payload" || return 2; fi
    if wizard_files_match "$a"; then ACTION_STATE=ready; ACTION_DETAIL="Initial content committed and verified."
    else ACTION_STATE=unverified; ACTION_DETAIL="Content write is not yet verified."; fi
  fi
}

wizard_apply_purchase() {
  local a="$1" verify_only="$2" previous="$3" id org users seats missing payload team body attempt=0
  id="$(printf '%s' "$a" | jq -r .id)"; org="$(printf '%s' "$a" | jq -r .org)"
  wizard_api GET "/orgs/$org/copilot/billing" || return 2
  if ! printf '%s' "$API_JSON" | jq -e '.seat_management_setting=="assign_selected" and (.public_code_suggestions|IN("allow","block"))' >/dev/null; then
    ACTION_STATE=pending; ACTION_DETAIL="Configure Copilot subscription, selected-seat management, and matching policy first."; return 0
  fi
  users="$(printf '%s' "$a" | jq -c '.users//.apply.body.selected_usernames//[]')"
  if printf '%s' "$a" | jq -e '(.teams//.apply.body.selected_teams//[])|length>0' >/dev/null; then
    # Team entitlement needs assigning-team read-back; do not infer it from overlapping user seats.
    wizard_api_pages "/orgs/$org/copilot/billing/seats" || return 2
    local requested assigned
    requested="$(printf '%s' "$a" | jq -c '.teams//.apply.body.selected_teams')"
    assigned="$(printf '%s' "$API_JSON" | jq -c '[.[].assigning_team.slug//empty]|unique')"
    if jq -en --argjson requested "$requested" --argjson assigned "$assigned" '$requested-$assigned|length==0' >/dev/null; then
      ACTION_STATE=ready; ACTION_DETAIL="Selected team seats verified."; return 0
    fi
    if [[ "$previous" == dispatching || "$previous" == unverified || "$verify_only" == true ]] || printf '%s' "$ACTION_DATA" | jq -e '.purchase_started==true' >/dev/null; then
      ACTION_STATE=unverified; ACTION_DETAIL="Team assignment is not yet verifiable; no repeat purchase attempted."; return 0
    fi
  else
    wizard_api_pages "/orgs/$org/copilot/billing/seats" || return 2
    seats="$(printf '%s' "$API_JSON" | jq -c '[.[]|select(.pending_cancellation_date==null)|.assignee.login]')"
    missing="$(jq -cn --argjson users "$users" --argjson seats "$seats" '$users-$seats')"
    if [[ "$(printf '%s' "$missing" | jq length)" == 0 ]]; then
      ACTION_STATE=ready; ACTION_DETAIL="Selected active seats verified."; return 0
    fi
    if [[ "$previous" == dispatching || "$previous" == unverified || "$verify_only" == true ]] || printf '%s' "$ACTION_DATA" | jq -e '.purchase_started==true' >/dev/null; then
      ACTION_STATE=unverified; ACTION_DETAIL="Seat purchase is not yet verifiable; no repeat purchase attempted."; return 0
    fi
  fi
  body="$(printf '%s' "$a" | jq -c '.apply.body')"
  ACTION_DATA='{"purchase_started":true}'
  wizard_ledger_set "$id" dispatching "Purchase started; reconcile seats before any retry." "$ACTION_DATA"
  if ! wizard_api POST "$(printf '%s' "$a" | jq -r .apply.path)" "$body"; then
    ACTION_STATE=unverified; ACTION_DETAIL="Purchase response uncertain; verify seats before retrying."; return 0
  fi
  ACTION_STATE=unverified; ACTION_DETAIL="Purchase accepted; awaiting seat read-back."
  wizard_apply_purchase "$a" true unverified
}

wizard_workflow_runs() {
  local repo="$1" workflow="$2" ref="$3" encoded
  encoded="$(jq -nr --arg value "$ref" '$value|@uri')"
  wizard_api GET "/repos/$repo/actions/workflows/$workflow/runs?event=workflow_dispatch&branch=$encoded&per_page=100"
}

wizard_apply_workflow() {
  local a="$1" verify_only="$2" previous="$3" repo workflow ref id head data baseline run_id attempts=0 maximum=12 candidates
  repo="$(printf '%s' "$a" | jq -r .repo)"; workflow="$(printf '%s' "$a" | jq -r .workflow)"
  ref="$(printf '%s' "$a" | jq -r '.ref//"main"')"; id="$(printf '%s' "$a" | jq -r .id)"
  run_id="$(printf '%s' "$ACTION_DATA" | jq -r '.run_id//empty')"
  if [[ -z "$run_id" ]]; then
    if [[ "$verify_only" == true ]] && ! printf '%s' "$ACTION_DATA" | jq -e '.baseline!=null' >/dev/null; then
      ACTION_STATE=pending; ACTION_DETAIL="Live check has not been dispatched."; return 0
    fi
    if ! printf '%s' "$ACTION_DATA" | jq -e '.baseline!=null' >/dev/null; then
      wizard_api GET "/repos/$repo/commits/$(jq -nr --arg v "$ref" '$v|@uri')" || return 2
      head="$(printf '%s' "$API_JSON" | jq -r .sha)"
      wizard_workflow_runs "$repo" "$workflow" "$ref" || return 2
      baseline="$(printf '%s' "$API_JSON" | jq -c '[.workflow_runs[].id]')"
      ACTION_DATA="$(jq -cn --arg head "$head" --argjson baseline "$baseline" '{head:$head,baseline:$baseline}')"
      wizard_ledger_set "$id" dispatching "Live check dispatch started; never dispatch again blindly." "$ACTION_DATA"
      data="$(jq -cn --arg ref "$ref" --argjson inputs "$(printf '%s' "$a" | jq -c '.inputs//{}')" '{ref:$ref,inputs:$inputs}')"
      if ! wizard_api POST "/repos/$repo/actions/workflows/$workflow/dispatches" "$data"; then
        ACTION_STATE=unverified; ACTION_DETAIL="Dispatch response uncertain; reconcile runs before retrying."; return 0
      fi
    fi
    while [[ "$attempts" -lt 3 ]]; do
      wizard_workflow_runs "$repo" "$workflow" "$ref" || return 2
      candidates="$(jq -cn --argjson data "$ACTION_DATA" --argjson response "$API_JSON" --arg actor "$(jq -r .actor "$WIZARD_RUN/plan.json")" \
        '$response.workflow_runs|map(select(.id as $id|($data.baseline|index($id)==null))|select(.head_sha==$data.head and .actor.login==$actor))')"
      if [[ "$(printf '%s' "$candidates" | jq length)" == 1 ]]; then
        run_id="$(printf '%s' "$candidates" | jq -r '.[0].id')"
        break
      elif [[ "$(printf '%s' "$candidates" | jq length)" -gt 1 ]]; then
        ACTION_STATE=unverified; ACTION_DETAIL="Multiple live runs match; inspect the run before resuming."; return 0
      fi
      attempts=$((attempts+1)); [[ "$attempts" -ge 3 ]] || sleep 2
    done
    [[ -n "$run_id" ]] || { ACTION_STATE=unverified; ACTION_DETAIL="Dispatched run is not yet identifiable."; return 0; }
    ACTION_DATA="$(jq -cn --argjson data "$ACTION_DATA" --arg run_id "$run_id" '$data+{run_id:$run_id}')"
    wizard_ledger_set "$id" unverified "Live check running." "$ACTION_DATA"
  fi
  attempts=0
  while [[ "$attempts" -lt "$maximum" ]]; do
    wizard_api GET "/repos/$repo/actions/runs/$run_id" || return 2
    if [[ "$(printf '%s' "$API_JSON" | jq -r .status)" == completed ]]; then
      if [[ "$(printf '%s' "$API_JSON" | jq -r .conclusion)" == success ]]; then
        ACTION_STATE=ready; ACTION_DETAIL="Live workflow run $run_id succeeded."
      else ACTION_STATE=failed; ACTION_DETAIL="Live workflow run $run_id did not succeed."; fi
      return 0
    fi
    attempts=$((attempts+1)); [[ "$attempts" -ge "$maximum" ]] || sleep 5
  done
  ACTION_STATE=unverified; ACTION_DETAIL="Live workflow still running; resume to check it without dispatching again."
}

wizard_compile_ghaw() {
  local a="$1" tmp file path name output='[]' compiled version rc=0 generated
  if ! GH_HOST="$WIZARD_HOST" gh aw --version >/dev/null 2>&1; then
    wizard_log "gh-aw is unavailable. Its package stays pending."; return 2
  fi
  version="$(GH_HOST="$WIZARD_HOST" gh aw --version 2>&1)"
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/github-wizard-ghaw.XXXXXX")"
  mkdir "$tmp/.github" "$tmp/.github/workflows"
  while IFS= read -r file; do
    path="$(printf '%s' "$file" | jq -r .path)"
    name="${path##*/}"
    if [[ "$path" != ".github/workflows/$name" || "$name" != *.md ]]; then rc=2; break; fi
    printf '%s' "$file" | jq -j .content >"$tmp/.github/workflows/$name"
    if ! (cd "$tmp" && GH_HOST="$WIZARD_HOST" gh aw compile "${name%.md}" >"$tmp/compiler.log" 2>&1); then rc=2; break; fi
    compiled="$tmp/.github/workflows/${name%.md}.lock.yml"
    if [[ ! -f "$compiled" || -L "$compiled" ]]; then rc=2; break; fi
    output="$(jq -cn --argjson all "$output" --argjson file "$file" --rawfile lock "$compiled" '$all+[$file,{path:($file.path|sub("\\.md$";".lock.yml")),content:$lock}]')"
  done < <(printf '%s' "$a" | jq -c '.files[]')
  # Remove only files in this freshly allocated compiler workspace.
  while IFS= read -r generated; do rm -f "$generated"; done < <(find "$tmp" -type f)
  while IFS= read -r generated; do rmdir "$generated" 2>/dev/null || true; done < <(find "$tmp" -depth -type d)
  [[ "$rc" == 0 ]] || { wizard_log "gh-aw compilation failed; resolve the installed release's prerequisites and re-plan."; return 2; }
  COMPILED_GHAW_ACTION="$(jq -cn --argjson a "$a" --argjson files "$output" --arg version "$version" '$a+{kind:"files",files:$files,compiler_version:$version}')"
}

wizard_apply_ghaw() {
  ACTION_STATE=pending; ACTION_DETAIL="Generate a new plan with compiled gh-aw locks before deployment."
}
