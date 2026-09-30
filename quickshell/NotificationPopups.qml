import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root
    screen: Quickshell.screens.find(s => s.name === "DP-1") ?? Quickshell.screens[0]

    // Stay visible briefly after the last card leaves, so it can animate out
    readonly property bool hasItems: Notifs.popups.length > 0
    visible: hasItems || hideDelay.running
    onHasItemsChanged: if (!hasItems) hideDelay.restart()
    Timer { id: hideDelay; interval: 260 }

    // Tucked into the corner below the bar and inside the right band
    anchors { top: true; right: true }
    exclusiveZone: 0
    implicitWidth: 360 + 24 + Theme.frame.radius
    implicitHeight: list.contentHeight + 24 + Theme.frame.radius
    Behavior on implicitHeight { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-notifications"

    FramePanel {
        anchors.fill: parent
        edge: "topRight"
    }

    ScriptModel {
        id: popupModel
        values: Notifs.popups.map(p => p.n)
    }

    ListView {
        id: list
        x: Theme.frame.radius + 12
        y: 12
        width: 360
        height: contentHeight
        spacing: 8
        interactive: false
        model: popupModel

        delegate: NotificationCard {
            required property var modelData
            notification: modelData
        }

        // New cards slide in from under the right edge of the frame
        add: Transition {
            NumberAnimation { property: "x"; from: 380; to: 0; duration: 280; easing.type: Easing.OutCubic }
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 }
        }
        // Dismissed or expired cards slide back out
        remove: Transition {
            NumberAnimation { property: "x"; to: 380; duration: 220; easing.type: Easing.InCubic }
            NumberAnimation { property: "opacity"; to: 0; duration: 200 }
        }
        // Remaining cards move smoothly into place
        displaced: Transition {
            NumberAnimation { property: "y"; duration: 220; easing.type: Easing.OutCubic }
        }
    }
}
