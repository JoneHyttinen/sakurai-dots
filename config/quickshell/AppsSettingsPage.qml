import QtQuick
import Quickshell
import Quickshell.Widgets

Column {
    id: page
    spacing: 20

    property string openKey: ""  // which app's list is open

    readonly property var kinds: [
        {
            key: "terminal",
            label: "Terminal",
            category: "TerminalEmulator",
            description: "Keybinds, and commands the shell runs in a terminal"
        },
        {
            key: "browser",
            label: "Web browser",
            category: "WebBrowser",
            description: "Your browser keybind"
        },
        {
            key: "fileManager",
            label: "File manager",
            category: "FileManager",
            description: "Your file manager keybind, and folders the shell opens"
        },
        {
            key: "editor",
            label: "Editor",
            category: "TextEditor",
            description: "Your editor keybind"
        },
        {
            key: "calculator",
            label: "Calculator",
            category: "Calculator",
            description: "Your calculator keybind"
        },
    ]

    // The command that starts a desktop entry's app, e.g. "alacritty"
    function commandOf(e) {
        return e.command?.[0] ?? e.id;
    }

    SettingsSection {
        title: "Default apps"

        Repeater {
            model: page.kinds
            delegate: Column {
                id: kind
                required property var modelData
                readonly property string value: Config.apps[modelData.key] ?? ""
                readonly property bool open: page.openKey === modelData.key

                // Installed apps of this kind
                readonly property var candidates: {
                    DesktopEntries.applications.values;
                    return DesktopEntries.applications.values.filter(e => !e.noDisplay && (e.categories ?? []).includes(modelData.category)).sort((a, b) => a.name.localeCompare(b.name));
                }
                readonly property var current: candidates.find(e => page.commandOf(e) === value) ?? null

                width: parent.width

                SettingRow {
                    label: kind.modelData.label
                    description: kind.modelData.description

                    MouseArea {
                        id: pickBtn
                        width: pickRow.implicitWidth + 24
                        height: 34
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: page.openKey = kind.open ? "" : kind.modelData.key

                        Rectangle {
                            anchors.fill: parent
                            radius: 10
                            color: pickBtn.containsMouse || kind.open ? Theme.colors.surfaceContainerHighest ?? Theme.colors.surfaceContainerHigh : Theme.colors.surfaceContainerHigh
                        }
                        Row {
                            id: pickRow
                            anchors.centerIn: parent
                            spacing: 8

                            IconImage {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: kind.current !== null
                                implicitSize: 18
                                source: kind.current ? Quickshell.iconPath(kind.current.icon) : ""
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: kind.current?.name ?? (kind.value !== "" ? kind.value : "From the Hyprland config")
                                color: Theme.colors.text
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize.body
                            }
                            Icon {
                                anchors.verticalCenter: parent.verticalCenter
                                name: kind.open ? "expand_less" : "expand_more"
                                color: Theme.colors.subtext
                            }
                        }
                    }
                }

                // Installed choices, plus a custom command
                Column {
                    visible: kind.open
                    x: 10
                    width: parent.width - 20
                    spacing: 2
                    bottomPadding: 10

                    Repeater {
                        model: kind.candidates
                        delegate: MouseArea {
                            id: opt
                            required property var modelData
                            readonly property bool selected: page.commandOf(modelData) === kind.value
                            width: parent.width
                            height: 38
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Config.apps[kind.modelData.key] = page.commandOf(modelData);
                                page.openKey = "";
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: 8
                                color: opt.selected ? Theme.colors.primary : Theme.colors.surfaceContainerHigh
                                opacity: opt.selected || opt.containsMouse ? 1 : 0
                            }
                            IconImage {
                                id: optIcon
                                anchors {
                                    left: parent.left
                                    leftMargin: 10
                                    verticalCenter: parent.verticalCenter
                                }
                                implicitSize: 22
                                source: Quickshell.iconPath(opt.modelData.icon)
                            }
                            Text {
                                anchors {
                                    left: optIcon.right
                                    leftMargin: 10
                                    verticalCenter: parent.verticalCenter
                                }
                                text: opt.modelData.name
                                color: opt.selected ? Theme.colors.primaryText : Theme.colors.text
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize.body
                            }
                            Text {
                                anchors {
                                    right: parent.right
                                    rightMargin: 10
                                    verticalCenter: parent.verticalCenter
                                }
                                text: page.commandOf(opt.modelData)
                                color: opt.selected ? Theme.colors.primaryText : Theme.colors.outline
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize.tiny
                            }
                        }
                    }

                    Text {
                        visible: kind.candidates.length === 0
                        leftPadding: 10
                        topPadding: 6
                        bottomPadding: 6
                        text: "No installed apps of this kind found"
                        color: Theme.colors.subtext
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize.small
                    }

                    // Anything else, typed as a command
                    Rectangle {
                        width: parent.width
                        height: 36
                        radius: 8
                        color: Theme.colors.surfaceContainerHigh

                        TextInput {
                            id: custom
                            anchors {
                                fill: parent
                                leftMargin: 10
                                rightMargin: 10
                            }
                            verticalAlignment: TextInput.AlignVCenter
                            color: Theme.colors.text
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize.small
                            clip: true
                            onAccepted: {
                                Config.apps[kind.modelData.key] = text.trim();
                                text = "";
                                page.openKey = "";
                            }

                            Text {
                                visible: custom.text === ""
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Other command… (Enter to save)"
                                color: Theme.colors.outline
                                font: custom.font
                            }
                        }
                    }
                }
            }
        }
    }

    Text {
        leftPadding: 4
        width: parent.width
        wrapMode: Text.Wrap
        text: "Saved for this machine only. Keybinds use the new apps right away."
        color: Theme.colors.subtext
        font.family: Theme.font
        font.pixelSize: Theme.fontSize.small
    }
}
