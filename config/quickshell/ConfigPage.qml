import QtQuick
import Quickshell

// Shortcuts to the Hyprland config files, opened in the default editor
Column {
    id: page
    spacing: 20

    readonly property string hypr: Quickshell.env("HOME") + "/.config/hypr"

    readonly property var groups: [
        {
            title: "Hyprland",
            files: [
                {
                    label: "Main config",
                    file: "hyprland.lua",
                    description: "Loads the other files"
                },
                {
                    label: "Keybinds",
                    file: "config/binds.lua",
                    description: "Keyboard and mouse shortcuts"
                },
                {
                    label: "Window rules",
                    file: "config/windowrules.lua",
                    description: "Floating, sizes and placement per app"
                },
                {
                    label: "Workspaces",
                    file: "config/workspaces.lua",
                    description: "Workspace rules and monitors"
                },
                {
                    label: "Monitors (this machine)",
                    file: "config/hosts/" + (Host.name !== "" ? Host.name : "default") + ".lua",
                    description: "Screens for " + (Host.name !== "" ? Host.name : "this machine")
                },
                {
                    label: "Input",
                    file: "config/inputs.lua",
                    description: "Keyboard layout, mouse and touchpad"
                },
                {
                    label: "Look and feel",
                    file: "config/decorations.lua",
                    description: "Borders, rounding, blur and shadows"
                },
                {
                    label: "Animations",
                    file: "config/animations.lua",
                    description: "Curves and animation speeds"
                },
                {
                    label: "Autostart",
                    file: "config/autostart.lua",
                    description: "Programs started with Hyprland"
                },
                {
                    label: "Environment",
                    file: "config/environment.lua",
                    description: "Environment variables"
                },
                {
                    label: "Variables",
                    file: "config/variables.lua",
                    description: "Shared names used by the other files"
                },
                {
                    label: "Colors",
                    file: "config/colors.lua",
                    description: "Named colors"
                },
                {
                    label: "Misc",
                    file: "config/misc.lua",
                    description: "Layout and other options"
                },
                {
                    label: "Plugins",
                    file: "config/plugins.lua",
                    description: "Plugin settings"
                },
                {
                    label: "Laptop",
                    file: "config/laptop.lua",
                    description: "Laptop-only overrides",
                    laptopOnly: true
                },
            ]
        },
        {
            title: "Lock and idle",
            files: [
                {
                    label: "Lock screen",
                    file: "hyprlock.conf",
                    description: "hyprlock"
                },
                {
                    label: "Idle",
                    file: "hypridle.conf",
                    description: "hypridle: when to dim, lock and sleep"
                },
                {
                    label: "Screen sharing",
                    file: "xdph.conf",
                    description: "xdg-desktop-portal-hyprland"
                },
            ]
        },
    ]

    Repeater {
        model: page.groups
        delegate: SettingsSection {
            id: group
            required property var modelData
            title: modelData.title

            Repeater {
                model: group.modelData.files.filter(f => !f.laptopOnly || Host.laptop)
                delegate: SettingRow {
                    id: fileRow
                    required property var modelData
                    readonly property string path: page.hypr + "/" + modelData.file
                    label: modelData.label
                    description: modelData.description + " · " + modelData.file

                    OpenButton {
                        text: "Open"
                        onClicked: Apps.openFile(fileRow.path)
                    }
                }
            }
        }
    }

    SettingsSection {
        title: "Folder"

        SettingRow {
            label: "Hyprland config folder"
            description: "~/.config/hypr"

            OpenButton {
                text: "Open folder"
                icon: "folder_open"
                onClicked: Apps.openFolder(page.hypr)
            }
        }
    }

    Text {
        leftPadding: 4
        width: parent.width
        wrapMode: Text.Wrap
        text: "Files open in your editor (" + Apps.editor + "), set under Default apps. Hyprland reloads on save."
        color: Theme.colors.subtext
        font.family: Theme.font
        font.pixelSize: Theme.fontSize.small
    }

    component OpenButton: MouseArea {
        id: btn
        property string text
        property string icon: "edit"

        width: btnRow.implicitWidth + 24
        height: 34
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        Rectangle {
            anchors.fill: parent
            radius: 10
            color: btn.containsMouse ? Theme.colors.surfaceContainerHighest ?? Theme.colors.surfaceContainerHigh : Theme.colors.surfaceContainerHigh
        }
        Row {
            id: btnRow
            anchors.centerIn: parent
            spacing: 8
            Icon {
                anchors.verticalCenter: parent.verticalCenter
                name: btn.icon
                color: Theme.colors.subtext
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: btn.text
                color: Theme.colors.text
                font.family: Theme.font
                font.pixelSize: Theme.fontSize.body
            }
        }
    }
}
