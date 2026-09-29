import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import Quickshell.Widgets

PanelWindow {
    id: root
    property bool shown: false
    property var barWindow: null

    // Stay visible while the panel slides out, then hide
    visible: shown || panel.x < width

    anchors { top: true; bottom: true; right: true }
    exclusiveZone: 0   // the bar's reserved space keeps us below it
    implicitWidth: 380
    color: "transparent"
    WlrLayershell.namespace: "qs-sidebar"
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property var player: Mpris.players.values.find(p => p.isPlaying)
        ?? Mpris.players.values[0] ?? null

    function open(target, bar) {
        const mon = Hyprland.focusedMonitor;
        screen = target ?? Quickshell.screens.find(s => s.name === mon?.name) ?? Quickshell.screens[0];
        barWindow = bar ?? null;
        shown = true;
        Panels.opened(root);
        grabDelay.restart();
        panel.forceActiveFocus();
    }
    function close() {
        shown = false;
        grab.active = false;
        Panels.closed(root);
    }
    function toggle(target, bar) { shown ? close() : open(target, bar) }

    IpcHandler {
        target: "sidebar"
        function toggle(): void { root.toggle() }
    }

    PwObjectTracker { objects: [root.sink, root.source] }

    HyprlandFocusGrab {
        id: grab
        windows: root.barWindow ? [root, root.barWindow] : [root]
        onCleared: root.close()
    }
    Timer {
        id: grabDelay
        interval: 50
        onTriggered: grab.active = root.shown
    }

    Rectangle {
        id: panel
        y: 8
        width: parent.width - 8
        height: parent.height - 16
        x: root.shown ? 0 : root.width + 20
        Behavior on x { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }

        radius: 16
        color: Theme.colors.surface
        border.width: 1
        border.color: Theme.colors.outlineVariant

        focus: true
        Keys.onEscapePressed: root.close()

        Flickable {
            anchors { fill: parent; margins: 12 }
            contentHeight: col.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: col
                width: parent.width
                spacing: 12

                // ── Header: clock + power ──────────────────────────
                Item {
                    id: header
                    width: parent.width
                    height: clockCol.implicitHeight

                    // The power button under the mouse, for the hint text
                    property var hovered: null

                    SystemClock { id: clock; precision: SystemClock.Minutes }

                    Column {
                        id: clockCol
                        anchors { left: parent.left; leftMargin: 4; top: parent.top }
                        Text {
                            text: Qt.formatDateTime(clock.date, "HH:mm")
                            color: Theme.colors.text
                            font.family: Theme.font
                            font.pixelSize: Math.round(28 * Theme.fontScale)
                            font.weight: Font.Medium
                        }
                        Text {
                            readonly property var hb: header.hovered
                            text: !hb ? Qt.formatDateTime(clock.date, "dddd, d MMMM")
                                : hb.armed ? "Click again to " + hb.modelData.label.toLowerCase()
                                : hb.modelData.label
                            color: hb?.armed ? Theme.colors.primary : Theme.colors.subtext
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize.small
                        }
                    }

                    Row {
                        anchors { right: parent.right; top: parent.top; topMargin: 2 }
                        spacing: 6

                        Repeater {
                            model: [
                                { icon: "bedtime",            label: "Suspend",   confirm: false, cmd: ["systemctl", "suspend"] },
                                { icon: "logout", label: "Log out", confirm: true, cmd: ["sh", "-c", "command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"] },
                                { icon: "restart_alt",        label: "Reboot",    confirm: true,  cmd: ["systemctl", "reboot"] },
                                { icon: "power_settings_new", label: "Shut down", confirm: true,  cmd: ["systemctl", "poweroff"] },
                            ]
                            delegate: MouseArea {
                                id: pb
                                required property var modelData
                                property bool armed: false
                                width: 32
                                height: 32
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor

                                onContainsMouseChanged: {
                                    if (containsMouse) header.hovered = pb;
                                    else if (header.hovered === pb) header.hovered = null;
                                }
                                onClicked: {
                                    if (modelData.confirm && !armed) {
                                        armed = true;
                                        disarm.restart();
                                        return;
                                    }
                                    root.close();
                                    Quickshell.execDetached(modelData.cmd);
                                }

                                Timer { id: disarm; interval: 3000; onTriggered: pb.armed = false }

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 10
                                    color: pb.armed ? Theme.colors.primary : Theme.colors.surfaceContainerHigh
                                    opacity: pb.armed || pb.containsMouse ? 1 : 0.6
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                                Icon {
                                    anchors.centerIn: parent
                                    name: pb.modelData.icon
                                    color: pb.armed ? Theme.colors.primaryText : Theme.colors.text
                                }
                            }
                        }
                    } 
                }               

                // ── Toggles ────────────────────────────────────────
                Grid {
                    id: toggles
                    width: parent.width
                    columns: 2
                    spacing: 8
                    readonly property real tileWidth: (width - spacing) / 2

                    ToggleTile {
                        width: toggles.tileWidth
                        icon: Notifs.dnd ? "do_not_disturb_on" : "do_not_disturb_off"
                        label: "Do Not Disturb"
                        active: Notifs.dnd
                        onClicked: Notifs.dnd = !Notifs.dnd
                    }
                    ToggleTile {
                        width: toggles.tileWidth
                        icon: "nightlight"
                        label: "Night light"
                        active: Panels.nightLight
                        onClicked: Panels.nightLight = !Panels.nightLight
                    }
                    ToggleTile {
                        readonly property bool muted: root.sink?.audio?.muted ?? true
                        width: toggles.tileWidth
                        icon: muted ? "volume_off" : "volume_up"
                        label: "Speaker"
                        active: !muted
                        onClicked: if (root.sink?.audio) root.sink.audio.muted = !muted
                    }
                    ToggleTile {
                        readonly property bool muted: root.source?.audio?.muted ?? true
                        width: toggles.tileWidth
                        icon: muted ? "mic_off" : "mic"
                        label: "Microphone"
                        active: !muted
                        onClicked: if (root.source?.audio) root.source.audio.muted = !muted
                    }
                }

                // ── Sliders ────────────────────────────────────────
                Rectangle {
                    width: parent.width
                    height: sliders.implicitHeight + 24
                    radius: Theme.radius
                    color: Theme.colors.surfaceContainer

                    Column {
                        id: sliders
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                        spacing: 14

                        Repeater {
                            model: [
                                { icon: "volume_up", node: root.sink },
                                { icon: "mic",       node: root.source },
                            ]
                            delegate: Row {
                                required property var modelData
                                readonly property real vol: modelData.node?.audio?.volume ?? 0
                                width: sliders.width
                                spacing: 10

                                Icon {
                                    anchors.verticalCenter: parent.verticalCenter
                                    name: parent.modelData.icon
                                    color: Theme.colors.subtext
                                }
                                SliderBar {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - 72
                                    value: parent.vol
                                    onMoved: v => {
                                        const a = parent.modelData.node?.audio;
                                        if (a) a.volume = v;
                                    }
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 34
                                    horizontalAlignment: Text.AlignRight
                                    text: Math.round(parent.vol * 100) + "%"
                                    color: Theme.colors.text
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontSize.small
                                }
                            }
                        }
                    }
                }

                // ── Media ──────────────────────────────────────────
                Rectangle {
                    visible: root.player !== null
                    width: parent.width
                    height: 88
                    radius: Theme.radius
                    color: Theme.colors.surfaceContainer

                    ClippingRectangle {
                        id: art
                        anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                        width: 64
                        height: 64
                        radius: 10
                        color: Theme.colors.surfaceContainerHigh

                        Image {
                            anchors.fill: parent
                            source: root.player?.trackArtUrl ?? ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }
                        Icon {
                            anchors.centerIn: parent
                            visible: !(root.player?.trackArtUrl)
                            name: "music_note"
                            font.pixelSize: 28
                            color: Theme.colors.subtext
                        }
                    }

                    Column {
                        anchors {
                            left: art.right; leftMargin: 12
                            right: parent.right; rightMargin: 12
                            verticalCenter: parent.verticalCenter
                        }
                        spacing: 2

                        Text {
                            width: parent.width
                            text: root.player?.trackTitle || "Unknown title"
                            elide: Text.ElideRight
                            color: Theme.colors.text
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize.body
                            font.weight: Font.Medium
                        }
                        Text {
                            width: parent.width
                            text: root.player?.trackArtist || root.player?.identity || ""
                            elide: Text.ElideRight
                            color: Theme.colors.subtext
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize.small
                        }

                        Row {
                            topPadding: 4
                            spacing: 4

                            Repeater {
                                model: [
                                    { icon: "skip_previous", run: () => root.player?.previous() },
                                    { icon: root.player?.isPlaying ? "pause" : "play_arrow", run: () => root.player?.togglePlaying() },
                                    { icon: "skip_next", run: () => root.player?.next() },
                                ]
                                delegate: MouseArea {
                                    id: mb
                                    required property var modelData
                                    width: 30
                                    height: 30
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: modelData.run()

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 8
                                        color: Theme.colors.surfaceContainerHigh
                                        opacity: mb.containsMouse ? 1 : 0
                                    }
                                    Icon {
                                        anchors.centerIn: parent
                                        name: mb.modelData.icon
                                        color: Theme.colors.text
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
