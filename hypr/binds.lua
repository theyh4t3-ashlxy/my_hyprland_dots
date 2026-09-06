-- i am not a keyboard, i am a piano

-- because repeating "SUPER" 50 times makes me want to cry
local mainMod = "SUPER"

-- wait the wiki literally says "for the majority of users it's recommended to use hyprland without uwsm" because they think we are not "adventurous" enough but whatever we do what we want
local terminal = "uwsm app -- kitty"

-- open apps
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(terminal))

-- window management
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + SPACE", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + SHIFT + SPACE", function()
    -- inside a function, dispatchers are literally just dumb tables that do nothing unless we wrap them in hl.dispatch() because why make things easy
    hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
    hl.dispatch(hl.dsp.window.pin())
end)

-- we use uwsm btw, not the regular hyprland. vaxry hates me :[ (according to the wiki ofc)
hl.bind(mainMod .. " + SHIFT + END", hl.dsp.exec_cmd("uwsm end"))

-- moving windows around (because vim is for the linux nerds)
hl.bind(mainMod .. " + I", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))

hl.bind(mainMod .. " + SHIFT + I", hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.move({ direction = "down" }))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.move({ direction = "right" }))

-- mouse controls (wow u really use guis instead of being an elitist -_-)
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- volume keys (f1 - f4)
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
-- holding these actually does stuff now instead of giving you carpal tunnel
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })

-- brightness keys (f5 & f6)
-- also holdable now so you can blind yourself instantly
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set +5%"), { locked = true, repeating = true })

-- airplane mode / wifi toggle (f8)
hl.bind("XF86WLAN", hl.dsp.exec_cmd("nmcli radio wifi toggle"), { locked = true })

-- lock screen (calls quickshell session lock with fallback)
hl.bind("XF86Launch1", hl.dsp.exec_cmd("qs ipc call lock lock 2>/dev/null || hyprlock"))
hl.bind(mainMod .. " + END", hl.dsp.exec_cmd("qs ipc call lock lock 2>/dev/null || hyprlock"))

-- screenshot
hl.bind("Print", hl.dsp.exec_cmd("hyprshot -m region"))
hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd("hyprshot -m window"))
hl.bind("CTRL + Print", hl.dsp.exec_cmd("hyprshot -m output"))

-- roll random wallpaper on the fly
hl.bind(mainMod .. " + ALT + W", hl.dsp.exec_cmd("python3 " .. os.getenv("HOME") .. "/.config/quickshell/scripts/wallpaper.py random all"))

-- workspaces (i mean.. there is literally a + in my quickshell but i still use the windows key?)
for i = 1, 9 do
    local ws = tostring(i)
    hl.bind(mainMod .. " + " .. i, hl.dsp.focus({ workspace = ws }))
    hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = ws }))
end