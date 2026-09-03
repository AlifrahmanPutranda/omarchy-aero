#!/bin/bash
# Install omarchy-aero: Aero-style minimize + numbered preview for Omarchy.
#
# One command from a clone of this repo:
#   ./install.sh
#
# What it does (all inside $HOME, nothing touches /usr/share/omarchy):
#   1. Copies the omarchy-minimized-* helper scripts to ~/.local/bin
#   2. Installs the aero.minimize shell plugin (number badges) and enables it
#   3. Appends a marked keybinding block to ~/.config/hypr/bindings.lua
#      (idempotent: an existing block is replaced in place)
#   4. Migrates away the older standalone-badge setup, if present
#   5. Reloads Hyprland and validates the config

set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

BEGIN_MARK="-- >>> aero.minimize bindings >>>"
END_MARK="-- <<< aero.minimize bindings <<<"
BINDINGS_FILE="$HOME/.config/hypr/bindings.lua"
PLUGIN_ID="aero.minimize"
PLUGIN_DIR="$HOME/.config/omarchy/plugins/$PLUGIN_ID"

log() { printf '\033[1;32m==>\033[0m %s\n' "$*"; }

# 1. Helper scripts -----------------------------------------------------------
log "Installing helper scripts to ~/.local/bin"
mkdir -p "$HOME/.local/bin"
cp "$repo_dir"/bin/omarchy-minimized-* "$HOME/.local/bin/"
chmod +x "$HOME/.local/bin"/omarchy-minimized-*

# 2. Shell plugin -------------------------------------------------------------
log "Installing the $PLUGIN_ID shell plugin"
mkdir -p "$PLUGIN_DIR"
cp "$repo_dir"/plugin/manifest.json "$repo_dir"/plugin/Aero.qml "$PLUGIN_DIR/"
# The registry only knows plugins it has scanned: rescan first, then enable,
# and surface a failure instead of silently leaving the plugin disabled.
omarchy-shell shell rescanPlugins >/dev/null 2>&1 || true
sleep 1
if ! omarchy plugin enable "$PLUGIN_ID" >/dev/null 2>&1; then
  echo "omarchy-aero: could not enable $PLUGIN_ID (it was still installed;" >&2
  echo "run 'omarchy plugin enable $PLUGIN_ID' after the shell rescans)" >&2
fi

# 3. Hyprland bindings --------------------------------------------------------
log "Adding keybindings to $BINDINGS_FILE"
mkdir -p "$HOME/.config/hypr"
touch "$BINDINGS_FILE"

tmp="$(mktemp)"
# Drop any previous managed block, then append the current one.
awk -v begin="$BEGIN_MARK" -v end="$END_MARK" '
  $0 == begin { skipping = 1; next }
  $0 == end   { skipping = 0; next }
  skipping    { next }
  { print }
' "$BINDINGS_FILE" > "$tmp"
printf '\n%s\n' "$BEGIN_MARK" >> "$tmp"
cat "$repo_dir/hypr/aero-bindings.lua" >> "$tmp"
printf '%s\n' "$END_MARK" >> "$tmp"
mv "$tmp" "$BINDINGS_FILE"

# 4. Migrate the old standalone-badge setup, if present ----------------------
if systemctl --user is-active omarchy-minimized-badges.service >/dev/null 2>&1; then
  log "Migrating: disabling the standalone badge service (now a shell plugin)"
  systemctl --user disable --now omarchy-minimized-badges.service >/dev/null 2>&1 || true
fi
rm -f "$HOME/.config/systemd/user/omarchy-minimized-badges.service"
rm -rf "$HOME/.config/qs-minimized"
systemctl --user daemon-reload >/dev/null 2>&1 || true

# 5. Apply ---------------------------------------------------------------------
log "Reloading Hyprland"
hyprctl reload >/dev/null 2>&1 || true
sleep 1
if [[ -n "$(hyprctl configerrors 2>/dev/null)" ]]; then
  echo "omarchy-aero: Hyprland reported config errors:" >&2
  hyprctl configerrors >&2
  exit 1
fi

log "Rescanning shell plugins"
omarchy-shell shell rescanPlugins >/dev/null 2>&1 || true

cat <<'DONE'

Done! Aero-style minimize is live:

  SUPER+M        minimize the focused window
  SUPER+ALT+M    preview: small cards with numbered badges
  1..9, 0 (=10)  restore that card instantly (or click its badge)
  ESC / Enter    close the preview

Log out and back in if the badges do not appear on the first preview.

DONE
