import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import Qt5Compat.GraphicalEffects

PanelWindow {
    id: root
    required property var modelData
    screen: modelData

    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(modelData)
    readonly property var workspace: monitor?.activeWorkspace ?? null
    readonly property bool emptyWorkspace: workspace !== null && workspace.toplevels.values.length === 0
    // SUPER + ALT + D shows it on the focused monitor, over windows
    readonly property bool forced: Panels.dockForced && Hyprland.focusedMonitor?.name === modelData.name
    readonly property bool shown: emptyWorkspace || forced

    // Desktop entry IDs: the .desktop file name without the extension
    readonly property var pinned: [
        "firefox-developer-edition",
        "Alacritty",
        "org.kde.dolphin",
        "steam",
        "spotify",
        "discord",
    ]

    // Themed tile icons: a Material Symbol name, or "svg" for icons/<id>.svg.
    // Apps not listed here keep their normal icon.
    readonly property var tileIcons: ({
        "firefox-developer-edition": "svg",
        "Alacritty": "terminal",
        "org.kde.dolphin": "folder",
        "steam": "svg",
        "spotify": "svg",
        "discord": "svg",
    })

    // Set from shell.qml; the dock's "all apps" button opens it
    property var launcher: null

    anchors { bottom: true; left: true; right: true }
    implicitHeight: 300  // room above the dock for tooltips
    color: "transparent"
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 0  // sit above the frame's bottom band, without reserving space
    WlrLayershell.namespace: "qs-dock"
    mask: Region { 
      item: dock
      Region { item: previews.visible ? previews : null }
    }  // only the dock itself takes clicks

    // ── Matching windows to apps ─────────────────────────────

    // "org.kde.dolphin" and "Org-KDE-Dolphin" both become "orgkdedolphin"
    function norm(s) {
        return (s ?? "").toLowerCase().replace(/[^a-z0-9]/g, "");
    }

    // Open windows that belong to a desktop entry
    function windowsFor(entry) {
        if (!entry) return [];
        const keys = [entry.id, entry.startupClass, entry.name].map(norm).filter(k => k !== "");
        return ToplevelManager.toplevels.values.filter(t => keys.includes(norm(t.appId)));
    }

    readonly property var pinnedEntries: {
        DesktopEntries.applications.values;  // re-run once .desktop files are scanned
        return pinned.map(id => DesktopEntries.byId(id)).filter(e => e !== null);
    }

    // Running apps that aren't pinned, one per app
    readonly property var running: {
        const claimed = new Set();
        for (const e of pinnedEntries)
            for (const w of windowsFor(e)) claimed.add(w);

        const seen = new Set();
        const out = [];
        for (const t of ToplevelManager.toplevels.values) {
            const key = norm(t.appId);
            if (key === "" || claimed.has(t) || seen.has(key)) continue;
            seen.add(key);
            out.push({ appId: t.appId, entry: DesktopEntries.heuristicLookup(t.appId) });
        }
        return out;
    }

    property var hovered: null
    property var previewFor: null

    // Short delay, so the mouse can travel from the icon into the previews
    Timer {
        id: previewHide
        interval: 250
        onTriggered: if (!root.hovered && !previewHover.hovered) root.previewFor = null
    }

    // ── One dock icon ────────────────────────────────────────

    component DockItem: MouseArea {
        id: item
        property var entry: null
        property var windows: []
        property string fallbackIcon: ""   // app id, for apps without a desktop entry
        property int cycle: 0
        readonly property string label: entry?.name ?? fallbackIcon
        readonly property string tileIcon: root.tileIcons[entry?.id ?? ""] ?? ""
        readonly property bool running: windows.length > 0

        width: 48
        height: 48
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor

        onContainsMouseChanged: {
            if (containsMouse) {
                root.hovered = item;
                root.previewFor = windows.length >= 2 ? item : null;
            } else {
                if (root.hovered === item) root.hovered = null;
                previewHide.restart();
            }
        }

        onClicked: mouse => {
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

        Rectangle {
            anchors.fill: parent
            radius: 14
            color: Theme.colors.surfaceContainerHigh
            opacity: item.containsMouse ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 150 } }
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
            scale: item.pressed ? 0.9 : (item.containsMouse ? 1.08 : 1)
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

        // Apps without a tile icon keep their normal icon
        IconImage {
            visible: item.tileIcon === ""
            anchors.centerIn: parent
            implicitSize: 36
            source: Quickshell.iconPath(item.entry?.icon || item.fallbackIcon)
            scale: item.pressed ? 0.9 : (item.containsMouse ? 1.08 : 1)
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

        // Tooltip with the app's name (not while previews are showing)
        Rectangle {
            visible: item.containsMouse && item.label !== "" && root.previewFor !== item
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

    // ── The dock ─────────────────────────────────────────────

    Item {
        id: dock
        anchors.horizontalCenter: parent.horizontalCenter
        width: row.implicitWidth + 20 + Theme.frame.radius * 2
        height: 64

        // Flush against the frame when shown; slides down into it when hidden
        y: root.shown ? parent.height - height : parent.height
        Behavior on y { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }

        FramePanel {
            anchors.fill: parent
            edge: "bottom"
        }

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 8

            // All apps (launcher)
            MouseArea {
                id: launcherButton
                visible: root.launcher !== null
                anchors.verticalCenter: parent.verticalCenter
                width: 48
                height: 48
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.launcher.toggle(root.screen)

                Rectangle {
                    anchors.fill: parent
                    radius: 14
                    color: Theme.colors.surfaceContainerHigh
                    opacity: launcherButton.containsMouse ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
                Icon {
                    anchors.centerIn: parent
                    name: "apps"
                    font.pixelSize: 28
                    color: Theme.colors.primary
                    scale: launcherButton.pressed ? 0.9 : (launcherButton.containsMouse ? 1.08 : 1)
                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                }
            }

            Rectangle {
                visible: root.launcher !== null
                anchors.verticalCenter: parent.verticalCenter
                width: 1
                height: 32
                color: Theme.colors.outlineVariant
            }

            // Pinned apps
            Repeater {
                model: root.pinnedEntries
                delegate: DockItem {
                    required property var modelData
                    anchors.verticalCenter: parent.verticalCenter
                    entry: modelData
                    windows: root.windowsFor(modelData)
                }
            }

            // Running apps that aren't pinned
            Rectangle {
                visible: root.running.length > 0
                anchors.verticalCenter: parent.verticalCenter
                width: 1
                height: 32
                color: Theme.colors.outlineVariant
            }

            Repeater {
                model: root.running
                delegate: DockItem {
                    required property var modelData
                    anchors.verticalCenter: parent.verticalCenter
                    entry: modelData.entry
                    fallbackIcon: modelData.appId
                    windows: ToplevelManager.toplevels.values.filter(t => root.norm(t.appId) === root.norm(modelData.appId))
                }
            }
        }
    }
    
    // ── Window previews ──────────────────────────────────────

    Rectangle {
        id: previews
        readonly property var target: root.previewFor

        visible: target !== null && root.shown
        width: previewRow.implicitWidth + 16
        height: previewRow.implicitHeight + 16
        radius: Theme.radius
        color: Theme.colors.surface
        border.width: 1
        border.color: Theme.colors.outlineVariant

        // Centred above the hovered icon, kept on screen
        x: target ? Math.max(8, Math.min(root.width - width - 8,
                target.mapToItem(null, target.width / 2, 0).x - width / 2)) : 0
        y: dock.y - height - 10

        HoverHandler {
            id: previewHover
            onHoveredChanged: if (!hovered) previewHide.restart()
        }

        Row {
            id: previewRow
            anchors.centerIn: parent
            spacing: 8

            Repeater {
                model: previews.target ? previews.target.windows : []
                delegate: MouseArea {
                    id: pv
                    required property var modelData  // a window
                    width: 220
                    height: shot.height + title.height + 16
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        modelData.activate();
                        root.previewFor = null;
                        Panels.dockForced = false;
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: 10
                        color: Theme.colors.surfaceContainerHigh
                        opacity: pv.containsMouse ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 120 } }
                    }

                    ScreencopyView {
                        id: shot
                        anchors { top: parent.top; topMargin: 6; horizontalCenter: parent.horizontalCenter }
                        captureSource: pv.modelData
                        live: true
                        constraintSize: Qt.size(208, 130)
                    }

                    Text {
                        id: title
                        anchors {
                            top: shot.bottom; topMargin: 4
                            left: parent.left; leftMargin: 8
                            right: parent.right; rightMargin: 8
                        }
                        text: pv.modelData.title
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                        color: Theme.colors.text
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize.small
                    }
                }
            }
        }
    }
}
