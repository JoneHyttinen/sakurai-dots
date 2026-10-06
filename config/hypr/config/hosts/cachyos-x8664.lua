-- Monitors
MONITOR1 = "DP-1"
MONITOR2 = "HDMI-A-1"
MONITOR3 = ""
PRIMARY_MONITOR = MONITOR1

hl.monitor({
	output = MONITOR1,
	mode = "1920x1080@144.0",
	position = "auto",
	scale = "auto",
})

hl.monitor({
	output = MONITOR2,
	mode = "1920x1080@60.0",
	position = "auto",
	scale = "auto",
})

-- Hyprland plugins
hl.on("hyprland.start", function()
	hl.exec_cmd("hyprpm reload -n")
end)
