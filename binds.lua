-- i am not a keyboard, i am a piano

local terminal = "kitty"
local launcher = "qs ipc call launcher toggle"
local browser = "firefox"

-- open apps
hl.bind("SUPER + T", hl.dsp.exec_cmd(terminal))
hl.bind("SUPER + R", hl.dsp.exec_cmd(launcher))
hl.bind("SUPER + B", hl.dsp.exec_cmd(browser))

-- window management
hl.bind("SUPER + Q", hl.dsp.window.close())
hl.bind("SUPER + SHIFT + Q", hl.dsp.exec_cmd("hyprctl dispatch forcekillactive"))
hl.bind("SUPER + F", hl.dsp.window.fullscreen())
hl.bind("SUPER + SPACE", hl.dsp.window.float({ action = "toggle" }))
hl.bind("SUPER + SHIFT + SPACE", hl.dsp.window.pin())

-- exit hyprland gracefully
hl.bind("SUPER + SHIFT + END", hl.dsp.exec_cmd("hyprshutdown"))

-- moving windows around (i-j-k-l gamer layout)
hl.bind("SUPER + I", hl.dsp.focus({ direction = "up" }))
hl.bind("SUPER + J", hl.dsp.focus({ direction = "left" }))
hl.bind("SUPER + K", hl.dsp.focus({ direction = "down" }))
hl.bind("SUPER + L", hl.dsp.focus({ direction = "right" }))

hl.bind("SUPER + SHIFT + I", hl.dsp.window.move({ direction = "up" }))
hl.bind("SUPER + SHIFT + J", hl.dsp.window.move({ direction = "left" }))
hl.bind("SUPER + SHIFT + K", hl.dsp.window.move({ direction = "down" }))
hl.bind("SUPER + SHIFT + L", hl.dsp.window.move({ direction = "right" }))

-- mouse controls
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- media keys
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"))

-- lock screen
hl.bind("XF86Launch1", hl.dsp.exec_cmd("hyprlock"))

-- screenshot
hl.bind("Print", hl.dsp.exec_cmd("hyprshot -m region"))
hl.bind("SUPER + Print", hl.dsp.exec_cmd("hyprshot -m window"))
hl.bind("CTRL + Print", hl.dsp.exec_cmd("hyprshot -m output"))

-- workspaces
for i = 1, 9 do
    local ws = tostring(i)
    hl.bind("SUPER + " .. i, hl.dsp.focus({ workspace = ws }))
    hl.bind("SUPER + SHIFT + " .. i, hl.dsp.window.move({ workspace = ws }))
end