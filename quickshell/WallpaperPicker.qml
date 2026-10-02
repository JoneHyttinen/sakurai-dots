import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets

PanelWindow {
    id: root
    visible: false
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-wallpapers"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    readonly property string home: Quickshell.env("HOME")
    readonly property string folder: home + "/Pictures/Wallpapers"

    property string current: ""   // wallpaper in use
    property string chosen: ""    // wallpaper clicked in the grid
    property var swatches: []     // candidate theme colors for `chosen`

    function open(target) {
        const mon = Hyprland.focusedMonitor;
        screen = target ?? Quickshell.screens.find(s => s.name === mon?.name) ?? Quickshell.screens[0];
        chosen = "";
        swatches = [];
        currentProc.running = true;
        visible = true;
        panel.forceActiveFocus();
        openAnim.restart();
    }
    function close() { visible = false }
    function toggle(target) { visible ? close() : open(target) }

    function pick(path) {
        chosen = path;
        swatches = [];
        colorsProc.running = false;
        colorsProc.command = ["magick", path, "-resize", "96x96", "-colors", "8",
                              "-format", "%c", "histogram:info:-"];
        colorsProc.running = true;
    }

    function apply(hex) {
        // Full path: Hyprland's PATH may not include ~/.local/bin
        Quickshell.execDetached([home + "/.local/bin/setwall", chosen, hex]);
        current = chosen;
        close();
    }

    // ImageMagick lists colors like "  1234: (r,g,b) #RRGGBB ...".
    // Rank by how common they are, favouring colourful ones over greys.
    function parseColors(text) {
        const found = [];
        for (const line of text.split("\n")) {
            const m = line.match(/^\s*(\d+):.*#([0-9A-Fa-f]{6})/);
            if (!m) continue;
            const hex = "#" + m[2].toLowerCase();
            const r = parseInt(hex.substr(1, 2), 16) / 255;
            const g = parseInt(hex.substr(3, 2), 16) / 255;
            const b = parseInt(hex.substr(5, 2), 16) / 255;
            const max = Math.max(r, g, b), min = Math.min(r, g, b);
            const sat = max === 0 ? 0 : (max - min) / max;
            found.push({ hex: hex, score: parseInt(m[1]) * (0.15 + sat) });
        }
        found.sort((a, b) => b.score - a.score);
        swatches = found.slice(0, 5).map(f => f.hex);
    }

    // Lets Hyprland open it: qs ipc call wallpaper toggle
    IpcHandler {
        target: "wallpaper"
        function toggle(): void { root.toggle() }
    }

    // Which wallpaper is in use (setwall keeps a link to it)
    Process {
        id: currentProc
        command: ["readlink", "-f", root.home + "/.cache/wallpaper"]
        stdout: StdioCollector { onStreamFinished: root.current = text.trim() }
    }

    Process {
        id: colorsProc
        stdout: StdioCollector { onStreamFinished: root.parseColors(text) }
    }

    // Dimmed backdrop; clicking it closes the picker
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: 0.25
    }
    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    Rectangle {
        id: panel
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.14
        width: grid.cellWidth * 4 + 24
        height: col.implicitHeight + 24
        radius: 16
        color: Theme.colors.surfaceContainer
        border.width: 1
        border.color: Theme.colors.outlineVariant

        focus: true
        Keys.onEscapePressed: root.close()

        ParallelAnimation {
            id: openAnim
            NumberAnimation { target: panel; property: "opacity"; from: 0; to: 1; duration: 160 }
            NumberAnimation { target: panel; property: "scale"; from: 0.97; to: 1; duration: 200; easing.type: Easing.OutCubic }
        }

        // Swallow clicks so they don't reach the backdrop
        MouseArea { anchors.fill: parent }

        Column {
            id: col
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
            spacing: 12

            Text {
                leftPadding: 6
                text: "Wallpapers"
                color: Theme.colors.text
                font.family: Theme.font
                font.pixelSize: Theme.fontSize.large
                font.weight: Font.Medium
            }

            GridView {
                id: grid
                width: parent.width
                height: Math.min(Math.ceil(count / 4), 3) * cellHeight
                cellWidth: 216
                cellHeight: 136
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                model: FolderListModel {
                    folder: "file://" + root.folder
                    nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp"]
                    showDirs: false
                }

                delegate: MouseArea {
                    id: thumb
                    required property string filePath
                    required property url fileUrl
                    readonly property bool isChosen: root.chosen === filePath
                    readonly property bool isCurrent: root.current === filePath

                    width: grid.cellWidth
                    height: grid.cellHeight
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.pick(filePath)

                    ClippingRectangle {
                        anchors { fill: parent; margins: 6 }
                        radius: 10
                        color: Theme.colors.surfaceContainerHigh

                        Image {
                            anchors.fill: parent
                            source: thumb.fileUrl
                            sourceSize: Qt.size(320, 200)
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                            scale: thumb.containsMouse ? 1.04 : 1
                            Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        }
                    }

                    // Outline: accent for the one you picked, subtle for the one in use
                    Rectangle {
                        anchors { fill: parent; margins: 6 }
                        radius: 10
                        color: "transparent"
                        border.width: thumb.isChosen ? 3 : thumb.isCurrent ? 2 : 0
                        border.color: thumb.isChosen ? Theme.colors.primary : Theme.colors.outline
                    }
                }
            }

            Text {
                visible: grid.count === 0
                leftPadding: 6
                text: "No wallpapers found in " + root.folder
                color: Theme.colors.subtext
                font.family: Theme.font
                font.pixelSize: Theme.fontSize.body
            }

            // Theme color choice for the picked wallpaper
            Row {
                visible: root.chosen !== ""
                leftPadding: 6
                spacing: 10

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.swatches.length > 0 ? "Pick an accent color:" : "Reading colors…"
                    color: Theme.colors.subtext
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize.body
                }

                Repeater {
                    model: root.swatches
                    delegate: MouseArea {
                        id: sw
                        required property string modelData
                        anchors.verticalCenter: parent.verticalCenter
                        width: 36
                        height: 36
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.apply(modelData)

                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: sw.modelData
                            border.width: sw.containsMouse ? 3 : 1
                            border.color: sw.containsMouse ? Theme.colors.text : Theme.colors.outlineVariant
                            scale: sw.pressed ? 0.9 : (sw.containsMouse ? 1.1 : 1)
                            Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                        }
                    }
                }
            }
        }
    }
}
