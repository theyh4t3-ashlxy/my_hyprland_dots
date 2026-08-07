-- # config: the brain of the operation
-- if this file breaks, the whole house of cards comes down.
-- handle with care, or don't. i'm not your boss.

-- fallback colors in case matugen hasn't run yet and our desktop looks like a sad concrete slab
local colors = {
	active_border_1 = "rgba(95CDF7ff)",
	active_border_2 = "rgba(2BB0F6ff)",
	inactive_border = "rgba(41474Dff)",
}

-- do not touch. do not breathe near this. do not make sudden eye contact.
-- if matugen breaks, we will literally lose the only thing tethering our sanity to this computer: pretty dynamic colors.
local ok, user_colors = pcall(require, "colors")
if ok and type(user_colors) == "table" then
	if user_colors.active_border_1 then colors.active_border_1 = user_colors.active_border_1 end
	if user_colors.active_border_2 then colors.active_border_2 = user_colors.active_border_2 end
	if user_colors.inactive_border then colors.inactive_border = user_colors.inactive_border end
end

hl.config({
	general = {
		-- gaps are just empty space for the soul to breathe (or to peek at our wallpaper)
		gaps_out = 10,
		border_size = 2,

		-- the colors that don't make me want to throw my laptop out the window
		col = {
			-- gradient with 2 colors and 50 degree angle
			active_border = {
				colors = { colors.active_border_1, colors.active_border_2 },
				angle = 50,
			},
			-- lua requires gradient syntax even for single colors
			inactive_border = {
				colors = { colors.inactive_border, colors.inactive_border },
				angle = 0,
			},
		},
	},

	animations = {
		-- animations are true because we love buttery-smooth frame drops
		enabled = true,
	},

	decoration = {
		-- 16px round corners because sharp edges are a hazard to my health
		rounding = 16, 
		-- 2.0 is a circle, 4.0 is a squircle. keeping it at 2.0 because squircles sound like a weird custom plugin that crashed wayland
		rounding_power = 2.0,  
		dim_inactive = false,
		shadow = {
			render_power = 4,
		},
		blur = {
			-- look, hyprmod enabled blur. so yes we are doing blur now. if my thinkpad explodes because of 2 passes of blur, so be it
			enabled = true,
			size = 4,
			passes = 2,
			new_optimizations = true,
			ignore_opacity = true,
			xray = false,
			noise = 0.015,
			contrast = 1.0,
			vibrancy = 0.15,
			popups = false,
		},
	},

	ecosystem = {
		-- ecosystem permissions is false because we are not a security analyst, we just want our custom stuff to run without crying
		enforce_permissions = false,
	},

	input = {
		touchpad = {
			-- disable while typing is false because we like living on the edge and typing on a laptop trackpad without palm rejection is a true test of strength (or to play roblox)
			disable_while_typing = false,
		},
	},

	misc = {
		force_default_wallpaper = 1,
		-- thank god we can disable the classic anime mascot wallpaper from staring into our soul
		disable_hyprland_logo = true,
		disable_splash_rendering = true,
	},

	xwayland = {
		enabled = true,
		-- force zero scaling is false so electron apps don't turn into a blurry, pixelated soup from 2005
		force_zero_scaling = false,
		use_nearest_neighbor = false,
	},
})