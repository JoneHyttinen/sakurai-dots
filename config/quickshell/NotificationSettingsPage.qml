import QtQuick
import Quickshell

Column {
    spacing: 20

    SettingsSection {
        title: "Popups"

        SettingRow {
            label: "Duration"
            description: "How long a popup stays on screen. Hovering pauses it."

            SettingSlider {
                from: 2
                to: 15
                step: 1
                suffix: " s"
                value: Config.notifications.timeout
                onEdited: v => Config.notifications.timeout = v
            }
        }

        SettingRow {
            label: "Maximum popups"
            description: "Older popups make room for new ones; all stay in the history"

            SettingSlider {
                from: 1
                to: 8
                step: 1
                value: Config.notifications.maxPopups
                onEdited: v => Config.notifications.maxPopups = v
            }
        }

        SettingRow {
            label: "Show on"
            description: "Which monitor popups appear on"

            SettingChoice {
                options: [
                    {
                        value: "primary",
                        label: "Primary monitor"
                    },
                    {
                        value: "focused",
                        label: "Focused monitor"
                    },
                ]
                current: Config.notifications.screen
                onChosen: v => Config.notifications.screen = v
            }
        }

        SettingRow {
            label: "Keep critical notifications"
            description: "Critical notifications stay until you dismiss them"

            SettingSwitch {
                checked: Config.notifications.keepCritical
                onToggled: v => Config.notifications.keepCritical = v
            }
        }
    }

    SettingsSection {
        title: "Try it"

        SettingRow {
            label: "Send a test notification"
            description: "See your settings in action"

            Row {
                spacing: 6

                Repeater {
                    model: [
                        {
                            label: "Normal",
                            urgency: "normal"
                        },
                        {
                            label: "Critical",
                            urgency: "critical"
                        },
                    ]
                    delegate: MouseArea {
                        id: testBtn
                        required property var modelData
                        width: testLabel.implicitWidth + 24
                        height: 32
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Quickshell.execDetached(["notify-send", "-u", modelData.urgency, "Test notification", "This is a " + modelData.urgency + " notification"])

                        Rectangle {
                            anchors.fill: parent
                            radius: 10
                            color: testBtn.containsMouse ? Theme.colors.primary : Theme.colors.surfaceContainerHigh
                        }
                        Text {
                            id: testLabel
                            anchors.centerIn: parent
                            text: testBtn.modelData.label
                            color: testBtn.containsMouse ? Theme.colors.primaryText : Theme.colors.text
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize.small
                            font.weight: Font.Medium
                        }
                    }
                }
            }
        }
    }
}
