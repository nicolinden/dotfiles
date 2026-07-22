-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()
config:set_strict_mode(true)

-- This is where you actually apply your config choices
config.font = wezterm.font("MesloLGS Nerd Font Mono")
config.font_size = 16.0

config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = false

config.keys = {
	{
		key = "LeftArrow",
		mods = "OPT",
		action = wezterm.action.SendString("\x1bb"),
	},
	{
		key = "RightArrow",
		mods = "OPT",
		action = wezterm.action.SendString("\x1bf"),
	},
}

-- my coolnight colorscheme:
config.colors = {
	foreground = "#CBE0F0",
	background = "#011423",
	cursor_bg = "#47FF9C",
	cursor_border = "#47FF9C",
	cursor_fg = "#011423",
	selection_bg = "#033259",
	selection_fg = "#CBE0F0",
	ansi = { "#214969", "#E52E2E", "#44FFB1", "#FFE073", "#0FC5ED", "#a277ff", "#24EAF7", "#24EAF7" },
	brights = { "#214969", "#E52E2E", "#44FFB1", "#FFE073", "#A277FF", "#a277ff", "#24EAF7", "#24EAF7" },
}

-- and finally, return the configuration to wezterm
return config
