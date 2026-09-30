import QtQuick

// A rounded pill that groups bar elements
Rectangle {
    id: chip
    default property alias content: row.data
    property int padding: 12
    property alias spacing: row.spacing

    implicitWidth: row.implicitWidth + padding * 2
    implicitHeight: 28
    radius: height / 2
    color: Theme.colors.surfaceContainerHigh

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 12
    }
}
