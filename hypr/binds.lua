local home = os.getenv("HOME") or ""
local mod = "WIN"
local term = "uwsm app -- kitty"

-- helpers to stop manual string concat abuse
local function bind(keys, dsp, opts)
	hl.bind(keys, dsp, opts)
end

local function mbind(key, dsp, opts)
	hl.bind(mod .. " + " .. key, dsp, opts)
end

local function qs(cmd)
	return hl.dsp.exec_cmd("qs ipc call " .. cmd)
end

-- core window management
mbind("T", hl.dsp.exec_cmd(term))
mbind("Q", hl.dsp.window.close())
mbind("F", hl.dsp.window.fullscreen())
mbind("SPACE", hl.dsp.window.float({ action = "toggle" }))
mbind("SHIFT + SPACE", function()
	hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
	hl.dispatch(hl.dsp.window.pin())
end)

-- session & quickshell controls
mbind("SHIFT + END", hl.dsp.exec_cmd("uwsm stop"))
mbind("END", qs("lock lock"))
mbind("D", qs("launcher toggle"))
bind("Print", qs("screenshot open"))

-- direction map (the anti-hjkl layout)
local directions = {
	I = "up",
	J = "left",
	K = "down",
	L = "right",
}

for key, dir in pairs(directions) do
	mbind(key, hl.dsp.focus({ direction = dir }))
	mbind("SHIFT + " .. key, hl.dsp.window.move({ direction = dir }))
end

-- mouse bindings
mbind("mouse:272", hl.dsp.window.drag(), { mouse = true })
mbind("mouse:273", hl.dsp.window.resize(), { mouse = true })

-- repeating audio / backlight keys
local repeating_keys = {
	XF86AudioRaiseVolume = "wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+",
	XF86AudioLowerVolume = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-",
	XF86MonBrightnessUp = "brightnessctl set +5%",
	XF86MonBrightnessDown = "brightnessctl set 5%-",
}

for key, cmd in pairs(repeating_keys) do
	bind(key, hl.dsp.exec_cmd(cmd), { locked = true, repeating = true })
end

-- hardware toggles
local single_toggles = {
	XF86AudioMute = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle",
	XF86AudioMicMute = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle",
	XF86WLAN = "nmcli radio wifi toggle",
	XF86Display = "hyprctl dispatch dpms toggle",
	XF86Favorites = "qs ipc call lock lock",
	XF86NotificationCenter = "qs ipc call notifs toggle",
	XF86PickupPhone = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle",
	XF86HangupPhone = "playerctl play-pause",
}

for key, cmd in pairs(single_toggles) do
	bind(key, hl.dsp.exec_cmd(cmd), { locked = true })
end

-- scripts using the resolved home path
mbind("ALT + W", hl.dsp.exec_cmd("python3 " .. home .. "/.config/quickshell/scripts/wallpaper.py random all"))
mbind("ALT + S", hl.dsp.exec_cmd(home .. "/.local/bin/qs-switch toggle"))

-- workspaces 1 to 10 (1-9, 0)
for i = 1, 10 do
	local key = tostring(i % 10)
	mbind(key, hl.dsp.focus({ workspace = i }))
	mbind("SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end
