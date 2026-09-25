-- Monitors
hl.monitor({
    output = "eDP-1",
    disabled = false,
    mode = "1920x1200@60",
    position = "0x0",
    scale = 1,
    cm = "srgb",
})

hl.monitor({
    output = "HDMI-A-1",
    disabled = false,
    mode = "1920x1080@60",
    position = "auto-left",
    scale = 1,
    transform = 0,
    cm = "srgb",
    vrr = 0,
})
