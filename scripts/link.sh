#!/usr/bin/env bash
# Symlink every top-level entry of claude/ into ~/.claude.
# Existing real files/dirs are moved to ~/.claude/backups/bepis-<timestamp>/ first.
set -euo pipefail
source "$(dirname "$0")/lib.sh"

section "Linking claude/ → $CLAUDE_DIR"
run mkdir -p "$CLAUDE_DIR"

backup_dir="$CLAUDE_DIR/backups/bepis-$(date +%Y%m%d-%H%M%S)"
linked=0 skipped=0 backed_up=0

while IFS= read -r name; do
  src="$CLAUDE_SRC/$name"
  dest="$CLAUDE_DIR/$name"

  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    ok "$name (already linked)"
    skipped=$((skipped + 1))
    continue
  fi

  if [ -e "$dest" ] || [ -L "$dest" ]; then
    run mkdir -p "$backup_dir"
    run mv "$dest" "$backup_dir/$name"
    warn "$name: backed up existing to ${backup_dir/#$HOME/~}/$name"
    backed_up=$((backed_up + 1))
  fi

  run ln -s "$src" "$dest"
  ok "$name → ${src/#$HOME/~}"
  linked=$((linked + 1))
done < <(managed_entries)

info "${C_DIM}linked: $linked, already ok: $skipped, backed up: $backed_up${C_RESET}"
