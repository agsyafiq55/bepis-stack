#!/usr/bin/env bash
# Make sure git, jq and the claude CLI are available.
set -euo pipefail
source "$(dirname "$0")/lib.sh"

section "Checking dependencies"

pkg_install() {
  if have apt-get; then run sudo apt-get install -y "$@"
  elif have brew; then run brew install "$@"
  elif have dnf; then run sudo dnf install -y "$@"
  elif have pacman; then run sudo pacman -S --noconfirm "$@"
  else
    err "No known package manager; install manually: $*"
    return 1
  fi
}

for tool in git jq; do
  if have "$tool"; then
    ok "$tool"
  else
    warn "$tool missing, installing"
    pkg_install "$tool"
  fi
done

if have claude; then
  ok "claude ($(claude --version 2>/dev/null | head -1))"
elif confirm "Claude Code CLI not found. Install it with the official installer?"; then
  run bash -c 'curl -fsSL https://claude.ai/install.sh | bash'
  export PATH="$HOME/.local/bin:$PATH"
else
  warn "claude not installed; plugin setup will be skipped"
fi
