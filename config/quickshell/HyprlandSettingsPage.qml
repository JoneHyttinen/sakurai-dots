import QtQuick

Column {
    id: page
    spacing: 20

    readonly property var h: Config.hyprland

    SettingsSection {
        title: "Gaps and borders"

        SettingRow {
            label: "Gaps between windows"
            description: "Space on each side of a window; two windows are twice this apart"

            SettingSlider {
                from: 0
                to: 20
                step: 1
                suffix: " px"
                value: page.h.gapsIn
                onEdited: v => page.h.gapsIn = v
            }
        }

        SettingRow {
            label: "Gap to the frame"
            description: "Space between windows and the screen frame"

            SettingSlider {
                from: 0
                to: 32
                step: 1
                suffix: " px"
                value: page.h.gapsOut
                onEdited: v => page.h.gapsOut = v
            }
        }

        SettingRow {
            label: "Border width"

            SettingSlider {
                from: 0
                to: 6
                step: 1
                suffix: " px"
                value: page.h.borderSize
                onEdited: v => page.h.borderSize = v
            }
        }

        SettingRow {
            label: "Match the frame"
            description: "Round windows so their corners follow the frame's inner corners"

            SettingSwitch {
                checked: page.h.matchFrame
                onToggled: v => page.h.matchFrame = v
            }
        }

        SettingRow {
            label: "Window rounding"
            description: page.h.matchFrame ? "Set by the frame: " + Math.max(0, Config.appearance.frameRadius - page.h.gapsOut) + " px" : "Corner radius of windows"
            enabled: !page.h.matchFrame
            opacity: enabled ? 1 : 0.5

            SettingSlider {
                from: 0
                to: 30
                step: 1
                suffix: " px"
                value: page.h.rounding
                onEdited: v => page.h.rounding = v
            }
        }
    }

    SettingsSection {
        title: "Transparency"

        SettingRow {
            label: "Focused window"

            SettingSlider {
                from: 0.5
                to: 1
                step: 0.01
                decimals: 2
                value: page.h.activeOpacity
                onEdited: v => page.h.activeOpacity = v
            }
        }

        SettingRow {
            label: "Other windows"
            description: "Below 1, windows show the blurred wallpaper behind them"

            SettingSlider {
                from: 0.5
                to: 1
                step: 0.01
                decimals: 2
                value: page.h.inactiveOpacity
                onEdited: v => page.h.inactiveOpacity = v
            }
        }
    }

    SettingsSection {
        title: "Animations"

        SettingRow {
            label: "Animations"
            description: "Window, workspace and fade animations"

            SettingSwitch {
                checked: page.h.animations
                onToggled: v => page.h.animations = v
            }
        }

        SettingRow {
            visible: page.h.animations
            label: "Speed"

            SettingChoice {
                options: [
                    {
                        value: "fast",
                        label: "Fast"
                    },
                    {
                        value: "normal",
                        label: "Normal"
                    },
                    {
                        value: "slow",
                        label: "Slow"
                    },
                ]
                current: page.h.animSpeed
                onChosen: v => page.h.animSpeed = v
            }
        }
    }

    Text {
        leftPadding: 4
        width: parent.width
        wrapMode: Text.Wrap
        text: "Applied to Hyprland right away and saved for this machine only."
        color: Theme.colors.subtext
        font.family: Theme.font
        font.pixelSize: Theme.fontSize.small
    }
}
