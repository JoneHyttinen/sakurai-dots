pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Machine-specific settings, picked by hostname
Singleton {
    id: root
    property string name: ""

    readonly property var hosts: ({
        "cachyos-x8664": {
            primaryMonitor: "DP-1",
            laptop: false,
        },
        "LAPTOP-HOSTNAME": {
            primaryMonitor: "eDP-1",
            laptop: true,
        },
    })

    readonly property var settings: hosts[name] ?? { primaryMonitor: "", laptop: false }
    readonly property string primaryMonitor: settings.primaryMonitor
    readonly property bool laptop: settings.laptop

    FileView {
        path: "/etc/hostname"
        onLoaded: root.name = text().trim()
    }
}
