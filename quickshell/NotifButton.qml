import QtQuick
import Quickshell

MouseArea {
    id: root
    readonly property var win: QsWindow.window
    readonly property var items: Notifs.history.values.slice().reverse()  // newest first

    implicitWidth: icon.implicitWidth
    implicitHeight: icon.implicitHeight
    cursorShape: Qt.PointingHandCursor
    onClicked: {
        popup.toggle();
        if (popup.visible) {
            Notifs.unread = 0;
            Notifs.now = Date.now();
        }
    }

    Icon {
        id: icon
        name: Notifs.dnd ? "notifications_off"
            : Notifs.unread > 0 ? "notifications_unread"
            : "notifications"
        color: Notifs.unread > 0 && !Notifs.dnd ? Theme.colors.primary : Theme.colors.text
    }

    BarPopup {
        id: popup
        anchorItem: root
        barWindow: root.win
        contentWidth: 380

        // Header: title, Do Not Disturb, Clear all
        Item {
            width: parent.width
            height: 28

            Text {
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                text: "Notifications"
                color: Theme.colors.text
                font.family: Theme.font
                font.pixelSize: Theme.fontSize.body
                font.weight: Font.Medium
            }

            Row {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                spacing: 4

                MouseArea {
                    id: dndBtn
                    width: 28
                    height: 28
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Notifs.dnd = !Notifs.dnd

                    Rectangle {
                        anchors.fill: parent
                        radius: 8
                        color: Theme.colors.surfaceContainerHigh
                        opacity: dndBtn.containsMouse ? 1 : 0
                    }
                    Icon {
                        anchors.centerIn: parent
                        name: Notifs.dnd ? "do_not_disturb_on" : "do_not_disturb_off"
                        color: Notifs.dnd ? Theme.colors.primary : Theme.colors.subtext
                    }
                }

                MouseArea {
                    id: clearBtn
                    visible: root.items.length > 0
                    width: clearLabel.implicitWidth + 16
                    height: 28
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Notifs.clearAll()

                    Rectangle {
                        anchors.fill: parent
                        radius: 8
                        color: Theme.colors.surfaceContainerHigh
                        opacity: clearBtn.containsMouse ? 1 : 0
                    }
                    Text {
                        id: clearLabel
                        anchors.centerIn: parent
                        text: "Clear all"
                        color: clearBtn.containsMouse ? Theme.colors.text : Theme.colors.subtext
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize.small
                    }
                }
            }
        }

        // History list
        Flickable {
            visible: root.items.length > 0
            width: parent.width
            height: Math.min(list.implicitHeight, 480)
            contentHeight: list.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: list
                width: parent.width
                spacing: 8

                Repeater {
                    model: root.items
                    delegate: NotificationCard {
                        required property var modelData
                        notification: modelData
                        inHistory: true
                        width: list.width
                        background: Theme.colors.surfaceContainerHigh
                        timeText: Notifs.ago(modelData)
                        onActivated: popup.visible = false
                    }
                }
            }
        }

        // Empty state
        Column {
            visible: root.items.length === 0
            width: parent.width
            topPadding: 16
            bottomPadding: 16
            spacing: 6

            Icon {
                anchors.horizontalCenter: parent.horizontalCenter
                name: "notifications"
                font.pixelSize: 32
                color: Theme.colors.subtext
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "No notifications"
                color: Theme.colors.subtext
                font.family: Theme.font
                font.pixelSize: Theme.fontSize.body
            }
        }
    }
}
