import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets

// SUPER + Tab window switcher, like macOS Cmd+Tab / Windows Alt+Tab.
// Hold SUPER, tap Tab to move along (SHIFT + Tab goes back), let go to switch.
// Hyprland drives it with: qs ipc call switcher next | prev | commit
PanelWindow {
    id: root
    visible: false
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-switcher"
    // Exclusive focus lets us see SUPER being released
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property var windows: []     // [{ address, cls, title, workspace, entry }], most recent first
    property int selected: 0
    property bool loading: false
    property int pendingSteps: 0 // Tab presses that arrived before the window list loaded
    property bool shown: false   // drawn yet? (skipped on a quick tap)

    readonly property var current: windows[selected] ?? null

    // Windows in focus order (0 = the focused one)
    Process {
        id: clientsProc
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                let list = [];
                try { list = JSON.parse(text); } catch (e) {}
                root.windows = list
                    .filter(c => c.mapped && !c.hidden && c.workspace.id !== -1 && c.focusHistoryID >= 0)
                    .sort((a, b) => a.focusHistoryID - b.focusHistoryID)
                    .map(c => {
                        const cls = c.class || c.initialClass;
                        const title = c.title || c.initialTitle || cls;
                        // Games (steam_app_*) are easier to find by their title
                        const entry = DesktopEntries.heuristicLookup(cls)
                            ?? (cls.startsWith("steam_app_") ? DesktopEntries.heuristicLookup(title) : null);
                        return {
                            address: c.address,
                            title: title,
                            workspace: c.workspace.name,
                            name: entry?.name || (cls.startsWith("steam_app_") ? title : cls),
                            icon: root.iconFor(entry, cls),
                        };
                    });
                root.loading = false;
                if (root.windows.length === 0) { root.close(); return; }
                // Start on the window before this one, then apply any extra Tabs
                root.selected = 0;
                root.step(root.pendingSteps);
                root.pendingSteps = 0;
            }
        }
    }

    // First icon the theme actually has, or "" to draw a generic glyph
    function iconFor(entry, cls) {
        const steamId = cls.match(/^steam_app_(\d+)$/)?.[1];
        const names = [entry?.icon, cls, cls.toLowerCase(), steamId ? "steam_icon_" + steamId : null];
        for (const n of names) {
            const path = n ? Quickshell.iconPath(n, true) : "";
            if (path !== "") return path;
        }
        return "";
    }

    // Where the mouse was when the panel opened; hovering only selects after it moves
    property point mouseStart: Qt.point(-1, -1)

    function open(steps) {
        const mon = Hyprland.focusedMonitor;
        screen = Quickshell.screens.find(s => s.name === mon?.name) ?? Quickshell.screens[0];
        windows = [];
        selected = 0;
        mouseStart = Qt.point(-1, -1);
        pendingSteps = steps;
        shown = false;
        loading = true;
        visible = true;
        keys.forceActiveFocus();
        showDelay.restart();
        clientsProc.running = false;
        clientsProc.running = true;
    }

    function close() {
        visible = false;
        shown = false;
        showDelay.stop();
    }

    function step(n) {
        if (windows.length === 0) return;
        selected = ((selected + n) % windows.length + windows.length) % windows.length;
    }

    // Tab / SHIFT + Tab
    function move(n) {
        if (!visible) open(n);
        else if (loading) pendingSteps += n;
        else step(n);
    }

    // Switch to the chosen window and close
    function commit() {
        if (!visible) return;
        if (loading) { pendingSteps = Math.max(pendingSteps, 1); commitWhenLoaded.restart(); return; }
        const w = current;
        close();
        if (w)
            Quickshell.execDetached(["hyprctl", "dispatch", `hl.dsp.focus({ window = "address:${w.address}" })`]);
    }

    // SUPER released before `hyprctl clients` answered: try again shortly
    Timer { id: commitWhenLoaded; interval: 20; onTriggered: root.commit() }

    // Like macOS, a quick SUPER + Tab tap switches without flashing the panel
    Timer { id: showDelay; interval: 120; onTriggered: root.shown = true }

    IpcHandler {
        target: "switcher"
        function next(): void { root.move(1) }
        function prev(): void { root.move(-1) }
        function commit(): void { root.commit() }
        function cancel(): void { root.close() }
    }

    // Keyboard while open
    Item {
        id: keys
        anchors.fill: parent
        focus: true

        Keys.onPressed: event => {
            switch (event.key) {
            case Qt.Key_Tab:
            case Qt.Key_Right:
            case Qt.Key_Down:
                root.move(1); break;
            case Qt.Key_Backtab:
            case Qt.Key_Left:
            case Qt.Key_Up:
                root.move(-1); break;
            case Qt.Key_Return:
            case Qt.Key_Enter:
            case Qt.Key_Space:
                root.commit(); break;
            case Qt.Key_Escape:
                root.close(); break;
            default:
                return;
            }
            event.accepted = true;
        }

        // Letting go of SUPER picks the window
        Keys.onReleased: event => {
            if (event.key === Qt.Key_Super_L || event.key === Qt.Key_Super_R || event.key === Qt.Key_Meta) {
                root.commit();
                event.accepted = true;
            }
        }
    }

    // Clicking outside the panel closes it
    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    Rectangle {
        id: box
        anchors.centerIn: parent
        readonly property int tileSize: 120
        readonly property int pad: 14
        readonly property int rowWidth: root.windows.length * (tileSize + list.spacing) - list.spacing
        readonly property bool overflow: rowWidth > parent.width - 120
        width: Math.min(rowWidth, parent.width - 120) + pad * 2
        height: tileSize + pad * 2 + titleText.height + 10
        radius: 22
        color: Theme.colors.surfaceContainer
        border.width: 1
        border.color: Theme.colors.outlineVariant
        visible: root.windows.length > 0
        opacity: root.shown ? 1 : 0
        scale: root.shown ? 1 : 0.96

        Behavior on opacity { NumberAnimation { duration: 120 } }
        Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

        // Swallow clicks so they don't reach the backdrop
        MouseArea { anchors.fill: parent }

        ListView {
            id: list
            anchors { top: parent.top; left: parent.left; right: parent.right; margins: box.pad }
            height: box.tileSize
            orientation: ListView.Horizontal
            spacing: 6
            clip: true
            interactive: false
            model: root.windows
            currentIndex: root.selected
            highlightMoveDuration: 0
            highlightFollowsCurrentItem: true
            preferredHighlightBegin: width / 2 - box.tileSize / 2
            preferredHighlightEnd: width / 2 + box.tileSize / 2
            highlightRangeMode: box.overflow ? ListView.ApplyRange : ListView.NoHighlightRange

            highlight: Rectangle {
                radius: 16
                color: Theme.colors.surfaceContainerHigh
                border.width: 2
                border.color: Theme.colors.primary
            }

            delegate: MouseArea {
                id: tile
                required property var modelData
                required property int index
                width: box.tileSize
                height: box.tileSize
                hoverEnabled: true
                onPositionChanged: mouse => {
                    const p = mapToItem(null, mouse.x, mouse.y);
                    if (root.mouseStart.x < 0) { root.mouseStart = p; return; }
                    if (Math.abs(p.x - root.mouseStart.x) + Math.abs(p.y - root.mouseStart.y) > 4)
                        root.selected = index;
                }
                onClicked: { root.selected = index; root.commit(); }

                Item {
                    id: icon
                    anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 14 }
                    width: 64
                    height: 64
                    scale: tile.index === root.selected ? 1.06 : 1
                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                    IconImage {
                        anchors.fill: parent
                        visible: tile.modelData.icon !== ""
                        source: tile.modelData.icon
                    }
                    // No icon in the theme: a plain tile with a generic glyph
                    Rectangle {
                        anchors.fill: parent
                        visible: tile.modelData.icon === ""
                        radius: 16
                        color: Theme.colors.surfaceContainerHigh
                        Icon {
                            anchors.centerIn: parent
                            name: "apps"
                            font.pixelSize: 34
                            color: Theme.colors.subtext
                        }
                    }
                }

                // Workspace badge
                Rectangle {
                    anchors { right: icon.right; bottom: icon.bottom; margins: -4 }
                    width: Math.max(20, wsText.implicitWidth + 10)
                    height: 20
                    radius: 10
                    color: Theme.colors.primary
                    Text {
                        id: wsText
                        anchors.centerIn: parent
                        text: tile.modelData.workspace.replace(/^special:/, "S:")
                        color: Theme.colors.primaryText
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize.tiny
                        font.bold: true
                    }
                }

                Text {
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 8; bottomMargin: 10 }
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    text: tile.modelData.name
                    color: tile.index === root.selected ? Theme.colors.text : Theme.colors.subtext
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize.small
                }
            }
        }

        // Full title of the chosen window
        Text {
            id: titleText
            anchors { top: list.bottom; topMargin: 8; left: parent.left; right: parent.right; leftMargin: 20; rightMargin: 20 }
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: root.current?.title ?? ""
            color: Theme.colors.text
            font.family: Theme.font
            font.pixelSize: Theme.fontSize.large
            font.weight: Font.Medium
        }
    }
}
