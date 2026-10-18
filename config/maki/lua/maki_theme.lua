-- the user's colour theme for maki's own UI.
--
-- bin/theme writes a user theme, ~/.config/maki/themes/dotfiles.toml, the dotfiles
-- theme's 16 colours as the palette plus the scope and UI roles. This plugin names
-- it to maki once, at init: maki.setup is a one-shot per init.lua, so the theme is
-- fixed at start. A new dotfiles theme is picked up on the next maki start (or
-- /reload), the way every other dotfiles consumer follows bin/theme.
--
-- The terminal itself (foot, tmux, nvim) takes its 16 slots from the theme the
-- usual way: bin/theme sends foot's OSC escapes to the open terminals. maki's user
-- theme uses the same palette, so its highlight reads the same way as the terminal's.

local function apply()
	-- the user theme's name is fixed by bin/theme; just point maki at it
	maki.setup({
		always_yolo = true,
		ui = { theme = "dotfiles" },
		net = {
			allowed_private_hosts = {
				"mcp.exa.ai",
				"raw.githubusercontent.com",
				"10.0.0.0/8",
				"172.16.0.0/12",
				"192.168.0.0/16",
				"198.18.0.0/16",
			},
		},
	})
end

local M = {}
M.apply = apply
return M
