-- imagine using 1366x768 in 2026 man.. unless u have a chromebook, shit aint cutting it.

hl.monitor({
    output = "eDP-1",
    mode = "1920x1200@60",
    position = "0x0",
    scale = 1,
    vrr = 1,
    cm = "srgb",
})

-- for the dual monitor setups or when i actually decide to hook up to a tv
-- hl.monitor({
--     output = "HDMI-A-1",
--     mode = "preferred",
--     position = "auto-right",
--     scale = 1,
-- })