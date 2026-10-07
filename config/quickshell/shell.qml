import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

ShellRoot {
    Launcher { id: appLauncher }
    ClipboardPicker {}
    WallpaperPicker { id: appWallpaperPicker }
    NotificationPopups {}

    IpcHandler {
        target: "dock"
        function toggle(): void { Panels.dockForced = !Panels.dockForced }
    }

    IpcHandler {
        target: "dashboard"
        function toggle(): void { Panels.dashboardToggle(Hyprland.focusedMonitor?.name ?? "") }
    }

    Variants {
        model: Quickshell.screens
        Frame {}
    }
    Variants {
        model: Quickshell.screens
        Bar { wallpaperPicker: appWallpaperPicker }
    }
    Variants {
        model: Quickshell.screens
        Dock { launcher: appLauncher }
    }
}
