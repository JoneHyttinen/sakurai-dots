-- CachyOS Hyprland Configuration

require("config.animations")
require("config.autostart")
require("config.colors")
require("config.decorations")
require("config.variables")

-- Machine-specific settings: config/hosts/<hostname>.lua (or hosts/default.lua)
do
	local f = io.open("/etc/hostname")
	local host = f and f:read("*l") or "default"
	if f then
		f:close()
	end

	local path = os.getenv("HOME") .. "/.config/hypr/config/hosts/" .. host .. ".lua"
	local exists = io.open(path)
	if exists then
		exists:close()
		require("config.hosts." .. host)
	else
		require("config.hosts.default")
	end
end

require("config.environment")
require("config.inputs")
require("config.binds")
require("config.misc")
require("config.windowrules")
require("config.workspaces")
require("config.plugins")
require("config.matugen")

if host == "elitebook" then
	require("config.laptop")
end
