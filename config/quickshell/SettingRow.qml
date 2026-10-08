import QtQuick

Item {
    id: row
    property string label
    property string description: ""
    default property alias control: slot.data

    width: parent ? parent.width : 600
    implicitHeight: Math.max(textCol.implicitHeight, slot.height) + 24

    Column {
        id: textCol
        anchors {
            left: parent.left
            leftMargin: 14
            right: slot.left
            rightMargin: 16
            verticalCenter: parent.verticalCenter
        }
        spacing: 2

        Text {
            width: parent.width
            text: row.label
            color: Theme.colors.text
            font.family: Theme.font
            font.pixelSize: Theme.fontSize.body
            font.weight: Font.Medium
        }
        Text {
            visible: text !== ""
            width: parent.width
            text: row.description
            wrapMode: Text.Wrap
            color: Theme.colors.subtext
            font.family: Theme.font
            font.pixelSize: Theme.fontSize.small
        }
    }

    Item {
        id: slot
        anchors {
            right: parent.right
            rightMargin: 14
            verticalCenter: parent.verticalCenter
        }
        width: childrenRect.width
        height: childrenRect.height
    }
}
