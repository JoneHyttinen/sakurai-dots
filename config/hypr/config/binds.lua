local mainMod = "SUPER"
local launchPrefix = "uwsm app -- " -- if you are not using UWSM, make this empty (e.g. "")

---------------------------
---- WINDOW MANAGEMENT ----
---------------------------

-- Window manipulation
hl.bind(mainMod .. " + Q", hl.dsp.window.close(), { description = "Close Window" })
hl.bind(mainMod .. " + ALT + T", hl.dsp.window.float({ action = "toggle" }), { description = "Toggle Floating" })
hl.bind(mainMod .. " + D", hl.dsp.window.fullscreen({ mode = 1 }), { description = "Maximize Window" })
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen(), { description = "Toggle Fullscreen" })
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"), { description = "Toggle Split Direction" })

-- Change focus
hl.bind(mainMod .. " + Left", hl.dsp.focus({ direction = "left" }), { description = "Focus Window Left" })
hl.bind(mainMod .. " + Right", hl.dsp.focus({ direction = "right" }), { description = "Focus Window Right" })
hl.bind(mainMod .. " + Up", hl.dsp.focus({ direction = "up" }), { description = "Focus Window Up" })
hl.bind(mainMod .. " + Down", hl.dsp.focus({ direction = "down" }), { description = "Focus Window Down" })
hl.bind("ALT + Tab", hl.dsp.window.cycle_next(), { description = "Cycle Windows" })

-- Move active window around workspaces & monitors
hl.bind(mainMod .. " + SHIFT + Up", hl.dsp.window.move({ direction = "u" }), { description = "Move Window Up" })
hl.bind(mainMod .. " + SHIFT + Right", hl.dsp.window.move({ direction = "r" }), { description = "Move Window Right" })
hl.bind(mainMod .. " + SHIFT + Left", hl.dsp.window.move({ direction = "l" }), { description = "Move Window Left" })
hl.bind(mainMod .. " + SHIFT + Down", hl.dsp.window.move({ direction = "d" }), { description = "Move Window Down" })
hl.bind(mainMod .. " + SHIFT + mouse_up", hl.dsp.window.move({ monitor = "-1" }), { description = "Move Window to Previous Monitor" })
hl.bind(mainMod .. " + SHIFT + mouse_down", hl.dsp.window.move({ monitor = "+1" }), { description = "Move Window to Next Monitor" })
hl.bind(mainMod .. " + CONTROL + SHIFT + Right", hl.dsp.window.move({ workspace = "m+1" }), { description = "Move Window to Next Workspace" })
hl.bind(mainMod .. " + CONTROL + SHIFT + Left", hl.dsp.window.move({ workspace = "m-1" }), { description = "Move Window to Previous Workspace" })
hl.bind(mainMod .. " + CONTROL + SHIFT + mouse_up", hl.dsp.window.move({ workspace = "m-1" }), { description = "Move Window to Previous Workspace (Scroll)" })
hl.bind(mainMod .. " + CONTROL + SHIFT + mouse_down", hl.dsp.window.move({ workspace = "m+1" }), { description = "Move Window to Next Workspace (Scroll)" })

-- Switch workspaces and move windows with numbers

hl.bind(
	mainMod .. " + ESCAPE",
	hl.dsp.focus({ workspace = "name:gaming" }),
	{ description = "Focus on Gaming Workspace" }
)
hl.bind(
	mainMod .. " + SHIFT + ESCAPE",
	hl.dsp.window.move({ workspace = "name:gaming" }),
	{ description = "Move to Gaming Workspace" }
)

for i = 1, 10 do
	local ws = (i == 10) and 10 or i
	local key = (i == 10) and "0" or tostring(i)

	hl.bind("SUPER + " .. key, function()
		hl.dispatch(hl.dsp.focus({ workspace = ws }))
	end, { description = "Focus on Workspace " .. key })

	hl.bind("SUPER + SHIFT + " .. key, function()
		hl.dispatch(hl.dsp.window.move({ workspace = ws }))
	end, { description = "Move Window to Workspace " .. key })
end

-- Move & Resize with mouse
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { description = "Move Window With Mouse" })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { description = "Resize Window With Mouse" })

-- Zoom
local function zoomfunction(value)
	local zoomvalue = hl.get_config("cursor:zoom_factor")
	if (zoomvalue + value) > 3.0 then
		hl.config({ cursor = { zoom_factor = 3.0 } })
	elseif (zoomvalue + value) < 1.0 then
		hl.config({ cursor = { zoom_factor = 1.0 } })
	else
		hl.config({ cursor = { zoom_factor = zoomvalue + value } })
	end
end
hl.bind(mainMod .. " + Minus", function()
	zoomfunction(-0.3)
end, { repeating = true, description = "Zoom Out" })
hl.bind(mainMod .. " + Plus", function()
	zoomfunction(0.3)
end, { repeating = true, description = "Zoom In" })

--# Zoom with keypad
hl.bind(mainMod .. " + code:82", function()
	zoomfunction(-0.3)
end, { repeating = true, description = "Zoom Out With Keypad" })
hl.bind(mainMod .. " + code:86", function()
	zoomfunction(0.3)
end, { repeating = true, description = "Zoom In With Keypad" })

-- Show the dock on populated workspace

hl.bind(mainMod .. " + ALT + D", hl.dsp.exec_cmd("qs ipc call dock toggle"), { description = "Toggle Dock" })

-- Swap all windows between the current workspace and the target workspace
hl.bind(
	mainMod .. " + CONTROL + SHIFT + 1",
	hl.dsp.exec_cmd("~/.config/hypr/scripts/swap-workspaces.sh 1"),
	{ description = "Swap All Windows Between Current Workspace and Workspace 1" }
)

hl.bind(
	mainMod .. " + CONTROL + SHIFT + 2",
	hl.dsp.exec_cmd("~/.config/hypr/scripts/swap-workspaces.sh 2"),
	{ description = "Swap All Windows Between Current Workspace and Workspace 2" }
)

hl.bind(
	mainMod .. " + CONTROL + SHIFT + 3",
	hl.dsp.exec_cmd("~/.config/hypr/scripts/swap-workspaces.sh 3"),
	{ description = "Swap All Windows Between Current Workspace and Workspace 3" }
)

hl.bind(
	mainMod .. " + CONTROL + SHIFT + 4",
	hl.dsp.exec_cmd("~/.config/hypr/scripts/swap-workspaces.sh 4"),
	{ description = "Swap All Windows Between Current Workspace and Workspace 4" }
)

hl.bind(
	mainMod .. " + CONTROL + SHIFT + 5",
	hl.dsp.exec_cmd("~/.config/hypr/scripts/swap-workspaces.sh 5"),
	{ description = "Swap All Windows Between Current Workspace and Workspace 5" }
)

hl.bind(
	mainMod .. " + CONTROL + SHIFT + 6",
	hl.dsp.exec_cmd("~/.config/hypr/scripts/swap-workspaces.sh 6"),
	{ description = "Swap All Windows Between Current Workspace and Workspace 6" }
)

---- LAUNCHER ----
------------------

hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(launchPrefix .. TERMINAL), { description = "Terminal" })
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.exec_cmd(launchPrefix .. FILE_MANAGER), { description = "File Manager" })
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(launchPrefix .. EDITOR), { description = "Text Editor" })
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd(launchPrefix .. CALCULATOR), { description = "Calculator" })
hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd(launchPrefix .. BROWSER), { description = "Browser" })
hl.bind(
	"CONTROL + SHIFT + Escape",
	hl.dsp.exec_cmd(launchPrefix .. TERMINAL .. " -e btop"),
	{ description = "Activity Monitor" }
)
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("qs ipc call launcher toggle"), { description = "Application Launcher" })
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("loginctl lock-session"), { description = "Lock PC" })
hl.bind(mainMod .. " + SHIFT + A", hl.dsp.exec_cmd("easyeffects"), { description = "Audio Control (EasyEffects)" })

---------------------------
---- HARDWARE CONTROLS ----
---------------------------

-- Audio

-- Media

-- Brightness

-------------------
---- UTILITIES ----
-------------------

-- Color Picker
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("hyprpicker -a -n"), { description = "Color picker" })
-- Region -> clipboard
hl.bind("Print", hl.dsp.exec_cmd('grim -g "$(slurp)" - | satty -f -'), { description = "Region to clipboard (Print)" })
-- Region -> file
hl.bind(
	"SHIFT + Print",
	hl.dsp.exec_cmd('grim -g "$(slurp)" ~/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png'),
	{ description = "Region to file (Print)" }
)
-- Full screen -> file
hl.bind(
	"CTRL + Print",
	hl.dsp.exec_cmd("grim ~/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png"),
	{ description = "Screen to file (Print)" }
)

-- Theming and Wallpaper
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("qs ipc call wallpaper toggle"), { description = "Wallpaper picker" })

-- Clipboard history
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("qs ipc call clipboard toggle"), { description = "Show Clipboard history" })

-- Notifications

-- Dashboard
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("qs ipc call dashboard toggle"), { description = "Show Dashboard" })

-- Settings
hl.bind(mainMod .. " + comma", hl.dsp.exec_cmd("qs ipc call settings toggle"), { description = "Show settings" })

-- Show shortcuts
hl.bind(mainMod .. " + K", hl.dsp.exec_cmd("qs ipc call keybinds toggle"), { description = "Show keybinds" })

-------------------------------
---- WORKSPACES & MONITORS ----
-------------------------------

-- Focus on monitors
-- hl.bind(mainMod .. " + 1", hl.dsp.focus({ monitor = MONITOR1 }))
-- hl.bind(mainMod .. " + 2", hl.dsp.focus({ monitor = MONITOR2 }))
-- hl.bind(mainMod .. " + 3", hl.dsp.focus({ monitor = MONITOR3 }))

-- Focus on workspace number
-- Absolute
for i = 1, NUM_WPM do
	local key = i % 10
	hl.bind(
		mainMod .. " + ALT + " .. key,
		hl.dsp.focus({ workspace = i }),
		{ description = "Focus on Workspace " .. key .. " (Absolute)" }
	)
end
-- Relative
for i = 1, NUM_WPM do
	local key = i % 10
	hl.bind(
		mainMod .. " + CONTROL + " .. key,
		hl.dsp.focus({ workspace = "m~" .. i }),
		{ description = "Focus on Workspace " .. key .. " of Current Monitor" }
	)
end

-- Move to adjacent workspaces and next empty on a given monitor
hl.bind(
	mainMod .. " + CONTROL + Right",
	hl.dsp.focus({ workspace = "m+1" }),
	{ description = "Focus Next Workspace on Monitor" }
)
hl.bind(
	mainMod .. " + CONTROL + Left",
	hl.dsp.focus({ workspace = "m-1" }),
	{ description = "Focus Previous Workspace on Monitor" }
)
hl.bind(
	mainMod .. " + CONTROL + Down",
	hl.dsp.focus({ workspace = "emptym" }),
	{ description = "Focus Empty Workspace on Monitor" }
)

-- Scroll through existing workspaces & monitors
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "m-1" }), { description = "Previous Workspace on Monitor (Scroll)" })
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "m+1" }), { description = "Next Workspace on Monitor (Scroll)" })
-- hl.bind(mainMod .. " + CONTROL + mouse_up", hl.dsp.focus({ workspace = "m-1" }))
-- hl.bind(mainMod .. " + CONTROL + mouse_down", hl.dsp.focus({ workspace = "m+1" }))

-- Special workspace (scratchpad)
hl.bind(
	mainMod .. " + SHIFT + S",
	hl.dsp.window.move({ workspace = "special" }),
	{ description = "Move Window to Scratchpad" }
)
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special(), { description = "Scratchpad (Special Workspace)" })
