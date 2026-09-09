local home = os.getenv("HOME") or ""
local mainMod = "WIN" -- calling it super is pure copium bill gates won anyway

-- the wiki thinks we are too fragile for uwsm so i run it out of spite
local terminal = "uwsm app -- kitty"

hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(terminal))

hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + SPACE", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + SHIFT + SPACE", function()
	-- closures turn dispatchers into inert garbage without hl.dispatch()
	hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
	hl.dispatch(hl.dsp.window.pin())
end)

-- vaxry please look away
hl.bind(mainMod .. " + SHIFT + END", hl.dsp.exec_cmd("uwsm stop || hyprctl dispatch exit"))

-- ijkl because hjkl was engineered by someone with mangled wrists
hl.bind(mainMod .. " + I", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))

hl.bind(mainMod .. " + SHIFT + I", hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.move({ direction = "down" }))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.move({ direction = "right" }))

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })

-- retina incinerator toggle
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set +5%"), { locked = true, repeating = true })

hl.bind("XF86WLAN", hl.dsp.exec_cmd("nmcli radio wifi toggle"), { locked = true })
hl.bind("XF86Display", hl.dsp.exec_cmd("hyprctl dispatch dpms toggle"), { locked = true })

-- useless corporate lenovo keys hijacked into doing actual work
hl.bind("XF86Favorites", hl.dsp.exec_cmd("qs ipc call lock lock"))
hl.bind("XF86NotificationCenter", hl.dsp.exec_cmd("qs ipc call notifs toggle"))
hl.bind("XF86PickupPhone", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
hl.bind("XF86HangupPhone", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })

hl.bind(mainMod .. " + END", hl.dsp.exec_cmd("qs ipc call lock lock"))

hl.bind("Print", hl.dsp.exec_cmd("qs ipc call screenshot open"))

hl.bind(mainMod .. " + ALT + W", hl.dsp.exec_cmd("python3 " .. home .. "/.config/quickshell/scripts/wallpaper.py random all"))

for i = 1, 9 do
	local ws = tostring(i)
	hl.bind(mainMod .. " + " .. i, hl.dsp.focus({ workspace = ws }))
	hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = ws }))
end
