import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root
    screen: Quickshell.screens.find(s => s.name === Host.primaryMonitor) ?? Quickshell.screens[0]

    // A fixed, always-mapped window over the right side; only the panel
    // inside it changes size, and only the panel takes clicks
    anchors { top: true; right: true; bottom: true }
    exclusiveZone: 0
    implicitWidth: 360 + 24 + Theme.frame.radius
    color: "transparent"
    mask: Region { item: panel.visible ? panel : null }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-notifications"

    readonly property bool hasItems: Notifs.popups.length > 0

    Item {
        id: panel
        width: parent.width
        // Fits the cards exactly; shrinks to nothing when there are none
        height: root.hasItems ? stack.implicitHeight + 24 + Theme.frame.radius : 0
        visible: height > Theme.frame.radius + Theme.radius
        Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

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

            // New cards slide in from under the right edge of the frame
            add: Transition {
                NumberAnimation { property: "x"; from: 380; duration: 280; easing.type: Easing.OutCubic }
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 }
            }
            // Cards below move smoothly to make room, or to close a gap
            move: Transition {
                NumberAnimation { property: "y"; duration: 220; easing.type: Easing.OutCubic }
            }

            Repeater {
                model: ScriptModel {
                    values: Notifs.popups.map(p => p.n)
                }
                delegate: NotificationCard {
                    required property var modelData
                    notification: modelData
                }
            }
        }
    }
}
