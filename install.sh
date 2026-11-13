#!/usr/bin/env bash
# bepis-stack bootstrap: deps → sync into ~/.claude → plugins → doctor.
#
#   ./install.sh                # full setup
#   ./install.sh --dry-run      # show what would happen
#   ./install.sh --no-plugins   # skip plugin installs
#
# On a fresh machine without a clone:
#   bash <(curl -fsSL https://raw.githubusercontent.com/agsyafiq55/bepis-stack/main/install.sh)
set -euo pipefail

REPO_URL="https://github.com/agsyafiq55/bepis-stack.git"
CLONE_DIR="${BEPIS_DIR:-$HOME/Projects/bepis-stack}"

DRY_RUN=0
WITH_PLUGINS=1
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --no-plugins) WITH_PLUGINS=0 ;;
    -h|--help) sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown option: $arg" >&2; exit 2 ;;
  esac
done
export DRY_RUN

# If we're not inside a clone (e.g. run via curl), clone first and re-exec.
SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || true)"
if [ ! -f "$SELF_DIR/scripts/lib.sh" ]; then
  if [ ! -d "$CLONE_DIR/.git" ]; then
    echo "==> Cloning $REPO_URL into $CLONE_DIR"
    mkdir -p "$(dirname "$CLONE_DIR")"
    git clone "$REPO_URL" "$CLONE_DIR"
  fi
  exec "$CLONE_DIR/install.sh" "$@"
fi

S="$SELF_DIR/scripts"
bash "$S/deps.sh"
bash "$S/sync.sh"
if [ "$WITH_PLUGINS" = 1 ]; then bash "$S/plugins.sh"; fi
if [ "$DRY_RUN" = 1 ]; then
  echo; echo "Dry run complete; nothing was changed."
else
  bash "$S/doctor.sh"
fi
