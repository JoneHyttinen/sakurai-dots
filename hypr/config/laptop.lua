-- Laptop-only overrides, loaded from hyprland.lua on the elitebook

hl.config({
	decoration = {
		blur = { enabled = false },
		shadow = { enabled = false },
	},
	input = {
		kb_layout = "fi",
		touchpad = {
			natural_scroll = true,
			disable_while_typing = true,
		},
	},
})

-- Three-finger horizontal swipe switches workspaces
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- Laptop panel
hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = 1.33 })

-- Brightness keys: repeat while held, work on the lock screen
local brightness = { repeating = true, locked = true, description = "Brightness" }
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set 5%+"), brightness)
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), brightness)
