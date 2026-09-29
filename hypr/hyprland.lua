-- the bare essentials so the system doesn't explode immediately the second i log in

require("config")
require("colors")
require("monitors")
require("anims")
require("binds")
require("startup")
require("rules")
require("gestures")

-- HyprMod managed settings
require("hyprmod")

-- Brain_ShellKeybinds (only loaded when brain_shell is the active shell)
local cache_file = (os.getenv("XDG_CACHE_HOME") or ((os.getenv("HOME") or "") .. "/.cache")) .. "/current_shell"
local cf = io.open(cache_file, "r")
local cur_shell = cf and cf:read("*l")
if cf then cf:close() end
if cur_shell and cur_shell:match("^%s*brain_shell%s*$") then
	local brain_binds = (os.getenv("HOME") or "") .. "/.config/Brain_Shell/Brain_ShellKeybinds.lua"
	local f = io.open(brain_binds, "r")
	if f then
		f:close()
		dofile(brain_binds)
	end
end
