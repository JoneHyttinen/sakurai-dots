import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Qt5Compat.GraphicalEffects

// One dock icon
component DockItem: MouseArea {
        id: item
        property var entry: null
        property var windows: []
        property string fallbackIcon: ""   // app id, for apps without a desktop entry
        property int cycle: 0
        readonly property string label: entry?.name ?? fallbackIcon
        readonly property string tileIcon: root.tileIcons[entry?.id ?? ""] ?? ""
        readonly property bool running: windows.length > 0

        // Dragging: which group this icon belongs to and where it sits in it
        property string group: ""
        property int groupIndex: -1
        property int groupCount: 0
        property real pressX: 0
        property real dragOffset: 0
        property bool dragging: false
        property bool dragged: false        // suppresses the click after a drag
        readonly property real slot: width + 8  // icon width + row spacing

        transform: Translate { x: item.dragOffset }
        z: dragging ? 10 : 0

        width: 48
        height: 48
        hoverEnabled: true
        preventStealing: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        cursorShape: dragging ? Qt.ClosedHandCursor : Qt.PointingHandCursor

        onContainsMouseChanged: {
            if (containsMouse) {
                root.hovered = item;
                root.previewFor = (windows.length >= 2 && root.menuFor === null && !dragging) ? item : null;
            } else {
                if (root.hovered === item) root.hovered = null;
                previewHide.restart();
            }
        }

        onPressed: mouse => {
            dragged = false;
            // Screen position, so the icon's own movement doesn't skew the drag
            pressX = item.mapToItem(null, mouse.x, mouse.y).x;
        }

        onPositionChanged: mouse => {
            if (!(pressedButtons & Qt.LeftButton) || group === "") return;
            const dx = item.mapToItem(null, mouse.x, mouse.y).x - pressX;
            if (!dragging && Math.abs(dx) > 8) {
                dragging = true;
                dragged = true;
                root.previewFor = null;
            }
            if (dragging) {
                // Stay inside this icon's own group
                const minDx = -groupIndex * slot;
                const maxDx = (groupCount - 1 - groupIndex) * slot;
                dragOffset = Math.max(minDx, Math.min(maxDx, dx));
            }
        }

        onReleased: {
            if (dragging) {
                const target = groupIndex + Math.round(dragOffset / slot);
                root.moveItem(group, groupIndex, target);
            }
            dragging = false;
            dragOffset = 0;
        }

        onClicked: mouse => {
            if (dragged) return;  // that was a drag, not a click
            if (mouse.button === Qt.RightButton) {
                root.openMenu(item);
                return;
            }
            Panels.dockForced = false;
            root.previewFor = null;
            // Middle-click, or nothing running: start the app
            if (mouse.button === Qt.MiddleButton || windows.length === 0) {
                entry?.execute();
                return;
            }
            // Otherwise focus its windows, cycling on repeated clicks
            windows[cycle % windows.length].activate();
            cycle++;
        }

        // Hover background
        Rectangle {
            anchors.fill: parent
            radius: 14
            color: Theme.colors.surfaceContainerHigh
            opacity: item.containsMouse || item.dragging ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }

        // Themed tile
        Rectangle {
            id: tile
            visible: item.tileIcon !== ""
            anchors.centerIn: parent
            width: 38
            height: 38
            radius: 12
            color: item.running ? Theme.colors.primary : Theme.colors.surfaceContainerHigh
            scale: item.dragging ? 1.12 : item.pressed ? 0.9 : (item.containsMouse ? 1.08 : 1)
            Behavior on color { ColorAnimation { duration: 200 } }
            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

            readonly property color glyphColor: item.running ? Theme.colors.primaryText : Theme.colors.text

            // Material Symbol glyph
            Icon {
                visible: item.tileIcon !== "svg"
                anchors.centerIn: parent
                name: item.tileIcon
                font.pixelSize: 38
                color: tile.glyphColor
            }

            // SVG glyph, recolored to the theme; keeps the file's own anti-aliasing
            Image {
                visible: item.tileIcon === "svg"
                anchors.centerIn: parent
                width: 32
                height: 32
                sourceSize: Qt.size(128, 128)
                source: item.tileIcon === "svg" ? Qt.resolvedUrl("icons/" + item.entry.id + ".svg") : ""
                smooth: true
                mipmap: true

                layer.enabled: true
                layer.effect: ColorOverlay { color: tile.glyphColor }
            }
        }

        // Apps without a tile icon keep their normal icon
        IconImage {
            visible: item.tileIcon === ""
            anchors.centerIn: parent
            implicitSize: 36
            source: Quickshell.iconPath(item.entry?.icon || item.fallbackIcon)
            scale: item.dragging ? 1.12 : item.pressed ? 0.9 : (item.containsMouse ? 1.08 : 1)
            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
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

        // Tooltip with the app's name (not while previews, the menu or a drag are showing)
        Rectangle {
            visible: item.containsMouse && item.label !== "" && !item.dragging
                && root.previewFor !== item && root.menuFor !== item
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
