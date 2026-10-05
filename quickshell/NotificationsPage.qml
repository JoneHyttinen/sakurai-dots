import QtQuick
import Quickshell
import Quickshell.Widgets

Item {
    id: page
    property bool active: false   // true while this tab is showing
    property var dashboard: null  // closed after opening a notification
    property var expanded: ({})   // app name -> true when its group shows everything

    // Looking at the tab counts as reading, like opening the bell's popup
    onActiveChanged: {
        if (active) {
            Notifs.unread = 0;
            Notifs.now = Date.now();
        }
    }

    // Newest first, grouped by app; groups ordered by their newest notification
    readonly property var groups: {
        const out = [];
        const index = {};
        for (const n of Notifs.history.values.slice().reverse()) {
            const key = n.appName || "Other";
            if (index[key] === undefined) {
                index[key] = out.length;
                out.push({ app: key, entry: n.desktopEntry, items: [] });
            }
            out[index[key]].items.push(n);
        }
        return out;
    }

    function clearGroup(g) { g.items.slice().forEach(n => n.dismiss()) }

    function toggleExpanded(app) {
        const e = Object.assign({}, expanded);
        e[app] = !e[app];
        expanded = e;
    }

    implicitHeight: col.implicitHeight

    // A small text-and-icon button for the header
    component HeaderButton: MouseArea {
        id: hb
        property string icon: ""
        property string label
        property bool on: false

        width: hbRow.implicitWidth + 20
        height: 30
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: hb.on ? Theme.colors.primary
                : hb.containsMouse ? Theme.colors.surfaceContainerHigh
                : Theme.colors.surfaceContainer
            Behavior on color { ColorAnimation { duration: 150 } }
        }
        Row {
            id: hbRow
            anchors.centerIn: parent
            spacing: 6

            Icon {
                visible: hb.icon !== ""
                anchors.verticalCenter: parent.verticalCenter
                name: hb.icon
                font.pixelSize: 16
                color: hb.on ? Theme.colors.primaryText : Theme.colors.text
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: hb.label
                color: hb.on ? Theme.colors.primaryText : Theme.colors.text
                font.family: Theme.font
                font.pixelSize: Theme.fontSize.small
                font.weight: Font.Medium
            }
        }
    }

    Column {
        id: col
        width: parent.width
        spacing: 12

        // ── Header ───────────────────────────────────────
        Item {
            width: parent.width
            height: 32

            Text {
                anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
                text: Notifs.history.values.length > 0
                    ? "Notifications  ·  " + Notifs.history.values.length
                    : "Notifications"
                color: Theme.colors.text
                font.family: Theme.font
                font.pixelSize: Theme.fontSize.medium
                font.weight: Font.Medium
            }

            Row {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                spacing: 6

                HeaderButton {
                    icon: Notifs.dnd ? "do_not_disturb_on" : "do_not_disturb_off"
                    label: "Do Not Disturb"
                    on: Notifs.dnd
                    onClicked: Notifs.dnd = !Notifs.dnd
                }
                HeaderButton {
                    visible: page.groups.length > 0
                    icon: "clear_all"
                    label: "Clear all"
                    onClicked: Notifs.clearAll()
                }
            }
        }

        // ── Nothing here ─────────────────────────────────
        Rectangle {
            visible: page.groups.length === 0
            width: parent.width
            height: 200
            radius: Theme.radius
            color: Theme.colors.surfaceContainer

            Column {
                anchors.centerIn: parent
                spacing: 8
                Icon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    name: Notifs.dnd ? "notifications_off" : "notifications"
                    font.pixelSize: 40
                    color: Theme.colors.outline
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

        // ── Groups ───────────────────────────────────────
        Flickable {
            visible: page.groups.length > 0
            width: parent.width
            height: Math.min(groupsCol.implicitHeight, 480)
            contentHeight: groupsCol.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: groupsCol
                width: parent.width
                spacing: 12

                Repeater {
                    model: page.groups
                    delegate: Rectangle {
                        id: group
                        required property var modelData
                        readonly property bool showAll: page.expanded[modelData.app] === true
                        readonly property var shownItems: showAll ? modelData.items : modelData.items.slice(0, 3)
                        readonly property var entry: DesktopEntries.heuristicLookup(modelData.entry || modelData.app)

                        width: groupsCol.width
                        height: groupCol.implicitHeight + 24
                        radius: Theme.radius
                        color: Theme.colors.surfaceContainer

                        Column {
                            id: groupCol
                            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                            spacing: 8

                            // App header
                            Item {
                                width: parent.width
                                height: 26

                                Row {
                                    anchors { left: parent.left; leftMargin: 2; verticalCenter: parent.verticalCenter }
                                    spacing: 8

                                    IconImage {
                                        anchors.verticalCenter: parent.verticalCenter
                                        visible: group.entry !== null
                                        implicitSize: 18
                                        source: group.entry ? Quickshell.iconPath(group.entry.icon) : ""
                                    }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: group.modelData.app
                                        color: Theme.colors.text
                                        font.family: Theme.font
                                        font.pixelSize: Theme.fontSize.body
                                        font.weight: Font.Medium
                                    }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: group.modelData.items.length
                                        color: Theme.colors.subtext
                                        font.family: Theme.font
                                        font.pixelSize: Theme.fontSize.small
                                    }
                                }

                                MouseArea {
                                    id: clearGroupBtn
                                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                                    width: clearLabel.implicitWidth + 16
                                    height: 24
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: page.clearGroup(group.modelData)

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 8
                                        color: Theme.colors.surfaceContainerHigh
                                        opacity: clearGroupBtn.containsMouse ? 1 : 0
                                    }
                                    Text {
                                        id: clearLabel
                                        anchors.centerIn: parent
                                        text: "Clear"
                                        color: clearGroupBtn.containsMouse ? Theme.colors.text : Theme.colors.subtext
                                        font.family: Theme.font
                                        font.pixelSize: Theme.fontSize.small
                                    }
                                }
                            }

                            // Notifications
                            Repeater {
                                model: group.shownItems
                                delegate: NotificationCard {
                                    required property var modelData
                                    notification: modelData
                                    inHistory: true
                                    width: groupCol.width
                                    background: Theme.colors.surfaceContainerHigh
                                    timeText: Notifs.ago(modelData)
                                    onActivated: page.dashboard?.close()
                                }
                            }

                            // Expand / collapse
                            MouseArea {
                                id: moreBtn
                                visible: group.modelData.items.length > 3
                                width: parent.width
                                height: 28
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: page.toggleExpanded(group.modelData.app)

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 8
                                    color: Theme.colors.surfaceContainerHigh
                                    opacity: moreBtn.containsMouse ? 1 : 0
                                }
                                Row {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    Icon {
                                        anchors.verticalCenter: parent.verticalCenter
                                        name: group.showAll ? "expand_less" : "expand_more"
                                        font.pixelSize: 18
                                        color: Theme.colors.subtext
                                    }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: group.showAll ? "Show less"
                                            : "Show " + (group.modelData.items.length - 3) + " more"
                                        color: Theme.colors.subtext
                                        font.family: Theme.font
                                        font.pixelSize: Theme.fontSize.small
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
