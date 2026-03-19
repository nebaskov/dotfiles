-- Velvet Pulse — lualine theme
-- Place at: ~/.config/nvim/lua/lualine/themes/velvetpulse.lua

local c = {
  bg       = "#0d0d1a",
  bg_light = "#181828",
  fg       = "#c8c8d8",
  purple   = "#b07cff",
  purple_m = "#9a6adb",
  blue_p   = "#7a8fd4",
  green    = "#66d98e",
  orange   = "#d9a06a",
  red      = "#d96070",
  inactive = "#6a6a8a",
  func     = "#7dcfff",
}

return {
  normal = {
    a = { fg = c.bg, bg = c.purple, gui = "bold" },
    b = { fg = c.fg, bg = c.bg_light },
    c = { fg = c.inactive, bg = c.bg },
  },
  insert = {
    a = { fg = c.bg, bg = c.green, gui = "bold" },
    b = { fg = c.fg, bg = c.bg_light },
  },
  visual = {
    a = { fg = c.bg, bg = c.blue_p, gui = "bold" },
    b = { fg = c.fg, bg = c.bg_light },
  },
  replace = {
    a = { fg = c.bg, bg = c.red, gui = "bold" },
    b = { fg = c.fg, bg = c.bg_light },
  },
  command = {
    a = { fg = c.bg, bg = c.orange, gui = "bold" },
    b = { fg = c.fg, bg = c.bg_light },
  },
  terminal = {
    a = { fg = c.bg, bg = c.func, gui = "bold" },
    b = { fg = c.fg, bg = c.bg_light },
  },
  inactive = {
    a = { fg = c.inactive, bg = c.bg_light },
    b = { fg = c.inactive, bg = c.bg },
    c = { fg = c.inactive, bg = c.bg },
  },
}
