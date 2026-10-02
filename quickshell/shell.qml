import Quickshell
import Quickshell.Io

ShellRoot {
    Launcher { id: appLauncher }
    WallpaperPicker { id: appWallpaperPicker }
    Sidebar { 
      id: appSidebar 
      wallpaperPicker: appWallpaperPicker
    }
    NotificationPopups {}

    Variants {
      model: Quickshell.screens
      Frame {}
    }

    Variants {
        model: Quickshell.screens
        Bar { sidebar: appSidebar }
    }

    Variants {
        model: Quickshell.screens
        Dock { launcher: appLauncher }
    }

    IpcHandler {
      target: "dock"
      function toggle(): void { Panels.dockForced = !Panels.dockForced }
    }
}
