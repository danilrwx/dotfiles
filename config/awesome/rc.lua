-- awesome, an X11 session next to i3 and dwm with dwm's keys and bar (~/w/dwm config.def.h): tags 1-9,
-- tile, max and floating layouts, a 2px border green on the focused window, and on top the tags, the
-- layout, the focused title, bin/wm-status and the tray. $mod+b hides the bar, and a held Super then
-- shows it over the windows. Notifications stay dunst's (bin/x-autostart): naughty is never required,
-- as it would claim org.freedesktop.Notifications. Linked to ~/.config/awesome by install.

local gears = require("gears")
local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local dpi = require("beautiful.xresources").apply_dpi
require("awful.autofocus")

-- errors as a dunst card, naughty being out
awesome.connect_signal("debug::error", function(err)
	awful.spawn({ "notify-send", "-u", "critical", "awesome", tostring(err) })
end)

-- theme ─────────────────────────────────────────────────────────────────────────────────────────────────────────
-- dwm's colors: black, white text, gray idle, green focus. dpi() turns logical px into the panel's 2x
local bg, fg, gray, dark, accent = "#000000", "#ffffff", "#888888", "#444444", "#00cd00"
beautiful.init({
	font = "Iosevka 11",
	bg_normal = bg, bg_focus = bg, bg_systray = bg,
	fg_normal = gray, fg_focus = fg, fg_urgent = accent,
	border_width = dpi(2), border_normal = bg, border_focus = accent, border_marked = accent,
	useless_gap = 0,
	taglist_fg_focus = fg, taglist_bg_focus = bg,
	taglist_fg_occupied = gray, taglist_fg_empty = dark, taglist_fg_urgent = accent,
	systray_icon_spacing = dpi(4),
	master_width_factor = 0.55,
})

local modkey = "Mod4"
local terminal = "st"
local bin = os.getenv("HOME") .. "/dotfiles/bin/"

-- dwm's layouts and their symbols in the bar
awful.layout.layouts = { awful.layout.suit.tile, awful.layout.suit.floating, awful.layout.suit.max }
local symbols = {
	[awful.layout.suit.tile] = "[]=",
	[awful.layout.suit.floating] = "><>",
	[awful.layout.suit.max] = "[M]",
}

-- the X11 setup and daemons, once a session: a restart ($mod+Control+r) finds dunst running
awful.spawn.with_shell("pgrep -u \"$USER\" -x dunst > /dev/null || " .. bin .. "x-autostart")

-- bar ───────────────────────────────────────────────────────────────────────────────────────────────────────────
local bar_height = dpi(20)
local sidepad = dpi(12) -- clear of the rounded screen corners, as dwm's sidepad

-- wm-status in its markup mode: Nerd Font icons a size below the text; killed on exit and restart
local status = wibox.widget.textbox()
local status_pid = awful.spawn.with_line_callback({ "env", "WM_STATUS_ICONS=markup", bin .. "wm-status" }, {
	stdout = function(line) status:set_markup(line) end,
})
awesome.connect_signal("exit", function()
	if type(status_pid) == "number" then awesome.kill(status_pid, awesome.unix_signal.SIGTERM) end
end)

-- the focused window's title, white as dwm's SchemeTitle
local title = wibox.widget.textbox()
local function update_title()
	local c = client.focus
	title:set_markup(c and ('<span foreground="' .. fg .. '">' .. gears.string.xml_escape(c.name or "") .. "</span>") or "")
end
client.connect_signal("focus", update_title)
client.connect_signal("unfocus", update_title)
client.connect_signal("property::name", update_title)

local bars = {}

-- docked: the bar takes its strip of the screen; hidden: it is gone, and peek() lays it over the windows
local function dock(s)
	local b = bars[s]
	b.peeking = false
	b.wibox.ontop = false
	b.wibox:struts({ top = b.hidden and 0 or bar_height })
	b.wibox.visible = not b.hidden
end

local function peek(on)
	for s in screen do
		local b = bars[s]
		if b and b.hidden and b.peeking ~= on then
			b.peeking = on
			b.wibox.ontop = on
			b.wibox.visible = on
		end
	end
end

awful.screen.connect_for_each_screen(function(s)
	awful.tag({ "1", "2", "3", "4", "5", "6", "7", "8", "9" }, s, awful.layout.layouts[1])

	local taglist = awful.widget.taglist({
		screen = s,
		filter = awful.widget.taglist.filter.all,
		buttons = gears.table.join(
			awful.button({}, 1, function(t) t:view_only() end),
			awful.button({ modkey }, 1, function(t) if client.focus then client.focus:move_to_tag(t) end end),
			awful.button({}, 3, awful.tag.viewtoggle)
		),
		widget_template = {
			{ id = "text_role", widget = wibox.widget.textbox },
			left = dpi(6), right = dpi(6),
			widget = wibox.container.margin,
		},
	})
	local layout = wibox.widget.textbox()
	local function update_layout() layout:set_text(" " .. (symbols[awful.layout.get(s)] or "?") .. " ") end
	tag.connect_signal("property::layout", update_layout)
	tag.connect_signal("property::selected", update_layout)
	update_layout()

	local systray = wibox.widget.systray()
	systray:set_screen(s) -- pinned, as dwm's systraypinning, not following the focus

	local w = wibox({ screen = s, height = bar_height, bg = bg, fg = gray, visible = true })
	w:geometry({ x = s.geometry.x, y = s.geometry.y, width = s.geometry.width, height = bar_height })
	w:setup({
		{
			{ taglist, layout, layout = wibox.layout.fixed.horizontal },
			{ title, left = dpi(8), widget = wibox.container.margin },
			{ status, systray, spacing = dpi(8), layout = wibox.layout.fixed.horizontal },
			layout = wibox.layout.align.horizontal,
		},
		left = sidepad, right = sidepad,
		widget = wibox.container.margin,
	})
	bars[s] = { wibox = w, hidden = false, peeking = false }
	dock(s)
end)

-- keys ──────────────────────────────────────────────────────────────────────────────────────────────────────────
local function sh(cmd) return function() awful.spawn.with_shell(cmd) end end
local function fnkey(arg) return sh(bin .. "wm-fnkeys " .. arg) end

local globalkeys = gears.table.join(
	awful.key({ modkey }, "p", sh(bin .. "wm-menu")),
	awful.key({ modkey, "Shift" }, "Return", function() awful.spawn(terminal) end),
	awful.key({ modkey }, "b", function()
		local s = awful.screen.focused()
		bars[s].hidden = not bars[s].hidden
		dock(s)
	end),
	-- Super alone shows the hidden bar while held
	awful.key({}, "Super_L", function() peek(true) end, function() peek(false) end),
	awful.key({ modkey }, "Super_L", nil, function() peek(false) end),
	awful.key({}, "Super_R", function() peek(true) end, function() peek(false) end),
	awful.key({ modkey }, "Super_R", nil, function() peek(false) end),

	awful.key({ modkey }, "j", function() awful.client.focus.byidx(1) end),
	awful.key({ modkey }, "k", function() awful.client.focus.byidx(-1) end),
	awful.key({ modkey }, "i", function() awful.tag.incnmaster(1, nil, true) end),
	awful.key({ modkey }, "d", function() awful.tag.incnmaster(-1, nil, true) end),
	awful.key({ modkey }, "h", function() awful.tag.incmwfact(-0.05) end),
	awful.key({ modkey }, "l", function() awful.tag.incmwfact(0.05) end),
	awful.key({ modkey }, "Tab", awful.tag.history.restore),
	awful.key({ modkey }, "t", function() awful.layout.set(awful.layout.suit.tile) end),
	awful.key({ modkey }, "f", function() awful.layout.set(awful.layout.suit.floating) end),
	awful.key({ modkey }, "m", function() awful.layout.set(awful.layout.suit.max) end),
	awful.key({ modkey }, "space", function() awful.layout.inc(1) end),
	awful.key({ modkey }, "0", function()
		for _, t in ipairs(awful.screen.focused().tags) do t.selected = true end
	end),
	awful.key({ modkey }, "comma", function() awful.screen.focus_relative(-1) end),
	awful.key({ modkey }, "period", function() awful.screen.focus_relative(1) end),
	awful.key({ modkey, "Control" }, "r", awesome.restart),
	awful.key({ modkey, "Shift" }, "q", awesome.quit),

	-- media, HONOR Fn and menu keys as under i3 and dwm (bin/wm-fnkeys, wm-ctl, screenshot-select)
	awful.key({}, "XF86AudioRaiseVolume", fnkey("vol-up")),
	awful.key({}, "XF86AudioLowerVolume", fnkey("vol-down")),
	awful.key({}, "XF86AudioMute", fnkey("vol-mute")),
	awful.key({ modkey }, "XF86AudioRaiseVolume", fnkey("mic-up")),
	awful.key({ modkey }, "XF86AudioLowerVolume", fnkey("mic-down")),
	awful.key({ modkey, "Shift" }, "m", fnkey("mic")),
	awful.key({}, "XF86AudioMicMute", fnkey("mic")),
	awful.key({}, "XF86MonBrightnessUp", fnkey("bright-up")),
	awful.key({}, "XF86MonBrightnessDown", fnkey("bright-down")),
	awful.key({}, "XF86TouchpadOn", fnkey("touchpad-on")),
	awful.key({}, "XF86TouchpadOff", fnkey("touchpad-off")),
	awful.key({}, "XF86TouchpadToggle", fnkey("touchpad-toggle")),
	awful.key({}, "XF86Launch1", fnkey("profile")),
	awful.key({}, "XF86AudioPlay", sh("playerctl play-pause")),
	awful.key({}, "XF86AudioNext", sh("playerctl next")),
	awful.key({}, "XF86AudioPrev", sh("playerctl previous")),
	awful.key({ modkey, "Shift" }, "s", sh(bin .. "screenshot-select")),
	awful.key({}, "Print", sh(bin .. "screenshot-select")),
	awful.key({ modkey }, "x", sh(bin .. "wm-ctl")),
	awful.key({ modkey, "Shift" }, "x", sh("i3lock -c 000000")),
	awful.key({ "Control", "Mod1" }, "s", sh(bin .. "sys-notify")),
	awful.key({ "Control", "Mod1" }, "c", sh(bin .. "cal-notify")),
	awful.key({ modkey }, "n", sh("dunstctl close")),
	awful.key({ modkey, "Shift" }, "n", sh("dunstctl close-all"))
)

-- tags as dwm's TAGKEYS: view, toggle view, move the window, toggle the window's tag
for i = 1, 9 do
	globalkeys = gears.table.join(globalkeys,
		awful.key({ modkey }, "#" .. i + 9, function()
			local t = awful.screen.focused().tags[i]
			if t then t:view_only() end
		end),
		awful.key({ modkey, "Control" }, "#" .. i + 9, function()
			local t = awful.screen.focused().tags[i]
			if t then awful.tag.viewtoggle(t) end
		end),
		awful.key({ modkey, "Shift" }, "#" .. i + 9, function()
			local t = client.focus and client.focus.screen.tags[i]
			if t then client.focus:move_to_tag(t) end
		end),
		awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9, function()
			local t = client.focus and client.focus.screen.tags[i]
			if t then client.focus:toggle_tag(t) end
		end)
	)
end
root.keys(globalkeys)

local clientkeys = gears.table.join(
	awful.key({ modkey, "Shift" }, "c", function(c) c:kill() end),
	awful.key({ modkey }, "Return", function(c) c:swap(awful.client.getmaster()) end),
	awful.key({ modkey, "Shift" }, "space", awful.client.floating.toggle),
	awful.key({ modkey, "Shift" }, "f", function(c) c.fullscreen = not c.fullscreen; c:raise() end),
	awful.key({ modkey, "Shift" }, "0", function(c) c:tags(c.screen.tags) end),
	awful.key({ modkey, "Shift" }, "comma", function(c) c:move_to_screen(c.screen.index - 1) end),
	awful.key({ modkey, "Shift" }, "period", function(c) c:move_to_screen() end)
)

local clientbuttons = gears.table.join(
	awful.button({}, 1, function(c) client.focus = c; c:raise() end),
	awful.button({ modkey }, 1, function(c) client.focus = c; c:raise(); awful.mouse.client.move(c) end),
	awful.button({ modkey }, 3, function(c) client.focus = c; c:raise(); awful.mouse.client.resize(c) end)
)

-- rules ─────────────────────────────────────────────────────────────────────────────────────────────────────────
awful.rules.rules = {
	{
		rule = {},
		properties = {
			border_width = beautiful.border_width,
			border_color = beautiful.border_normal,
			focus = awful.client.focus.filter,
			raise = true,
			keys = clientkeys,
			buttons = clientbuttons,
			screen = awful.screen.preferred,
			size_hints_honor = false,
			-- as dwm's clampfloating: centred, and nothing larger than the work area
			placement = awful.placement.centered + awful.placement.no_offscreen,
		},
	},
	-- floating as under i3: dialogs, Telegram, askpass, Steam's popups, bin/wm-ctl's terminal
	{ rule_any = { type = { "dialog" } }, properties = { floating = true } },
	{ rule_any = { class = { "TelegramDesktop", "telegram-desktop" }, name = { "SSH Askpass" } },
		properties = { floating = true } },
	{ rule = { class = "steam" }, except = { name = "Steam" }, properties = { floating = true } },
	{ rule = { class = "wm-ctl" }, properties = { floating = true, width = dpi(900), height = dpi(600) } },
}

-- a floating window that asks for more than the work area is cut down to it (GTK3's file chooser)
client.connect_signal("manage", function(c)
	if c.floating or awful.layout.get(c.screen) == awful.layout.suit.floating then
		local wa = c.screen.workarea
		local bw = 2 * c.border_width
		c:geometry({ width = math.min(c.width, wa.width - bw), height = math.min(c.height, wa.height - bw) })
		awful.placement.centered(c, { honor_workarea = true })
	end
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
