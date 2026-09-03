# omarchy-aero

**Windows Aero-style minimize for [Omarchy](https://omarchy.org).**

`SUPER+M` minimizes a window out of the tiling. `SUPER+ALT+M` flips every
minimized window into a row of small preview cards with **numbered badges** —
press that number (or click the badge) and the window is instantly back on
the workspace you came from. No thinking, no hunting.

![Aero preview](docs/aero-preview-v2.png)

## Keys

| Key | Action |
|-----|--------|
| `SUPER+M` | Minimize the focused window |
| `SUPER+ALT+M` | Toggle the preview (small cards + numbered badges) |
| `1`–`9`, `0` (=10) | Restore that card — oldest minimized window is `1` |
| click a badge | Same as pressing its number |
| `ESC` / `Enter` | Close the preview |

The number keys only live inside the preview's keymap, so normal typing is
never disturbed. Restoring follows the window back to your previous
workspace and closes the preview automatically.

## Install

From a clone of this repo (or `git clone` it anywhere):

```bash
git clone https://github.com/AlifrahmanPutranda/omarchy-aero.git
cd omarchy-aero
./install.sh
```

`install.sh` only touches your home directory: helper scripts go to
`~/.local/bin`, the badge overlay becomes the `aero.minimize` shell plugin,
and a clearly-marked block is appended to `~/.config/hypr/bindings.lua`.
Remove everything with `./uninstall.sh`.

## How it works

- **Minimize** is Hyprland's canonical pattern: the window is moved (silently,
  unfollowed) to the hidden special workspace `special:minimized` — the
  process keeps running, the window is simply out of the layout.
- **Small cards** come from a workspace rule: big gaps on
  `special:minimized` shrink whatever lands there into preview cards.
- **Badges** are a [Quickshell](https://quickshell.outfoxxed.me) service
  plugin (`plugin/Aero.qml`): while the preview is visible it polls the
  compositor and floats a numbered, theme-colored chip on each card. Numbers
  are stable — oldest minimized window is `1` — and match the restore script.
- **Restore** moves the chosen window back to the workspace the preview was
  opened from, follows it, and leaves the preview keymap.

Helpers (`bin/`) are plain bash + `jq` + `hyprctl`; the Hyprland side uses
Omarchy's Lua config (`hl.dsp.*` dispatchers, `define_submap`,
`workspace_rule`).

## Requirements

- Omarchy 4.0+ (Hyprland Lua config)
- `jq` (ships with Omarchy)

## License

MIT
