import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Wayland

// Volume and brightness indicator that slides out of the right side of the frame
PanelWindow {
    id: root
    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false

    property string mode: "volume"  // or "brightness"
    readonly property bool isVolume: mode === "volume"
    readonly property real value: isVolume ? volume : Brightness.percent
    readonly property bool dimmed: isVolume && muted

    property bool shown: false
    property bool ready: false  // ignore the values reported while starting up

    function show(m) {
        // Popups and the dashboard already show these values
        if (!ready || Panels.current !== null) return;
        mode = m;
        const mon = Hyprland.focusedMonitor;
        screen = Quickshell.screens.find(s => s.name === mon?.name) ?? screen;
        shown = true;
        hideTimer.restart();
    }

    PwObjectTracker { objects: [root.sink] }
    onVolumeChanged: show("volume")
    onMutedChanged: show("volume")

    Connections {
        target: Brightness
        function onChangedByKey() { root.show("brightness") }
    }

    Timer { interval: 1500; running: true; onTriggered: root.ready = true }
    Timer { id: hideTimer; interval: 1500; onTriggered: root.shown = false }

    // Always mapped, just slid out of view, so it appears instantly
    anchors { right: true }
    exclusiveZone: 0  // the right band's reserved space keeps it flush with the frame
    implicitWidth: 64
    implicitHeight: 210 + Theme.frame.radius * 2
    color: "transparent"
    mask: Region {}  // clicks pass straight through
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-osd"

    Item {
        id: panel
        width: parent.width
        height: parent.height
        x: root.shown ? 0 : width
        Behavior on x { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

        FramePanel {
            anchors.fill: parent
            edge: "rightMid"
        }

        Column {
            anchors.centerIn: parent
            spacing: 10

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.dimmed ? "Muted" : Math.round(root.value * 100) + "%"
                color: Theme.colors.text
                font.family: Theme.font
                font.pixelSize: Theme.fontSize.small
                font.weight: Font.Medium
            }

            // Vertical bar, filled from the bottom
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 8
                height: 140
                radius: 4
                color: Theme.colors.surfaceContainerHigh

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: parent.height * Math.max(0, Math.min(1, root.value))
                    radius: 4
                    color: root.dimmed ? Theme.colors.outline : Theme.colors.primary
                    Behavior on height { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }

            Icon {
                anchors.horizontalCenter: parent.horizontalCenter
                name: !root.isVolume
                    ? (root.value < 0.34 ? "brightness_low" : root.value < 0.67 ? "brightness_medium" : "brightness_high")
                    : root.muted ? "volume_off"
                    : root.volume < 0.01 ? "volume_mute"
                    : root.volume < 0.5 ? "volume_down"
                    : "volume_up"
                color: root.dimmed ? Theme.colors.outline : Theme.colors.primary
            }
        }
    }
}
