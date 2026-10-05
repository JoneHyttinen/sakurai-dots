import QtQuick
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
    WlrLayershell.namespace: "qs-launcher"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property string query: ""
    property int selected: 0

    // ── Launch counts, saved between sessions ───────────────

    FileView {
        path: Quickshell.env("HOME") + "/.local/state/quickshell/launcher-usage.json"
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) writeAdapter();
        }

        JsonAdapter {
            id: usage
            property var counts: ({})  // desktop entry id -> number of launches
        }
    }

    function uses(app) { return usage.counts[app.id] ?? 0 }

    function recordLaunch(app) {
        // Assign a new object so the change is noticed and saved
        const c = Object.assign({}, usage.counts);
        c[app.id] = (c[app.id] ?? 0) + 1;
        usage.counts = c;
    }

    // ── Apps and ranking ────────────────────────────────────

    readonly property var apps: DesktopEntries.applications.values
        .filter(a => !a.noDisplay)
        .sort((a, b) => a.name.localeCompare(b.name))

    // Most used first, then alphabetical
    readonly property var appsByUsage: apps.slice().sort((a, b) => uses(b) - uses(a))

    // Name match quality, plus a small bonus for apps you launch often
    function score(app, q) {
        const name = app.name.toLowerCase();
        let s = 0;
        if (name === q) s = 100;
        else if (name.startsWith(q)) s = 80;
        else if (name.split(/\s+/).some(w => w.startsWith(q))) s = 60;
        else if (name.includes(q)) s = 40;
        else {
            const extra = [app.genericName, app.comment, String(app.keywords ?? "")].join(" ").toLowerCase();
            s = extra.includes(q) ? 20 : 0;
        }
        return s > 0 ? s + Math.min(15, uses(app)) : 0;
    }

    // ── Calculator ──────────────────────────────────────────

    // Returns a number for simple math like "2+2" or "2^10", otherwise null
    function calculate(text) {
        if (!/^[\d\s+\-*/().,%^]+$/.test(text)) return null;  // only digits and operators
        if (!/\d/.test(text) || !/[+\-*/%^]/.test(text)) return null;
        try {
            const expr = text.replace(/,/g, ".").replace(/\^/g, "**");
            const value = Function("return (" + expr + ")")();
            return Number.isFinite(value) ? Number(value.toPrecision(12)) : null;
        } catch (e) {
            return null;
        }
    }

    // ── Results: a mix of calculator, command and app rows ──

    readonly property var results: {
        const raw = query.trim();

        if (raw.startsWith(">")) {
            const cmd = raw.slice(1).trim();
            return cmd !== "" ? [{ kind: "cmd", cmd: cmd }] : [];
        }

        const out = [];
        const value = calculate(raw);
        if (value !== null) out.push({ kind: "calc", value: value });

        const q = raw.toLowerCase();
        const matched = q === "" ? appsByUsage : apps
            .map(a => ({ app: a, s: score(a, q) }))
            .filter(r => r.s > 0)
            .sort((x, y) => y.s - x.s)
            .map(r => r.app);

        return out.concat(matched.map(a => ({ kind: "app", app: a })));
    }

    function launch(r, inTerminal) {
        if (!r) return;
        close();
        if (r.kind === "app") {
            recordLaunch(r.app);
            r.app.execute();
        } else if (r.kind === "calc") {
            Quickshell.execDetached(["wl-copy", String(r.value)]);
        } else if (r.kind === "cmd") {
            if (inTerminal)
                Quickshell.execDetached(["alacritty", "-e", "sh", "-c", r.cmd + "; exec $SHELL"]);
            else
                Quickshell.execDetached(["sh", "-c", r.cmd]);
        }
    }

    // ── Opening and closing ─────────────────────────────────

    function open(target) {
        const mon = Hyprland.focusedMonitor;
        screen = target ?? Quickshell.screens.find(s => s.name === mon?.name) ?? Quickshell.screens[0];
        search.text = "";
        selected = 0;
        visible = true;
        search.forceActiveFocus();
        openAnim.restart();
    }
    function close() { visible = false }
    function toggle(target) { visible ? close() : open(target) }

    // Lets Hyprland open it: qs ipc call launcher toggle
    IpcHandler {
        target: "launcher"
        function toggle(): void { root.toggle() }
    }

    // Dimmed backdrop; clicking it closes the launcher
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
        id: box
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.22
        width: 560
        height: col.implicitHeight + 24
        radius: 16
        color: Theme.colors.surfaceContainer
        border.width: 1
        border.color: Theme.colors.outlineVariant

        ParallelAnimation {
            id: openAnim
            NumberAnimation { target: box; property: "opacity"; from: 0; to: 1; duration: 160 }
            NumberAnimation { target: box; property: "scale"; from: 0.97; to: 1; duration: 200; easing.type: Easing.OutCubic }
        }

        // Swallow clicks so they don't reach the backdrop
        MouseArea { anchors.fill: parent }

        Column {
            id: col
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
            spacing: 8

            // Search field
            Rectangle {
                width: parent.width
                height: 44
                radius: 12
                color: Theme.colors.surfaceContainerHigh

                Icon {
                    id: searchIcon
                    anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                    name: root.query.trim().startsWith(">") ? "terminal" : "search"
                    color: Theme.colors.subtext
                }

                TextInput {
                    id: search
                    anchors {
                        left: searchIcon.right; leftMargin: 10
                        right: parent.right; rightMargin: 12
                        verticalCenter: parent.verticalCenter
                    }
                    color: Theme.colors.text
                    selectionColor: Theme.colors.primary
                    selectedTextColor: Theme.colors.primaryText
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize.large
                    clip: true

                    onTextChanged: {
                        root.query = text;
                        root.selected = 0;
                        list.positionViewAtBeginning();
                    }

                    Keys.onPressed: event => {
                        const last = root.results.length - 1;
                        if (event.key === Qt.Key_Escape) {
                            root.close();
                        } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab) {
                            root.selected = Math.min(root.selected + 1, last);
                        } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab) {
                            root.selected = Math.max(root.selected - 1, 0);
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            root.launch(root.results[root.selected], event.modifiers & Qt.ShiftModifier);
                        } else {
                            return;
                        }
                        event.accepted = true;
                    }

                    Text {
                        visible: search.text === ""
                        text: "Search apps  ·  2+2  ·  > command"
                        color: Theme.colors.subtext
                        font: search.font
                    }
                }
            }

            // Results
            ListView {
                id: list
                width: parent.width
                height: Math.min(count, 8) * 48
                visible: count > 0
                clip: true
                model: root.results
                currentIndex: root.selected
                boundsBehavior: Flickable.StopAtBounds
                highlightMoveDuration: 100
                onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                highlight: Rectangle {
                    radius: 10
                    color: Theme.colors.surfaceContainerHigh
                }

                delegate: MouseArea {
                    id: row
                    required property var modelData
                    required property int index
                    readonly property bool current: ListView.isCurrentItem
                    readonly property bool isApp: modelData.kind === "app"

                    readonly property string title: isApp ? modelData.app.name
                        : modelData.kind === "calc" ? "= " + modelData.value
                        : modelData.cmd
                    readonly property string subtitle: isApp
                        ? (modelData.app.genericName || modelData.app.comment || "")
                        : modelData.kind === "calc" ? "Enter to copy"
                        : "Run command  ·  Shift+Enter to run in a terminal"

                    width: ListView.view.width
                    height: 48
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    // positionChanged rather than entered, so the selection doesn't
                    // jump when results move under a stationary mouse while typing
                    onPositionChanged: root.selected = index
                    onClicked: mouse => root.launch(modelData, mouse.modifiers & Qt.ShiftModifier)

                    // App icon, or a symbol for calculator/command rows
                    Item {
                        id: iconBox
                        anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                        width: 32
                        height: 32

                        IconImage {
                            visible: row.isApp
                            anchors.fill: parent
                            source: row.isApp ? Quickshell.iconPath(row.modelData.app.icon) : ""
                        }
                        Icon {
                            visible: !row.isApp
                            anchors.centerIn: parent
                            name: row.modelData.kind === "calc" ? "calculate" : "terminal"
                            font.pixelSize: 26
                            color: Theme.colors.primary
                        }
                    }

                    Column {
                        anchors {
                            left: iconBox.right; leftMargin: 12
                            right: parent.right; rightMargin: 10
                            verticalCenter: parent.verticalCenter
                        }
                        spacing: 1

                        Text {
                            width: parent.width
                            text: row.title
                            elide: Text.ElideRight
                            color: row.current ? Theme.colors.primary : Theme.colors.text
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize.medium
                            font.weight: Font.Medium
                        }
                        Text {
                            width: parent.width
                            visible: text !== ""
                            text: row.subtitle
                            elide: Text.ElideRight
                            color: Theme.colors.subtext
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize.tiny
                        }
                    }
                }
            }

            Text {
                visible: list.count === 0
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                topPadding: 8
                bottomPadding: 8
                text: root.query.trim().startsWith(">") ? "Type a command to run" : "No results"
                color: Theme.colors.subtext
                font.family: Theme.font
                font.pixelSize: Theme.fontSize.body
            }
        }
    }
}
