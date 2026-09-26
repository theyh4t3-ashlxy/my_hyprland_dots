local win = "WIN"
local home = os.getenv("HOME") or ""
local term = "uwsm app -- kitty"

-- Helpers
local function bind(keys, dsp, opts)
	hl.bind(keys, dsp, opts)
end

local function mbind(key, dsp, opts)
	hl.bind(win .. " + " .. key, dsp, opts)
end

local function action(act)
	return hl.dsp.exec_cmd(home .. "/.local/bin/qs-action " .. act)
end

-- Core window management
mbind("T", hl.dsp.exec_cmd(term))
mbind("Q", hl.dsp.window.close())
mbind("F", hl.dsp.window.fullscreen())
mbind("SPACE", hl.dsp.window.float({ action = "toggle" }))

-- Synchronized float + pin toggle (Pip / Sticky mode)
mbind("SHIFT + SPACE", function()
	local win = hl.get_active_window()
	if not win then return end

	if win.floating and win.pinned then
		hl.dispatch(hl.dsp.window.pin({ action = "disable" }))
		hl.dispatch(hl.dsp.window.float({ action = "disable" }))
	else
		hl.dispatch(hl.dsp.window.float({ action = "enable" }))
		hl.dispatch(hl.dsp.window.pin({ action = "enable" }))
	end
end)

-- Unified desktop & shell controls (dynamically routed to quickshell / brain_shell)
mbind("D", action("launcher"))
mbind("N", action("notifs"))
mbind("V", action("clipboard"))
mbind("W", action("wallpaper"))
mbind("A", action("audio"))
mbind("ESCAPE", action("powermenu"))
mbind("END", action("lock"))
mbind("SHIFT + END", hl.dsp.exec_cmd("uwsm stop"))
bind("Print", action("screenshot"))

-- Direction map (u / d / l / r format)
-- Note: use hl.dsp.window.swap if you want to swap tiled positions,
-- or hl.dsp.window.move if you want to shift across monitors/groups.
local directions = {
	I = "u",
	J = "l",
	K = "d",
	L = "r",
}

for key, dir in pairs(directions) do
	mbind(key, hl.dsp.focus({ direction = dir }))
	mbind("SHIFT + " .. key, hl.dsp.window.swap({ direction = dir }))
end

-- Mouse bindings
mbind("mouse:272", hl.dsp.window.drag(), { mouse = true })
mbind("mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Repeating audio / backlight keys
local repeating_keys = {
	XF86AudioRaiseVolume = "wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+",
	XF86AudioLowerVolume = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-",
	XF86MonBrightnessUp = "brightnessctl set +5%",
	XF86MonBrightnessDown = "brightnessctl set 5%-",
}

for key, cmd in pairs(repeating_keys) do
	bind(key, hl.dsp.exec_cmd(cmd), { locked = true, repeating = true })
end

-- Native hardware toggles
bind("XF86Display", hl.dsp.dpms({ action = "toggle" }), { locked = true })

-- Command-based hardware toggles
local single_toggles = {
	XF86AudioMute = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle",
	XF86AudioMicMute = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle",
	XF86WLAN = "nmcli radio wifi toggle",
	XF86Favorites = home .. "/.local/bin/qs-action lock",
	XF86NotificationCenter = home .. "/.local/bin/qs-action notifs",
	XF86PickupPhone = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle",
	XF86HangupPhone = "playerctl play-pause",
}

for key, cmd in pairs(single_toggles) do
	bind(key, hl.dsp.exec_cmd(cmd), { locked = true })
end

-- Workspaces 1 to 10 (1-9, 0)
for i = 1, 10 do
	local key = tostring(i % 10)
	mbind(key, hl.dsp.focus({ workspace = i }))
	-- Set follow = false if you want silent move
	mbind("SHIFT + " .. key, hl.dsp.window.move({ workspace = i, follow = true }))
end
