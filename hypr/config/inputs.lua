-- Input configuration

hl.config({
	input = {
		sensitivity = -0.28,
		accel_profile = "flat",
		kb_layout = "fi",
	},
	-- Uncomment the section below to enable software cursors; this can help with cursor display or behavior issues
	cursor = {
		no_hardware_cursors = true,
		--	no_warps = false,
		--	persistent_warps = true,
	},
})

hl.gesture({ fingers = 4, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 3, direction = "down", action = "close" })
hl.gesture({ fingers = 3, direction = "up", action = "fullscreen" })
hl.gesture({ fingers = 3, direction = "left", action = "float" })

local cursor_hidden = false
local real_cursor_theme = "Bibata-Modern-Classic" -- your normal theme
local cursor_size = 24

hl.bind("SUPER + H", function()
	cursor_hidden = not cursor_hidden
	local theme = cursor_hidden and "invisible" or real_cursor_theme
	hl.dispatch(hl.dsp.exec_cmd("hyprctl setcursor " .. theme .. " " .. cursor_size))
end)
