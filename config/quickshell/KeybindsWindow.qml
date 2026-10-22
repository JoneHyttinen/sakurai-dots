import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

FloatingWindow {
    id: win
    title: "Keybinds"
    visible: false
    implicitWidth: 800
    implicitHeight: 640
    color: Theme.colors.surface

    property var binds: []
    property string query: ""

    // Hyprland's modifier bits, in the order they're usually written
    readonly property var mods: [[64, "SUPER"], [4, "CTRL"], [8, "ALT"], [1, "SHIFT"]]

    function prettyKey(k) {
        const names = {
            "Return": "Enter",
            "escape": "Esc",
            "Escape": "Esc",
            "space": "Space",
            "slash": "/",
            "comma": ",",
            "period": ".",
            "minus": "-",
            "equal": "=",
            "mouse:272": "Left click",
            "mouse:273": "Right click",
            "mouse_down": "Scroll down",
            "mouse_up": "Scroll up",
            "left": "←",
            "right": "→",
            "up": "↑",
            "down": "↓"
        };
        return names[k] ?? (k.length === 1 ? k.toUpperCase() : k);
    }

    function keysOf(b) {
        const out = mods.filter(m => b.modmask & m[0]).map(m => m[1]);
        if (b.key)
            out.push(prettyKey(b.key));
        return out;
    }

    readonly property var filtered: {
        const q = query.trim().toLowerCase();
        return q === "" ? binds : binds.filter(b => b.search.includes(q));
    }
    readonly property var described: filtered.filter(b => b.description !== "")
    readonly property var undescribed: filtered.filter(b => b.description === "")

    // ── Opening and closing ──────────────────────────────

    // Hyprland's window list says whether it's really open; Quickshell's
    // `visible` can still read true after the window was closed by Hyprland
    function isOpen() {
        return ToplevelManager.toplevels.values.some(t => t.title === "Keybinds");
    }
    function open() {
        search.text = "";
        loader.running = true;
        visible = false;
        visible = true;
        search.forceActiveFocus();
    }
    function close() {
        visible = false;
    }

    // qs ipc call keybinds toggle
    IpcHandler {
        target: "keybinds"
        function toggle(): void {
            win.isOpen() ? win.close() : win.open();
        }
    }

    // ── Reading the binds ────────────────────────────────

    Process {
        id: loader
        command: ["hyprctl", "binds", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    win.binds = JSON.parse(text).map(b => {
                        const keys = win.keysOf(b);
                        const description = b.has_description ? (b.description ?? "") : "";
                        const action = [b.dispatcher, b.arg].filter(s => s).join("  ");
                        return {
                            keys: keys,
                            description: description,
                            action: action,
                            search: (keys.join(" ") + " " + description + " " + action).toLowerCase()
                        };
                    }).sort((a, b) => a.description.localeCompare(b.description));
                } catch (e) {
                    win.binds = [];
                }
            }
        }
    }

    // ── One bind ─────────────────────────────────────────

    component BindRow: Item {
        id: row
        required property var bind
        width: parent ? parent.width : 600
        height: 44

        Rectangle {
            anchors.fill: parent
            radius: 10
            color: Theme.colors.surfaceContainer
            opacity: hover.hovered ? 1 : 0
        }
        HoverHandler {
            id: hover
        }

        // Keycaps
        Row {
            id: caps
            anchors {
                left: parent.left
                leftMargin: 12
                verticalCenter: parent.verticalCenter
            }
            width: 280
            spacing: 4

            Repeater {
                model: row.bind.keys
                delegate: Rectangle {
                    required property string modelData
                    anchors.verticalCenter: parent.verticalCenter
                    width: capText.implicitWidth + 16
                    height: 26
                    radius: 7
                    color: Theme.colors.surfaceContainerHigh
                    border.width: 1
                    border.color: Theme.colors.outlineVariant

                    Text {
                        id: capText
                        anchors.centerIn: parent
                        text: modelData
                        color: Theme.colors.text
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize.small
                        font.weight: Font.Medium
                    }
                }
            }
        }

        // What it does
        Text {
            anchors {
                left: caps.right
                leftMargin: 12
                right: parent.right
                rightMargin: 12
                verticalCenter: parent.verticalCenter
            }
            text: row.bind.description !== "" ? row.bind.description : row.bind.action
            elide: Text.ElideRight
            color: row.bind.description !== "" ? Theme.colors.text : Theme.colors.subtext
            font.family: row.bind.description !== "" ? Theme.font : "monospace"
            font.pixelSize: Theme.fontSize.body
        }
    }

    component SectionTitle: Text {
        leftPadding: 4
        topPadding: 8
        color: Theme.colors.subtext
        font.family: Theme.font
        font.pixelSize: Theme.fontSize.small
        font.weight: Font.Medium
    }

    // ── Layout ───────────────────────────────────────────

    Column {
        id: header
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 20
        }
        spacing: 14

        Row {
            spacing: 10
            Icon {
                anchors.verticalCenter: parent.verticalCenter
                name: "keyboard"
                font.pixelSize: 26
                color: Theme.colors.primary
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Keybinds"
                color: Theme.colors.text
                font.family: Theme.font
                font.pixelSize: Math.round(22 * Theme.fontScale)
                font.weight: Font.Bold
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: win.filtered.length + (win.query !== "" ? " matching" : "")
                color: Theme.colors.subtext
                font.family: Theme.font
                font.pixelSize: Theme.fontSize.body
            }
        }

        // Search
        Rectangle {
            width: parent.width
            height: 42
            radius: 12
            color: Theme.colors.surfaceContainerHigh

            Icon {
                id: searchIcon
                anchors {
                    left: parent.left
                    leftMargin: 12
                    verticalCenter: parent.verticalCenter
                }
                name: "search"
                color: Theme.colors.subtext
            }
            TextInput {
                id: search
                anchors {
                    left: searchIcon.right
                    leftMargin: 10
                    right: parent.right
                    rightMargin: 12
                    verticalCenter: parent.verticalCenter
                }
                color: Theme.colors.text
                font.family: Theme.font
                font.pixelSize: Theme.fontSize.large
                clip: true
                onTextChanged: win.query = text
                Keys.onEscapePressed: win.close()

                Text {
                    visible: search.text === ""
                    text: "Search by key or action…"
                    color: Theme.colors.subtext
                    font: search.font
                }
            }
        }
    }

    Flickable {
        anchors {
            left: parent.left
            right: parent.right
            top: header.bottom
            bottom: parent.bottom
            margins: 20
            topMargin: 12
        }
        contentHeight: list.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: list
            width: parent.width
            spacing: 2

            Repeater {
                model: win.described
                delegate: BindRow {
                    required property var modelData
                    bind: modelData
                }
            }

            SectionTitle {
                visible: win.undescribed.length > 0
                text: "Not described yet"
            }

            Repeater {
                model: win.undescribed
                delegate: BindRow {
                    required property var modelData
                    bind: modelData
                }
            }

            Text {
                visible: win.filtered.length === 0
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                topPadding: 40
                text: win.binds.length === 0 ? "Reading binds…" : "No binds match"
                color: Theme.colors.subtext
                font.family: Theme.font
                font.pixelSize: Theme.fontSize.body
            }
        }
    }
}
