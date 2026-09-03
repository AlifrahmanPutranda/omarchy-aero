-- Managed by omarchy-aero install.sh; edit in the repo and re-run install.

-- Minimize: hide the focused window into a hidden special workspace.
o.bind("SUPER + M", "Minimize window", hl.dsp.window.move({ workspace = "special:minimized", follow = false }))

-- Aero-style preview: windows on special:minimized shrink into small cards
-- (big gaps), the aero.minimize plugin badges them with numbers, and the
-- submap below lets a plain number key restore that card without thinking.
hl.workspace_rule({ workspace = "special:minimized", gaps_in = 60, gaps_out = 320, border_size = 3 })

o.bind("SUPER + ALT + M", "Minimized window preview", "omarchy-minimized-preview")

hl.define_submap("minimized", function()
  local function restore(key, n)
    hl.bind(key, hl.dsp.exec_cmd("omarchy-minimized-restore " .. n), {
      submap = "minimized",
      description = "Restore minimized window " .. n,
    })
  end
  restore("1", 1)
  restore("2", 2)
  restore("3", 3)
  restore("4", 4)
  restore("5", 5)
  restore("6", 6)
  restore("7", 7)
  restore("8", 8)
  restore("9", 9)
  restore("0", 10)

  local function close(key)
    hl.bind(key, hl.dsp.exec_cmd("omarchy-minimized-close"), {
      submap = "minimized",
      description = "Close minimized preview",
    })
  end
  close("ESCAPE")
  close("RETURN")
  -- The opener key works from inside the submap too (toggles back closed).
  hl.bind("SUPER + ALT + M", hl.dsp.exec_cmd("omarchy-minimized-preview"), {
    submap = "minimized",
    description = "Close minimized preview",
  })
end)
