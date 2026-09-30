import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    screen: Quickshell.screens.find(s => s.name === "DP-1") ?? Quickshell.screens[0]
    visible: Notifs.popups.length > 0

    // Tucked into the corner below the bar and inside the right band
    anchors { top: true; right: true }
    exclusiveZone: 0
    implicitWidth: 360 + 24 + Theme.frame.radius
    implicitHeight: stack.implicitHeight + 24 + Theme.frame.radius
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-notifications"

    FramePanel {
        anchors.fill: parent
        edge: "topRight"
    }

    Column {
        id: stack
        x: Theme.frame.radius + 12
        y: 12
        width: 360
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
