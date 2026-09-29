import QtQuick
import Quickshell
import Quickshell.Hyprland

PanelWindow {
    required property var modelData
    screen: modelData

    anchors { top: true; left: true; right: true }
    implicitHeight: 44
    color: "transparent"

    SystemClock { id: clock; precision: SystemClock.Minutes }

    Rectangle {
        anchors.fill: parent
        anchors { topMargin: 8; leftMargin: 8; rightMargin: 8 }
        radius: Theme.radius
        color: Theme.colors.surfaceContainer

        Row {
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            Repeater {
                model: Hyprland.workspaces
                delegate: Rectangle {
                    required property HyprlandWorkspace modelData
                    readonly property bool active: Hyprland.focusedWorkspace?.id === modelData.id

                    visible: modelData.id > 0   // hide special workspaces
                    width: active ? 26 : 10
                    height: 10
                    radius: 5
                    color: active ? Theme.colors.primary : Theme.colors.outlineVariant

                    Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 220 } }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: modelData.activate()
                    }
                }
            }
        }

        Text {
            anchors.centerIn: parent
            text: Qt.formatDateTime(clock.date, "ddd d MMM   HH:mm")
            color: Theme.colors.text
            font.family: Theme.font
            font.pixelSize: 13
            font.weight: Font.Medium
        }

        Row {
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            spacing: 14

            Tray { anchors.verticalCenter: parent.verticalCenter }
            Volume { anchors.verticalCenter: parent.verticalCenter }
            Network { anchors.verticalCenter: parent.verticalCenter }
        }
    }
}
