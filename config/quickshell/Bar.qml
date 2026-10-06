import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import Quickshell.Wayland

PanelWindow {
    id: bar
    required property var modelData
    property var wallpaperPicker: null
    screen: modelData

    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)

    anchors { top: true; left: true; right: true }
    implicitHeight: Theme.frame.top
    color: "transparent"  // the frame draws the bar's background

    SystemClock { id: clock; precision: SystemClock.Minutes }

    // "Keep awake" toggle in the dashboard
    IdleInhibitor {
        window: bar
        enabled: Panels.keepAwake
    }

    // Hyprland doesn't update monitor info when a special workspace is
    // toggled, so ask for fresh data whenever that happens
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "activespecial") Hyprland.refreshMonitors();
        }
    }

    readonly property bool scratchpadOpen:
        monitor?.lastIpcObject?.specialWorkspace?.name === "special:special"

    // The dashboard keybind opens the dashboard on the focused monitor's bar
    Connections {
        target: Panels
        function onDashboardToggle(screenName) {
            if (screenName === bar.screen?.name) dashboard.toggle();
        }
    }

    Item {
        anchors.fill: parent
        anchors { leftMargin: Theme.frame.side + 4; rightMargin: Theme.frame.side + 4 }

        // ── Workspaces ───────────────────────────────────
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

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 1
                height: 14
                color: Theme.colors.outlineVariant
            }

            // Numbered workspaces on this monitor
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

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 1
                height: 14
                color: Theme.colors.outlineVariant
            }

            // Scratchpad (SUPER + S)
            MouseArea {
                id: scratch
                readonly property var wsObj: Hyprland.workspaces.values.find(w => w.name === "special:special") ?? null
                readonly property bool open: bar.scratchpadOpen
                readonly property bool occupied: (wsObj?.toplevels.values.length ?? 0) > 0

                anchors.verticalCenter: parent.verticalCenter
                width: open ? 36 : 26
                height: 22
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.workspace.toggle_special()"])

                Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: scratch.open ? Theme.colors.primary
                        : scratch.containsMouse ? Theme.colors.surfaceContainer
                        : "transparent"
                    Behavior on color { ColorAnimation { duration: 180 } }
                }

                Icon {
                    anchors.centerIn: parent
                    name: "layers"
                    font.pixelSize: 16
                    color: scratch.open ? Theme.colors.primaryText
                        : scratch.occupied ? Theme.colors.text
                        : Theme.colors.outline
                }
            }
        }

        // ── Clock; click for the dashboard ───────────────
        MouseArea {
            anchors.centerIn: parent
            width: clockChip.width
            height: clockChip.height
            cursorShape: Qt.PointingHandCursor
            onClicked: dashboard.toggle()

            BarChip {
                id: clockChip
                color: dashboard.shown ? Theme.colors.surfaceContainer : Theme.colors.surfaceContainerHigh

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Qt.formatDateTime(clock.date, "ddd d MMM   HH:mm")
                    color: dashboard.shown ? Theme.colors.primary : Theme.colors.text
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize.body
                    font.weight: Font.Medium
                }
            }

            Dashboard {
                id: dashboard
                anchorItem: clockChip
                barWindow: bar
                wallpaperPicker: bar.wallpaperPicker
            }
        }

        // ── Right side ───────────────────────────────────
        Row {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            spacing: 6

            BarChip {
                visible: SystemTray.items.values.length > 0
                padding: 8
                Tray { anchors.verticalCenter: parent.verticalCenter }
            }

            BarChip {
                spacing: 14
                Volume { anchors.verticalCenter: parent.verticalCenter }
                Network { anchors.verticalCenter: parent.verticalCenter }
                Battery { anchors.verticalCenter: parent.verticalCenter }
                NotifButton { anchors.verticalCenter: parent.verticalCenter }
            }

            // Dashboard button
            MouseArea {
                anchors.verticalCenter: parent.verticalCenter
                width: tuneChip.width
                height: tuneChip.height
                cursorShape: Qt.PointingHandCursor
                onClicked: dashboard.toggle()

                BarChip {
                    id: tuneChip
                    padding: 8

                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: "tune"
                        color: dashboard.shown ? Theme.colors.primary : Theme.colors.text
                    }
                }
            }
        }
    }
}
