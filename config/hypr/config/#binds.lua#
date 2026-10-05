local mainMod = "SUPER"
local launchPrefix = "uwsm app -- " -- if you are not using UWSM, make this empty (e.g. "")

---------------------------
---- WINDOW MANAGEMENT ----
---------------------------

-- Window manipulation
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + ALT + T", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + D", hl.dsp.window.fullscreen({ mode = 1 }))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))

-- Change focus
hl.bind(mainMod .. " + Left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + Right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + Up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + Down", hl.dsp.focus({ direction = "down" }))
hl.bind("ALT + Tab", hl.dsp.window.cycle_next())

-- Move active window around workspaces & monitors
hl.bind(mainMod .. " + SHIFT + Up", hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + SHIFT + Right", hl.dsp.window.move({ direction = "r" }))
hl.bind(mainMod .. " + SHIFT + Left", hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + SHIFT + Down", hl.dsp.window.move({ direction = "d" }))
hl.bind(mainMod .. " + SHIFT + mouse_up", hl.dsp.window.move({ monitor = "-1" }))
hl.bind(mainMod .. " + SHIFT + mouse_down", hl.dsp.window.move({ monitor = "+1" }))
hl.bind(mainMod .. " + CONTROL + SHIFT + Right", hl.dsp.window.move({ workspace = "m+1" }))
hl.bind(mainMod .. " + CONTROL + SHIFT + Left", hl.dsp.window.move({ workspace = "m-1" }))
hl.bind(mainMod .. " + CONTROL + SHIFT + mouse_up", hl.dsp.window.move({ workspace = "m-1" }))
hl.bind(mainMod .. " + CONTROL + SHIFT + mouse_down", hl.dsp.window.move({ workspace = "m+1" }))

-- Switch workspaces and move windows with numbers

hl.bind(mainMod .. " + ESCAPE", hl.dsp.focus({ workspace = "name:gaming" }))
hl.bind(mainMod .. " + SHIFT + ESCAPE", hl.dsp.window.move({ workspace = "name:gaming" }))

for i = 1, 10 do
	local ws = (i == 10) and 10 or i
	local key = (i == 10) and "0" or tostring(i)

	hl.bind("SUPER + " .. key, function()
		hl.dispatch(hl.dsp.focus({ workspace = ws }))
	end)

	hl.bind("SUPER + SHIFT + " .. key, function()
		hl.dispatch(hl.dsp.window.move({ workspace = ws }))
	end)
end

-- Move & Resize with mouse
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag())
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize())

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
end, { repeating = true })
hl.bind(mainMod .. " + Plus", function()
	zoomfunction(0.3)
end, { repeating = true })

--# Zoom with keypad
hl.bind(mainMod .. " + code:82", function()
	zoomfunction(-0.3)
end, { repeating = true })
hl.bind(mainMod .. " + code:86", function()
	zoomfunction(0.3)
end, { repeating = true })

-- Show the dock on populated workspace

hl.bind(mainMod .. " + ALT + D", hl.dsp.exec_cmd("qs ipc call dock toggle"))

-- Swap all windows between the current workspace and the target workspace
hl.bind(mainMod .. " + CONTROL + SHIFT + 1", hl.dsp.exec_cmd("~/.config/hypr/scripts/swap-workspaces.sh 1"))

hl.bind(mainMod .. " + CONTROL + SHIFT + 2", hl.dsp.exec_cmd("~/.config/hypr/scripts/swap-workspaces.sh 2"))

hl.bind(mainMod .. " + CONTROL + SHIFT + 3", hl.dsp.exec_cmd("~/.config/hypr/scripts/swap-workspaces.sh 3"))

hl.bind(mainMod .. " + CONTROL + SHIFT + 4", hl.dsp.exec_cmd("~/.config/hypr/scripts/swap-workspaces.sh 4"))

hl.bind(mainMod .. " + CONTROL + SHIFT + 5", hl.dsp.exec_cmd("~/.config/hypr/scripts/swap-workspaces.sh 5"))

hl.bind(mainMod .. " + CONTROL + SHIFT + 6", hl.dsp.exec_cmd("~/.config/hypr/scripts/swap-workspaces.sh 6"))

---- LAUNCHER ----
------------------

hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(launchPrefix .. TERMINAL))
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.exec_cmd(launchPrefix .. FILE_MANAGER))
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(launchPrefix .. EDITOR))
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd(launchPrefix .. CALCULATOR))
hl.bind("XF86Calculator", hl.dsp.exec_cmd(launchPrefix .. CALCULATOR))
hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd(launchPrefix .. BROWSER))
hl.bind("CONTROL + SHIFT + Escape", hl.dsp.exec_cmd(launchPrefix .. TERMINAL .. " -e btop"))
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("qs ipc call launcher toggle"))
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("loginctl lock-session"))
hl.bind(mainMod .. " + SHIFT + A", hl.dsp.exec_cmd("easyeffects"))

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
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("hyprpicker -a -n"))
-- Region -> clipboard
hl.bind("Print", hl.dsp.exec_cmd('grim -g "$(slurp)" - | satty -f -'))
-- Region -> file
hl.bind("SHIFT + Print", hl.dsp.exec_cmd('grim -g "$(slurp)" ~/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png'))
-- Full screen -> file
hl.bind("CTRL + Print", hl.dsp.exec_cmd("grim ~/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png"))

-- Theming and Wallpaper
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("qs ipc call wallpaper toggle"))

-- Clipboard

-- Notifications

-- Sidebar
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("qs ipc call sidebar toggle"))

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
	hl.bind(mainMod .. " + ALT + " .. key, hl.dsp.focus({ workspace = i }))
end
-- Relative
for i = 1, NUM_WPM do
	local key = i % 10
	hl.bind(mainMod .. " + CONTROL + " .. key, hl.dsp.focus({ workspace = "m~" .. i }))
end

-- Move to adjacent workspaces and next empty on a given monitor
hl.bind(mainMod .. " + CONTROL + Right", hl.dsp.focus({ workspace = "m+1" }))
hl.bind(mainMod .. " + CONTROL + Left", hl.dsp.focus({ workspace = "m-1" }))
hl.bind(mainMod .. " + CONTROL + Down", hl.dsp.focus({ workspace = "emptym" }))

-- Scroll through existing workspaces & monitors
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "m-1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "m+1" }))
hl.bind(mainMod .. " + CONTROL + mouse_up", hl.dsp.focus({ workspace = "m-1" }))
hl.bind(mainMod .. " + CONTROL + mouse_down", hl.dsp.focus({ workspace = "m+1" }))

-- Special workspace (scratchpad)
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special" }))
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special())
