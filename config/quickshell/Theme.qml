pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property alias colors: palette

    readonly property int radius: Config.appearance.radius
    readonly property string font: Config.appearance.font
    readonly property real fontScale: Config.appearance.fontScale

    readonly property QtObject fontSize: QtObject {
        readonly property int tiny: Math.round(11 * root.fontScale)
        readonly property int small: Math.round(12 * root.fontScale)
        readonly property int body: Math.round(13 * root.fontScale)
        readonly property int medium: Math.round(14 * root.fontScale)
        readonly property int large: Math.round(15 * root.fontScale)
    }

    readonly property QtObject frame: QtObject {
        readonly property int top: Config.appearance.frameTop
        readonly property int side: Config.appearance.frameSide
        readonly property int radius: Config.appearance.frameRadius
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

    // "auto", "light" or "dark", as saved per machine
    property string modePref: "auto"

    FileView {
        path: Quickshell.env("HOME") + "/.local/state/theme-mode"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.modePref = text().trim() || "auto"
        onLoadFailed: root.modePref = "auto"
    }

    // Run setwall again on the current wallpaper, keeping its accent color
    function reapply() {
        Quickshell.execDetached(["sh", "-c", '"$HOME/.local/bin/setwall" "$HOME/.cache/wallpaper" "$1"', "sh", themeInfo.color]);
    }

    function setModePreference(p) {
        root.modePref = p;
        Quickshell.execDetached(["sh", "-c", 'mkdir -p "$HOME/.local/state"; ' + 'if [ "$1" = auto ]; then rm -f "$HOME/.local/state/theme-mode"; ' + 'else printf %s "$1" > "$HOME/.local/state/theme-mode"; fi; ' + '"$HOME/.local/bin/setwall" "$HOME/.cache/wallpaper" "$2"', "sh", p, themeInfo.color]);
    }

    // The dashboard's light/dark tile
    function toggleMode() {
        setModePreference(dark ? "light" : "dark");
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
