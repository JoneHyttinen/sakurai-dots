import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets

PanelWindow {
    id: root
    required property var modelData
    screen: modelData

    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(modelData)
    readonly property var workspace: monitor?.activeWorkspace ?? null
    readonly property bool shown: workspace !== null && workspace.toplevels.values.length === 0

    // Desktop entry IDs: the .desktop file name without the extension
    readonly property var pinned: [
        "firefox-developer-edition",
        "Alacritty",
        "org.kde.dolphin",
        "steam",
        "spotify",
        "discord",
    ]

    property var launcher: null

    anchors { bottom: true; left: true; right: true }
    implicitHeight: 100
    color: "transparent"
    exclusionMode: ExclusionMode.Normal 
    exclusiveZone: 0  // sit above the frame's bottom band, without reserving space
    WlrLayershell.namespace: "qs-dock"
    mask: Region { item: dock }          // only the dock itself takes clicks

    Item {
        id: dock
        anchors.horizontalCenter: parent.horizontalCenter
        width: row.implicitWidth + 20 + Theme.frame.radius * 2
        height: 64

        // Flush against the frame when shown; slides down into it when hidden
        y: root.shown ? parent.height - height : parent.height
        Behavior on y { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }

        FramePanel {
            anchors.fill: parent
            edge: "bottom"
        }
        
        Row {
            id: row
            anchors.centerIn: parent
            spacing: 8

            MouseArea {
                id: launcherButton
                visible: root.launcher !== null
                width: 48
                height: 48
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.launcher.toggle(root.screen)

                Rectangle {
                    anchors.fill: parent
                    radius: 14
                    color: Theme.colors.surfaceContainerHigh
                    opacity: launcherButton.containsMouse ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }

                Icon {
                    anchors.centerIn: parent
                    name: "apps"
                    font.pixelSize: 28
                    color: Theme.colors.primary
                    scale: launcherButton.pressed ? 0.9 : (launcherButton.containsMouse ? 1.08 : 1)
                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                }
            }

            Rectangle {
                visible: root.launcher !== null
                anchors.verticalCenter: parent.verticalCenter
                width: 1
                height: 32
                color: Theme.colors.outlineVariant
            }

            Repeater {
                model: root.pinned
                delegate: Item {
                    id: app
                    required property string modelData
                    // Mentioning applications.values makes this re-run once
                    // Quickshell finishes scanning .desktop files at startup
                    readonly property var entry: {
                        DesktopEntries.applications.values;
                        return DesktopEntries.byId(modelData);
                    }

                    visible: entry !== null
                    width: 48
                    height: 48

                    Rectangle {
                        anchors.fill: parent
                        radius: 14
                        color: Theme.colors.surfaceContainerHigh
                        opacity: mouse.containsMouse ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }

                    IconImage {
                        anchors.centerIn: parent
                        implicitSize: 36
                        source: app.entry ? Quickshell.iconPath(app.entry.icon) : ""
                        scale: mouse.pressed ? 0.9 : (mouse.containsMouse ? 1.08 : 1)
                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                    }

                    MouseArea {
                        id: mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: app.entry?.execute()
                    }
                }
            }
        }
    }
}
