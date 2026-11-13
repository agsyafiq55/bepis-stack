#!/usr/bin/env bash
# Copy claude/ into ~/.claude. The repo is the source of truth; edit it, then re-run this.
#
# - Directories (skills/, commands/, ...): files are copied over. Files that exist only
#   on the machine are left alone (nothing is ever deleted).
# - settings.json: deep-merged. Repo values win; keys only the machine has (e.g. the
#   model picked with /model) are kept.
# - Other files: copied; a differing existing file is backed up first.
# - Old symlinks from the previous setup are replaced with real copies.
set -euo pipefail
source "$(dirname "$0")/lib.sh"

section "Syncing claude/ → $CLAUDE_DIR"
run mkdir -p "$CLAUDE_DIR"

backup_dir="$CLAUDE_DIR/backups/bepis-$(date +%Y%m%d-%H%M%S)"
changed=0 unchanged=0

backup() { # backup <path>
  run mkdir -p "$backup_dir"
  run cp -a "$1" "$backup_dir/"
  warn "backed up ${1/#$HOME/~} to ${backup_dir/#$HOME/~}/"
}

# Replace a symlink with a real copy of what it pointed at, so nothing is lost.
materialize() { # materialize <path>
  [ -L "$1" ] || return 0
  local tmp; tmp="$(mktemp -d)"
  if [ "$DRY_RUN" = 1 ]; then
    info "${C_DIM}[dry-run] would replace symlink ${1/#$HOME/~} with a real copy${C_RESET}"
  else
    cp -aL "$1" "$tmp/x" 2>/dev/null || true
    rm "$1"
    [ -e "$tmp/x" ] && mv "$tmp/x" "$1"
    rmdir "$tmp" 2>/dev/null || rm -rf "$tmp"
  fi
}

copy_file() { # copy_file <src> <dest>
  if [ -f "$2" ] && cmp -s "$1" "$2"; then
    unchanged=$((unchanged + 1))
    return
  fi
  [ -f "$2" ] && backup "$2"
  run mkdir -p "$(dirname "$2")"
  run cp -p "$1" "$2"
  changed=$((changed + 1))
  ok "${2/#$HOME/~}"
}

merge_settings() { # merge_settings <src> <dest>
  local src="$1" dest="$2" merged
  if [ ! -f "$dest" ]; then
    run cp -p "$src" "$dest"
    changed=$((changed + 1)); ok "settings.json (created)"
    return
  fi
  merged="$(jq -s '.[0] * .[1]' "$dest" "$src")"
  if [ "$(jq -S . "$dest")" = "$(printf '%s' "$merged" | jq -S .)" ]; then
    unchanged=$((unchanged + 1)); ok "settings.json (already up to date)"
    return
  fi
  backup "$dest"
  if [ "$DRY_RUN" = 1 ]; then
    info "${C_DIM}[dry-run] would merge repo settings into ${dest/#$HOME/~}${C_RESET}"
  else
    printf '%s\n' "$merged" > "$dest"
  fi
  changed=$((changed + 1)); ok "settings.json (merged)"
}

while IFS= read -r name; do
  src="$CLAUDE_SRC/$name"
  dest="$CLAUDE_DIR/$name"
  materialize "$dest"

  if [ -d "$src" ]; then
    while IFS= read -r f; do
      rel="${f#"$src"/}"
      copy_file "$f" "$dest/$rel"
    done < <(find "$src" -type f ! -name .gitkeep | sort)
    run mkdir -p "$dest"
  elif [ "$name" = "settings.json" ]; then
    merge_settings "$src" "$dest"
  else
    copy_file "$src" "$dest"
  fi
done < <(managed_entries)

info "${C_DIM}changed: $changed, already up to date: $unchanged${C_RESET}"
