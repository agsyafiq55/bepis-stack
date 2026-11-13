#!/usr/bin/env bash
# Check that ~/.claude has what the repo defines and the status line renders.
set -uo pipefail
source "$(dirname "$0")/lib.sh"

problems=0

section "Files in $CLAUDE_DIR match the repo"
while IFS= read -r name; do
  src="$CLAUDE_SRC/$name"
  dest="$CLAUDE_DIR/$name"

  if [ -L "$dest" ]; then
    err "$name is still a symlink (run scripts/sync.sh to replace it with a copy)"
    problems=$((problems + 1))
  elif [ -d "$src" ]; then
    bad=0
    while IFS= read -r f; do
      rel="${f#"$src"/}"
      if ! cmp -s "$f" "$dest/$rel"; then
        err "$name/$rel is missing or differs (run scripts/sync.sh)"
        bad=1
      fi
    done < <(find "$src" -type f ! -name .gitkeep)
    [ "$bad" = 0 ] && ok "$name/" || problems=$((problems + 1))
  elif [ "$name" = "settings.json" ]; then
    if [ -f "$dest" ] && jq -e -n --slurpfile a "$src" --slurpfile b "$dest" \
         '$a[0] | to_entries | all(.[]; $b[0][.key] == .value)' >/dev/null 2>&1; then
      ok "$name (repo values present)"
    else
      err "$name is missing repo values (run scripts/sync.sh)"
      problems=$((problems + 1))
    fi
  elif cmp -s "$src" "$dest"; then
    ok "$name"
  else
    err "$name is missing or differs (run scripts/sync.sh)"
    problems=$((problems + 1))
  fi
done < <(managed_entries)

section "Tools"
for tool in git jq claude; do
  if have "$tool"; then ok "$tool"; else err "$tool not found"; problems=$((problems + 1)); fi
done

section "Settings"
if jq empty "$CLAUDE_SRC/settings.json" 2>/dev/null; then
  ok "claude/settings.json is valid JSON"
else
  err "claude/settings.json is not valid JSON"
  problems=$((problems + 1))
fi

section "Status line"
sample='{"model":{"display_name":"Test Model"},"context_window":{"used_percentage":42,"total_input_tokens":12000,"total_output_tokens":3400},"cost":{"total_cost_usd":0.0123}}'
if out="$(printf '%s' "$sample" | "$CLAUDE_DIR/statusline/statusline.sh" 2>&1)" && [ -n "$out" ]; then
  ok "renders: $out"
else
  err "installed statusline.sh failed: $out"
  problems=$((problems + 1))
fi

echo
if [ "$problems" -eq 0 ]; then
  printf '%sAll good.%s\n' "$C_GREEN" "$C_RESET"
else
  printf '%s%d problem(s) found.%s\n' "$C_RED" "$problems" "$C_RESET"
  exit 1
fi
