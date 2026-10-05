import QtQuick

MouseArea {
    id: row
    property string icon
    property string label
    property bool selected: false

    width: parent ? parent.width : 200
    height: 36
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: Theme.colors.surfaceContainerHigh
        opacity: row.selected || row.containsMouse ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 120 } }
    }

    Row {
        anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
        spacing: 10

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            name: row.icon
            color: row.selected ? Theme.colors.primary : Theme.colors.text
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 28
            text: row.label
            elide: Text.ElideRight
            color: row.selected ? Theme.colors.primary : Theme.colors.text
            font.family: Theme.font
            font.pixelSize: Theme.fontSize.body
        }
    }
}
