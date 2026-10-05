import QtQuick

Column {
    id: cal
    property date today: new Date()
    property date shown: new Date()  // the month on display
    spacing: 6

    function dayAt(i) {
        const first = new Date(shown.getFullYear(), shown.getMonth(), 1);
        const offset = (first.getDay() + 6) % 7;  // Monday = 0
        return new Date(shown.getFullYear(), shown.getMonth(), 1 - offset + i);
    }
    function shiftMonth(n) {
        shown = new Date(shown.getFullYear(), shown.getMonth() + n, 1);
    }

    // Month and navigation
    Item {
        width: parent.width
        height: 28

        Text {
            anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
            text: Qt.formatDate(cal.shown, "MMMM yyyy")
            color: Theme.colors.text
            font.family: Theme.font
            font.pixelSize: Theme.fontSize.body
            font.weight: Font.Medium
        }

        Row {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            spacing: 2

            Repeater {
                model: [{ icon: "chevron_left", n: -1 }, { icon: "chevron_right", n: 1 }]
                delegate: MouseArea {
                    id: nav
                    required property var modelData
                    width: 26
                    height: 26
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: cal.shiftMonth(modelData.n)

                    Rectangle {
                        anchors.fill: parent
                        radius: 8
                        color: Theme.colors.surfaceContainerHigh
                        opacity: nav.containsMouse ? 1 : 0
                    }
                    Icon {
                        anchors.centerIn: parent
                        name: nav.modelData.icon
                        color: Theme.colors.subtext
                    }
                }
            }
        }
    }

    // Weekdays
    Row {
        Repeater {
            model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
            delegate: Text {
                required property string modelData
                width: cal.width / 7
                horizontalAlignment: Text.AlignHCenter
                text: modelData
                color: Theme.colors.subtext
                font.family: Theme.font
                font.pixelSize: Theme.fontSize.tiny
            }
        }
    }

    // Days: six weeks, so every month fits
    Grid {
        columns: 7

        Repeater {
            model: 42
            delegate: Item {
                required property int index
                readonly property date day: cal.dayAt(index)
                readonly property bool inMonth: day.getMonth() === cal.shown.getMonth()
                readonly property bool isToday: day.toDateString() === cal.today.toDateString()

                width: cal.width / 7
                height: 28

                Rectangle {
                    anchors.centerIn: parent
                    width: 26
                    height: 26
                    radius: 13
                    color: parent.isToday ? Theme.colors.primary : "transparent"
                }
                Text {
                    anchors.centerIn: parent
                    text: parent.day.getDate()
                    color: parent.isToday ? Theme.colors.primaryText
                        : parent.inMonth ? Theme.colors.text
                        : Theme.colors.outline
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize.small
                    font.weight: parent.isToday ? Font.Bold : Font.Normal
                }
            }
        }
    }
}
