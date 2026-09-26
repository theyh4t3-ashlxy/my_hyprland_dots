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

-- Brain_ShellKeybinds (optional, safely guarded so foreign setups do not explode)
local brain_binds = (os.getenv("HOME") or "") .. "/.config/Brain_Shell/Brain_ShellKeybinds.lua"
local f = io.open(brain_binds, "r")
if f then
	f:close()
	dofile(brain_binds)
end
