#!/bin/bash
# Remove omarchy-aero (installed by ./install.sh).

set -euo pipefail

BEGIN_MARK="-- >>> aero.minimize bindings >>>"
END_MARK="-- <<< aero.minimize bindings <<<"
BINDINGS_FILE="$HOME/.config/hypr/bindings.lua"
PLUGIN_ID="aero.minimize"

log() { printf '\033[1;32m==>\033[0m %s\n' "$*"; }

log "Disabling the $PLUGIN_ID shell plugin"
omarchy plugin disable "$PLUGIN_ID" >/dev/null 2>&1 || true
rm -rf "$HOME/.config/omarchy/plugins/$PLUGIN_ID"

log "Removing helper scripts"
rm -f "$HOME/.local/bin"/omarchy-minimized-{preview,restore,close,badges,visible}

if [[ -f "$BINDINGS_FILE" ]]; then
  log "Removing the keybinding block"
  tmp="$(mktemp)"
  awk -v begin="$BEGIN_MARK" -v end="$END_MARK" '
    $0 == begin { skipping = 1; next }
    $0 == end   { skipping = 0; next }
    skipping    { next }
    { print }
  ' "$BINDINGS_FILE" > "$tmp"
  mv "$tmp" "$BINDINGS_FILE"
fi

hyprctl reload >/dev/null 2>&1 || true
omarchy-shell shell rescanPlugins >/dev/null 2>&1 || true
log "Removed. Minimized windows stay on special:minimized until you move them out."
