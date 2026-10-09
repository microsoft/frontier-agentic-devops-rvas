#!/usr/bin/env bash

wizard_nav_write() {
  local data="$1" temporary="$WIZARD_INTERVIEW_DIR/navigation.tmp"
  printf '%s\n' "$data" >"$temporary" && mv "$temporary" "$WIZARD_INTERVIEW_DIR/navigation.json" ||
    wizard_die "Cannot save interview progress."
}

wizard_nav_begin() {
  local kind="$1" title="$2" options="${3:-}" state key
  WIZARD_REPLAY=false WIZARD_HAS_PREVIOUS=false WIZARD_PREVIOUS=''
  if [[ -z "${WIZARD_INTERVIEW_DIR:-}" ]]; then wizard_replay_unmute; return 0; fi
  key="$(jq -cn --arg kind "$kind" --arg title "$title" --arg options "$options" '{kind:$kind,title:$title,options:$options}')"
  state="$(cat "$WIZARD_INTERVIEW_DIR/navigation.json")" || return 1
  if jq -en --argjson state "$state" --arg key "$key" '$state.answers[$state.cursor].key==$key' >/dev/null; then
    WIZARD_HAS_PREVIOUS=true
    WIZARD_PREVIOUS="$(jq -r '.answers[.cursor].answer' <<<"$state")"
    if jq -e '.cursor<.replay_until' <<<"$state" >/dev/null; then
      WIZARD_REPLAY=true WIZARD_REPLY="$WIZARD_PREVIOUS"
      wizard_nav_write "$(jq '.cursor+=1' <<<"$state")"
    fi
  else
    wizard_nav_write "$(jq '.answers=.answers[0:.cursor] | .replay_until=.cursor' <<<"$state")"
  fi
  [[ "$WIZARD_REPLAY" == true ]] || wizard_replay_unmute
  WIZARD_QUESTION_KEY="$key"
}

wizard_nav_finish() {
  local state answer="$1"
  [[ "${WIZARD_REPLAY:-false}" != true ]] || return 0
  [[ -n "${WIZARD_INTERVIEW_DIR:-}" ]] || return 0
  if ! jq -en --arg answer "$answer" '$answer|test("github_pat_[A-Za-z0-9_]{20,}|gh[pousr]_[A-Za-z0-9]{20,}")|not' >/dev/null; then
    printf 'Do not enter credentials. Keep tokens in gh authentication or the environment.\n' >&2; return 1
  fi
  state="$(cat "$WIZARD_INTERVIEW_DIR/navigation.json")" || return 1
  wizard_nav_write "$(jq --arg key "$WIZARD_QUESTION_KEY" --arg answer "$answer" '
    if .answers[.cursor].key!=$key or .answers[.cursor].answer!=$answer then
      .answers=.answers[0:.cursor]
    else . end |
    .answers[.cursor]={key:$key,answer:$answer} | .cursor+=1
  ' <<<"$state")"
}

wizard_nav_back() {
  local state
  [[ -n "${WIZARD_INTERVIEW_DIR:-}" ]] || { printf 'Back is available during init.\n' >&2; return 0; }
  state="$(cat "$WIZARD_INTERVIEW_DIR/navigation.json")" || return 1
  if [[ "$(jq -r .cursor <<<"$state")" == 0 ]]; then
    printf 'You are at the first question.\n' >&2; return 0
  fi
  wizard_nav_write "$(jq '.replay_until=.cursor-1 | .back=true' <<<"$state")"
  printf '\nBack: earlier answers are kept. Changing an answer resets later choices.\n' >&2
  return 1
}

wizard_nav_retry() {
  [[ -n "${WIZARD_INTERVIEW_DIR:-}" ]] || return 0
  if [[ "${WIZARD_REPLAY:-false}" == true ]]; then
    wizard_nav_write "$(jq '.cursor=([.cursor-1,0]|max) | .replay_until=.cursor' "$WIZARD_INTERVIEW_DIR/navigation.json")"
    WIZARD_REPLAY=false
    wizard_replay_unmute
  fi
}

wizard_edit_answers() {
  local directory="${WIZARD_INTERVIEW_DIR:-}" options selected status error="${1:-}" help
  [[ -n "$directory" ]] || { printf 'Editing earlier answers is available during init.\n' >&2; return 0; }
  options="$(jq -c '[.answers|to_entries[]|{value:("question:"+(.key|tostring)),
    label:((.value.key|fromjson|.title|gsub(":?\\s+$";""))+" = "+(.value.answer|gsub("[\u0000-\u001f\u007f]";" ")|.[0:55])),
    description:"Return to this answer. A changed answer resets later choices."}]' "$directory/navigation.json")"
  [[ "$(jq length <<<"$options")" -gt 0 ]] || { printf 'No earlier answers to edit yet.\n' >&2; return 0; }
  selected="$(jq -r '.[-1].value' <<<"$options")"
  help='Select an answer and press Enter to edit it. Right returns without editing. Esc cancels the interview.'
  if ! wizard_keyboard; then
    options="$(jq -c '.+[{value:"__return__",label:"Return without editing",description:"Keep all answers and return to the current question or review."}]' <<<"$options")"
    selected=__return__
    help='Select an answer to edit, or choose Return without editing. Ctrl+C stops the interview.'
  fi
  [[ -z "$error" ]] || WIZARD_PAGE_NOTICE="Cannot save this configuration: $error"
  # The editor is a navigation control, not another configuration answer.
  local WIZARD_INTERVIEW_DIR=''
  if wizard_choose 'Edit an earlier answer' "$selected" "$help" "$options"; then status=0; else status=$?; fi
  WIZARD_INTERVIEW_DIR="$directory"
  [[ "$status" -eq 0 ]] || return "$status"
  [[ "$WIZARD_REPLY" != __return__ ]] || return 0
  selected="${WIZARD_REPLY#question:}"
  wizard_nav_write "$(jq --argjson index "$selected" '.replay_until=$index | .back=true' "$directory/navigation.json")"
  return 1
}

wizard_interview_cleanup() {
  local file
  [[ -n "${WIZARD_INTERVIEW_DIR:-}" && -d "$WIZARD_INTERVIEW_DIR" ]] || return 0
  while IFS= read -r file; do rm -f "$file"; done < <(find "$WIZARD_INTERVIEW_DIR" -maxdepth 1 -type f)
  rmdir "$WIZARD_INTERVIEW_DIR"
}
