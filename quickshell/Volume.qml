import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

MouseArea {
    id: root
    readonly property var win: QsWindow.window
    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? true
    readonly property var sinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio)

    function setVolume(v) { if (sink?.audio) sink.audio.volume = Math.max(0, Math.min(1, v)) }
    function setMuted(m) { if (sink?.audio) sink.audio.muted = m }

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight
    cursorShape: Qt.PointingHandCursor
    onClicked: popup.toggle()
    onWheel: wheel => setVolume(volume + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))

    PwObjectTracker { objects: [root.sink] }

    Row {
        id: row
        spacing: 4
        Icon {
            anchors.verticalCenter: parent.verticalCenter
            name: root.muted ? "volume_off"
                : root.volume < 0.01 ? "volume_mute"
                : root.volume < 0.5 ? "volume_down"
                : "volume_up"
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round(root.volume * 100) + "%"
            color: Theme.colors.subtext
            font.family: Theme.font
            font.pixelSize: Theme.fontSize.small
            font.weight: Font.Medium
        }
    }

    BarPopup {
        id: popup
        anchorItem: root
        barWindow: root.win
        contentWidth: 300

        Text {
            text: "Output"
            color: Theme.colors.subtext
            font.family: Theme.font
            font.pixelSize: Theme.fontSize.small
            font.weight: Font.Medium
        }

        Row {
            width: parent.width
            spacing: 10

            MouseArea {
                width: 24
                height: 24
                anchors.verticalCenter: parent.verticalCenter
                cursorShape: Qt.PointingHandCursor
                onClicked: root.setMuted(!root.muted)
                Icon {
                    anchors.centerIn: parent
                    name: root.muted ? "volume_off" : "volume_up"
                    color: root.muted ? Theme.colors.subtext : Theme.colors.primary
                }
            }
            SliderBar {
                width: parent.width - 78
                anchors.verticalCenter: parent.verticalCenter
                value: root.volume
                onMoved: v => root.setVolume(v)
            }
            Text {
                width: 34
                anchors.verticalCenter: parent.verticalCenter
                horizontalAlignment: Text.AlignRight
                text: Math.round(root.volume * 100) + "%"
                color: Theme.colors.text
                font.family: Theme.font
                font.pixelSize: Theme.fontSize.small
            }
        }

        Rectangle { width: parent.width; height: 1; color: Theme.colors.outlineVariant }

        Text {
            text: "Devices"
            color: Theme.colors.subtext
            font.family: Theme.font
            font.pixelSize: Theme.fontSize.small
            font.weight: Font.Medium
        }

        Column {
            width: parent.width
            spacing: 2
            Repeater {
                model: root.sinks
                delegate: MenuRow {
                    required property PwNode modelData
                    label: modelData.description || modelData.nickname || modelData.name
                    icon: /headphone|headset/i.test(label) ? "headphones" : "speaker"
                    selected: modelData === root.sink
                    onClicked: Pipewire.preferredDefaultAudioSink = modelData
                }
            }
        }

        MenuRow {
            icon: "tune"
            label: "Sound settings"
            onClicked: {
                popup.close();
                Quickshell.execDetached(["pavucontrol"]);
            }
        }
    }
}
