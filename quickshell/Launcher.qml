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

    readonly property var apps: DesktopEntries.applications.values
        .filter(a => !a.noDisplay)
        .sort((a, b) => a.name.localeCompare(b.name))

    readonly property var results: {
        const q = query.trim().toLowerCase();
        if (q === "") return apps;
        return apps
            .map(a => ({ app: a, score: score(a, q) }))
            .filter(r => r.score > 0)
            .sort((x, y) => y.score - x.score)
            .map(r => r.app);
    }

    // Simple ranking: exact name > name prefix > word prefix > substring > description/keywords
    function score(app, q) {
        const name = app.name.toLowerCase();
        if (name === q) return 100;
        if (name.startsWith(q)) return 80;
        if (name.split(/\s+/).some(w => w.startsWith(q))) return 60;
        if (name.includes(q)) return 40;
        const extra = [app.genericName, app.comment, String(app.keywords ?? "")].join(" ").toLowerCase();
        return extra.includes(q) ? 20 : 0;
    }

    function open() {
        const mon = Hyprland.focusedMonitor;
        screen = Quickshell.screens.find(s => s.name === mon?.name) ?? Quickshell.screens[0];
        search.text = "";
        selected = 0;
        visible = true;
        search.forceActiveFocus();
        openAnim.restart();
    }
    function close() { visible = false }
    function toggle() { visible ? close() : open() }
    function launch(app) {
        if (!app) return;
        close();
        app.execute();
    }

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
                    name: "search"
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
                    font.pixelSize: 15
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
                            root.launch(root.results[root.selected]);
                        } else {
                            return;
                        }
                        event.accepted = true;
                    }

                    Text {
                        visible: search.text === ""
                        text: "Search apps…"
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
                    width: ListView.view.width
                    height: 48
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    // positionChanged rather than entered, so the selection doesn't
                    // jump when results move under a stationary mouse while typing
                    onPositionChanged: root.selected = index
                    onClicked: root.launch(modelData)

                    IconImage {
                        id: appIcon
                        anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                        implicitSize: 32
                        source: Quickshell.iconPath(row.modelData.icon)
                    }

                    Column {
                        anchors {
                            left: appIcon.right; leftMargin: 12
                            right: parent.right; rightMargin: 10
                            verticalCenter: parent.verticalCenter
                        }
                        spacing: 1

                        Text {
                            width: parent.width
                            text: row.modelData.name
                            elide: Text.ElideRight
                            color: row.current ? Theme.colors.primary : Theme.colors.text
                            font.family: Theme.font
                            font.pixelSize: 14
                            font.weight: Font.Medium
                        }
                        Text {
                            width: parent.width
                            readonly property string desc: row.modelData.genericName || row.modelData.comment || ""
                            visible: desc !== ""
                            text: desc
                            elide: Text.ElideRight
                            color: Theme.colors.subtext
                            font.family: Theme.font
                            font.pixelSize: 11
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
                text: "No results"
                color: Theme.colors.subtext
                font.family: Theme.font
                font.pixelSize: 13
            }
        }
    }
}
