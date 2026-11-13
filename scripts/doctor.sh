#!/usr/bin/env bash
# Check that ~/.claude is wired to this repo and the status line renders.
set -uo pipefail
source "$(dirname "$0")/lib.sh"

problems=0

section "Links in $CLAUDE_DIR"
while IFS= read -r name; do
  dest="$CLAUDE_DIR/$name"
  src="$CLAUDE_SRC/$name"
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    ok "$name"
  elif [ -e "$dest" ]; then
    err "$name exists but is not linked to the repo (run scripts/link.sh)"
    problems=$((problems + 1))
  else
    err "$name missing (run scripts/link.sh)"
    problems=$((problems + 1))
  fi
done < <(managed_entries)

section "Tools"
for tool in git jq claude; do
  if have "$tool"; then ok "$tool"; else err "$tool not found"; problems=$((problems + 1)); fi
done

section "Settings"
if jq empty "$CLAUDE_SRC/settings.json" 2>/dev/null; then
  ok "settings.json is valid JSON"
else
  err "settings.json is not valid JSON"
  problems=$((problems + 1))
fi

section "Status line"
sample='{"model":{"display_name":"Test Model"},"context_window":{"used_percentage":42,"total_input_tokens":12000,"total_output_tokens":3400},"cost":{"total_cost_usd":0.0123}}'
if out="$(printf '%s' "$sample" | "$CLAUDE_SRC/statusline/statusline.sh" 2>&1)" && [ -n "$out" ]; then
  ok "renders: $out"
else
  err "statusline.sh failed: $out"
  problems=$((problems + 1))
fi

echo
if [ "$problems" -eq 0 ]; then
  printf '%sAll good.%s\n' "$C_GREEN" "$C_RESET"
else
  printf '%s%d problem(s) found.%s\n' "$C_RED" "$problems" "$C_RESET"
  exit 1
fi
