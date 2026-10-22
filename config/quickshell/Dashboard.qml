import QtQuick
import QtQuick.Layouts

BarPopup {
    id: dash
    property var wallpaperPicker: null
    property int tab: 0

    contentWidth: 860

    readonly property var tabs: [
        {
            icon: "dashboard",
            label: "Overview"
        },
        {
            icon: "music_note",
            label: "Media"
        },
        {
            icon: "monitoring",
            label: "System"
        },
        {
            icon: "notifications",
            label: "Notifications"
        },
    ]

    // Slide the new page in from the side you're moving towards
    property int lastTab: 0
    onTabChanged: {
        pageSlide.from = tab > lastTab ? 28 : -28;
        lastTab = tab;
        pageAnim.restart();
    }

    ParallelAnimation {
        id: pageAnim
        NumberAnimation {
            id: pageSlide
            target: pageShift
            property: "x"
            to: 0
            duration: 280
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: pages
            property: "opacity"
            from: 0
            to: 1
            duration: 220
        }
    }

    // Tab bar, with one indicator that slides to the selected tab
    Item {
        id: tabBar
        width: parent.width
        height: 52

        Row {
            id: tabRow
            anchors.fill: parent

            Repeater {
                id: tabRepeater
                model: dash.tabs
                delegate: MouseArea {
                    id: tb
                    required property var modelData
                    required property int index
                    readonly property bool active: dash.tab === index
                    readonly property real labelWidth: tabCol.implicitWidth

                    width: tabRow.width / dash.tabs.length
                    height: tabRow.height
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: dash.tab = index

                    Column {
                        id: tabCol
                        anchors.centerIn: parent
                        spacing: 2

                        Icon {
                            anchors.horizontalCenter: parent.horizontalCenter
                            name: tb.modelData.icon
                            color: tb.active ? Theme.colors.primary : Theme.colors.subtext
                            Behavior on color {
                                ColorAnimation {
                                    duration: 200
                                }
                            }
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: tb.modelData.label
                            color: tb.active ? Theme.colors.primary : tb.containsMouse ? Theme.colors.text : Theme.colors.subtext
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize.small
                            font.weight: Font.Medium
                            Behavior on color {
                                ColorAnimation {
                                    duration: 200
                                }
                            }
                        }
                    }
                }
            }
        }

        // The sliding indicator, as wide as the selected tab's label
        Rectangle {
            readonly property var target: tabRepeater.count > dash.tab ? tabRepeater.itemAt(dash.tab) : null
            readonly property real targetWidth: target ? target.labelWidth + 12 : 0

            anchors.bottom: parent.bottom
            height: 3
            radius: 1.5
            color: Theme.colors.primary

            width: targetWidth
            x: target ? target.x + (target.width - targetWidth) / 2 : 0

            Behavior on x {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on width {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutCubic
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
        id: pages
        width: parent.width
        height: children[currentIndex]?.implicitHeight ?? 0
        currentIndex: dash.tab
        clip: true // while the height animates, the new page doesn't spill over

        Behavior on height {
            NumberAnimation {
                duration: 240
                easing.type: Easing.OutCubic
            }
        }

        transform: Translate {
            id: pageShift
        }

        OverviewPage {
            dashboard: dash
            wallpaperPicker: dash.wallpaperPicker
            targetScreen: dash.barWindow?.screen ?? null
        }

        MediaPage {
            active: dash.shown && dash.tab === 1
            dashboard: dash
        }

        SystemPage {
            active: dash.shown && dash.tab === 2
        }

        NotificationsPage {
            active: dash.shown && dash.tab === 3
            dashboard: dash
        }
    }
}
