# shellcheck shell=bash
# log.sh — logging helpers for the provisioning scripts.
# Pure I/O: writes to stderr so stdout stays clean for machine-readable output.
# Colour auto-disables when stderr is not a TTY (CI-safe).

if [[ -t 2 ]]; then
  _C_RESET=$'\033[0m'; _C_RED=$'\033[31m'; _C_GRN=$'\033[32m'
  _C_YLW=$'\033[33m'; _C_BLU=$'\033[34m'; _C_DIM=$'\033[2m'
else
  _C_RESET=''; _C_RED=''; _C_GRN=''; _C_YLW=''; _C_BLU=''; _C_DIM=''
fi

log_info()  { printf '%s[info]%s  %s\n' "$_C_BLU" "$_C_RESET" "$*" >&2; }
log_ok()    { printf '%s[ ok ]%s  %s\n' "$_C_GRN" "$_C_RESET" "$*" >&2; }
log_warn()  { printf '%s[warn]%s  %s\n' "$_C_YLW" "$_C_RESET" "$*" >&2; }
log_error() { printf '%s[fail]%s  %s\n' "$_C_RED" "$_C_RESET" "$*" >&2; }
log_plan()  { printf '%s[plan]%s  %s\n' "$_C_DIM" "$_C_RESET" "$*" >&2; }
log_step()  { printf '\n%s==>%s %s\n'   "$_C_BLU" "$_C_RESET" "$*" >&2; }
die()       { log_error "$*"; exit 1; }
