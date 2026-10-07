import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Widgets
import Quickshell.Services.Pipewire

Item {
    id: page
    property bool active: false  // true while this tab is showing; runs the visualizer
    property var dashboard: null  // closed when jumping to the player

    // The player picked in the list, or else the one that's playing
    property var chosen: null
    readonly property var players: Mpris.players.values
    readonly property var player: (chosen !== null && players.includes(chosen)) ? chosen
        : players.find(p => p.isPlaying) ?? players[0] ?? null

    // Visualizer levels from cava, 0..1
    property var levels: []

    // Volume: the player's own where supported, otherwise the system volume
    property bool volumeOpen: false
    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool playerVolume: player?.volumeSupported ?? false
    readonly property real vol: playerVolume ? player.volume : (sink?.audio?.volume ?? 0)

    function setVol(v) {
        v = Math.max(0, Math.min(1, v));
        if (playerVolume) player.volume = v;
        else if (sink?.audio) sink.audio.volume = v;
    }

    PwObjectTracker { objects: [page.sink] }

    // Spotify reports cover art at an address that doesn't serve the image
    function artUrl(url) {
        if (!url) return "";
        return url.replace("https://open.spotify.com/image/", "https://i.scdn.co/image/");
    }
    function fmt(s) {
        if (!isFinite(s) || s < 0) s = 0;
        const m = Math.floor(s / 60);
        const sec = Math.floor(s % 60);
        return m + ":" + (sec < 10 ? "0" : "") + sec;
    }

    implicitHeight: col.implicitHeight

    // Players don't report their position continuously, so ask once a second
    Timer {
        interval: 1000
        repeat: true
        running: page.active && (page.player?.isPlaying ?? false)
        onTriggered: page.player?.positionChanged()
    }

    Process {
        running: page.active
        command: ["cava", "-p", Quickshell.env("HOME") + "/.config/quickshell/cava.conf"]
        stdout: SplitParser {
            onRead: data => {
                page.levels = data.split(";").filter(s => s !== "").map(n => Number(n) / 100);
            }
        }
        onRunningChanged: if (!running) page.levels = []
    }

    // ── A round control button ───────────────────────────
    component ControlButton: MouseArea {
        id: btn
        property string icon
        property bool on: false     // shuffle/repeat enabled
        property bool big: false    // the play/pause button

        width: big ? 52 : 38
        height: width
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: btn.big ? Theme.colors.primary : Theme.colors.surfaceContainerHigh
            opacity: btn.big ? 1 : (btn.containsMouse ? 1 : 0)
            scale: btn.pressed ? 0.92 : 1
            Behavior on opacity { NumberAnimation { duration: 120 } }
            Behavior on scale { NumberAnimation { duration: 100 } }
        }
        Icon {
            anchors.centerIn: parent
            name: btn.icon
            font.pixelSize: btn.big ? 28 : 22
            color: btn.big ? Theme.colors.primaryText
                : btn.on ? Theme.colors.primary
                : Theme.colors.text
        }
    }

    Column {
        id: col
        width: parent.width
        spacing: 12

        // ── Players (when there's more than one) ─────────
        Row {
            visible: page.players.length > 1
            spacing: 6

            Repeater {
                model: page.players
                delegate: MouseArea {
                    id: chip
                    required property var modelData
                    readonly property bool selected: modelData === page.player
                    readonly property var entry: DesktopEntries.heuristicLookup(modelData.desktopEntry ?? "")

                    width: chipRow.implicitWidth + 20
                    height: 30
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: page.chosen = modelData

                    Rectangle {
                        anchors.fill: parent
                        radius: height / 2
                        color: chip.selected ? Theme.colors.primary
                            : chip.containsMouse ? Theme.colors.surfaceContainerHigh
                            : Theme.colors.surfaceContainer
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    Row {
                        id: chipRow
                        anchors.centerIn: parent
                        spacing: 6

                        IconImage {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: chip.entry !== null
                            implicitSize: 16
                            source: chip.entry ? Quickshell.iconPath(chip.entry.icon) : ""
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: chip.modelData.identity
                            color: chip.selected ? Theme.colors.primaryText : Theme.colors.text
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize.small
                            font.weight: Font.Medium
                        }
                    }
                }
            }
        }

        // ── Nothing playing ──────────────────────────────
        Rectangle {
            visible: page.player === null
            width: parent.width
            height: 200
            radius: Theme.radius
            color: Theme.colors.surfaceContainer

            Column {
                anchors.centerIn: parent
                spacing: 8
                Icon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    name: "music_off"
                    font.pixelSize: 40
                    color: Theme.colors.outline
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Nothing playing"
                    color: Theme.colors.subtext
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize.body
                }
            }
        }

        // ── Player ───────────────────────────────────────
        ClippingRectangle {
            visible: page.player !== null
            width: parent.width
            height: 300
            radius: Theme.radius
            color: Theme.colors.surfaceContainer

            // Blurred album art in the background, dimmed so text stays readable
            Image {
                id: bgArt
                anchors.fill: parent
                source: page.artUrl(page.player?.trackArtUrl)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: false
            }
            MultiEffect {
                anchors.fill: parent
                source: bgArt
                visible: bgArt.status === Image.Ready
                blurEnabled: true
                blur: 1.0
                blurMax: 64
                saturation: 0.1
            }
            Rectangle {
                anchors.fill: parent
                color: Theme.colors.surfaceContainer
                opacity: bgArt.status === Image.Ready ? 0.72 : 1
            }

            // Album art
            ClippingRectangle {
                id: art
                anchors { left: parent.left; top: parent.top; margins: 20 }
                width: 180
                height: 180
                radius: 14
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
                    font.pixelSize: 56
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

            // Track info, progress and controls
            Column {
                anchors {
                    left: art.right; leftMargin: 24
                    right: parent.right; rightMargin: 20
                    verticalCenter: art.verticalCenter
                }
                spacing: 4

                Text {
                    width: parent.width
                    text: page.player?.trackTitle || "Unknown title"
                    elide: Text.ElideRight
                    color: Theme.colors.text
                    font.family: Theme.font
                    font.pixelSize: Math.round(22 * Theme.fontScale)
                    font.weight: Font.Bold
                }
                Text {
                    width: parent.width
                    text: page.player?.trackArtist || page.player?.identity || ""
                    elide: Text.ElideRight
                    color: Theme.colors.text
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize.medium
                }
                Text {
                    width: parent.width
                    visible: text !== ""
                    text: page.player?.trackAlbum ?? ""
                    elide: Text.ElideRight
                    color: Theme.colors.subtext
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize.small
                }

                Item { width: 1; height: 14 }

                // Progress; drag to seek
                SliderBar {
                    width: parent.width
                    live: false
                    value: (page.player?.length ?? 0) > 0 ? page.player.position / page.player.length : 0
                    onMoved: v => {
                      if (!page.player?.canSeek) return;
                      page.player.position = v * page.player.length;
                      page.player.positionChanged();
                    }
                }
                Item {
                    width: parent.width
                    height: 18

                    Text {
                        anchors.left: parent.left
                        text: page.fmt(page.player?.position ?? 0)
                        color: Theme.colors.subtext
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize.tiny
                    }
                    Text {
                        anchors.right: parent.right
                        text: page.fmt(page.player?.length ?? 0)
                        color: Theme.colors.subtext
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize.tiny
                    }
                }

                Item { width: 1; height: 6 }

                Row {
                    spacing: 10

                    ControlButton {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: page.player?.shuffleSupported ?? false
                        icon: "shuffle"
                        on: page.player?.shuffle ?? false
                        onClicked: page.player.shuffle = !page.player.shuffle
                    }
                    ControlButton {
                        anchors.verticalCenter: parent.verticalCenter
                        icon: "skip_previous"
                        onClicked: page.player?.previous()
                    }
                    ControlButton {
                        anchors.verticalCenter: parent.verticalCenter
                        big: true
                        icon: page.player?.isPlaying ? "pause" : "play_arrow"
                        onClicked: page.player?.togglePlaying()
                    }
                    ControlButton {
                        anchors.verticalCenter: parent.verticalCenter
                        icon: "skip_next"
                        onClicked: page.player?.next()
                    }
                    ControlButton {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: page.player?.loopSupported ?? false
                        readonly property int loop: page.player?.loopState ?? MprisLoopState.None
                        icon: loop === MprisLoopState.Track ? "repeat_one" : "repeat"
                        on: loop !== MprisLoopState.None
                        // Off → whole playlist → one track → off
                        onClicked: page.player.loopState =
                            loop === MprisLoopState.None ? MprisLoopState.Playlist
                            : loop === MprisLoopState.Playlist ? MprisLoopState.Track
                            : MprisLoopState.None
                    }
                    // Volume: click to show the slider, scroll to adjust
                    ControlButton {
                        anchors.verticalCenter: parent.verticalCenter
                        icon: page.vol < 0.01 ? "volume_mute"
                            : page.vol < 0.5 ? "volume_down"
                            : "volume_up"
                        on: page.volumeOpen
                        onClicked: page.volumeOpen = !page.volumeOpen
                        onWheel: w => page.setVol(page.vol + (w.angleDelta.y > 0 ? 0.05 : -0.05))
                    }

                    SliderBar {
                        anchors.verticalCenter: parent.verticalCenter
                        width: page.volumeOpen ? 120 : 0
                        visible: width > 0
                        value: page.vol
                        onMoved: v => page.setVol(v)
                        Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                    }
                }
            }

            // ── Waveform driven by the audio ─────────────
            Canvas {
                id: wave
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 20 }
                height: 64

                readonly property string fillColor: Theme.colors.primary
                onFillColorChanged: requestPaint()

                Connections {
                    target: page
                    function onLevelsChanged() { wave.requestPaint() }
                }

                // A smooth curve through the levels, mirrored around the middle
                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();

                    const v = page.levels;
                    const n = v.length;
                    if (n < 2) return;

                    const w = width, mid = height / 2;
                    const pts = v.map((l, i) => ({ x: i / (n - 1) * w, y: Math.max(1, l * mid) }));

                    ctx.fillStyle = fillColor;
                    ctx.globalAlpha = 0.8;
                    ctx.beginPath();

                    // Upper edge, left to right
                    ctx.moveTo(0, mid - pts[0].y);
                    for (let i = 0; i < n - 1; i++) {
                        const cx = (pts[i].x + pts[i + 1].x) / 2;
                        const cy = mid - (pts[i].y + pts[i + 1].y) / 2;
                        ctx.quadraticCurveTo(pts[i].x, mid - pts[i].y, cx, cy);
                    }
                    ctx.lineTo(w, mid - pts[n - 1].y);

                    // Lower edge, right to left
                    ctx.lineTo(w, mid + pts[n - 1].y);
                    for (let i = n - 1; i > 0; i--) {
                        const cx = (pts[i].x + pts[i - 1].x) / 2;
                        const cy = mid + (pts[i].y + pts[i - 1].y) / 2;
                        ctx.quadraticCurveTo(pts[i].x, mid + pts[i].y, cx, cy);
                    }
                    ctx.lineTo(0, mid + pts[0].y);

                    ctx.closePath();
                    ctx.fill();
                }
            }
        }
    }
}
