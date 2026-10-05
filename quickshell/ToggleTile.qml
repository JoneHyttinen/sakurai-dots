import QtQuick

MouseArea {
    id: tile
    property string icon
    property string label
    property bool active: false

    height: 56
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: tile.active ? Theme.colors.primary : Theme.colors.surfaceContainerHigh
        opacity: tile.containsMouse ? 0.9 : 1
        scale: tile.pressed ? 0.97 : 1
        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on scale { NumberAnimation { duration: 100 } }
    }

    Row {
        anchors { fill: parent; leftMargin: 14; rightMargin: 10 }
        spacing: 10

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            name: tile.icon
            color: tile.active ? Theme.colors.primaryText : Theme.colors.text
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 28
            text: tile.label
            elide: Text.ElideRight
            color: tile.active ? Theme.colors.primaryText : Theme.colors.text
            font.family: Theme.font
            font.pixelSize: Theme.fontSize.body
            font.weight: Font.Medium
        }
    }
}
