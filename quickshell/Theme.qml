pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    property alias colors: palette
    readonly property int radius: 12
    readonly property string font: "Inter"

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
            property string outline: "#8e9099"
            property string outlineVariant: "#44474e"
        }
    }
}
