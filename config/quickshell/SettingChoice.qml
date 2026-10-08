import QtQuick

Row {
    id: choice
    property var options: []   // [{ value, label }]
    property var current
    signal chosen(var value)

    spacing: 4

    Repeater {
        model: choice.options
        delegate: MouseArea {
            id: opt
            required property var modelData
            readonly property bool active: modelData.value === choice.current

            width: optLabel.implicitWidth + 24
            height: 32
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: choice.chosen(modelData.value)

            Rectangle {
                anchors.fill: parent
                radius: 10
                color: opt.active ? Theme.colors.primary : opt.containsMouse ? Theme.colors.surfaceContainerHighest ?? Theme.colors.surfaceContainerHigh : Theme.colors.surfaceContainerHigh
                Behavior on color {
                    ColorAnimation {
                        duration: 120
                    }
                }
            }
            Text {
                id: optLabel
                anchors.centerIn: parent
                text: opt.modelData.label
                color: opt.active ? Theme.colors.primaryText : Theme.colors.text
                font.family: Theme.font
                font.pixelSize: Theme.fontSize.small
                font.weight: Font.Medium
            }
        }
    }
}
