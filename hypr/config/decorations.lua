-- Look and feel configuration
-- Border colors come from config/matugen.lua (generated from the wallpaper)

hl.config({
	general = {
		gaps_in = 6,
		gaps_out = 8,
		border_size = 2,
		extend_border_grab_area = 10,
		resize_on_border = true,
	},
	decoration = {
		rounding = 12, -- matches Theme.radius in Quickshell
		rounding_power = 2,
		dim_special = 0.3,
		active_opacity = 1.0,
		inactive_opacity = 0.92,
		fullscreen_opacity = 1,
		shadow = {
			enabled = true,
			range = 20,
			render_power = 3,
			color = "rgba(0000004d)",
		},
		blur = {
			size = 6,
			passes = 3,
			noise = 0.02,
			vibrancy = 0.2,
			special = true,
		},
	},
})
