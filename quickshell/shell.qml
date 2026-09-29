import Quickshell

ShellRoot {
    Launcher { id: appLauncher }

    Variants {
        model: Quickshell.screens
        Bar {}
    }
    Variants {
        model: Quickshell.screens
        Dock { launcher: appLauncher }
    }
    NotificationPopups {}
}
