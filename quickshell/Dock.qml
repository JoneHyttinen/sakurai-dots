import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets

PanelWindow {
    id: root
    required property var modelData
    screen: modelData

    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(modelData)
    readonly property var workspace: monitor?.activeWorkspace ?? null
    readonly property bool emptyWorkspace: workspace !== null && workspace.toplevels.values.length === 0
    // SUPER + D shows it on the focused monitor, over windows
    readonly property bool forced: Panels.dockForced && Hyprland.focusedMonitor?.name === modelData.name
    readonly property bool shown: emptyWorkspace || forced

    // Pinned apps, saved to disk (see DockPins.qml)
    readonly property var pinned: DockPins.ids

    // Themed tile icons: a Material Symbol name, or "svg" for icons/<id>.svg.
    // Apps not listed here keep their normal icon.
    readonly property var tileIcons: ({
        "firefox": "svg",
        "Alacritty": "terminal",
        "org.kde.dolphin": "folder",
        "steam": "svg",
        "spotify": "svg",
        "discord": "svg",
    })

    // Set from shell.qml; the dock's "all apps" button opens it
    property var launcher: null

    anchors { bottom: true; left: true; right: true }
    implicitHeight: 300  // room above the dock for tooltips, previews and the menu
    color: "transparent"
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 0  // sit above the frame's bottom band, without reserving space
    WlrLayershell.namespace: "qs-dock"
    mask: Region {
        item: dock
        Region { item: previews.visible ? previews : null }
        Region { item: menu.visible ? menu : null }
    }

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

    // ── Hover previews ───────────────────────────────────────

    property var hovered: null      // dock icon under the mouse
    property var previewFor: null   // dock icon whose window previews are showing

    // Short delay, so the mouse can travel from the icon into the previews
    Timer {
        id: previewHide
        interval: 250
        onTriggered: if (!root.hovered && !previewHover.hovered) root.previewFor = null
    }

    // ── Right-click menu ─────────────────────────────────────

    property var menuFor: null  // dock icon whose right-click menu is open

    function openMenu(it) {
        previewFor = null;
        menuFor = it;
        menuGrabDelay.restart();
    }
    function closeMenu() {
        menuFor = null;
        menuGrab.active = false;
    }
    onShownChanged: if (!shown) closeMenu()

    // Close the menu when clicking anywhere else
    HyprlandFocusGrab {
        id: menuGrab
        windows: [root]
        onCleared: root.closeMenu()
    }
    Timer {
        id: menuGrabDelay
        interval: 50
        onTriggered: menuGrab.active = root.menuFor !== null
    }

    // Menu entries for a dock icon; { separator: true } draws a divider
    function menuItems(it) {
        const out = [];
        const e = it.entry;

        if (e) {
            for (const a of Array.from(e.actions ?? []))
                out.push({ icon: "arrow_outward", label: a.name, run: () => a.execute() });
            out.push({ icon: "add", label: "New window", run: () => e.execute() });
        }

        if (it.windows.length >= 2) {
            out.push({ separator: true });
            for (const w of it.windows)
                out.push({ icon: "select_window", label: w.title || "Window", run: () => w.activate() });
        }

        if (it.windows.length > 0 || e) out.push({ separator: true });

        if (it.windows.length > 0) {
            out.push({
                icon: "close",
                label: it.windows.length > 1 ? "Close all windows" : "Close window",
                run: () => it.windows.forEach(w => w.close()),
            });
        }
        if (e) {
            const isPinned = DockPins.isPinned(e.id);
            out.push({
                icon: isPinned ? "keep_off" : "keep",
                label: isPinned ? "Unpin" : "Pin to dock",
                run: () => DockPins.toggle(e.id),
            });
        }
        return out;
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
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        onContainsMouseChanged: {
            if (containsMouse) {
                root.hovered = item;
                root.previewFor = (windows.length >= 2 && root.menuFor === null) ? item : null;
            } else {
                if (root.hovered === item) root.hovered = null;
                previewHide.restart();
            }
        }

        onClicked: mouse => {
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
            opacity: item.containsMouse ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }

        // Themed tile
        Rectangle {
            id: tile
            visible: item.tileIcon !== ""
            anchors.centerIn: parent
            width: 40
            height: 40
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

        // Tooltip with the app's name (not while previews or the menu are showing)
        Rectangle {
            visible: item.containsMouse && item.label !== "" && root.previewFor !== item && root.menuFor !== item
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
                        // ── Memory ──
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 1
                height: 32
                color: Theme.colors.outlineVariant
            }

            MouseArea {
                id: mem
                anchors.verticalCenter: parent.verticalCenter
                width: 48
                height: 48
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    Panels.dockForced = false;
                    Quickshell.execDetached(["alacritty", "-e", "btop"]);
                }

                readonly property real value: SystemStats.memPercent
                readonly property string ringColor: value > 0.85 ? Theme.colors.error : Theme.colors.primary
                readonly property string trackColor: Theme.colors.surfaceContainerHigh

                // Redraw the ring when the value or theme colors change
                onValueChanged: ring.requestPaint()
                onRingColorChanged: ring.requestPaint()
                onTrackColorChanged: ring.requestPaint()

                Rectangle {
                    anchors.fill: parent
                    radius: 14
                    color: Theme.colors.surfaceContainerHigh
                    opacity: mem.containsMouse ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }

                Canvas {
                    id: ring
                    anchors.centerIn: parent
                    width: 38
                    height: 38
                    antialiasing: true
                    onAvailableChanged: if (available) requestPaint()

                    onPaint: {
                        const ctx = getContext("2d");
                        const c = width / 2;
                        const r = c - 3;
                        const start = -Math.PI / 2;  // 12 o'clock

                        ctx.reset();
                        ctx.lineWidth = 4;
                        ctx.lineCap = "round";

                        // Track
                        ctx.strokeStyle = mem.trackColor;
                        ctx.beginPath();
                        ctx.arc(c, c, r, 0, 2 * Math.PI);
                        ctx.stroke();

                        // Usage
                        ctx.strokeStyle = mem.ringColor;
                        ctx.beginPath();
                        ctx.arc(c, c, r, start, start + 2 * Math.PI * mem.value);
                        ctx.stroke();
                    }
                }

                Text {
                    anchors.centerIn: ring
                    text: Math.round(mem.value * 100) + "%"
                    color: Theme.colors.text
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize.tiny
                    font.weight: Font.Medium
                }

                // Tooltip with the exact numbers
                Rectangle {
                    visible: mem.containsMouse
                    anchors { bottom: parent.top; bottomMargin: 14; horizontalCenter: parent.horizontalCenter }
                    width: memTip.implicitWidth + 16
                    height: 24
                    radius: 8
                    color: Theme.colors.surface
                    border.width: 1
                    border.color: Theme.colors.outlineVariant

                    Text {
                        id: memTip
                        anchors.centerIn: parent
                        text: "Memory  ·  " + SystemStats.gib(SystemStats.memUsed)
                            + " / " + SystemStats.gib(SystemStats.memTotal) + " GB"
                        color: Theme.colors.text
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize.small
                    }
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

    // ── Right-click menu ─────────────────────────────────────

    Rectangle {
        id: menu
        readonly property var target: root.menuFor
        readonly property var items: target ? root.menuItems(target) : []
        // Never taller than the space above the dock
        readonly property real maxHeight: dock.y - 20

        visible: target !== null && root.shown
        width: 250
        height: Math.min(menuCol.implicitHeight + 16, maxHeight)
        radius: Theme.radius
        color: Theme.colors.surface
        border.width: 1
        border.color: Theme.colors.outlineVariant

        // Centred above the icon, kept on screen
        x: target ? Math.max(8, Math.min(root.width - width - 8,
                target.mapToItem(null, target.width / 2, 0).x - width / 2)) : 0
        y: dock.y - height - 10

        // Scrolls when the menu has more entries than fit
        Flickable {
            anchors { fill: parent; margins: 8 }
            contentHeight: menuCol.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: menuCol
                width: parent.width
                spacing: 2

                Text {
                    width: parent.width
                    leftPadding: 10
                    topPadding: 4
                    bottomPadding: 4
                    text: menu.target?.label ?? ""
                    elide: Text.ElideRight
                    color: Theme.colors.subtext
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize.small
                    font.weight: Font.Medium
                }

                Repeater {
                    model: menu.items
                    delegate: Item {
                        id: entry
                        required property var modelData
                        width: menuCol.width
                        height: modelData.separator ? 9 : 36

                        Rectangle {
                            visible: entry.modelData.separator === true
                            anchors.centerIn: parent
                            width: parent.width - 16
                            height: 1
                            color: Theme.colors.outlineVariant
                        }

                        MenuRow {
                            visible: entry.modelData.separator !== true
                            anchors.fill: parent
                            icon: entry.modelData.icon ?? ""
                            label: entry.modelData.label ?? ""
                            onClicked: {
                                entry.modelData.run();
                                root.closeMenu();
                                Panels.dockForced = false;
                            }
                        }
                    }
                }
            }
        }
    }
}
