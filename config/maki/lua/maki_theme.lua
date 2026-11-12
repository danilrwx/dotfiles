-- the user's colour theme for maki's own UI.
--
-- config/maki/themes/dotfiles.toml, the dotfiles' one (pastel) theme's 16 colours as
-- the palette plus the scope and UI roles. This plugin names it to maki once, at init:
-- maki.setup is a one-shot per init.lua, so the theme is fixed at start. An edit is
-- picked up on the next maki start (or /reload).
--
-- The terminal itself (kitty, tmux, nvim) takes its 16 slots from config/kitty/theme.conf;
-- maki's user theme uses the same palette, so its highlight reads the same way as the
-- terminal's.

local function apply()
	-- the user theme's name is fixed by the file's; just point maki at it
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
