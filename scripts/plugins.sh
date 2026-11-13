#!/usr/bin/env bash
# Add marketplaces and install plugins listed in plugins/plugins.txt.
set -euo pipefail
source "$(dirname "$0")/lib.sh"

LIST="$REPO_DIR/plugins/plugins.txt"

section "Plugins"

if ! have claude; then
  warn "claude CLI not found, skipping"
  exit 0
fi

known_mkts="$(claude plugin marketplace list --json 2>/dev/null | jq -r '.[] | .name, (.repo // empty), (.url // empty)' || true)"
known_plugins="$(claude plugin list --json 2>/dev/null | jq -r '.[] | (.id // empty), (.name // empty)' || true)"

while read -r kind value _rest; do
  case "$kind" in
    ''|\#*) continue ;;
    marketplace)
      if grep -qxF "$value" <<<"$known_mkts"; then
        ok "marketplace $value (already added)"
      else
        run claude plugin marketplace add "$value" && ok "marketplace $value"
      fi
      ;;
    plugin)
      if grep -qxF "$value" <<<"$known_plugins" || grep -qxF "${value%@*}" <<<"$known_plugins"; then
        ok "plugin $value (already installed)"
      else
        run claude plugin install "$value" && ok "plugin $value"
      fi
      ;;
    *) warn "unknown line in plugins.txt: $kind $value" ;;
  esac
done < "$LIST"
