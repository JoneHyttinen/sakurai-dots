import QtQuick

Item {
    id: root
    property real value: 0
    signal moved(real v)

    readonly property real clamped: Math.max(0, Math.min(1, value))
    implicitWidth: 200
    implicitHeight: 20

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 6
        radius: 3
        color: Theme.colors.surfaceContainerHigh

        Rectangle {
            width: parent.width * root.clamped
            height: parent.height
            radius: 3
            color: Theme.colors.primary
        }
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        x: (root.width - width) * root.clamped
        width: 16
        height: 16
        radius: 8
        color: Theme.colors.primary
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        function update(mx) { root.moved(Math.max(0, Math.min(1, mx / width))) }
        onPressed: mouse => update(mouse.x)
        onPositionChanged: mouse => { if (pressed) update(mouse.x) }
    }
}
