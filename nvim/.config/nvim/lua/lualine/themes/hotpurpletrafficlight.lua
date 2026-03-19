-- HotPurpleTrafficLight lualine theme
-- Place at: ~/.config/nvim/lua/lualine/themes/hotpurpletrafficlight.lua
--
-- Usage in your lualine config:
--   require("lualine").setup({ options = { theme = "hotpurpletrafficlight" } })

local c = {
  bg       = "#000000",
  bg_light = "#1a1a2e",
  fg       = "#d1d1e0",
  purple   = "#9933ff",
  purple_m = "#a64dff",
  blue_p   = "#6666ff",
  blue_dim = "#4d4dff",
  green    = "#00ff00",
  orange   = "#ff9933",
  red      = "#ff0000",
  inactive = "#9999ff",
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
    a = { fg = c.bg, bg = c.purple_m, gui = "bold" },
    b = { fg = c.fg, bg = c.bg_light },
  },
  inactive = {
    a = { fg = c.inactive, bg = c.bg_light },
    b = { fg = c.inactive, bg = c.bg },
    c = { fg = c.inactive, bg = c.bg },
  },
}
