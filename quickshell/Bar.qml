import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import Quickshell.Wayland

PanelWindow {
    id: bar
    required property var modelData
    property var sidebar: null
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
    screen: modelData

    anchors { top: true; left: true; right: true }
    implicitHeight: Theme.frame.top
    color: "transparent"  // the frame draws the bar's background

    SystemClock { id: clock; precision: SystemClock.Minutes }

    // "Keep awake" toggle in the sidebar
    IdleInhibitor {
        window: bar
        enabled: Panels.keepAwake
    }

    Item {
        anchors.fill: parent
        anchors { leftMargin: Theme.frame.side + 4; rightMargin: Theme.frame.side + 4 }

        // Workspaces
        BarChip {
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            padding: 6
            spacing: 4

            // Games workspace (SUPER + ESC)
            MouseArea {
                id: games
                readonly property var wsObj: Hyprland.workspaces.values.find(w => w.name === "gaming") ?? null
                readonly property bool active: wsObj !== null && bar.monitor?.activeWorkspace?.id === wsObj.id
                readonly property bool focused: wsObj !== null && Hyprland.focusedWorkspace?.id === wsObj.id
                readonly property bool occupied: (wsObj?.toplevels.values.length ?? 0) > 0

                anchors.verticalCenter: parent.verticalCenter
                width: active ? 36 : 26
                height: 22
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Quickshell.execDetached(["hyprctl", "dispatch", 'hl.dsp.focus({ workspace = "name:gaming" })'])

                Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: games.active ? Theme.colors.primary
                        : games.containsMouse ? Theme.colors.surfaceContainer
                        : "transparent"
                    opacity: games.active && !games.focused ? 0.6 : 1
                    Behavior on color { ColorAnimation { duration: 180 } }
                }

                Icon {
                    anchors.centerIn: parent
                    name: "sports_esports"
                    font.pixelSize: 16
                    color: games.active ? Theme.colors.primaryText
                        : games.occupied ? Theme.colors.text
                        : Theme.colors.outline
                }
            }

            // Divider after the games workspace
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 1
                height: 14
                color: Theme.colors.outlineVariant
            }

            Repeater {
                model: Hyprland.workspaces
                delegate: MouseArea {
                    id: ws
                    required property HyprlandWorkspace modelData
                    // Shown on this bar's monitor
                    readonly property bool active: bar.monitor?.activeWorkspace?.id === modelData.id
                    // The one with keyboard focus, across all monitors
                    readonly property bool focused: Hyprland.focusedWorkspace?.id === modelData.id
                    readonly property bool occupied: modelData.toplevels.values.length > 0

                    // Only this monitor's regular (non-special) workspaces
                    visible: modelData.id > 0 && modelData.monitor?.name === bar.screen?.name
                    anchors.verticalCenter: parent.verticalCenter
                    width: active ? 36 : 22
                    height: 22
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: modelData.activate()

                    Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                    Rectangle {
                        anchors.fill: parent
                        radius: height / 2
                        color: ws.active ? Theme.colors.primary
                            : ws.containsMouse ? Theme.colors.surfaceContainer
                            : "transparent"
                        opacity: ws.active && !ws.focused ? 0.6 : 1
                        Behavior on color { ColorAnimation { duration: 180 } }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: ws.modelData.id
                        color: ws.active ? Theme.colors.primaryText
                            : ws.occupied ? Theme.colors.text
                            : Theme.colors.outline
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize.small
                        font.weight: ws.active ? Font.Bold : Font.Medium
                    }
                }
            }
        }

        // Clock
        BarChip {
            anchors.centerIn: parent

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Qt.formatDateTime(clock.date, "ddd d MMM   HH:mm")
                color: Theme.colors.text
                font.family: Theme.font
                font.pixelSize: Theme.fontSize.body
                font.weight: Font.Medium
            }
        }

        // Right side
        Row {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            spacing: 6

            BarChip {
                visible: SystemTray.items.values.length > 0
                padding: 4
                Tray { anchors.verticalCenter: parent.verticalCenter }
            }

            BarChip {
                spacing: 14
                Volume { anchors.verticalCenter: parent.verticalCenter }
                Network { anchors.verticalCenter: parent.verticalCenter }
                NotifButton { anchors.verticalCenter: parent.verticalCenter }
            }

            BarChip {
                padding: 8

                MouseArea {
                    anchors.verticalCenter: parent.verticalCenter
                    width: sbIcon.implicitWidth
                    height: sbIcon.implicitHeight
                    cursorShape: Qt.PointingHandCursor
                    onClicked: bar.sidebar?.toggle(bar.screen, bar)

                    Icon {
                        id: sbIcon
                        name: "tune"
                        color: bar.sidebar?.shown ? Theme.colors.primary : Theme.colors.text
                    }
                }
            }
        }
    }
}
