#!/usr/bin/env bash

WIZARD_CONFIG_LIB_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
WIZARD_CONFIG_ROOT=$(cd "$WIZARD_CONFIG_LIB_DIR/.." && pwd)
source "$WIZARD_CONFIG_LIB_DIR/interview.sh"
source "$WIZARD_CONFIG_LIB_DIR/navigation.sh"
source "$WIZARD_CONFIG_LIB_DIR/discovery.sh"

wizard_validate_config() {
  if [ "$#" -ne 1 ] || [ ! -f "$1" ]; then
    printf '%s\n' 'Config: supply an existing JSON file.' >&2
    return 1
  fi
  jq -e -s -f "$WIZARD_CONFIG_ROOT/validate.jq" -- "$1" >/dev/null
}

wizard_effective_config() {
  [ "$#" -eq 1 ] || { printf '%s\n' 'Config: supply one JSON file.' >&2; return 1; }
  wizard_validate_config "$1" || return 1
  jq '
    .defaults = ({packages:[],repository_visibility:"private",settings:{}} + (.defaults // {}))
    | .defaults as $defaults
    | .organizations |= map(
        .packages = (if has("packages") then .packages else $defaults.packages end)
        | .settings = ($defaults.settings + (.settings // {}))
        | .create = (.create // false) | .adopt = (.adopt // false)
        | .owners = (.owners // []) | .teams = (.teams // [])
        | .repositories = (.repositories // [])
        | .teams |= map(.members = (.members // []) | .repositories = (.repositories // []))
        | .repositories |= map(
            .visibility = (.visibility // $defaults.repository_visibility)
            | .stack = (.stack // "none") | .adopt = (.adopt // false)
            | .files = (.files // []) | .labels = (.labels // [])
            | .properties = (.properties // {}) | .environments = (.environments // [])
            | .workflows = (.workflows // []) | .copilot_users = (.copilot_users // [])))
  ' -- "$1"
}

wizard_csv_json() {
  jq -cn --arg value "$1" '$value | split(",") | map(gsub("^\\s+|\\s+$";"")) | map(select(length > 0)) | unique'
}

wizard_package_selected() {
  printf '%s' "$1" | jq -e --arg id "$2" 'index($id) != null' >/dev/null
}

wizard_customize_config() {
  local config=$1 org_count org_index=0 repo_count repo_index packages login name names count force build test_command
  local title profile adopt agent_path source_file
  org_count=$(printf '%s' "$config" | jq '.organizations | length') || return 1
  while [ "$org_index" -lt "$org_count" ]; do
    login=$(printf '%s' "$config" | jq -r --argjson i "$org_index" '.organizations[$i].login') || return 1
    packages=$(printf '%s' "$config" | jq -c --argjson i "$org_index" '.organizations[$i].packages') || return 1
    repo_count=$(printf '%s' "$config" | jq --argjson i "$org_index" '.organizations[$i].repositories | length') || return 1
    repo_index=0
    while [ "$repo_index" -lt "$repo_count" ]; do
      name=$(printf '%s' "$config" | jq -r --argjson i "$org_index" --argjson r "$repo_index" '.organizations[$i].repositories[$r].name') || return 1
      if wizard_package_selected "$packages" workspace; then
        wizard_prompt_bool "Configure labels for $login/$name?" true 'Use a small shared label set, or provide your own names.' || return 1
        if [ "$WIZARD_REPLY" = true ]; then
          wizard_prompt_list labels 'Label names (comma-separated; blank uses bug,docs,enhancement,question): ' '' \
            'Use distinct label names of at most 50 characters, without URL separators.' || return 1
          names=$(wizard_csv_json "${WIZARD_REPLY:-bug,docs,enhancement,question}") || return 1
          config=$(printf '%s' "$config" | jq --argjson i "$org_index" --argjson r "$repo_index" --argjson names "$names" '
            .organizations[$i].repositories[$r].labels = ($names | map(
              . as $name | {name:$name,color:({bug:"d73a4a",docs:"0075ca",enhancement:"a2eeef",question:"d876e3"}[$name] // "ededed")}))') || return 1
        fi
      fi
      if wizard_package_selected "$packages" actions; then
        wizard_prompt_bool "Configure pull-request review gates for $login/$name?" true 'Recommended for shared code. Existing repositories stay staged until a later enforcement plan is approved.' || return 1
        if [ "$WIZARD_REPLY" = true ]; then
          wizard_prompt_checked 'Required human approvals (0-6): ' 1 \
            'Enter an integer from 0 to 6. One independent reviewer is a useful starting point.' \
            '$answer|test("^[0-6]$")' || return 1; count=$WIZARD_REPLY
          wizard_prompt_bool 'Prevent force pushes?' true 'Protect the default branch from rewritten history.' || return 1; force=$WIZARD_REPLY
          printf '%s\n' 'The rule dismisses stale reviews and resolves review threads. Positive approval counts also require approval of the latest push.' >&2
          config=$(printf '%s' "$config" | jq --argjson i "$org_index" --argjson r "$repo_index" --argjson count "$count" --argjson force "$force" '
            .organizations[$i].repositories[$r].rulesets = [{
              name:"reviewed-default-branch",target:"branch",enforcement:"active",enforcement_approved:false,
              conditions:{ref_name:{include:["~DEFAULT_BRANCH"],exclude:[]}},
              rules:([{type:"pull_request",parameters:{
                required_approving_review_count:$count,dismiss_stale_reviews_on_push:true,
                require_code_owner_review:false,require_last_push_approval:($count > 0),required_review_thread_resolution:true
              }}] + (if $force then [{type:"non_fast_forward"}] else [] end))
            }]') || return 1
        fi
      fi
      if wizard_package_selected "$packages" copilot; then
        wizard_prompt_bool "Write repository Copilot instructions for $login/$name?" || return 1
        if [ "$WIZARD_REPLY" = true ]; then
          build=''; test_command=''
          case "$(printf '%s' "$config" | jq -r --argjson i "$org_index" --argjson r "$repo_index" '.organizations[$i].repositories[$r].stack')" in
            node) build='npm run build'; test_command='npm test' ;;
            python) build='python -m compileall starter.py'; test_command='python -m unittest test_starter.py' ;;
          esac
          wizard_prompt_required 'Actual build command: ' "$build" 'Use a command that works in this repository. It is recorded as instructions, not executed here.' || return 1; build=$WIZARD_REPLY
          wizard_prompt_required 'Actual test command: ' "$test_command" 'Use the command developers should run before opening a PR.' || return 1; test_command=$WIZARD_REPLY
          config=$(printf '%s' "$config" | jq --argjson i "$org_index" --argjson r "$repo_index" --arg build "$build" --arg test "$test_command" '
            .organizations[$i].repositories[$r].copilot =
              ((.organizations[$i].repositories[$r].copilot // {}) + {
                instructions:[{path:".github/copilot-instructions.md",content:
                  ("# Build and test\n\nBuild command:\n\n```sh\n"+$build+"\n```\n\nTest command:\n\n```sh\n"+$test+"\n```\n")
                }]
              })') || return 1
        fi
      fi
      repo_index=$((repo_index + 1))
    done
    if wizard_package_selected "$packages" copilot; then
      wizard_prompt_bool "Configure shared Copilot content in $login/.github-private?" || return 1
      if [ "$WIZARD_REPLY" = true ]; then
        if ! printf '%s' "$config" | jq -e --argjson i "$org_index" '.organizations[$i].repositories | any((.name|ascii_downcase) == ".github-private")' >/dev/null; then
          adopt=false
          if [[ "$(jq -r --argjson i "$org_index" '.organizations[$i].create' <<<"$config")" != true ]]; then
            wizard_prompt_bool 'Explicitly adopt an existing .github-private repository? Answer no to create a new one.' || return 1
            adopt=$WIZARD_REPLY
          fi
          config=$(printf '%s' "$config" | jq --argjson i "$org_index" --argjson adopt "$adopt" '
            .organizations[$i].repositories += [{name:".github-private",adopt:$adopt,visibility:"private",stack:"none",files:[],labels:[],properties:{},environments:[],workflows:[],copilot_users:[]}]') || return 1
        fi
        wizard_prompt_bool 'Write a private member profile?' || return 1
        if [ "$WIZARD_REPLY" = true ]; then
          wizard_prompt_required 'Actual organization title: ' || return 1; title=$WIZARD_REPLY
          wizard_prompt_required 'Member profile text (one line): ' || return 1; profile=$WIZARD_REPLY
          config=$(printf '%s' "$config" | jq --argjson i "$org_index" --arg title "$title" --arg profile "$profile" '
            (.organizations[$i].repositories[] | select((.name|ascii_downcase)==".github-private").files) +=
              [{path:"profile/README.md",content:("# "+$title+"\n\n"+$profile+"\n")}]') || return 1
        fi
        while :; do
          wizard_prompt_agent_source || return 1
          [ -n "$WIZARD_REPLY" ] || break
          source_file=$WIZARD_REPLY
          wizard_prompt_path 'Agent target path inside .github-private (for example agents/reviewer.agent.md): ' '' \
            'Use a relative path without traversal or .git. Each copied agent needs a different target path.' \
            "$(jq -c --argjson i "$org_index" '
              [.organizations[$i] | (.copilot | (.agents[]?,.instructions[]?) | .path),
                (.repositories[] | select((.name|ascii_downcase)==".github-private") | .files[]?.path)]' <<<"$config")" || return 1
          agent_path=$WIZARD_REPLY
          config=$(printf '%s' "$config" | jq --argjson i "$org_index" --arg path "$agent_path" --rawfile content "$source_file" '
            .organizations[$i].copilot.agents = ((.organizations[$i].copilot.agents // []) + [{path:$path,content:$content}])') || return 1
        done
      fi
    fi
    org_index=$((org_index + 1))
  done
  printf '%s\n' "$config"
}

wizard_review_error() {
  local directory="$WIZARD_INTERVIEW_DIR" error="$1"
  # Review controls must not become configuration answers.
  local WIZARD_INTERVIEW_DIR=''
  while :; do
    WIZARD_PAGE_NOTICE="Cannot save this configuration: $error"
    wizard_choose 'Resolve configuration error' edit \
      'Fix the reported error before saving. Returning from the editor keeps you here; it does not restart earlier sections.' \
      '[{"value":"edit","label":"Fix an answer","description":"Open the answer editor. Select the answer to change and press Enter."},{"value":"cancel","label":"Cancel interview without saving","description":"Exit now. No configuration or GitHub changes are saved."}]' || return 1
    if [[ "$WIZARD_REPLY" == cancel ]]; then
      printf 'Interview cancelled. No configuration was saved.\n' >&2
      return 1
    fi
    WIZARD_INTERVIEW_DIR="$directory"
    if wizard_edit_answers "$error"; then WIZARD_INTERVIEW_DIR=''
    else return 1; fi
  done
}

wizard_init() (
  local status
  if ! wizard_guided; then wizard_init_once "$@"; return $?; fi
  WIZARD_INTERVIEW_DIR="$(mktemp -d "${TMPDIR:-/tmp}/github-wizard-interview.XXXXXX")" || return 1
  chmod 700 "$WIZARD_INTERVIEW_DIR"
  wizard_nav_write '{"answers":[],"cursor":0,"replay_until":0,"back":false}'
  trap 'wizard_interview_cleanup' EXIT
  while :; do
    wizard_nav_write "$(jq '.cursor=0 | .back=false' "$WIZARD_INTERVIEW_DIR/navigation.json")"
    if wizard_init_once "$@"; then return 0; else status=$?; fi
    if ! jq -e '.back==true' "$WIZARD_INTERVIEW_DIR/navigation.json" >/dev/null; then return "$status"; fi
  done
)

wizard_init_once() (
  if [ "$#" -ne 1 ] || [ -z "$1" ]; then
    printf '%s\n' 'Init: supply an output file.' >&2
    return 1
  fi
  local output=$1 directory staging='' staging_owned=false config org teams repositories team repo packages
  local host actor enterprise identity defaults owners login create adopt billing
  local name team_name slug members grants permission stack visibility template users selected option choices feature owner workflow ref default_answer validation_error
  case "$output" in /*|./*|../*) ;; *) output="./$output" ;; esac
  directory=$(dirname "$output")
  if [ ! -d "$directory" ] || [ -e "$output" ] || [ -L "$output" ]; then
    printf '%s\n' 'Init: output directory must exist and output file must not exist.' >&2
    return 1
  fi
  umask 077
  WIZARD_ORIGINAL_TTY=''
  WIZARD_PAGED=false WIZARD_REPLAY_MUTED=false
  if wizard_keyboard; then
    WIZARD_ORIGINAL_TTY="$(stty -g)" || return 1
    WIZARD_PAGED=true
    exec 3>&2
    if wizard_replaying; then
      exec 2>"$WIZARD_INTERVIEW_DIR/replay-output"
      WIZARD_REPLAY_MUTED=true
    fi
  fi
  trap 'status=$?; if [[ "$WIZARD_REPLAY_MUTED" == true ]]; then wizard_replay_unmute; if [[ "$status" -ne 0 ]] && ! jq -e ".back==true" "$WIZARD_INTERVIEW_DIR/navigation.json" >/dev/null; then cat "$WIZARD_INTERVIEW_DIR/replay-output" >&2; fi; fi; wizard_discovery_stop; wizard_ui_restore; if [ "$staging_owned" = true ] && [ -n "$staging" ]; then rm -f "$staging"; fi' EXIT
  trap 'printf "\nInterview interrupted.\n" >&2; exit 130' INT
  trap 'exit 143' TERM
  wizard_section 'GitHub enterprise setup' 'Build a customer workspace. Read-only lookups suggest existing accounts and resources; no GitHub settings change.'
  if ! wizard_replaying && ! wizard_paged; then
    printf '%s\n' 'Choose what you need, review the summary, then save. Plan and apply are separate steps.' >&2
    if wizard_keyboard; then
      printf '%s\n' 'Up/Down: move. Space: toggle. Enter: continue. B: Back; E: edit earlier answers. Text fields: :back or :edit. Esc or Ctrl+C: stop.' >&2
    else printf '%s\n' 'Text mode: enter a listed value or number. Blank accepts a shown default.' >&2; fi
  fi
  wizard_section '1. Enterprise and account' 'An enterprise contains organizations. Each organization owns teams and repositories.'
  wizard_prompt_identifier host 'GitHub host: ' 'github.com' \
    'Use github.com unless your enterprise uses a customer.ghe.com data-residency domain.' || return 1; host=$WIZARD_REPLY
  wizard_suggest_account "$host" || return 1; actor=$WIZARD_REPLY
  wizard_suggest_value 'Existing enterprise slug' enterprises "$host" '' \
    "Copy the name after /enterprises/ in https://$host/enterprises/YOUR-ENTERPRISE. The enterprise must already exist." || return 1; enterprise=$WIZARD_REPLY
  wizard_choose 'Account identity' personal \
    'Managed users (EMU) are company-provisioned through an identity provider. Choose EMU only if your enterprise uses that model.' \
    '[{"value":"personal","label":"Personal accounts","description":"Members use their own GitHub accounts."},{"value":"emu","label":"Enterprise Managed Users (EMU)","description":"Company-managed accounts; IdP controls membership. No public repositories."}]' || return 1
  identity=$WIZARD_REPLY
  wizard_section '2. Capabilities' 'Workspace and Actions are recommended to start. Add other capabilities when you need them.'
  wizard_select_packages '["workspace","actions"]' || return 1; defaults=$WIZARD_REPLY
  choices='[{"value":"private","label":"Private (recommended)","description":"Only users and teams with access can see repositories."},{"value":"internal","label":"Internal","description":"Members of the enterprise can discover and read repositories."}]'
  if [ "$identity" != emu ]; then
    choices=$(printf '%s' "$choices" | jq '.+[{value:"public",label:"Public",description:"Visible to everyone. Do not use for confidential code."}]') || return 1
  fi
  wizard_choose 'Default repository visibility' private 'This is the default for new repositories. Individual repositories can override it.' "$choices" || return 1
  visibility=$WIZARD_REPLY
  config=$(jq -cn --arg host "$host" --arg actor "$actor" --arg slug "$enterprise" --arg identity "$identity" --argjson packages "$defaults" --arg visibility "$visibility" \
    '{schema_version:1,host:$host,actor:$actor,enterprise:{slug:$slug,identity:$identity},defaults:{packages:$packages,repository_visibility:$visibility,settings:{}},organizations:[]}') || return 1
  while :; do
    wizard_section '3. Organization and project' "Use an organization under $enterprise, or plan a new one."
    create=false
    if wizard_guided; then
      wizard_choose 'Organization setup' existing \
        "Find existing organizations at https://$host/enterprises/$enterprise/organizations. A new organization needs enterprise-owner access." \
        '[{"value":"existing","label":"Use an existing organization","description":"Review existing settings before proposing updates."},{"value":"create","label":"Create a new organization","description":"Choose an unused name. Creation happens only after plan approval."}]' || return 1
      [ "$WIZARD_REPLY" != create ] || create=true
    fi
    if wizard_guided && [[ "$create" == false ]]; then
      wizard_suggest_value 'Organization login' organizations "$host" "$enterprise" \
        "Choose an organization in $enterprise, or enter its name from https://$host/ORGANIZATION." \
        "$(jq -c '[.organizations[].login]' <<<"$config")" || return 1
    else
      wizard_prompt_identifier organization 'Organization login: ' '' \
        "Enter the organization name from https://$host/ORGANIZATION, for example contoso-engineering. This is not the enterprise slug." \
        "$(jq -c '[.organizations[].login]' <<<"$config")" || return 1
    fi
    login=$WIZARD_REPLY
    if ! wizard_guided; then
      wizard_prompt_bool 'Create this organization under the enterprise?' || return 1; create=$WIZARD_REPLY
    fi
    adopt=false
    if [ "$create" = false ]; then
      wizard_prompt_bool 'Allow the plan to propose updates to this existing organization?' false \
        'Yes explicitly adopts selected settings. No leaves organization updates blocked. You still review the exact plan before apply.' || return 1; adopt=$WIZARD_REPLY
    fi
    wizard_prompt_list users 'Organization owner logins (comma-separated): ' "$actor" \
      'List at least one actual GitHub username, without emails or duplicate logins. For EMU, owners must agree with your IdP setup.' true || return 1
    owners=$(wizard_csv_json "$WIZARD_REPLY") || return 1
    if [ "$owners" = "[]" ]; then
      printf '%s\n' 'Interview: enter at least one real organization owner.' >&2
      return 1
    fi
    billing=
    if [ "$create" = true ]; then
      wizard_prompt_checked 'Organization billing email: ' '' 'Enter a billing email such as admin@example.com.' \
        '$answer|test("^[^ @]+@[^ @]+\\.[^ @]+$")' || return 1; billing=$WIZARD_REPLY
    fi
    if wizard_guided; then
      wizard_choose 'Capabilities for this organization' inherit \
        'Reuse the enterprise choices, or customize the capability checklist for this organization.' \
        '[{"value":"inherit","label":"Use the selected capabilities","description":"Keep the choices from the earlier checklist."},{"value":"custom","label":"Choose a different set","description":"Open the checklist again for this organization."},{"value":"none","label":"No packages","description":"Only record the organization scope."}]' || return 1
      case "$WIZARD_REPLY" in
        inherit) WIZARD_REPLY='' ;;
        custom) wizard_select_packages "$defaults" || return 1; WIZARD_REPLY="$(jq -r 'join(",")' <<<"$WIZARD_REPLY")"; [[ -n "$WIZARD_REPLY" ]] || WIZARD_REPLY=none ;;
      esac
    else
      wizard_prompt_checked 'Organization package override (comma IDs; blank inherits defaults; none selects none): ' '' \
        'Use capability IDs, blank to inherit, or none to skip all packages.' \
        '$answer|ascii_downcase|.=="" or .=="none" or
          (split(",")|map(gsub("^\\s+|\\s+$";"")|select(length>0))|(. - $context|length)==0)' \
        "$(jq -c '[.packages[].id]' "$WIZARD_CONFIG_ROOT/catalog.json")" || return 1
      WIZARD_REPLY="$(jq -nr --arg value "$WIZARD_REPLY" '$value|ascii_downcase')"
    fi
    case "$WIZARD_REPLY" in
      '') packages=$defaults ;;
      none) packages='[]' ;;
      *) packages="$(wizard_package_closure "$(wizard_csv_json "$WIZARD_REPLY")")" || return 1 ;;
    esac
    org=$(jq -cn --arg login "$login" --argjson create "$create" --argjson adopt "$adopt" --argjson owners "$owners" --arg billing "$billing" --argjson packages "$packages" \
      '{login:$login,create:$create,adopt:$adopt,owners:$owners,packages:$packages,settings:{},teams:[],repositories:[]} + (if $billing == "" then {} else {billing_email:$billing} end)') || return 1
    teams='[]'
    while :; do
      if wizard_guided && ! wizard_package_selected "$packages" workspace; then break; fi
      default_answer=false; [ "$teams" != '[]' ] || default_answer=true
      wizard_prompt_bool 'Add a team?' "$default_answer" 'Teams let you grant access to a group instead of managing each repository collaborator.' || return 1; [ "$WIZARD_REPLY" = true ] || break
      wizard_prompt_checked 'Team name: ' Developers \
        'Use a distinct team name with letters, numbers and single spaces or hyphens, up to 100 characters.' \
        '$answer | length<=100 and test("^[A-Za-z0-9]+([ -][A-Za-z0-9]+)*$") and
          (. as $name|$context|map(ascii_downcase)|index($name|ascii_downcase|gsub(" ";"-"))==null)' \
        "$(jq -c '[.[].slug]' <<<"$teams")" || return 1; team_name=$WIZARD_REPLY
      slug="$(printf '%s' "$team_name" | tr '[:upper:] ' '[:lower:]-')"
      wizard_prompt_identifier slug 'Team slug: ' "$slug" 'The slug must match the lowercase team name with spaces replaced by hyphens.' \
        "$(jq -c '[.[].slug]' <<<"$teams")" || return 1; slug=$WIZARD_REPLY
      wizard_prompt_list users 'Member logins (comma-separated; blank none): ' '' \
        'Leave blank if your IdP manages membership. Otherwise use distinct GitHub usernames, not emails.' || return 1
      members=$(wizard_csv_json "$WIZARD_REPLY") || return 1
      grants='[]'
      while :; do
        default_answer=false; [ "$grants" != '[]' ] || default_answer=true
        wizard_prompt_bool 'Grant this team repository access?' "$default_answer" 'You can name a repository you will create below. Access is verified during apply.' || return 1; [ "$WIZARD_REPLY" = true ] || break
        wizard_prompt_identifier repo 'Repository name within this organization: ' service 'Use the repository name only, not an owner/name pair. Each repository needs one grant per team.' \
          "$(jq -c '[.[].name]' <<<"$grants")" || return 1; name=$WIZARD_REPLY
        wizard_choose 'Team repository permission' push 'Write is usually enough for developers. Reserve Admin for repository administrators.' \
          '[{"value":"pull","label":"Read","description":"Read and clone code."},{"value":"triage","label":"Triage","description":"Manage issues and pull requests without writing code."},{"value":"push","label":"Write (recommended)","description":"Push branches and contribute code."},{"value":"maintain","label":"Maintain","description":"Manage the repository without sensitive administrative access."},{"value":"admin","label":"Admin","description":"Full repository administration."}]' || return 1; permission=$WIZARD_REPLY
        grants=$(printf '%s' "$grants" | jq --arg name "$name" --arg permission "$permission" '. + [{name:$name,permission:$permission}]') || return 1
      done
      team=$(jq -cn --arg name "$team_name" --arg slug "$slug" --argjson members "$members" --argjson repositories "$grants" '{name:$name,slug:$slug,members:$members,repositories:$repositories}') || return 1
      teams=$(printf '%s' "$teams" | jq --argjson team "$team" '. + [$team]') || return 1
    done
    repositories='[]'
    while :; do
      if wizard_guided && ! wizard_package_selected "$packages" workspace; then break; fi
      default_answer=false; [ "$repositories" != '[]' ] || default_answer=true
      wizard_prompt_bool 'Add a repository?' "$default_answer" 'A starter repository gives the team code, tests and CI it can use immediately.' || return 1; [ "$WIZARD_REPLY" = true ] || break
      adopt=false
      if wizard_guided && [[ "$create" != true ]]; then
        wizard_prompt_bool 'Explicitly adopt an existing repository?' false 'Yes proposes content through review PRs. No plans a new repository and refuses to overwrite an existing one.' || return 1; adopt=$WIZARD_REPLY
      fi
      if wizard_guided && [[ "$adopt" == true ]]; then
        wizard_suggest_value 'Existing repository' repositories "$host" "$login" 'Choose a repository to adopt. Its content will be proposed through PRs.' \
          "$(jq -c '[.[].name]' <<<"$repositories")" || return 1
        name="$WIZARD_REPLY"
      else
        wizard_prompt_identifier repo 'Repository name: ' service 'Use a short project name, for example payments-api. An existing name requires adoption.' \
          "$(jq -c '[.[].name]' <<<"$repositories")" || return 1; name=$WIZARD_REPLY
      fi
      if ! wizard_guided; then
        wizard_prompt_bool 'Explicitly adopt an existing repository?' false 'Yes proposes content through review PRs. No plans a new repository and refuses to overwrite an existing one.' || return 1; adopt=$WIZARD_REPLY
        if [[ "$create" == true && "$adopt" == true ]]; then
          printf 'A new organization cannot contain an existing repository. Choose no adoption.\n' >&2; return 1
        fi
      fi
      if wizard_guided; then
        choices='[{"value":"inherit","label":"Use the shared default","description":"Keep the default selected earlier."},{"value":"private","label":"Private","description":"Only collaborators can access this repository."},{"value":"internal","label":"Internal","description":"Readable by members of the enterprise."}]'
        if [ "$identity" != emu ]; then choices="$(jq -c '.+[{value:"public",label:"Public",description:"Visible to everyone."}]' <<<"$choices")"; fi
        default_answer=inherit
        if [[ "$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]')" == .github-private ]]; then
          choices="$(jq -c 'map(select(.value=="private"))' <<<"$choices")"; default_answer=private
        fi
        wizard_choose 'Repository visibility' "$default_answer" \
          "The shared default is $(jq -r .defaults.repository_visibility <<<"$config"). .github-private uses private visibility. Review existing visibility changes in the plan." "$choices" || return 1
        visibility=$WIZARD_REPLY; [ "$visibility" != inherit ] || visibility=''
      else
        wizard_prompt_checked 'Repository visibility (blank inherits default): ' '' \
          'Use private, internal, or public; EMU cannot use public. .github-private requires private. Blank otherwise inherits the default.' \
          '$answer|ascii_downcase|.=="" or (. as $value|$context|index($value)!=null)' \
          "$(jq -cn --arg identity "$identity" --arg name "$name" '
            if ($name|ascii_downcase)==".github-private" then ["private"]
            elif $identity=="emu" then ["private","internal"] else ["private","internal","public"] end')" || return 1
        visibility="$(jq -nr --arg value "$WIZARD_REPLY" '$value|ascii_downcase')"
        if [[ "$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]')" == .github-private && -z "$visibility" ]]; then visibility=private; fi
      fi
      default_answer=none
      if wizard_guided && [ "$adopt" = false ] && wizard_package_selected "$packages" actions; then default_answer=node; fi
      wizard_choose 'Project starter' "$default_answer" 'Bundled starters need Workspace and Actions. For existing code, choose None unless you want a reviewed starter PR.' \
        '[{"value":"none","label":"None","description":"Keep existing code, or create a minimal repository."},{"value":"node","label":"Node.js","description":"Working JavaScript source, tests and ci.yml on main."},{"value":"python","label":"Python","description":"Working Python source, tests and ci.yml on main."},{"value":"template","label":"Customer repository template","description":"Copy a template you maintain; the source commit is recorded in the plan."}]' || return 1
      stack=$WIZARD_REPLY; template=''
      if [ "$stack" = node ] || [ "$stack" = python ]; then
        if ! wizard_package_selected "$packages" actions; then
          printf '%s\n' 'The bundled starter requires Actions. Actions is included in this organization configuration; review it in the summary.' >&2
          packages="$(wizard_package_closure "$(jq -c '.+["actions"]|unique' <<<"$packages")")" || return 1
        fi
      fi
      if wizard_guided; then
        if [ "$stack" = template ]; then
          stack=none; wizard_prompt_checked 'Customer template owner/name: ' '' \
            'Use owner/name for a GitHub template, for example contoso/service-template, not a URL.' \
            '$answer|test("^[A-Za-z0-9][A-Za-z0-9-]*/[A-Za-z0-9_.-]+$")' || return 1; template=$WIZARD_REPLY
        fi
      else
        [ "$stack" != template ] || stack=none
        wizard_prompt_checked 'Customer template owner/name (blank none): ' '' \
          'Leave blank or use owner/name, not a URL.' \
          '$answer|.=="" or test("^[A-Za-z0-9][A-Za-z0-9-]*/[A-Za-z0-9_.-]+$")' || return 1; template=$WIZARD_REPLY
      fi
      repo=$(jq -cn --arg name "$name" --argjson adopt "$adopt" --arg visibility "$visibility" --arg stack "$stack" --arg template "$template" \
        '{name:$name,adopt:$adopt,stack:$stack,files:[],labels:[],properties:{},environments:[],workflows:[],copilot_users:[]} + (if $visibility == "" then {} else {visibility:$visibility} end) + (if $template == "" then {} else {template:$template} end)') || return 1
      if wizard_package_selected "$packages" actions; then
        if [ "$stack" = node ] || [ "$stack" = python ]; then
          printf '%s\n' 'The starter includes a live ci.yml check on main during apply. Review Actions usage costs in the plan.' >&2
        fi
        while :; do
          wizard_prompt_bool 'Select a workflow for a live CI check during apply?' false 'Bundled starters already include their CI check. Use this for a different existing workflow with workflow_dispatch enabled.' || return 1; [ "$WIZARD_REPLY" = true ] || break
          wizard_prompt_checked 'Workflow file or ID: ' ci.yml \
            'Use a .yml/.yaml filename under .github/workflows/, or a positive numeric workflow ID.' \
            '$answer|test("^[1-9][0-9]*$") or
              (test("\\.ya?ml$") and (test("[/?#%\\\\]")|not) and (contains("..")|not))' || return 1; workflow=$WIZARD_REPLY
          wizard_prompt_ref 'Workflow branch or tag: ' main || return 1; ref=$WIZARD_REPLY
          repo=$(printf '%s' "$repo" | jq --arg workflow "$workflow" --arg ref "$ref" '.workflows += [{workflow:$workflow,ref:$ref,inputs:{}}]') || return 1
        done
      fi
      repositories=$(printf '%s' "$repositories" | jq --argjson repo "$repo" '. + [$repo]') || return 1
    done
    org=$(printf '%s' "$org" | jq --argjson teams "$teams" --argjson repositories "$repositories" --argjson packages "$packages" '.teams=$teams | .repositories=$repositories | .packages=$packages') || return 1
    wizard_section '4. Capability settings' 'Choose which features to enable. Review the planned changes before apply.'
    if wizard_package_selected "$packages" actions; then
      choices='[{"value":"selected","label":"GitHub-owned and explicitly allowed actions (recommended)","description":"Use GitHub-owned actions and add approved third-party patterns."},{"value":"local_only","label":"Organization actions only","description":"Blocks standard actions such as actions/checkout, including bundled CI."},{"value":"all","label":"All actions","description":"Allows third-party actions without an allowlist."}]'
      if jq -e 'any(.repositories[]; .stack=="node" or .stack=="python") or (.packages|index("ghaw")!=null)' <<<"$org" >/dev/null; then
        choices="$(jq -c 'map(select(.value!="local_only"))' <<<"$choices")" || return 1
      fi
      wizard_choose 'Allowed GitHub Actions' selected \
        'An allowlist limits which actions can run. Bundled CI and gh-aw need GitHub-owned actions, so organization-only is unavailable for those choices.' \
        "$choices" || return 1; option=$WIZARD_REPLY
      choices='[]'
      if [ "$option" = selected ]; then
        if wizard_guided; then
          wizard_prompt 'Additional approved action patterns (comma-separated; blank none): ' '' \
            'GitHub-owned actions are included. Add only approved sources, for example trusted-vendor/action@*.' || return 1
        else wizard_prompt_required 'Allowed action patterns (comma-separated): ' || return 1; fi
        choices=$(wizard_csv_json "$WIZARD_REPLY") || return 1
      fi
      wizard_choose 'Default workflow token permission' read 'Use read-only by default. A workflow can request the specific write permissions it needs.' \
        '[{"value":"read","label":"Read (recommended)","description":"Least-privilege default for GITHUB_TOKEN."},{"value":"write","label":"Write","description":"Broad write defaults; use only when required and reviewed."}]' || return 1; selected=$WIZARD_REPLY
      default_answer=false; wizard_guided && default_answer=true
      org=$(printf '%s' "$org" | jq --arg policy "$option" --arg permission "$selected" --argjson choices "$choices" --argjson github "$default_answer" '.actions={permissions:{allowed_actions:$policy},workflow_permissions:{default_workflow_permissions:$permission}} | if $policy == "selected" then .actions.selected_actions={github_owned_allowed:$github,verified_allowed:false,patterns_allowed:$choices} else . end') || return 1
      if wizard_guided; then
        wizard_prompt_bool 'Require full commit-SHA pins for actions?' "$create" \
          'Generated workflows are pinned during planning. For existing organizations, enable enforcement only after updating existing workflows.' || return 1
        org=$(printf '%s' "$org" | jq --argjson required "$WIZARD_REPLY" '.actions.permissions.sha_pinning_required=$required') || return 1
      fi
    fi
    if wizard_package_selected "$packages" copilot; then
      wizard_section 'Copilot' 'An enabled subscription is required for seat assignments. Feature and model policies may need an owner in GitHub settings.'
      wizard_prompt_list users 'Copilot seat user logins (comma-separated; blank none): ' '' \
        'Use distinct GitHub usernames, or leave blank and select teams below.' || return 1
      users=$(wizard_csv_json "$WIZARD_REPLY") || return 1
      wizard_prompt_list slugs 'Copilot seat team slugs (comma-separated; blank none): ' '' \
        'Use distinct team slugs, not @organization/team references.' || return 1
      choices=$(wizard_csv_json "$WIZARD_REPLY") || return 1
      selected=false
      if [[ "$users" == '[]' && "$choices" == '[]' ]] && wizard_guided; then
        WIZARD_PAGE_NOTICE='No Copilot users or teams selected. Seat purchase is skipped; Copilot instructions remain available.'
        printf '%s\n' "$WIZARD_PAGE_NOTICE" >&2
      else
        wizard_prompt_bool 'Enable Copilot seats for the selected users and teams?' false \
          'Assign seats only to the users and teams listed above. Changes run after plan approval.' || return 1
        selected="$WIZARD_REPLY"
        if [[ "$selected" == true && "$users" == '[]' && "$choices" == '[]' ]]; then
          printf 'Copilot seat purchase needs at least one user login or team slug. Choose no purchase or provide recipients.\n' >&2
          return 1
        fi
      fi
      org=$(printf '%s' "$org" | jq --argjson users "$users" --argjson teams "$choices" --argjson purchase "$selected" '.copilot={users:$users,teams:$teams,purchase:$purchase}') || return 1
    fi
    if wizard_package_selected "$packages" identity; then
      wizard_section 'Identity and access' 'SAML, SCIM and IdP changes remain owner handoffs. Membership changes must follow your identity model.'
      wizard_prompt_bool 'Require organization 2FA? Review disruption and recovery in the plan.' false \
        'This creates an owner handoff. For EMU, authentication policy belongs in the IdP. Check recovery access before enforcing 2FA.' || return 1
      org=$(printf '%s' "$org" | jq --argjson required "$WIZARD_REPLY" '.identity={require_two_factor:$required}') || return 1
    fi
    if wizard_package_selected "$packages" security; then
      wizard_section 'Code Security and Secret Protection' 'Private repositories may require product licenses. The plan checks supported settings; selecting this package does not activate a subscription.'
      wizard_choose 'CodeQL setup' default 'Default setup is the simplest choice for supported languages. Advanced setup needs reviewed workflow and build configuration.' \
        '[{"value":"none","label":"Keep current setup","description":"Do not request a different CodeQL deployment."},{"value":"default","label":"Default setup (recommended)","description":"GitHub manages the analysis workflow for supported languages."},{"value":"advanced","label":"Advanced setup","description":"Manage a codeql.yml workflow and language/build configuration."}]' || return 1; option=$WIZARD_REPLY
      wizard_prompt_bool 'Enable Secret Protection and push protection?' false \
        'Scan for secrets and block supported secret types before they are pushed.' || return 1; selected=$WIZARD_REPLY
      org=$(printf '%s' "$org" | jq --arg codeql "$option" --argjson scanning "$selected" \
        '.security={codeql:$codeql,purchase:($codeql!="none" or $scanning)} | if $scanning then .security += {secret_scanning:true,push_protection:true} else . end') || return 1
    fi
    if wizard_package_selected "$packages" quality; then
      wizard_section 'Code Quality' 'Code Quality is a separate product from CodeQL. Setup and a completed analysis are required before enforcing its gates.'
      wizard_prompt_bool 'Enable Code Quality?' false \
        'Configure Code Quality and verify its analysis during apply. Review gates stay staged.' || return 1; selected=$WIZARD_REPLY
      org=$(printf '%s' "$org" | jq --argjson enabled "$selected" \
        '.quality={enabled:$enabled,live_analysis:$enabled,purchase:$enabled,enforce:false}') || return 1
    fi
    if wizard_package_selected "$packages" ghaw; then
      wizard_section 'Agentic workflows' 'An installed gh-aw compiler and engine credentials are required. Pilots are manual; schedules stay disabled.'
      wizard_select_pilots || return 1; choices=$WIZARD_REPLY
      wizard_choose 'Inference engine' copilot 'Engine authentication is separate from GitHub write authorization. The wizard does not create or save credentials.' \
        '[{"value":"copilot","label":"Copilot","description":"Use the installed release'\''s supported Copilot authentication."},{"value":"claude","label":"Claude","description":"Needs customer-managed Anthropic credentials."},{"value":"codex","label":"Codex","description":"Needs customer-managed OpenAI credentials."}]' || return 1; option=$WIZARD_REPLY
      wizard_prompt_bool 'Select live pilot runs during apply?' || return 1
      org=$(printf '%s' "$org" | jq --argjson pilots "$choices" --arg engine "$option" --argjson run "$WIZARD_REPLY" '.ghaw={pilots:$pilots,engine:$engine,run:$run,schedule_approved:false,output_limit:3}') || return 1
    fi
    for feature in migration integrations billing audit lifecycle drift publishing release license innersource vendors lfs sre; do
      if wizard_package_selected "$packages" "$feature"; then
        wizard_section "$feature" 'The adapter records supported GitHub operations and names external or owner-only prerequisites. Inventory reports do not complete a rollout.'
        wizard_prompt_identifier user "Owner login for $feature setup or external handoffs: " "$actor" \
          'Use the GitHub username of the person who will complete outstanding owner steps.' || return 1; owner=$WIZARD_REPLY
        org=$(printf '%s' "$org" | jq --arg feature "$feature" --arg owner "$owner" '.[$feature]={owner:$owner}') || return 1
        case "$feature" in
          migration)
            wizard_prompt_required 'Migration source system or inventory scope: ' || return 1
            org=$(printf '%s' "$org" | jq --arg source "$WIZARD_REPLY" '.migration += {inventory:true,source:$source}') || return 1 ;;
          integrations)
            wizard_prompt_list slugs 'Existing App slugs to connect (comma-separated; blank none): ' '' \
              'Use distinct existing App slugs, without URLs or spaces.' || return 1
            choices=$(wizard_csv_json "$WIZARD_REPLY") || return 1
            org=$(printf '%s' "$org" | jq --argjson apps "$choices" '.integrations += {apps:$apps,webhooks:[]}') || return 1 ;;
          billing)
            wizard_prompt_bool 'Select usage reports?' || return 1; selected=$WIZARD_REPLY
            wizard_prompt_bool 'Select budget configuration handoff? Budgets are not universal spending caps.' || return 1
            org=$(printf '%s' "$org" | jq --argjson usage "$selected" --argjson budgets "$WIZARD_REPLY" '.billing += {usage:$usage,budgets:$budgets}') || return 1 ;;
          audit)
            wizard_prompt_bool 'Select audit export?' || return 1; selected=$WIZARD_REPLY
            wizard_prompt_bool 'Select audit streaming handoff?' || return 1
            org=$(printf '%s' "$org" | jq --argjson export "$selected" --argjson streaming "$WIZARD_REPLY" '.audit += {export:$export,streaming:$streaming}') || return 1 ;;
          lifecycle|drift)
            org=$(printf '%s' "$org" | jq --arg feature "$feature" '.[$feature].inventory=true') || return 1 ;;
          publishing)
            wizard_prompt_bool 'Select Pages publishing?' || return 1; selected=$WIZARD_REPLY
            wizard_prompt_bool 'Select Packages or GHCR publishing?' || return 1
            org=$(printf '%s' "$org" | jq --argjson pages "$selected" --argjson packages "$WIZARD_REPLY" '.publishing += {pages:$pages,packages:$packages}') || return 1 ;;
          vendors)
            org=$(printf '%s' "$org" | jq '.vendors.review=true') || return 1 ;;
          sre)
            org=$(printf '%s' "$org" | jq '.sre.handoff=true') || return 1 ;;
          lfs)
            wizard_prompt_required 'LFS file patterns (comma-separated; for example *.psd): ' || return 1
            choices=$(wizard_csv_json "$WIZARD_REPLY") || return 1
            org=$(printf '%s' "$org" | jq --argjson patterns "$choices" '.lfs.patterns=$patterns') || return 1 ;;
          license)
            wizard_prompt 'Denied SPDX license IDs (comma-separated; blank none): ' || return 1
            choices=$(wizard_csv_json "$WIZARD_REPLY") || return 1
            org=$(printf '%s' "$org" | jq --argjson licenses "$choices" '.license.deny_licenses=$licenses') || return 1 ;;
        esac
      fi
    done
    config=$(printf '%s' "$config" | jq --argjson org "$org" '.organizations += [$org]') || return 1
    wizard_prompt_bool 'Add another organization?' || return 1; [ "$WIZARD_REPLY" = true ] || break
  done
  wizard_section '5. Project conventions and review' 'Choose labels and review gates, then inspect the complete configuration before saving.'
  if printf '%s' "$config" | jq -e 'any(.organizations[]; any(.packages[]; . == "workspace" or . == "actions" or . == "copilot"))' >/dev/null; then
    if wizard_guided; then
      wizard_prompt_bool 'Configure labels, review gates or shared Copilot content?' true \
        'Recommended for a usable project. Existing repository content goes through PRs; adopted rules stay staged until separately approved.' || return 1
      if [ "$WIZARD_REPLY" = true ]; then WIZARD_REPLY=yes; else WIZARD_REPLY=no; fi
    else
      wizard_prompt_checked 'Configure labels, review gates or shared Copilot content? [yes/no; blank skips]: ' '' \
        'Answer yes or no, or leave blank to skip customization.' \
        '$answer|ascii_downcase|. as $value|["","yes","y","true","no","n","false"]|index($value)!=null' || return 1
      WIZARD_REPLY="$(jq -nr --arg value "$WIZARD_REPLY" '$value|ascii_downcase')"
    fi
    case "$WIZARD_REPLY" in
      yes|y|true) config=$(wizard_customize_config "$config") || return 1 ;;
      ''|no|n|false) ;;
      *) printf '%s\n' 'Answer yes or no, or leave blank to skip customization.' >&2; return 1 ;;
    esac
  fi
  wizard_section '6. Review and save' 'Check the summary. Save writes configuration only; plan and apply are separate.'
  if ! validation_error="$(printf '%s' "$config" | jq -e -s -f "$WIZARD_CONFIG_ROOT/validate.jq" 2>&1)"; then
    printf 'Cannot save this configuration: %s\n' "$validation_error" >&2
    if wizard_guided; then wizard_review_error "$validation_error"; fi
    return 1
  fi
  wizard_config_summary "$config"
  wizard_prompt_bool 'Save this configuration? This does not approve apply.' true || return 1
  [ "$WIZARD_REPLY" = true ] || { printf '%s\n' 'Configuration was not saved.' >&2; return 1; }
  staging="$directory/.wizard-config.$$.${RANDOM}.json"
  (set -o noclobber; printf '%s\n' "$config" > "$staging") || return 1
  staging_owned=true
  wizard_validate_config "$staging" || return 1
  # A hard link publishes the complete file without replacing an existing path.
  ln "$staging" "$output" || return 1
  rm -f "$staging"
  staging=
  printf 'Saved configuration: %s\n' "$output" >&2
  printf '\nNext: check your identity and enterprise access, then generate a read-only plan.\n' >&2
  printf '  bash %q doctor --config %q\n' "$WIZARD_CONFIG_ROOT/../github-enterprise-wizard.sh" "$output" >&2
  printf '  bash %q plan --config %q --output %q\n' "$WIZARD_CONFIG_ROOT/../github-enterprise-wizard.sh" "$output" "${output%.json}.plan.json" >&2
  printf 'Review that plan before apply. No resources or purchases have been approved yet.\n' >&2
)
