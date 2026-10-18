pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// User settings, saved in config/quickshell/settings.json (shared by both machines)
Singleton {
    id: root
    property alias appearance: adapter.appearance
    property alias notifications: adapter.notifications
    property alias dock: adapter.dock
    property alias bar: adapter.bar

    FileView {
        path: Quickshell.env("HOME") + "/.config/quickshell/settings.json"
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
        }

        JsonAdapter {
            id: adapter

            // Defaults, used until settings.json has a value
            property JsonObject appearance: JsonObject {
                property string font: "Geist"
                property real fontScale: 1.25
                property int radius: 12
                property int frameTop: 40
                property int frameSide: 8
                property int frameRadius: 20
            }

            property JsonObject notifications: JsonObject {
                property int timeout: 5          // seconds
                property int maxPopups: 5
                property string screen: "primary" // "primary" or "focused"
                property bool keepCritical: true
            }

            property JsonObject dock: JsonObject {
                property string mode: "empty"  // "empty", "always" or "never"
                property bool showRunning: true
                property bool showMemory: true
                property bool themedTiles: true
            }

            property JsonObject bar: JsonObject {
                property string timeFormat: "24h"       // "24h" or "12h"
                property bool showSeconds: false
                property bool showDate: true
                property string dateFormat: "ddd d MMM"
                property string workspaceStyle: "numbers" // "numbers" or "dots"
                property bool showGaming: true
                property bool showScratchpad: true
                property bool showTray: true
                property bool showVolume: true
                property bool showNetwork: true
                property bool showNotifications: true
                property bool showBattery: true
                property bool showDashboardButton: true
            }
        }
    }
}
