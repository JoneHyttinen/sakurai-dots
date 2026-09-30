import Quickshell

ShellRoot {
    Launcher { id: appLauncher }
    Sidebar { id: appSidebar }
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
}
