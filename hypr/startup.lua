-- autostart stuff that runs when hyprland starts

local wp = "awww-daemon --format argb"
local qs = "quickshell"
local idle = "hypridle"
hl.on("hyprland.start", function()
	hl.exec_cmd(wp)
	hl.exec_cmd(qs)
	hl.exec_cmd(idle)
end)
