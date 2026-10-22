import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

FloatingWindow {
    id: win
    title: "Quickshell Settings"
    visible: false
    implicitWidth: 960
    implicitHeight: 640
    color: Theme.colors.surface

    property int page: 0
    property var picker: null  // set from shell.qml

    readonly property var pages: [
        {
            icon: "palette",
            label: "Appearance"
        },
        {
            icon: "notifications",
            label: "Notifications"
        },
        {
            icon: "dock_to_bottom",
            label: "Dock"
        },
        {
            icon: "toolbar",
            label: "Bar"
        },
        {
            icon: "wallpaper",
            label: "Wallpaper & Theme"
        },
        {
            icon: "grid_view",
            label: "Hyprland"
        },
        {
            icon: "info",
            label: "About"
        },
    ]

    // SUPER + comma: qs ipc call settings toggle
    // Always opens: if the window was closed by Hyprland, `visible` can still
    // read true, so reset it first, which brings the window back either way.
    IpcHandler {
        target: "settings"
        function toggle(): void {
            win.visible = false;
            win.visible = true;
        }
    }

    // Escape closes the window
    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: win.visible = false
    }

    // ── Sidebar ──────────────────────────────────────────
    Rectangle {
        id: sidebar
        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
        }
        width: 230
        color: Theme.colors.surfaceContainerLow ?? Theme.colors.surfaceContainer

        Column {
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 12
            }
            spacing: 2

            Text {
                leftPadding: 10
                topPadding: 6
                bottomPadding: 14
                text: "Settings"
                color: Theme.colors.text
                font.family: Theme.font
                font.pixelSize: Math.round(20 * Theme.fontScale)
                font.weight: Font.Bold
            }

            Repeater {
                model: win.pages
                delegate: MouseArea {
                    id: nav
                    required property var modelData
                    required property int index
                    readonly property bool active: win.page === index

                    width: parent.width
                    height: 40
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: win.page = index

                    Rectangle {
                        anchors.fill: parent
                        radius: 10
                        color: nav.active ? Theme.colors.primary : Theme.colors.surfaceContainerHigh
                        opacity: nav.active || nav.containsMouse ? 1 : 0
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 120
                            }
                        }
                    }
                    Row {
                        anchors {
                            left: parent.left
                            leftMargin: 12
                            verticalCenter: parent.verticalCenter
                        }
                        spacing: 12
                        Icon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: nav.modelData.icon
                            color: nav.active ? Theme.colors.primaryText : Theme.colors.subtext
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: nav.modelData.label
                            color: nav.active ? Theme.colors.primaryText : Theme.colors.text
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize.body
                            font.weight: Font.Medium
                        }
                    }
                }
            }
        }
    }

    // ── Current page ─────────────────────────────────────
    Flickable {
        anchors {
            left: sidebar.right
            right: parent.right
            top: parent.top
            bottom: parent.bottom
        }
        contentHeight: content.implicitHeight + 56
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: content
            x: 28
            y: 28
            width: parent.width - 56
            spacing: 20

            Text {
                text: win.pages[win.page].label
                color: Theme.colors.text
                font.family: Theme.font
                font.pixelSize: Math.round(24 * Theme.fontScale)
                font.weight: Font.Bold
            }

            StackLayout {
                width: parent.width
                height: children[currentIndex]?.implicitHeight ?? 0
                currentIndex: win.page

                AppearancePage {}
                NotificationSettingsPage {}
                DockSettingsPage {}
                BarSettingsPage {}
                WallpaperSettingsPage {
                    picker: win.picker
                    targetScreen: win.screen
                }
                HyprlandSettingsPage {}
                AboutPage {
                    active: win.visible && win.page === 6
                }
            }
        }
    }
}
