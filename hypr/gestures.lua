-- touchpad gestures because trackpad life is real

-- 4-finger swipe left/right to switch workspaces
hl.gesture({ fingers = 4, direction = "horizontal", action = "workspace" })

-- 3-finger swipe down to close active window
hl.gesture({ fingers = 3, direction = "down", action = "close" })

-- 4-finger swipe up to toggle notifications
-- (taps aren't natively supported, so swipe up is the next best thing)
hl.gesture({
	fingers = 4,
	direction = "up",
	action = function()
		hl.exec_cmd("qs ipc call notifs toggle")
	end,
})
