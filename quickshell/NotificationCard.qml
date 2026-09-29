import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications

MouseArea {
    id: card
    required property var notification
    readonly property bool critical: notification.urgency === NotificationUrgency.Critical

    function iconSource(s) {
        if (!s) return "";
        if (s.startsWith("/")) return "file://" + s;
        if (s.includes("://")) return s;
        return Quickshell.iconPath(s);
    }
    function actionList() {
        const out = [];
        const a = notification.actions;
        for (let i = 0; i < a.length; i++) out.push(a[i]);
        return out;
    }

    readonly property string imageSource: iconSource(notification.image) || iconSource(notification.appIcon)
    readonly property var extraActions: actionList().filter(a => a.identifier !== "default")

    width: 360
    height: content.implicitHeight + 24
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    onEntered: Notifs.hold(notification, true)
    onExited: Notifs.hold(notification, false)
    onClicked: {
        const def = actionList().find(a => a.identifier === "default");
        if (def) def.invoke();
        Notifs.removePopup(notification);
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.colors.surfaceContainer
        border.width: 1
        border.color: card.critical ? Theme.colors.primary : Theme.colors.outlineVariant
    }

    Row {
        id: content
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
        spacing: 12

        // Avatar / app icon
        Item {
            width: 40
            height: 40

            ClippingRectangle {
                anchors.fill: parent
                radius: 10
                color: "transparent"
                visible: card.imageSource !== ""
                IconImage {
                    anchors.fill: parent
                    source: card.imageSource
                }
            }
            Icon {
                anchors.centerIn: parent
                visible: card.imageSource === ""
                name: "notifications"
                font.pixelSize: 26
                color: Theme.colors.primary
            }
        }

        Column {
            width: parent.width - 52
            spacing: 3

            // App name + close button
            Item {
                width: parent.width
                height: 18

                Text {
                    anchors { left: parent.left; right: closeBtn.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
                    text: card.notification.appName
                    elide: Text.ElideRight
                    color: Theme.colors.subtext
                    font.family: Theme.font
                    font.pixelSize: 11
                }
                MouseArea {
                    id: closeBtn
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    width: 18
                    height: 18
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: card.notification.dismiss()
                    Icon {
                        anchors.centerIn: parent
                        name: "close"
                        font.pixelSize: 16
                        color: closeBtn.containsMouse ? Theme.colors.text : Theme.colors.subtext
                    }
                }
            }

            Text {
                width: parent.width
                text: card.notification.summary
                elide: Text.ElideRight
                color: Theme.colors.text
                font.family: Theme.font
                font.pixelSize: 13
                font.weight: Font.Medium
            }

            Text {
                width: parent.width
                visible: text !== ""
                text: card.notification.body
                textFormat: Text.StyledText
                wrapMode: Text.Wrap
                maximumLineCount: 3
                elide: Text.ElideRight
                color: Theme.colors.subtext
                font.family: Theme.font
                font.pixelSize: 12
            }

            // Extra action buttons, e.g. "Reply" or "Mark as read"
            Row {
                visible: card.extraActions.length > 0
                topPadding: 6
                spacing: 6

                Repeater {
                    model: card.extraActions
                    delegate: MouseArea {
                        id: actionBtn
                        required property var modelData
                        width: label.implicitWidth + 20
                        height: 26
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            modelData.invoke();
                            Notifs.removePopup(card.notification);
                        }
                        Rectangle {
                            anchors.fill: parent
                            radius: 8
                            color: actionBtn.containsMouse ? Theme.colors.primary : Theme.colors.surfaceContainerHigh
                        }
                        Text {
                            id: label
                            anchors.centerIn: parent
                            text: actionBtn.modelData.text
                            color: actionBtn.containsMouse ? Theme.colors.primaryText : Theme.colors.text
                            font.family: Theme.font
                            font.pixelSize: 12
                        }
                    }
                }
            }
        }
    }
}
