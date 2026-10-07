import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: root
    visible: false
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-clipboard"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property var entries: []   // [{ id, text, line, image }], newest first
    property string query: ""
    property int selected: 0

    readonly property var results: {
        const q = query.trim().toLowerCase();
        return q === "" ? entries : entries.filter(e => e.text.toLowerCase().includes(q));
    }

    // cliphist list prints "<id>\t<preview>" per entry, newest first
    Process {
        id: listProc
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.entries = text.split("\n").filter(l => l !== "").slice(0, 200).map(l => {
                    const tab = l.indexOf("\t");
                    const preview = l.slice(tab + 1);
                    const img = preview.match(/binary data (\S+ \S+) (\w+)/);
                    return {
                        id: l.slice(0, tab),
                        line: l,
                        image: img !== null,
                        text: img ? "Image  ·  " + img[2].toUpperCase() + ", " + img[1] : preview,
                    };
                });
                root.selected = Math.min(root.selected, Math.max(0, root.results.length - 1));
            }
        }
    }

    function reload() {
        listProc.running = false;
        listProc.running = true;
    }

    function open(target) {
        const mon = Hyprland.focusedMonitor;
        screen = target ?? Quickshell.screens.find(s => s.name === mon?.name) ?? Quickshell.screens[0];
        search.text = "";
        selected = 0;
        reload();
        visible = true;
        search.forceActiveFocus();
        openAnim.restart();
    }
    function close() { visible = false }
    function toggle(target) { visible ? close() : open(target) }

    // Put an entry back on the clipboard
    function choose(e) {
        if (!e) return;
        close();
        Quickshell.execDetached(["sh", "-c", 'cliphist decode "$1" | wl-copy', "sh", e.id]);
    }

    function remove(e) {
        if (!e) return;
        Quickshell.execDetached(["sh", "-c", 'printf "%s\\n" "$1" | cliphist delete', "sh", e.line]);
        reloadSoon.restart();
    }

    function clearAll() {
        Quickshell.execDetached(["cliphist", "wipe"]);
        reloadSoon.restart();
    }

    // cliphist runs separately, so give it a moment before listing again
    Timer { id: reloadSoon; interval: 150; onTriggered: root.reload() }

    // Lets Hyprland open it: qs ipc call clipboard toggle
    IpcHandler {
        target: "clipboard"
        function toggle(): void { root.toggle() }
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
        id: box
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.18
        width: 620
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
                    name: "content_paste_search"
                    color: Theme.colors.subtext
                }

                TextInput {
                    id: search
                    anchors {
                        left: searchIcon.right; leftMargin: 10
                        right: clearBtn.left; rightMargin: 10
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
                            root.choose(root.results[root.selected]);
                        } else if (event.key === Qt.Key_Delete && (event.modifiers & Qt.ShiftModifier)) {
                            root.remove(root.results[root.selected]);
                        } else {
                            return;
                        }
                        event.accepted = true;
                    }

                    Text {
                        visible: search.text === ""
                        text: "Search clipboard  ·  Shift+Del removes"
                        color: Theme.colors.subtext
                        font: search.font
                    }
                }

                // Clear the whole history
                MouseArea {
                    id: clearBtn
                    visible: root.entries.length > 0
                    anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                    width: clearLabel.implicitWidth + 16
                    height: 28
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.clearAll()

                    Rectangle {
                        anchors.fill: parent
                        radius: 8
                        color: Theme.colors.surfaceContainerHighest ?? Theme.colors.surfaceContainer
                        opacity: clearBtn.containsMouse ? 1 : 0
                    }
                    Text {
                        id: clearLabel
                        anchors.centerIn: parent
                        text: "Clear all"
                        color: clearBtn.containsMouse ? Theme.colors.text : Theme.colors.subtext
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize.small
                    }
                }
            }

            // Entries
            ListView {
                id: list
                width: parent.width
                height: Math.min(count, 9) * 44
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
                    height: 44
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                    onPositionChanged: root.selected = index
                    onClicked: mouse => {
                        if (mouse.button === Qt.MiddleButton) root.remove(modelData);
                        else root.choose(modelData);
                    }

                    Icon {
                        id: kind
                        anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                        name: row.modelData.image ? "image" : "notes"
                        color: row.current ? Theme.colors.primary : Theme.colors.subtext
                    }

                    Text {
                        anchors {
                            left: kind.right; leftMargin: 12
                            right: parent.right; rightMargin: 12
                            verticalCenter: parent.verticalCenter
                        }
                        // Show multi-line copies on one line
                        text: row.modelData.text.replace(/\s+/g, " ")
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        textFormat: Text.PlainText
                        color: row.current ? Theme.colors.text : Theme.colors.subtext
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize.body
                        font.italic: row.modelData.image
                    }
                }
            }

            Text {
                visible: list.count === 0
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                topPadding: 8
                bottomPadding: 8
                text: root.entries.length === 0 ? "Nothing copied yet" : "No matches"
                color: Theme.colors.subtext
                font.family: Theme.font
                font.pixelSize: Theme.fontSize.body
            }
        }
    }
}
