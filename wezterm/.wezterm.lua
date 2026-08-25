-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices.

-- For example, changing the initial geometry for new windows:
config.initial_cols = 160
config.initial_rows = 45

-- or, changing the font size and color scheme.
-- for color schemes search https://wezterm.org/colorschemes/a/index.html
config.font_size = 14
config.color_scheme = 'Abernathy'

-- Finally, return the configuration to wezterm:
return config
