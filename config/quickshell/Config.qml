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
    property alias wallpaper: adapter.wallpaper
    property alias performance: adapter.performance
    property alias hyprland: adapter.hyprland
    // True once this machine's settings file has been read, so nothing
    // acts on the default values while it's still loading
    property bool loaded: false

    FileView {
        // One settings file per machine, named after its hostname, so
        // pulling changes from the other machine never overwrites these
        path: Host.name !== "" ? Quickshell.env("HOME") + "/.config/quickshell/settings/" + Host.name + ".json" : ""
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoaded: root.loaded = true
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
            root.loaded = true;
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
                property real panelOpacity: 1.0 // frame and attached panels
                property bool panelBlur: true   // blur behind them, when see-through
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

            property JsonObject wallpaper: JsonObject {
                property string folder: ""            // empty = ~/Pictures/Wallpapers
                property string transition: "grow"
                property real transitionDuration: 1.0  // seconds
                property string scheme: "auto"         // "auto" or a matugen scheme name
                property real monoThreshold: 0.08      // below this, a wallpaper counts as black and white
            }

            property JsonObject performance: JsonObject {
                property bool windowPreviews: true  // live previews when hovering the dock
                property bool mediaBlur: true       // blurred album art in the Media tab
                property bool visualizer: true      // audio waveform in the Media tab
                property int statsInterval: 1000    // ms between system stats readings
            }

            property JsonObject hyprland: JsonObject {
                property int gapsIn: 4
                property int gapsOut: 8
                property int borderSize: 2
                property int rounding: 12
                property bool matchFrame: true     // rounding follows the frame's inner corners
                property real activeOpacity: 1.0
                property real inactiveOpacity: 0.92
                property bool blur: true
                property int blurSize: 6
                property int blurPasses: 3
                property bool shadow: true
                property int shadowRange: 20
                property bool animations: true
                property string animSpeed: "normal"    // "fast", "normal" or "slow"
                property string shadowStyle: "shadow"  // "none", "shadow" or "glow"
                property real glowStrength: 0.6        // 0..1, how opaque the glow is
            }
        }
    }
}
