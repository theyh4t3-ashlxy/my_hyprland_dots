-- autostart stuff that runs when hyprland starts

local wp = "awww-daemon --format argb"
local idle = "hypridle"
hl.on("hyprland.start", function()
	hl.exec_cmd(wp)
	hl.exec_cmd("/home/ashley/.local/bin/qs-switch restore")
	hl.exec_cmd(idle)
end)
