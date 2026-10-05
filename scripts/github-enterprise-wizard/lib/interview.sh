#!/usr/bin/env bash

wizard_guided() { [[ -t 0 ]]; }
wizard_keyboard() {
  wizard_guided && [[ "${TERM:-dumb}" != dumb && "${WIZARD_PLAIN:-false}" != true ]] &&
    { [[ -t 2 ]] || [[ "${WIZARD_REPLAY_MUTED:-false}" == true && -t 3 ]]; }
}
wizard_paged() { [[ "${WIZARD_PAGED:-false}" == true ]]; }

wizard_replay_unmute() {
  if [[ "${WIZARD_REPLAY_MUTED:-false}" == true ]]; then
    exec 2>&3
    WIZARD_REPLAY_MUTED=false
  fi
}

wizard_page() {
  wizard_paged || return 0
  local question='' section="${WIZARD_PAGE_SECTION:-1}" progress='' index
  printf '\033[2J\033[H' >&2
  wizard_style '1;36'; printf 'GitHub enterprise setup\n' >&2; wizard_style 0
  wizard_style 36
  printf 'Section %s/6: %s\n' "$section" "${WIZARD_PAGE_TITLE:-Enterprise and account}" >&2
  wizard_style 0
  for ((index=1; index<=6; index++)); do
    if [[ "$index" -lt "$section" ]]; then progress="${progress}="
    elif [[ "$index" == "$section" ]]; then progress="${progress}>"
    else progress="${progress}."; fi
  done
  if [[ -n "${WIZARD_INTERVIEW_DIR:-}" ]]; then
    question="$(jq -r '.cursor+1' "$WIZARD_INTERVIEW_DIR/navigation.json")" || return 1
    wizard_style 32; printf '[%s]' "$progress" >&2; wizard_style 0
    wizard_style '1;36'; printf ' Question %s\n' "$question" >&2; wizard_style 0
  fi
  wizard_style 33; printf 'Estimate: 5-10 min for one starter.\n' >&2; wizard_style 0
  wizard_style 36; printf 'More packages or organizations take longer.\n\n' >&2; wizard_style 0
  [[ -z "${WIZARD_PAGE_CONTEXT:-}" ]] || printf '%s\n' "$WIZARD_PAGE_CONTEXT" >&2
  [[ -z "${WIZARD_PAGE_DESCRIPTION:-}" ]] || printf '%s\n\n' "$WIZARD_PAGE_DESCRIPTION" >&2
  if [[ -n "${WIZARD_PAGE_NOTICE:-}" ]]; then
    printf '%s\n\n' "$WIZARD_PAGE_NOTICE" >&2
    WIZARD_PAGE_NOTICE=''
  fi
  if [[ "$1" == 'Save this configuration?'* && -n "${WIZARD_REVIEW_CONFIG:-}" ]]; then
    wizard_print_config_summary "$WIZARD_REVIEW_CONFIG"
  fi
}

wizard_read_text() {
  local bindings='' binding status enabled_editing=false
  if wizard_paged; then
    if [[ ! -o emacs && ! -o vi ]]; then
      set -o emacs
      enabled_editing=true
    fi
    bindings="$( { bind -p; bind -s; } 2>/dev/null | while IFS= read -r binding; do
      if [[ "$binding" == '"\e[C":'* || "$binding" == '"\eOC":'* ]]; then printf '%s\n' "$binding"; fi
    done)"
    if ! bind '"\e[C": "\C-m"' '"\eOC": "\C-m"'; then
      printf 'Right Arrow is unavailable. Use Enter to continue.\n' >&2
    fi
  fi
  if wizard_paged; then
    if IFS= read -e -r WIZARD_REPLY; then status=0; else status=$?; fi
  else
    if IFS= read -r WIZARD_REPLY; then status=0; else status=$?; fi
  fi
  if wizard_paged; then
    bind -r '\e[C'
    bind -r '\eOC'
    while IFS= read -r binding; do
      [[ -z "$binding" ]] || bind "$binding"
    done <<<"$bindings"
    if [[ "$enabled_editing" == true ]]; then set +o emacs; fi
  fi
  return "$status"
}

wizard_style() {
  if [[ -t 2 && "${TERM:-dumb}" != dumb && "${NO_COLOR+x}" != x && "${WIZARD_PLAIN:-false}" != true ]]; then printf '\033[%sm' "$1" >&2; fi
}

wizard_replaying() {
  [[ -n "${WIZARD_INTERVIEW_DIR:-}" ]] &&
    jq -e '.cursor<.replay_until' "$WIZARD_INTERVIEW_DIR/navigation.json" >/dev/null
}

wizard_ui_restore() {
  if [[ -n "${WIZARD_ORIGINAL_TTY:-}" ]]; then
    stty "$WIZARD_ORIGINAL_TTY"
    if wizard_keyboard; then
      printf '\033[?25h' >&2
      wizard_style 0
    fi
  fi
}

wizard_section() {
  if [[ "$1" =~ ^([1-6])\.\ (.*)$ ]]; then
    WIZARD_PAGE_SECTION="${BASH_REMATCH[1]}" WIZARD_PAGE_TITLE="${BASH_REMATCH[2]}"
    WIZARD_PAGE_CONTEXT=''
  else WIZARD_PAGE_CONTEXT="$1"; fi
  WIZARD_PAGE_DESCRIPTION="$2"
  if wizard_paged; then return 0; fi
  if wizard_replaying; then return 0; fi
  printf '\n' >&2; wizard_style '1;36'; printf '%s' "$1" >&2; wizard_style 0
  printf '\n%s\n' "$2" >&2
}

wizard_prompt() {
  local default="${2:-}" help="${3:-}"
  wizard_nav_begin text "$1" || return 1
  [[ "$WIZARD_REPLAY" != true ]] || return 0
  [[ "$WIZARD_HAS_PREVIOUS" != true ]] || default="$WIZARD_PREVIOUS"
  while :; do
    wizard_page "$1" || return 1
    if wizard_paged; then
      printf 'Enter or Right Arrow: continue.\n' >&2
      printf 'Type a command, then press Enter:\n' >&2
      printf '  :back = previous question | :edit = edit answers\n' >&2
      printf '  :clear = empty an optional field\n' >&2
      [[ "$WIZARD_HAS_PREVIOUS" != true ]] || printf 'Saved answer shown below. Blank keeps it.\n' >&2
      printf '\n================\n\n' >&2
    fi
    [[ -z "$help" ]] || printf '%s\n' "$help" >&2
    wizard_style '1;36'
    printf '%s' "$1" >&2
    if wizard_guided && [[ -n "$default" ]]; then printf '[%s] ' "$default" >&2; fi
    wizard_style 0
    if wizard_guided; then
      if ! wizard_read_text; then
        printf '\nInterview stopped: input ended before completion.\n' >&2; return 1
      fi
      if [[ "$WIZARD_REPLY" == :back ]]; then
        if wizard_nav_back; then continue; else return 1; fi
      fi
      if [[ "$WIZARD_REPLY" == :edit ]]; then
        if wizard_edit_answers; then continue; else return 1; fi
      fi
      if [[ "$WIZARD_REPLY" == :clear ]]; then WIZARD_REPLY=''
      else [[ -n "$WIZARD_REPLY" ]] || WIZARD_REPLY="$default"; fi
    elif ! IFS= read -r WIZARD_REPLY; then
      printf '\nInterview stopped: input ended before completion.\n' >&2; return 1
    fi
    if ! jq -en --arg answer "$WIZARD_REPLY" '
      $answer | (test("[\u0000-\u001f\u007f]") or
        test("github_pat_[A-Za-z0-9_]{20,}|gh[pousr]_[A-Za-z0-9]{20,}")) | not' >/dev/null; then
      WIZARD_PAGE_NOTICE='Enter one line without control characters or credentials. Keep tokens in gh authentication.'
      printf '%s\n' "$WIZARD_PAGE_NOTICE" >&2
      continue
    fi
    if [[ "${WIZARD_DEFER_ANSWER:-false}" != true ]]; then wizard_nav_finish "$WIZARD_REPLY" || return 1; fi
    return 0
  done
}

wizard_prompt_required() {
  local parent_deferred="${WIZARD_DEFER_ANSWER:-false}" WIZARD_DEFER_ANSWER=true
  while :; do
    wizard_prompt "$1" "${2:-}" "${3:-}" || return 1
    if jq -en --arg answer "$WIZARD_REPLY" '$answer|test("\\S")' >/dev/null; then
      if [[ "$parent_deferred" != true ]]; then wizard_nav_finish "$WIZARD_REPLY" || return 1; fi
      return 0
    fi
    wizard_nav_retry
    WIZARD_PAGE_NOTICE="This field is required. ${3:-Enter the actual value for your organization.}"
    printf 'This field is required. %s\n' "${3:-Enter the actual value for your organization.}" >&2
  done
}

wizard_prompt_checked() {
  local title="$1" default="$2" help="$3" predicate="$4" context="${5:-null}" status
  local parent_deferred="${WIZARD_DEFER_ANSWER:-false}"
  local WIZARD_DEFER_ANSWER=true
  while :; do
    wizard_prompt "$title" "$default" "$help" || return 1
    WIZARD_REPLY="$(jq -nr --arg answer "$WIZARD_REPLY" '$answer|gsub("^\\s+|\\s+$";"")')" || return 1
    if jq -en --arg answer "$WIZARD_REPLY" --argjson context "$context" "$predicate" >/dev/null; then
      if [[ "$parent_deferred" != true ]]; then wizard_nav_finish "$WIZARD_REPLY" || return 1; fi
      return 0
    else status=$?; fi
    if [[ "$status" -ne 1 ]]; then printf 'Cannot validate %s\n' "$title" >&2; return 1; fi
    wizard_nav_retry
    WIZARD_PAGE_NOTICE="Invalid value. $help"
    printf '%s\n' "$WIZARD_PAGE_NOTICE" >&2
  done
}

wizard_prompt_path() {
  wizard_prompt_checked "$1" "${2:-}" "$3" \
    '$answer | length>0 and (startswith("/")|not) and
      (test("(^|/)(\\.\\.|\\.git)(/|$)|\\\\|^[A-Za-z]:|[?#%]")|not) and
      (contains("..")|not) and
      (. as $path | $context|map(ascii_downcase)|index($path|ascii_downcase)==null)' "${4:-[]}"
}

wizard_prompt_ref() {
  local WIZARD_DEFER_ANSWER=true
  command -v git >/dev/null || { printf 'Install Git before entering a workflow ref.\n' >&2; return 1; }
  while :; do
    wizard_prompt_path "$1" "${2:-main}" \
      'Use a valid Git branch or tag, such as main or feature/payments.' || return 1
    if git check-ref-format "refs/heads/$WIZARD_REPLY" >/dev/null 2>&1; then
      wizard_nav_finish "$WIZARD_REPLY" || return 1; return 0
    fi
    wizard_nav_retry
    WIZARD_PAGE_NOTICE='Enter a valid Git branch or tag. Spaces, doubled slashes, @{ and .lock suffixes are not allowed.'
    printf '%s\n' "$WIZARD_PAGE_NOTICE" >&2
  done
}

wizard_prompt_agent_source() {
  local WIZARD_DEFER_ANSWER=true
  while :; do
    wizard_prompt 'Local Markdown agent file to copy (blank skips): ' '' \
      'Enter an unquoted absolute or relative path. Shell variables are not expanded; blank skips.' || return 1
    if [[ -z "$WIZARD_REPLY" ]]; then wizard_nav_finish '' || return 1; return 0; fi
    if [[ "$WIZARD_REPLY" == *.[mM][dD] || "$WIZARD_REPLY" == *.[mM][aA][rR][kK][dD][oO][wW][nN] ]] &&
      [[ -f "$WIZARD_REPLY" && -r "$WIZARD_REPLY" && ! -L "$WIZARD_REPLY" ]] &&
      jq -e -Rs 'test("github_pat_[A-Za-z0-9_]{20,}|gh[pousr]_[A-Za-z0-9]{20,}")|not' -- "$WIZARD_REPLY" >/dev/null; then
      wizard_nav_finish "$WIZARD_REPLY" || return 1; return 0
    fi
    wizard_nav_retry
    WIZARD_PAGE_NOTICE='Choose a readable Markdown file, not a symlink, and remove any literal GitHub credentials.'
    printf '%s\n' "$WIZARD_PAGE_NOTICE" >&2
  done
}

wizard_prompt_list() {
  local kind="$1" title="$2" default="${3:-}" help="${4:-}" required="${5:-false}" rule
  case "$kind" in
    users) rule='all(.[]; length<=100 and test("^[A-Za-z0-9][A-Za-z0-9_-]*$") and (contains("--")|not)) and length==(map(ascii_downcase)|unique|length)' ;;
    slugs) rule='all(.[]; length<=100 and test("^[A-Za-z0-9][A-Za-z0-9_-]*$")) and length==(map(ascii_downcase)|unique|length)' ;;
    labels) rule='all(.[]; length<=50 and (test("[/?#%\\\\]")|not) and (contains("..")|not)) and length==(map(ascii_downcase)|unique|length)' ;;
    *) rule='all(.[]; length>0)' ;;
  esac
  wizard_prompt_checked "$title" "$default" "$help" \
    "(\$answer|split(\",\")|map(gsub(\"^\\\\s+|\\\\s+\$\";\"\")|select(length>0))) |
      (if \$context then length>0 else true end) and ($rule)" "$required"
}

wizard_prompt_identifier() {
  local kind="$1" title="$2" default="$3" help="$4" pattern limit=39 existing="${5:-[]}"
  case "$kind" in
    host) pattern='^(github\.com|[a-z0-9]([a-z0-9-]*[a-z0-9])?\.ghe\.com)$'; limit=71 ;;
    user) pattern='^[A-Za-z0-9][A-Za-z0-9_-]*$'; limit=100 ;;
    enterprise|slug) pattern='^[A-Za-z0-9][A-Za-z0-9_-]*$'; limit=100 ;;
    repo) pattern='^[A-Za-z0-9_.-]+$'; limit=100 ;;
    *) pattern='^[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?$' ;;
  esac
  local WIZARD_DEFER_ANSWER=true
  while :; do
    wizard_prompt_required "$title" "$default" "$help" || return 1
    WIZARD_REPLY="$(jq -nr --arg answer "$WIZARD_REPLY" '$answer|gsub("^\\s+|\\s+$";"")')" || return 1
    if [[ "$kind" == host ]]; then WIZARD_REPLY="$(printf '%s' "$WIZARD_REPLY" | tr '[:upper:]' '[:lower:]')"; fi
    if [[ ${#WIZARD_REPLY} -le "$limit" && "$WIZARD_REPLY" =~ $pattern &&
      "$WIZARD_REPLY" != *'..'* && "$WIZARD_REPLY" != . ]]; then
      if [[ "$kind" == host || "$kind" == repo || "$kind" == enterprise || "$kind" == slug || "$WIZARD_REPLY" != *'--'* ]]; then
        if jq -en --arg answer "$WIZARD_REPLY" --argjson existing "$existing" \
          '$existing|map(ascii_downcase)|index($answer|ascii_downcase)==null' >/dev/null; then
          wizard_nav_finish "$WIZARD_REPLY" || return 1; return 0
        fi
        wizard_nav_retry
        WIZARD_PAGE_NOTICE="Already listed: $WIZARD_REPLY. Choose a different $kind name."
        printf '%s\n' "$WIZARD_PAGE_NOTICE" >&2
        continue
      fi
    fi
    wizard_nav_retry
    WIZARD_PAGE_NOTICE="Use a valid $kind name, not a URL or email."
    printf 'Use a valid %s name, not a URL or email. %s\n' "$kind" "$help" >&2
  done
}

wizard_ui_key() {
  local key='' next='' sequence=''
  IFS= read -r -s -n 1 key || return 1
  case "$key" in
    '') WIZARD_KEY=enter ;;
    ' ') WIZARD_KEY=space ;;
    k) WIZARD_KEY=up ;; j) WIZARD_KEY=down ;;
    q) WIZARD_KEY=cancel ;;
    b|B) WIZARD_KEY=back ;;
    e|E) WIZARD_KEY=edit ;;
    $'\033')
      if ! IFS= read -r -s -n 1 -t 1 next; then WIZARD_KEY=cancel; return 0; fi
      case "$next" in
        '['|O)
          while :; do
            IFS= read -r -s -n 1 -t 1 next || { WIZARD_KEY=cancel; return 0; }
            sequence="$sequence$next"
            case "$next" in [A-Za-z~]|'@'|'['|'\'|']'|'^'|'_'|'`'|'{'|'|'|'}') break ;; esac
          done
          case "$sequence" in
            *A) WIZARD_KEY=up ;; *B) WIZARD_KEY=down ;; *C) WIZARD_KEY=forward ;; *D) WIZARD_KEY=back ;;
            *H|1~|7~) WIZARD_KEY=home ;; *F|4~|8~) WIZARD_KEY=end ;; *) WIZARD_KEY=other ;;
          esac ;;
        *) WIZARD_KEY=cancel ;;
      esac ;;
    *) WIZARD_KEY=other ;;
  esac
}

wizard_clip_menu_text() {
  jq -nr --arg text "$1" --argjson width "$2" '
    reduce ($text|explode[]) as $char ({text:"",cells:0,done:false};
      (if $char<128 then 1 else 2 end) as $cells |
      if .done or .cells+$cells>$width then .done=true
      else .text+=([$char]|implode) | .cells+=$cells end) | .text'
}

wizard_ui_select() {
  local title="$1" default="$2" options="$3" mode="${4:-single}" help="${5:-}"
  local values=() labels=() descriptions=() checked=() row cursor=0 index=0 start=0 end drawn=0 mark key total selection='[]' width=75 height label_width size current_size editor=false
  [[ "$title" != 'Edit an earlier answer' ]] || editor=true
  wizard_nav_begin "$mode" "$title" "$options" || return 1
  [[ "$WIZARD_REPLAY" != true ]] || return 0
  [[ "$WIZARD_HAS_PREVIOUS" != true ]] || default="$WIZARD_PREVIOUS"
  wizard_page "$title" || return 1
  [[ "$WIZARD_HAS_PREVIOUS" != true ]] || printf 'Saved selection restored.\n' >&2
  [[ -z "$help" ]] || printf '\n%s\n' "$help" >&2
  size="$(stty size)" || return 1
  width="${size##* }"; height="${size% *}"
  [[ "$width" -gt 0 ]] || width=80
  [[ "$height" -gt 0 ]] || height=30
  if [[ "$width" -lt 20 || "$height" -lt 16 ]]; then
    printf 'Keyboard menus need at least 16 rows and 20 columns. Enlarge the terminal or re-run init with --plain.\n' >&2
    return 1
  fi
  width=$((width-5))
  label_width=$width
  [[ "$mode" != multi ]] || label_width=$((width-4))
  while IFS= read -r row; do
    values[$index]="$(printf '%s' "$row" | jq -r .value)"
    labels[$index]="$(printf '%s' "$row" | jq -r .label)"
    descriptions[$index]="$(printf '%s' "$row" | jq -r '.description//""')"
    checked[$index]=false
    if [[ "$mode" == multi ]]; then
      if jq -en --argjson chosen "$default" --arg value "${values[$index]}" '$chosen|index($value)!=null' >/dev/null; then checked[$index]=true; fi
    elif [[ "${values[$index]}" == "$default" ]]; then cursor=$index; fi
    index=$((index+1))
  done < <(printf '%s' "$options" | jq -c '.[]')
  total=$index
  [[ "$total" -gt 0 ]] || { printf 'No choices are available.\n' >&2; return 1; }
  if ! stty -echo -icanon min 1 time 0; then
    printf 'Cannot enable keyboard selection. Re-run init with --plain.\n' >&2; return 1
  fi
  printf '\n' >&2; wizard_style '1;36'; printf '%s\n' "$title" >&2; wizard_style 0
  printf '\033[?25l' >&2
  while :; do
    current_size="$(stty size)" || { wizard_ui_restore; return 1; }
    if [[ "$current_size" != "$size" ]]; then
      size="$current_size"; width="${size##* }"; height="${size% *}"
      [[ "$width" -gt 0 ]] || width=80
      [[ "$height" -gt 0 ]] || height=30
      if [[ "$width" -lt 20 || "$height" -lt 16 ]]; then
        wizard_ui_restore
        printf 'Keyboard menus need at least 16 rows and 20 columns. Enlarge the terminal or re-run init with --plain.\n' >&2
        return 1
      fi
      width=$((width-5)); label_width=$width
      [[ "$mode" != multi ]] || label_width=$((width-4))
      if wizard_paged; then wizard_page "$title" || { wizard_ui_restore; return 1; }
      else printf '\033[2J\033[H' >&2; fi
      [[ -z "$help" ]] || printf '\n%s\n' "$help" >&2
      printf '\n%s\n' "$title" >&2
      drawn=0
    fi
    [[ "$drawn" -eq 0 ]] || printf '\033[%sA' "$drawn" >&2
    if [[ "$cursor" -lt "$start" ]]; then start=$cursor; fi
    if [[ "$cursor" -ge $((start+6)) ]]; then start=$((cursor-5)); fi
    end=$((start+6)); [[ "$end" -le "$total" ]] || end=$total
    drawn=0
    for ((index=start; index<end; index++)); do
      mark=' '
      [[ "$index" -ne "$cursor" ]] || mark='>'
      if [[ "$index" == "$cursor" ]]; then wizard_style '1;36'
      elif [[ "${checked[$index]}" == true ]]; then wizard_style 32; fi
      if [[ "$mode" == multi ]]; then
        key=' '; [[ "${checked[$index]}" != true ]] || key=x
        printf '\r\033[2K %s [%s] %s\n' "$mark" "$key" "$(wizard_clip_menu_text "${labels[$index]}" "$label_width")" >&2
      else
        printf '\r\033[2K %s %s\n' "$mark" "$(wizard_clip_menu_text "${labels[$index]}" "$label_width")" >&2
      fi
      wizard_style 0
      drawn=$((drawn+1))
    done
    printf '\r\033[2K %s\n' "$(wizard_clip_menu_text "${descriptions[$cursor]}" "$width")" >&2
    printf '\r\033[2K Choice %s/%s.\n' "$((cursor+1))" "$total" >&2
    if [[ "$editor" == true ]]; then
      if [[ "$width" -ge 32 ]]; then
        printf '\r\033[2K Up/Down: move. Enter: edit answer.\n' >&2
        printf '\r\033[2K Right/Left: return. Esc: stop.\n' >&2
      else
        printf '\r\033[2K Up/Down: move\n\r\033[2K Enter: edit\n\r\033[2K Right/Left: back\n\r\033[2K Esc: stop\n' >&2
      fi
    else
      if [[ "$width" -ge 32 ]]; then
        printf '\r\033[2K Up/Down: move. Enter/Right: next.\n' >&2
        printf '\r\033[2K Left/B: back. E: edit. Esc: stop.\n' >&2
      else
        printf '\r\033[2K Up/Down: move\n\r\033[2K Enter/Right: next\n\r\033[2K Left/B: back\n\r\033[2K E: edit; Esc: stop\n' >&2
      fi
    fi
    drawn=$((drawn+4))
    [[ "$width" -ge 32 ]] || drawn=$((drawn+2))
    if [[ "$mode" == multi ]]; then
      if [[ "$width" -ge 32 ]]; then printf '\r\033[2K Space: toggle a checkbox.\n' >&2
      else printf '\r\033[2K Space: toggle\n' >&2; fi
      drawn=$((drawn+1))
    fi
    if ! wizard_ui_key; then wizard_ui_restore; printf '\nInterview stopped: input ended before completion.\n' >&2; return 1; fi
    case "$WIZARD_KEY" in
      up) cursor=$(((cursor+total-1)%total)) ;;
      down) cursor=$(((cursor+1)%total)) ;;
      home) cursor=0 ;; end) cursor=$((total-1)) ;;
      back) if [[ "$editor" == true ]]; then
          wizard_ui_restore; WIZARD_REPLY=__return__; return 0
        fi
        if ! wizard_nav_back; then wizard_ui_restore; return 1; fi ;;
      edit) [[ "$editor" != true ]] || continue
        wizard_ui_restore; if ! wizard_edit_answers; then return 1; fi
        wizard_page "$title" || return 1
        [[ -z "$help" ]] || printf '\n%s\n' "$help" >&2
        printf '\n' >&2; wizard_style '1;36'; printf '%s\n' "$title" >&2; wizard_style 0
        stty -echo -icanon min 1 time 0 || return 1
        printf '\033[?25l' >&2; drawn=0 ;;
      space) if [[ "$mode" == multi ]]; then
        if [[ "${checked[$cursor]}" == true ]]; then checked[$cursor]=false; else checked[$cursor]=true; fi
      fi ;;
      cancel) wizard_ui_restore; printf '\nInterview cancelled. No configuration was saved.\n' >&2; return 1 ;;
      forward) if [[ "$editor" == true ]]; then
          wizard_ui_restore; WIZARD_REPLY=__return__; return 0
        fi
        break ;;
      enter) break ;;
    esac
  done
  wizard_ui_restore
  if [[ "$mode" == multi ]]; then
    for ((index=0; index<total; index++)); do
      if [[ "${checked[$index]}" == true ]]; then
        selection="$(jq -cn --argjson all "$selection" --arg value "${values[$index]}" '$all+[$value]')"
      fi
    done
    WIZARD_REPLY="$selection"
  else WIZARD_REPLY="${values[$cursor]}"; fi
  if [[ "${WIZARD_DEFER_ANSWER:-false}" != true ]]; then wizard_nav_finish "$WIZARD_REPLY"; fi
}

wizard_choose() {
  local title="$1" default="$2" help="$3" options="$4" row number=0 answer label raw
  if wizard_keyboard; then wizard_ui_select "$title" "$default" "$options" single "$help"; return $?; fi
  if ! wizard_replaying; then printf '\n%s\n' "$help" >&2; fi
  while IFS= read -r row; do
    number=$((number+1))
    printf '  %s) %s: %s\n' "$number" "$(printf '%s' "$row" | jq -r .label)" "$(printf '%s' "$row" | jq -r '.description//""')" >&2
  done < <(printf '%s' "$options" | jq -c '.[]')
  label="$(printf '%s' "$options" | jq -r --arg value "$default" '.[]|select(.value==$value)|.label')"
  local WIZARD_DEFER_ANSWER=true
  while :; do
    wizard_prompt "$title: " "$label" || return 1
    raw="$WIZARD_REPLY"
    answer="$(jq -nr --arg answer "$raw" '$answer|gsub("^\\s+|\\s+$";"")|ascii_downcase')" || return 1
    [[ -n "$answer" ]] || answer="$default"
    row="$(jq -r --arg answer "$answer" '.[]|select((.value|ascii_downcase)==($answer|ascii_downcase))|.value' <<<"$options")" || return 1
    if [[ -n "$row" ]]; then answer="$row"
    elif [[ "$answer" =~ ^[0-9]+$ ]]; then
      answer="$(printf '%s' "$options" | jq -r --arg n "$answer" '($n|tonumber) as $i | if $i>0 and $i<=length then .[$i-1].value else empty end')"
    fi
    if [[ "${WIZARD_BOOLEAN_CHOICE:-false}" == true ]]; then
      case "$answer" in yes|y) answer=true ;; no|n) answer=false ;; esac
    fi
    row="$(printf '%s' "$options" | jq -r --arg label "$answer" '.[]|select((.label|ascii_downcase)==($label|ascii_downcase))|.value')"
    [[ -z "$row" ]] || answer="$row"
    if printf '%s' "$options" | jq -e --arg value "$answer" 'any(.[]; .value==$value)' >/dev/null; then
      wizard_nav_finish "$raw" || return 1
      WIZARD_REPLY="$answer"; return 0
    fi
    printf 'Select one of the listed values or numbers.\n' >&2
  done
}

wizard_prompt_bool() {
  local default="${2:-false}" help="${3:-}" WIZARD_BOOLEAN_CHOICE=true
  if wizard_guided; then
    wizard_choose "$1" "$default" "${help:-Choose Yes to include this in the saved plan. Nothing changes now.}" \
      '[{"value":"false","label":"No","description":"Skip this choice."},{"value":"true","label":"Yes","description":"Include this choice. Apply still needs separate approval."}]' || return 1
    return 0
  fi
  [[ -z "$help" ]] || printf '%s\n' "$help" >&2
  local WIZARD_DEFER_ANSWER=true
  while :; do
    wizard_prompt "$1 [yes/no]: " || return 1
    WIZARD_REPLY="$(jq -nr --arg answer "$WIZARD_REPLY" '$answer|gsub("^\\s+|\\s+$";"")|ascii_downcase')" || return 1
    case "$WIZARD_REPLY" in
      yes|y|true) wizard_nav_finish "$WIZARD_REPLY" || return 1; WIZARD_REPLY=true; return 0 ;;
      no|n|false) wizard_nav_finish "$WIZARD_REPLY" || return 1; WIZARD_REPLY=false; return 0 ;;
      *) printf 'Answer yes or no. Nothing is approved by a blank answer.\n' >&2 ;;
    esac
  done
}

wizard_select_packages() {
  local default="$1" selected options raw
  local WIZARD_DEFER_ANSWER=true
  while :; do
    if wizard_guided; then
      options="$(jq -c '[.packages[]|{value:.id,label:.name,description:(.capabilities[0:2]|join("; "))}]' "$WIZARD_CONFIG_ROOT/catalog.json")"
      if ! wizard_replaying; then
        printf '\nSelect the capabilities you need. Workspace, Codespaces, Advanced Security and Code Quality are selected by default.\n' >&2
        printf 'Optional products may need licenses or owner setup. Selecting a package does not purchase it.\n' >&2
      fi
      if wizard_keyboard; then
        wizard_ui_select 'Capabilities' "$default" "$options" multi \
          'Required packages are included automatically. Selecting a package does not purchase products.' || return 1
        selected="$WIZARD_REPLY"
      else
        jq -r '.[]|"  \(.value): \(.label) (\(.description))"' <<<"$options" >&2
        wizard_prompt 'Package IDs, comma-separated (none selects none): ' "$(jq -r 'join(",")' <<<"$default")" || return 1
        raw="$WIZARD_REPLY"
        WIZARD_REPLY="$(jq -nr --arg value "$raw" '$value|gsub("^\\s+|\\s+$";"")|ascii_downcase')" || return 1
        if [[ "$WIZARD_REPLY" == none ]]; then selected='[]'; else selected="$(wizard_csv_json "$WIZARD_REPLY")" || return 1; fi
      fi
    else
      wizard_prompt 'Default packages (comma-separated IDs; blank selects none): ' || return 1
      raw="$WIZARD_REPLY"
      WIZARD_REPLY="$(jq -nr --arg value "$raw" '$value|gsub("^\\s+|\\s+$";"")|ascii_downcase')" || return 1
      if [[ "$WIZARD_REPLY" == none ]]; then selected='[]'; else selected="$(wizard_csv_json "$WIZARD_REPLY")" || return 1; fi
    fi
    if jq -e --argjson chosen "$selected" '($chosen-[.packages[].id]|length)==0' "$WIZARD_CONFIG_ROOT/catalog.json" >/dev/null; then
      if wizard_keyboard; then raw="$selected"; fi
      wizard_nav_finish "$raw" || return 1
      break
    fi
    wizard_nav_retry
    WIZARD_PAGE_NOTICE='Unknown package ID. Use the IDs in the capability list, or none.'
    printf '%s\n' "$WIZARD_PAGE_NOTICE" >&2
  done
  selected="$(wizard_package_closure "$selected")" || return 1
  printf 'Selected capabilities (including required packages): %s\n' "$(jq -r 'if length==0 then "none" else join(", ") end' <<<"$selected")" >&2
  WIZARD_REPLY="$selected"
}

wizard_package_closure() {
  local selected="$1" previous=''
  while [[ "$previous" != "$selected" ]]; do
    previous="$selected"
    selected="$(jq -c --argjson chosen "$selected" \
      '($chosen+[.packages[]|select(.id as $id|$chosen|index($id)!=null)|.prerequisites[]])|unique' "$WIZARD_CONFIG_ROOT/catalog.json")" || return 1
  done
  printf '%s\n' "$selected"
}

wizard_select_pilots() {
  local WIZARD_DEFER_ANSWER=true options selected raw
  options='[{"value":"issue-triage","label":"Issue triage","description":"Suggest issue labels within declared output limits."},{"value":"ci-diagnosis","label":"CI diagnosis","description":"Report why a workflow failed."},{"value":"documentation","label":"Documentation suggestions","description":"Report suggested documentation changes; no file writes."},{"value":"regression-tests","label":"Regression-test suggestions","description":"Report proposed tests; no file writes."},{"value":"review-assistance","label":"Review assistance","description":"Provide review feedback; never approve or merge."},{"value":"summaries","label":"Repository summaries","description":"Summarize authorized repository activity."}]'
  while :; do
    if wizard_keyboard; then
      wizard_ui_select 'Pilot workflows' '["issue-triage"]' "$options" multi || return 1
      raw="$WIZARD_REPLY"; selected="$raw"
    else
      printf 'Pilots: %s\n' "$(jq -r 'map(.value)|join(",")' <<<"$options")" >&2
      wizard_prompt 'Selected gh-aw pilots (comma-separated): ' issue-triage || return 1
      raw="$WIZARD_REPLY"; selected="$(wizard_csv_json "$raw")" || return 1
    fi
    if jq -en --argjson selected "$selected" --argjson options "$options" \
      '$selected|length>0 and (. - [$options[].value]|length)==0' >/dev/null; then
      wizard_nav_finish "$raw" || return 1; WIZARD_REPLY="$selected"; return 0
    fi
    wizard_nav_retry
    WIZARD_PAGE_NOTICE='Select at least one listed pilot, or go back and remove gh-aw from the capability checklist.'
    printf '%s\n' "$WIZARD_PAGE_NOTICE" >&2
  done
}

wizard_config_summary() {
  WIZARD_REVIEW_CONFIG="$1"
  if ! wizard_paged; then wizard_print_config_summary "$1"; fi
}

wizard_print_config_summary() {
  printf '\nReview your configuration\n' >&2
  printf '%s' "$1" | jq -r '
    .defaults.repository_visibility as $visibility |
    "Host: \(.host) | Enterprise: \(.enterprise.slug) | Account: \(.enterprise.identity)",
    (.organizations[] |
      "\nOrganization: \(.login) (\(if .create then "create" elif .adopt then "adopt" else "existing; updates not approved" end))",
      "  Owners: \(.owners|join(", "))",
      "  Capabilities: \(.packages|join(", "))",
      "  Teams: \(if (.teams|length)==0 then "none" else [.teams[].name]|join(", ") end)",
      (.repositories[] | "  Repository: \(.name) (\(if .adopt then "adopt; content through PRs" else "create" end)), \(.visibility//$visibility), starter \(.stack)"),
      "  Purchases selected: \(if .copilot.purchase or .security.purchase or .quality.purchase then "yes; review costs in the plan" else "none" end)")
  ' >&2
  printf '\nThis saves choices only. Doctor checks access; plan shows proposed changes.\n' >&2
}
