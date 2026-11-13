#!/usr/bin/env bash
# Shared helpers. Source this; don't run it.

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLAUDE_SRC="$REPO_DIR/claude"
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
DRY_RUN="${DRY_RUN:-0}"

if [ -t 1 ]; then
  C_RESET=$'\033[0m'; C_DIM=$'\033[2m'; C_RED=$'\033[31m'
  C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'; C_CYAN=$'\033[36m'
else
  C_RESET=; C_DIM=; C_RED=; C_GREEN=; C_YELLOW=; C_CYAN=
fi

section() { printf '\n%s==> %s%s\n' "$C_CYAN" "$*" "$C_RESET"; }
info()    { printf '  %s\n' "$*"; }
ok()      { printf '  %s✓%s %s\n' "$C_GREEN" "$C_RESET" "$*"; }
warn()    { printf '  %s!%s %s\n' "$C_YELLOW" "$C_RESET" "$*"; }
err()     { printf '  %s✗%s %s\n' "$C_RED" "$C_RESET" "$*" >&2; }

# run CMD...: execute, or just print it in dry-run mode.
run() {
  if [ "$DRY_RUN" = 1 ]; then
    printf '  %s[dry-run]%s %s\n' "$C_DIM" "$C_RESET" "$*"
  else
    "$@"
  fi
}

have() { command -v "$1" >/dev/null 2>&1; }

# Ask a yes/no question; default no. Non-interactive => no.
confirm() {
  [ -t 0 ] || return 1
  local reply
  read -r -p "  $1 [y/N] " reply
  [[ "$reply" =~ ^[Yy]$ ]]
}

# Entries in claude/ that get synced into ~/.claude (top level only).
managed_entries() {
  local p
  for p in "$CLAUDE_SRC"/* "$CLAUDE_SRC"/.[!.]*; do
    [ -e "$p" ] && basename "$p"
  done | sort
}
