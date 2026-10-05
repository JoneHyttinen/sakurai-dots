pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property alias colors: palette
    readonly property int radius: 12
    readonly property string font: "Geist"

    readonly property QtObject frame: QtObject {
        readonly property int top: 40     // the bar's height; the top band of the frame
        readonly property int side: 8     // left, right and bottom bands
        readonly property int radius: 20  // inner corners of the frame
    }

    // Change this one number to scale all UI text
    readonly property real fontScale: 1.25

    readonly property QtObject fontSize: QtObject {
        readonly property int tiny:   Math.round(11 * root.fontScale)
        readonly property int small:  Math.round(12 * root.fontScale)
        readonly property int body:   Math.round(13 * root.fontScale)
        readonly property int medium: Math.round(14 * root.fontScale)
        readonly property int large:  Math.round(15 * root.fontScale)
    }

    FileView {
        path: Quickshell.env("HOME") + "/.cache/matugen/quickshell.json"
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            id: palette
            // fallbacks until matugen has run
            property string background: "#111318"
            property string surface: "#111318"
            property string surfaceContainer: "#1d2024"
            property string surfaceContainerHigh: "#282a2f"
            property string text: "#e2e2e9"
            property string subtext: "#c4c6d0"
            property string primary: "#aac7ff"
            property string primaryText: "#0a305f"
            property string secondary: "#bec6dc"
            property string outline: "#8e9099"
            property string outlineVariant: "#44474e"
        }
  }

    // Light/dark mode, as last applied by setwall
    readonly property bool dark: themeInfo.mode !== "light"

    function toggleMode() {
        const next = dark ? "light" : "dark";
        Quickshell.execDetached(["sh", "-c",
            'mkdir -p "$HOME/.local/state" && printf %s "$1" > "$HOME/.local/state/theme-mode" '
            + '&& "$HOME/.local/bin/setwall" "$HOME/.cache/wallpaper" "$2"',
            "sh", next, themeInfo.color]);
    }

    FileView {
        path: Quickshell.env("HOME") + "/.cache/theme-state.json"
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            id: themeInfo
            property string mode: "dark"
            property string color: ""
        }
    }
}
