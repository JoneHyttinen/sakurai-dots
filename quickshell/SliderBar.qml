import QtQuick

Item {
    id: root
    property real value: 0
    // true: report every movement while dragging (volume).
    // false: report only once, on release (seeking).
    property bool live: true
    signal moved(real v)

    // While held, show where the mouse is instead of the reported value
    readonly property bool dragging: area.pressed
    property real dragValue: 0
    readonly property real shown: Math.max(0, Math.min(1, dragging ? dragValue : value))

    implicitWidth: 200
    implicitHeight: 20

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 6
        radius: 3
        color: Theme.colors.surfaceContainerHigh

        Rectangle {
            width: parent.width * root.shown
            height: parent.height
            radius: 3
            color: Theme.colors.primary
        }
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        x: (root.width - width) * root.shown
        width: root.dragging ? 18 : 16
        height: width
        radius: width / 2
        color: Theme.colors.primary
        Behavior on width { NumberAnimation { duration: 100 } }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor

        function update(mx) {
            root.dragValue = Math.max(0, Math.min(1, mx / width));
            if (root.live) root.moved(root.dragValue);
        }

        onPressed: m => update(m.x)
        onPositionChanged: m => { if (pressed) update(m.x) }
        onReleased: if (!root.live) root.moved(root.dragValue)
    }
}
