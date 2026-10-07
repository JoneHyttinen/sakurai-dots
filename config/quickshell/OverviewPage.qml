import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Widgets

Item {
    id: page
    property var dashboard: null        // closed after actions
    property var wallpaperPicker: null
    property var targetScreen: null

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property var player: Mpris.players.values.find(p => p.isPlaying)
        ?? Mpris.players.values[0] ?? null

    // Spotify reports cover art at an address that doesn't serve the image
    function artUrl(url) {
        if (!url) return "";
        return url.replace("https://open.spotify.com/image/", "https://i.scdn.co/image/");
    }

    implicitHeight: content.implicitHeight

    PwObjectTracker { objects: [page.sink, page.source] }
    SystemClock { id: clock; precision: SystemClock.Minutes }

    Row {
        id: content
        width: parent.width
        spacing: 12
        readonly property real sideWidth: 260
        readonly property real midWidth: width - sideWidth * 2 - spacing * 2

        // ── Left: clock and calendar ─────────────────────
        Rectangle {
            width: content.sideWidth
            height: leftCol.implicitHeight + 24
            radius: Theme.radius
            color: Theme.colors.surfaceContainer

            Column {
                id: leftCol
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                spacing: 10

                Column {
                    leftPadding: 4
                    Text {
                        text: Qt.formatDateTime(clock.date, "HH:mm")
                        color: Theme.colors.text
                        font.family: Theme.font
                        font.pixelSize: Math.round(34 * Theme.fontScale)
                        font.weight: Font.Medium
                    }
                    Text {
                        text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
                        color: Theme.colors.subtext
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize.small
                    }
                }

                Calendar {
                    width: parent.width
                    today: clock.date
                }
            }
        }

        // ── Middle: toggles and sliders ──────────────────
        Column {
            width: content.midWidth
            spacing: 12

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
                    icon: "coffee"
                    label: "Keep awake"
                    active: Panels.keepAwake
                    onClicked: Panels.keepAwake = !Panels.keepAwake
                }
                ToggleTile {
                    width: toggles.tileWidth
                    icon: "nightlight"
                    label: "Night light"
                    active: Panels.nightLight
                    onClicked: Panels.nightLight = !Panels.nightLight
                }
                ToggleTile {
                    width: toggles.tileWidth
                    icon: Theme.dark ? "dark_mode" : "light_mode"
                    label: Theme.dark ? "Dark mode" : "Light mode"
                    active: Theme.dark
                    onClicked: Theme.toggleMode()
                }
                ToggleTile {
                    readonly property bool muted: page.source?.audio?.muted ?? true
                    width: toggles.tileWidth
                    icon: muted ? "mic_off" : "mic"
                    label: "Microphone"
                    active: !muted
                    onClicked: if (page.source?.audio) page.source.audio.muted = !muted
                }
                ToggleTile {
                    width: toggles.tileWidth
                    icon: "wallpaper"
                    label: "Wallpaper"
                    onClicked: {
                        page.dashboard?.close();
                        page.wallpaperPicker?.open(page.targetScreen);
                    }
                }
            }

            // Sliders; click an icon to mute
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
                            { icon: "volume_up", off: "volume_off", node: page.sink },
                            { icon: "mic",       off: "mic_off",    node: page.source },
                        ]
                        delegate: Row {
                            id: sliderRow
                            required property var modelData
                            readonly property var audio: modelData.node?.audio ?? null
                            readonly property real vol: audio?.volume ?? 0
                            readonly property bool muted: audio?.muted ?? true
                            width: sliders.width
                            spacing: 10

                            MouseArea {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 24
                                height: 24
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (sliderRow.audio) sliderRow.audio.muted = !sliderRow.muted

                                Icon {
                                    anchors.centerIn: parent
                                    name: sliderRow.muted ? sliderRow.modelData.off : sliderRow.modelData.icon
                                    color: sliderRow.muted ? Theme.colors.outline : Theme.colors.subtext
                                }
                            }
                            SliderBar {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 78
                                value: sliderRow.vol
                                onMoved: v => { if (sliderRow.audio) sliderRow.audio.volume = v }
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 34
                                horizontalAlignment: Text.AlignRight
                                text: Math.round(sliderRow.vol * 100) + "%"
                                color: Theme.colors.text
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize.small
                            }
                        }
                    }
                    // Screen brightness (laptops)
                    Row {
                        visible: Brightness.available
                        width: sliders.width
                        spacing: 10

                        Icon {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 24
                            horizontalAlignment: Text.AlignHCenter
                            name: "brightness_medium"
                            color: Theme.colors.subtext
                        }
                        SliderBar {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 78
                            value: Brightness.percent
                            onMoved: v => Brightness.set(v)
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 34
                            horizontalAlignment: Text.AlignRight
                            text: Math.round(Brightness.percent * 100) + "%"
                            color: Theme.colors.text
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize.small
                        }
                    }
            // Power profiles (laptop)
            Rectangle {
                visible: Host.laptop
                width: parent.width
                height: 76
                radius: Theme.radius
                color: Theme.colors.surfaceContainer

                Row {
                    id: profiles
                    anchors.centerIn: parent
                    spacing: 6

                    Repeater {
                        model: [
                            { icon: "energy_savings_leaf", label: "Saver",       profile: PowerProfile.PowerSaver },
                            { icon: "balance",             label: "Balanced",    profile: PowerProfile.Balanced },
                            { icon: "bolt",                label: "Performance", profile: PowerProfile.Performance },
                        ]
                        delegate: MouseArea {
                            id: pp
                            required property var modelData
                            readonly property bool active: PowerProfiles.profile === modelData.profile

                            // Some laptops have no performance profile
                            visible: modelData.profile !== PowerProfile.Performance || PowerProfiles.hasPerformanceProfile
                            width: 84
                            height: 56
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: PowerProfiles.profile = modelData.profile

                            Rectangle {
                                anchors.fill: parent
                                radius: 12
                                color: pp.active ? Theme.colors.primary
                                    : pp.containsMouse ? Theme.colors.surfaceContainerHigh
                                    : "transparent"
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                            Column {
                                anchors.centerIn: parent
                                spacing: 2
                                Icon {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    name: pp.modelData.icon
                                    color: pp.active ? Theme.colors.primaryText : Theme.colors.text
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: pp.modelData.label
                                    color: pp.active ? Theme.colors.primaryText : Theme.colors.subtext
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontSize.tiny
                                    font.weight: Font.Medium
                                }
                            }
                        }
                    }
                }
            }
                }
            }
        }

        // ── Right: media and power ───────────────────────
        Column {
            width: content.sideWidth
            spacing: 12

            // Media
            Rectangle {
                width: parent.width
                height: 96
                radius: Theme.radius
                color: Theme.colors.surfaceContainer

                // Nothing playing
                Row {
                    visible: page.player === null
                    anchors.centerIn: parent
                    spacing: 8
                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: "music_off"
                        color: Theme.colors.outline
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Nothing playing"
                        color: Theme.colors.subtext
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize.body
                    }
                }

                ClippingRectangle {
                    id: art
                    visible: page.player !== null
                    anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                    width: 68
                    height: 68
                    radius: 10
                    color: Theme.colors.surfaceContainerHigh

                    Image {
                        id: artImage
                        anchors.fill: parent
                        source: page.artUrl(page.player?.trackArtUrl)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                    Icon {
                        anchors.centerIn: parent
                        visible: artImage.status !== Image.Ready
                        name: "music_note"
                        font.pixelSize: 28
                        color: Theme.colors.subtext
                    }
                    // Click the cover to jump to the player's window
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            page.dashboard?.close();
                            MediaFocus.focus(page.player);
                        }
                    }
                }

                Column {
                    visible: page.player !== null
                    anchors {
                        left: art.right; leftMargin: 12
                        right: parent.right; rightMargin: 12
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: 2

                    Text {
                        width: parent.width
                        text: page.player?.trackTitle || "Unknown title"
                        elide: Text.ElideRight
                        color: Theme.colors.text
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize.body
                        font.weight: Font.Medium
                    }
                    Text {
                        width: parent.width
                        text: page.player?.trackArtist || page.player?.identity || ""
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
                                { icon: "skip_previous", run: () => page.player?.previous() },
                                { icon: page.player?.isPlaying ? "pause" : "play_arrow", run: () => page.player?.togglePlaying() },
                                { icon: "skip_next", run: () => page.player?.next() },
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

            // Power
            Rectangle {
                width: parent.width
                height: powerCol.implicitHeight + 24
                radius: Theme.radius
                color: Theme.colors.surfaceContainer

                Column {
                    id: powerCol
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                    spacing: 8

                    Row {
                        id: powerRow
                        property var hovered: null  // button under the mouse, for the hint
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 8

                        Repeater {
                            model: [
                                { icon: "bedtime",            label: "Suspend",   confirm: false, cmd: ["systemctl", "suspend"] },
                                { icon: "lock",               label: "Lock",      confirm: false, cmd: ["loginctl", "lock-session"] },
                                { icon: "logout",             label: "Log out",   confirm: true,  cmd: ["sh", "-c", "command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"] },
                                { icon: "restart_alt",        label: "Reboot",    confirm: true,  cmd: ["systemctl", "reboot"] },
                                { icon: "power_settings_new", label: "Shut down", confirm: true,  cmd: ["systemctl", "poweroff"] },
                            ]
                            delegate: MouseArea {
                                id: pb
                                required property var modelData
                                property bool armed: false
                                width: 36
                                height: 36
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor

                                onContainsMouseChanged: {
                                    if (containsMouse) powerRow.hovered = pb;
                                    else if (powerRow.hovered === pb) powerRow.hovered = null;
                                }
                                onClicked: {
                                    if (modelData.confirm && !armed) {
                                        armed = true;
                                        disarm.restart();
                                        return;
                                    }
                                    page.dashboard?.close();
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

                    // What the hovered button does
                    Text {
                        readonly property var hb: powerRow.hovered
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: !hb ? "Power"
                            : hb.armed ? "Click again to " + hb.modelData.label.toLowerCase()
                            : hb.modelData.label
                        color: hb?.armed ? Theme.colors.primary : Theme.colors.subtext
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize.small
                    }
                }
            }
        }
    }
}
