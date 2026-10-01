-- CachyOS Hyprland Configuration

require("config.animations")
require("config.autostart")
require("config.colors")
require("config.decorations")
require("config.variables")
require("config.environment")
require("config.inputs")
require("config.binds")
require("config.misc")
require("config.monitors")
require("config.windowrules")
require("config.workspaces")
require("config.plugins")
require("config.matugen")

local f = io.open("/etc/hostname")
local host = f and f:read("*l") or ""
if f then
	f:close()
end

if host == "elitebook" then
	require("config.laptop")
end
