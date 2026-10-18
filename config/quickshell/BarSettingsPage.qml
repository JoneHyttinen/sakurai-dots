import QtQuick

Column {
    id: page
    spacing: 20

    // For date format previews
    readonly property date now: new Date()

    SettingsSection {
        title: "Clock"

        SettingRow {
            label: "Time format"

            SettingChoice {
                options: [
                    {
                        value: "24h",
                        label: "24-hour"
                    },
                    {
                        value: "12h",
                        label: "12-hour"
                    },
                ]
                current: Config.bar.timeFormat
                onChosen: v => Config.bar.timeFormat = v
            }
        }

        SettingRow {
            label: "Show seconds"

            SettingSwitch {
                checked: Config.bar.showSeconds
                onToggled: v => Config.bar.showSeconds = v
            }
        }

        SettingRow {
            label: "Show date"

            SettingSwitch {
                checked: Config.bar.showDate
                onToggled: v => Config.bar.showDate = v
            }
        }

        SettingRow {
            visible: Config.bar.showDate
            label: "Date format"

            SettingChoice {
                options: ["ddd d MMM", "dddd d MMMM", "d.M.yyyy", "yyyy-MM-dd"].map(f => ({
                            value: f,
                            label: Qt.formatDate(page.now, f)
                        }))
                current: Config.bar.dateFormat
                onChosen: v => Config.bar.dateFormat = v
            }
        }
    }

    SettingsSection {
        title: "Workspaces"

        SettingRow {
            label: "Style"

            SettingChoice {
                options: [
                    {
                        value: "numbers",
                        label: "Numbers"
                    },
                    {
                        value: "dots",
                        label: "Dots"
                    },
                ]
                current: Config.bar.workspaceStyle
                onChosen: v => Config.bar.workspaceStyle = v
            }
        }

        SettingRow {
            label: "Gaming workspace"
            description: "Gamepad icon for the workspace on SUPER + ESC"

            SettingSwitch {
                checked: Config.bar.showGaming
                onToggled: v => Config.bar.showGaming = v
            }
        }

        SettingRow {
            label: "Scratchpad"
            description: "Icon for the special workspace on SUPER + S"

            SettingSwitch {
                checked: Config.bar.showScratchpad
                onToggled: v => Config.bar.showScratchpad = v
            }
        }
    }

    SettingsSection {
        title: "Status icons"

        Repeater {
            model: [
                {
                    key: "showTray",
                    label: "System tray",
                    description: ""
                },
                {
                    key: "showVolume",
                    label: "Volume",
                    description: ""
                },
                {
                    key: "showNetwork",
                    label: "Network",
                    description: ""
                },
                {
                    key: "showNotifications",
                    label: "Notifications",
                    description: "Bell with unread indicator"
                },
                {
                    key: "showBattery",
                    label: "Battery",
                    description: "Only shown on machines with a battery"
                },
                {
                    key: "showDashboardButton",
                    label: "Dashboard button",
                    description: "The clock opens the dashboard either way"
                },
            ]
            delegate: SettingRow {
                required property var modelData
                label: modelData.label
                description: modelData.description

                SettingSwitch {
                    checked: Config.bar[modelData.key]
                    onToggled: v => Config.bar[modelData.key] = v
                }
            }
        }
    }
}
