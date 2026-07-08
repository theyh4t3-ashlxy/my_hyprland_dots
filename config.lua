-- # config: the brain of the operation
-- if this file breaks, the whole house of cards comes down.
-- handle with care, or don't. i'm not your boss.

-- fallback colors in case matugen hasn't run yet
local colors = {
	active_border_1 = "rgba(95CDF7ff)",
	active_border_2 = "rgba(2BB0F6ff)",
	inactive_border = "rgba(41474Dff)",
}

-- try to load matugen colors (if they exist)
local ok, user_colors = pcall(require, "colors")
if ok and type(user_colors) == "table" then
	if user_colors.active_border_1 then colors.active_border_1 = user_colors.active_border_1 end
	if user_colors.active_border_2 then colors.active_border_2 = user_colors.active_border_2 end
	if user_colors.inactive_border then colors.inactive_border = user_colors.inactive_border end
end

hl.config({
	general = {
		-- gaps are just empty space for the soul to breathe
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

	decoration = {
		rounding = 16, 
		rounding_power = 2.0,  -- 2.0 = circle, 4.0 = squircle
		blur = {
			enabled = false,
		}
	},

	misc = {
		force_default_wallpaper = 1,
		disable_hyprland_logo = true,
	},
})