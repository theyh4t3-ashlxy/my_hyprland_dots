-- gestures.lua
-- laptop touchpad gestures
-- hyprnightmare edition

-- 3-finger horizontal swipe to switch workspaces (Handles left/right 1:1)
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- 3-finger swipe up for fullscreen
hl.gesture({
    fingers = 3,
    direction = "up",
    action = "fullscreen"
})

-- 3-finger swipe down to close active window
hl.gesture({
    fingers = 3,
    direction = "down",
    action = "close"
})

-- 4-finger swipe up to open a terminal
hl.gesture({
    fingers = 4,
    direction = "up",
    action = function()
        hl.exec_cmd("kitty")
    end
})

-- 4-finger swipe down to toggle your specific scratchpad workspace
hl.gesture({
    fingers = 4,
    direction = "down",
    action = "special",
    workspace_name = "scratchpad",
    disable_inhibit = true
})