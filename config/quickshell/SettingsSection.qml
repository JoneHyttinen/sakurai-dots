import QtQuick

Column {
    id: section
    property string title
    default property alias content: rows.data

    width: parent ? parent.width : 600
    spacing: 8

    Text {
        leftPadding: 4
        text: section.title
        color: Theme.colors.subtext
        font.family: Theme.font
        font.pixelSize: Theme.fontSize.small
        font.weight: Font.Medium
    }

    Rectangle {
        width: parent.width
        height: rows.implicitHeight + 8
        radius: Theme.radius
        color: Theme.colors.surfaceContainer

        Column {
            id: rows
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 4
            }
        }
    }
}
