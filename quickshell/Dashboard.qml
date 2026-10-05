import QtQuick
import QtQuick.Layouts

BarPopup {
    id: dash
    property var wallpaperPicker: null
    property int tab: 0

    contentWidth: 860

    readonly property var tabs: [
        { icon: "dashboard",     label: "Overview" },
        { icon: "music_note",    label: "Media" },
        { icon: "monitoring",    label: "System" },
        { icon: "notifications", label: "Notifications" },
    ]

    // Tab bar
    Row {
        id: tabBar
        width: parent.width

        Repeater {
            model: dash.tabs
            delegate: MouseArea {
                id: tb
                required property var modelData
                required property int index
                readonly property bool active: dash.tab === index

                width: tabBar.width / dash.tabs.length
                height: 52
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: dash.tab = index

                Column {
                    anchors.centerIn: parent
                    spacing: 2

                    Icon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        name: tb.modelData.icon
                        color: tb.active ? Theme.colors.primary : Theme.colors.subtext
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: tb.modelData.label
                        color: tb.active ? Theme.colors.primary
                            : tb.containsMouse ? Theme.colors.text
                            : Theme.colors.subtext
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize.small
                        font.weight: Font.Medium
                    }
                }

                // Underline for the active tab
                Rectangle {
                    anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
                    width: tb.active ? 40 : 0
                    height: 3
                    radius: 1.5
                    color: Theme.colors.primary
                    Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                }
            }
        }
    }

    Rectangle {
        width: parent.width
        height: 1
        color: Theme.colors.outlineVariant
    }

    // Pages; the dashboard takes the height of the current one
    StackLayout {
        width: parent.width
        height: children[currentIndex]?.implicitHeight ?? 0
        currentIndex: dash.tab

        OverviewPage {
            dashboard: dash
            wallpaperPicker: dash.wallpaperPicker
            targetScreen: dash.barWindow?.screen ?? null
        }

        MediaPage {
            active: dash.shown && dash.tab === 1
        }

        SystemPage {
            active: dash.shown && dash.tab === 2
        }

        // Placeholders until those pages are built
        Repeater {
            model: ["Notifications"]
            delegate: Item {
                required property string modelData
                implicitHeight: 200
                Text {
                    anchors.centerIn: parent
                    text: parent.modelData + " is coming soon"
                    color: Theme.colors.subtext
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize.body
                }
            }
        }
    }
}
