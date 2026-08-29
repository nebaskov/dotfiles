-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This will hold the configuration.
local config = wezterm.config_builder()
local act = wezterm.action

-- This is where you actually apply your config choices.

-- For example, changing the initial geometry for new windows:
config.initial_cols = 160
config.initial_rows = 45

-- or, changing the font size and color scheme.
-- for color schemes search https://wezterm.org/colorschemes/a/index.html
config.font_size = 14
config.color_scheme = 'Abernathy'

-- shortcuts
config.keys = {
    -- Splits
    {
        key = 'd',
        mods = 'CMD',
        action = act.SplitHorizontal { domain = 'CurrentPaneDomain' },
    },
    {
        key = 'd',
        mods = 'CMD|SHIFT',
        action = act.SplitVertical { domain = 'CurrentPaneDomain' },
    },

    -- Move between panes with Option + h/j/k/l
    { key = 'h', mods = 'ALT', action = act.ActivatePaneDirection 'Left' },
    { key = 'j', mods = 'ALT', action = act.ActivatePaneDirection 'Down' },
    { key = 'k', mods = 'ALT', action = act.ActivatePaneDirection 'Up' },
    { key = 'l', mods = 'ALT', action = act.ActivatePaneDirection 'Right' },

    -- Resize with Option + Shift + h/j/k/l
    {
        key = 'h',
        mods = 'CMD|SHIFT',
        action = act.AdjustPaneSize { 'Left', 3 },
    },
    {
        key = 'j',
        mods = 'CMD|SHIFT',
        action = act.AdjustPaneSize { 'Down', 3 },
    },
    {
        key = 'k',
        mods = 'CMD|SHIFT',
        action = act.AdjustPaneSize { 'Up', 3 },
    },
    {
        key = 'l',
        mods = 'CMD|SHIFT',
        action = act.AdjustPaneSize { 'Right', 3 },
    },

    -- Other useful pane controls
    {
        key = 'Enter',
        mods = 'CMD|SHIFT',
        action = act.TogglePaneZoomState,
    },
    {
        key = 'w',
        mods = 'CMD|SHIFT',
        action = act.CloseCurrentPane { confirm = true },
    },
}

-- Finally, return the configuration to wezterm:
return config
