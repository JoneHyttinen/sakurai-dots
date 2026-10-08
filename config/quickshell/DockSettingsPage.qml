import QtQuick
import Quickshell
import Quickshell.Widgets

Column {
    id: page
    spacing: 20

    // Pinned entries, refreshed once .desktop files are scanned
    readonly property var pinnedEntries: {
        DesktopEntries.applications.values;
        return DockPins.ids.map(id => ({
                    id: id,
                    entry: DesktopEntries.byId(id)
                }));
    }

    function move(from, to) {
        const ids = DockPins.ids.slice();
        if (to < 0 || to >= ids.length)
            return;
        const [moved] = ids.splice(from, 1);
        ids.splice(to, 0, moved);
        DockPins.setOrder(ids);
    }

    // A small round icon button
    component IconButton: MouseArea {
        id: ib
        property string icon
        property bool danger: false
        width: 30
        height: 30
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        opacity: enabled ? 1 : 0.3

        Rectangle {
            anchors.fill: parent
            radius: 8
            color: ib.danger ? Theme.colors.error : Theme.colors.surfaceContainerHighest ?? Theme.colors.surfaceContainerHigh
            opacity: ib.containsMouse ? 1 : 0
        }
        Icon {
            anchors.centerIn: parent
            name: ib.icon
            font.pixelSize: 18
            color: ib.danger && ib.containsMouse ? Theme.colors.surface : Theme.colors.subtext
        }
    }

    SettingsSection {
        title: "Behavior"

        SettingRow {
            label: "Show the dock"
            description: "SUPER + ALT + D shows it in every mode"

            SettingChoice {
                options: [
                    {
                        value: "empty",
                        label: "On empty workspaces"
                    },
                    {
                        value: "always",
                        label: "Always"
                    },
                    {
                        value: "never",
                        label: "Only with SUPER + ALT + D"
                    },
                ]
                current: Config.dock.mode
                onChosen: v => Config.dock.mode = v
            }
        }

        SettingRow {
            label: "Running apps"
            description: "Show running apps that aren't pinned, after a divider"

            SettingSwitch {
                checked: Config.dock.showRunning
                onToggled: v => Config.dock.showRunning = v
            }
        }
    }

    SettingsSection {
        title: "Look"

        SettingRow {
            label: "Themed tiles"
            description: "Monochrome icons on tiles in your theme colors, for apps that have one"

            SettingSwitch {
                checked: Config.dock.themedTiles
                onToggled: v => Config.dock.themedTiles = v
            }
        }

        SettingRow {
            label: "Memory indicator"
            description: "RAM usage ring at the end of the dock"

            SettingSwitch {
                checked: Config.dock.showMemory
                onToggled: v => Config.dock.showMemory = v
            }
        }
    }

    SettingsSection {
        title: "Pinned apps"

        Repeater {
            model: page.pinnedEntries
            delegate: Item {
                id: pinRow
                required property var modelData
                required property int index
                width: parent.width
                height: 48

                IconImage {
                    id: pinIcon
                    anchors {
                        left: parent.left
                        leftMargin: 14
                        verticalCenter: parent.verticalCenter
                    }
                    implicitSize: 28
                    source: pinRow.modelData.entry ? Quickshell.iconPath(pinRow.modelData.entry.icon) : ""
                }
                Column {
                    anchors {
                        left: pinIcon.right
                        leftMargin: 12
                        right: pinButtons.left
                        rightMargin: 12
                        verticalCenter: parent.verticalCenter
                    }
                    Text {
                        width: parent.width
                        text: pinRow.modelData.entry?.name ?? pinRow.modelData.id
                        elide: Text.ElideRight
                        color: Theme.colors.text
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize.body
                    }
                    Text {
                        visible: !pinRow.modelData.entry
                        text: "Not installed on this machine"
                        color: Theme.colors.outline
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize.tiny
                    }
                }

                Row {
                    id: pinButtons
                    anchors {
                        right: parent.right
                        rightMargin: 10
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: 2

                    IconButton {
                        icon: "arrow_upward"
                        enabled: pinRow.index > 0
                        onClicked: page.move(pinRow.index, pinRow.index - 1)
                    }
                    IconButton {
                        icon: "arrow_downward"
                        enabled: pinRow.index < page.pinnedEntries.length - 1
                        onClicked: page.move(pinRow.index, pinRow.index + 1)
                    }
                    IconButton {
                        icon: "close"
                        danger: true
                        onClicked: DockPins.toggle(pinRow.modelData.id)
                    }
                }
            }
        }

        // Pin another app
        Item {
            id: adder
            width: parent.width
            height: addCol.implicitHeight + 20

            readonly property var matches: {
                const q = addSearch.text.trim().toLowerCase();
                if (q === "")
                    return [];
                return DesktopEntries.applications.values.filter(a => !a.noDisplay && !DockPins.isPinned(a.id) && a.name.toLowerCase().includes(q)).slice(0, 6);
            }

            Column {
                id: addCol
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 10
                }
                spacing: 4

                Rectangle {
                    width: parent.width
                    height: 36
                    radius: 10
                    color: Theme.colors.surfaceContainerHigh

                    Icon {
                        id: addIcon
                        anchors {
                            left: parent.left
                            leftMargin: 10
                            verticalCenter: parent.verticalCenter
                        }
                        name: "add"
                        color: Theme.colors.subtext
                    }
                    TextInput {
                        id: addSearch
                        anchors {
                            left: addIcon.right
                            leftMargin: 8
                            right: parent.right
                            rightMargin: 10
                            verticalCenter: parent.verticalCenter
                        }
                        color: Theme.colors.text
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize.body
                        clip: true

                        Text {
                            visible: addSearch.text === ""
                            text: "Pin an app…"
                            color: Theme.colors.subtext
                            font: addSearch.font
                        }
                    }
                }

                Repeater {
                    model: adder.matches
                    delegate: MouseArea {
                        id: match
                        required property var modelData
                        width: addCol.width
                        height: 38
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            DockPins.toggle(modelData.id);
                            addSearch.text = "";
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: 8
                            color: Theme.colors.surfaceContainerHigh
                            opacity: match.containsMouse ? 1 : 0
                        }
                        IconImage {
                            id: matchIcon
                            anchors {
                                left: parent.left
                                leftMargin: 10
                                verticalCenter: parent.verticalCenter
                            }
                            implicitSize: 24
                            source: Quickshell.iconPath(match.modelData.icon)
                        }
                        Text {
                            anchors {
                                left: matchIcon.right
                                leftMargin: 10
                                verticalCenter: parent.verticalCenter
                            }
                            text: match.modelData.name
                            color: Theme.colors.text
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize.body
                        }
                    }
                }
            }
        }
    }
}
