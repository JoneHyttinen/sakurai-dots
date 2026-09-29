import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    screen: Quickshell.screens.find(s => s.name === "DP-1") ?? Quickshell.screens[0]
    visible: Notifs.popups.length > 0

    anchors { top: true; right: true }
    margins { top: 8; right: 8 }  // the bar's reserved space already pushes this below it
    exclusiveZone: 0
    implicitWidth: 360
    implicitHeight: stack.implicitHeight
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-notifications"

    Column {
        id: stack
        width: parent.width
        spacing: 8

        Repeater {
            model: Notifs.popups
            delegate: NotificationCard {
                required property var modelData
                notification: modelData.n
            }
        }
    }
}
