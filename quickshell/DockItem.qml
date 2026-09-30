import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Qt5Compat.GraphicalEffects

// One dock icon
MouseArea {
    id: item
    required property var dock              // the Dock window: hover/preview state, tile icons
    property var entry: null
    property var windows: []
    property string fallbackIcon: ""   // app id, for apps without a desktop entry
    property int cycle: 0
    readonly property string label: entry?.name ?? fallbackIcon
    readonly property string tileIcon: dock.tileIcons[entry?.id ?? ""] ?? ""
    readonly property bool running: windows.length > 0

    width: 48
    height: 48
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
    cursorShape: Qt.PointingHandCursor

    onContainsMouseChanged: {
        if (containsMouse) {
            dock.hovered = item;
            dock.previewFor = windows.length >= 2 ? item : null;
        } else {
            if (dock.hovered === item) dock.hovered = null;
            dock.schedulePreviewHide();
        }
    }

    onClicked: mouse => {
        Panels.dockForced = false;
        dock.previewFor = null;
        // Middle-click, or nothing running: start the app
        if (mouse.button === Qt.MiddleButton || windows.length === 0) {
            entry?.execute();
            return;
        }
        // Otherwise focus its windows, cycling on repeated clicks
        windows[cycle % windows.length].activate();
        cycle++;
    }

    Rectangle {
        anchors.fill: parent
        radius: 14
        color: Theme.colors.surfaceContainerHigh
        opacity: item.containsMouse ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }

    // Every icon is drawn through this effect; only the colorization changes.
    // Running apps keep their own colors, idle pins are recolored to the theme.
    Item {
        id: icon
        anchors.fill: parent
        scale: item.pressed ? 0.9 : (item.containsMouse ? 1.08 : 1)
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

        layer.enabled: true
        layer.smooth: true
        layer.effect: MultiEffect {
            colorizationColor: Theme.colors.secondary
            // Tiles tint their own glyph instead, so the tile background stays clean
            colorization: item.running || item.tileIcon !== "" ? 0 : 1
            Behavior on colorization { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        }

        // Themed tile
        Rectangle {
            id: tile
            visible: item.tileIcon !== ""
            anchors.centerIn: parent
            width: 42
            height: 42
            radius: 12
            color: item.running ? Theme.colors.primary : Theme.colors.surfaceContainerHigh
            Behavior on color { ColorAnimation { duration: 200 } }

            readonly property color glyphColor: item.running ? Theme.colors.primaryText : Theme.colors.secondary

            // Material Symbol glyph
            Icon {
                visible: item.tileIcon !== "svg"
                anchors.centerIn: parent
                name: item.tileIcon
                font.pixelSize: 40
                color: tile.glyphColor
            }

            // SVG glyph, recolored to the theme; keeps the file's own anti-aliasing
            Image {
                visible: item.tileIcon === "svg"
                anchors.centerIn: parent
                width: 34
                height: 34
                sourceSize: Qt.size(128, 128)
                source: item.tileIcon === "svg" ? Qt.resolvedUrl("icons/" + item.entry.id + ".svg") : ""
                smooth: true
                mipmap: true

                // Render the mask at 4x and keep mipmaps, so it scales down cleanly
                layer.enabled: true
                layer.effect: ColorOverlay { color: tile.glyphColor }
            }
        }

        // Apps without a tile icon use their normal icon
        IconImage {
            visible: item.tileIcon === ""
            anchors.centerIn: parent
            implicitSize: 36
            source: Quickshell.iconPath(item.entry?.icon || item.fallbackIcon, "application-x-executable")
        }
    }

    // Running indicator: one dot per window, up to three
    Row {
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: -4 }
        spacing: 3

        Repeater {
            model: Math.min(item.windows.length, 3)
            delegate: Rectangle {
                width: 4
                height: 4
                radius: 2
                color: Theme.colors.primary
            }
        }
    }

    // Tooltip with the app's name (not while previews are showing)
    Rectangle {
        visible: item.containsMouse && item.label !== "" && dock.previewFor !== item
        anchors { bottom: parent.top; bottomMargin: 14; horizontalCenter: parent.horizontalCenter }
        width: tip.implicitWidth + 16
        height: 24
        radius: 8
        color: Theme.colors.surface
        border.width: 1
        border.color: Theme.colors.outlineVariant

        Text {
            id: tip
            anchors.centerIn: parent
            text: item.label
            color: Theme.colors.text
            font.family: Theme.font
            font.pixelSize: Theme.fontSize.small
        }
    }
}
