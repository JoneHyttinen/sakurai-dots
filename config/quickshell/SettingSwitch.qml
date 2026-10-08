import QtQuick

MouseArea {
    id: sw
    property bool checked: false
    signal toggled(bool value)

    width: 46
    height: 26
    cursorShape: Qt.PointingHandCursor
    onClicked: toggled(!checked)

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: sw.checked ? Theme.colors.primary : Theme.colors.surfaceContainerHigh
        border.width: sw.checked ? 0 : 1
        border.color: Theme.colors.outline
        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        x: sw.checked ? parent.width - width - 4 : 4
        width: sw.checked ? 18 : 14
        height: width
        radius: width / 2
        color: sw.checked ? Theme.colors.primaryText : Theme.colors.outline
        Behavior on x {
            NumberAnimation {
                duration: 160
                easing.type: Easing.OutCubic
            }
        }
        Behavior on width {
            NumberAnimation {
                duration: 160
            }
        }
    }
}
