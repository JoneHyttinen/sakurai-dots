-- Laptop: one built-in screen
MONITOR1 = "eDP-1"
MONITOR2 = ""
MONITOR3 = ""
PRIMARY_MONITOR = MONITOR1

hl.monitor({
	output = MONITOR1,
	mode = "1920x1080@60.01",
	position = "auto",
	scale = "auto",
})

-- Brightness keys, with the on-screen indicator
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("qs ipc call brightness up"))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("qs ipc call brightness down"))

-- Touchpad
hl.config({
	input = {
		touchpad = {
			natural_scroll = true,
			tap_to_click = true,
		},
	},
})

-- Three fingers left/right: switch workspaces (the content follows your fingers)
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- Three fingers up: open the dashboard
hl.gesture({
	fingers = 3,
	direction = "up",
	action = function()
		hl.exec_cmd("qs ipc call dashboard toggle")
	end,
})
