import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets

Column {
    id: page
    property var picker: null      // the wallpaper picker, to open it from here
    property var targetScreen: null

    spacing: 20

    readonly property string home: Quickshell.env("HOME")
    property string wallPath: ""

    // Which wallpaper is in use; refreshed whenever the theme changes
    Process {
        id: readWall
        running: true
        command: ["readlink", "-f", page.home + "/.cache/wallpaper"]
        stdout: StdioCollector {
            onStreamFinished: page.wallPath = text.trim()
        }
    }
    Connections {
        target: Theme.colors
        function onPrimaryChanged() {
            readWall.running = true;
        }
    }

    // Scheme and threshold changes re-apply the theme after a short pause,
    // so dragging the slider doesn't run setwall on every step
    Timer {
        id: reapplySoon
        interval: 600
        onTriggered: Theme.reapply()
    }

    readonly property var schemes: [
        {
            value: "auto",
            label: "Auto"
        },
        {
            value: "tonal-spot",
            label: "Tonal spot"
        },
        {
            value: "content",
            label: "Content"
        },
        {
            value: "expressive",
            label: "Expressive"
        },
        {
            value: "fidelity",
            label: "Fidelity"
        },
        {
            value: "fruit-salad",
            label: "Fruit salad"
        },
        {
            value: "rainbow",
            label: "Rainbow"
        },
        {
            value: "neutral",
            label: "Neutral"
        },
        {
            value: "monochrome",
            label: "Monochrome"
        },
    ]

    // A plain button
    component Button: MouseArea {
        id: btn
        property string icon: ""
        property string label
        width: btnRow.implicitWidth + 24
        height: 34
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        Rectangle {
            anchors.fill: parent
            radius: 10
            color: btn.containsMouse ? Theme.colors.primary : Theme.colors.surfaceContainerHigh
            Behavior on color {
                ColorAnimation {
                    duration: 120
                }
            }
        }
        Row {
            id: btnRow
            anchors.centerIn: parent
            spacing: 6
            Icon {
                visible: btn.icon !== ""
                anchors.verticalCenter: parent.verticalCenter
                name: btn.icon
                font.pixelSize: 18
                color: btn.containsMouse ? Theme.colors.primaryText : Theme.colors.text
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: btn.label
                color: btn.containsMouse ? Theme.colors.primaryText : Theme.colors.text
                font.family: Theme.font
                font.pixelSize: Theme.fontSize.small
                font.weight: Font.Medium
            }
        }
    }

    // ── Wallpaper ────────────────────────────────────────
    SettingsSection {
        title: "Wallpaper"

        // Current wallpaper
        Item {
            width: parent.width
            height: 180

            ClippingRectangle {
                id: preview
                anchors {
                    left: parent.left
                    leftMargin: 12
                    verticalCenter: parent.verticalCenter
                }
                width: 270
                height: 152
                radius: 10
                color: Theme.colors.surfaceContainerHigh

                Image {
                    anchors.fill: parent
                    source: page.wallPath !== "" ? "file://" + page.wallPath : ""
                    sourceSize: Qt.size(540, 304)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: false
                }
            }

            Column {
                anchors {
                    left: preview.right
                    leftMargin: 16
                    right: parent.right
                    rightMargin: 12
                    verticalCenter: parent.verticalCenter
                }
                spacing: 10

                Text {
                    width: parent.width
                    text: page.wallPath.split("/").pop() || "No wallpaper set"
                    elide: Text.ElideMiddle
                    color: Theme.colors.text
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize.body
                    font.weight: Font.Medium
                }

                Button {
                    icon: "wallpaper"
                    label: "Choose wallpaper…"
                    onClicked: page.picker?.open(page.targetScreen)
                }
            }
        }

        SettingRow {
            label: "Folder"
            description: "Where the picker looks for wallpapers. Press Enter to save."

            Rectangle {
                width: 260
                height: 34
                radius: 10
                color: Theme.colors.surfaceContainerHigh

                TextInput {
                    id: folderInput
                    anchors {
                        fill: parent
                        leftMargin: 10
                        rightMargin: 10
                    }
                    verticalAlignment: TextInput.AlignVCenter
                    text: Config.wallpaper.folder
                    color: Theme.colors.text
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize.small
                    clip: true
                    onAccepted: Config.wallpaper.folder = text.trim()

                    Text {
                        visible: folderInput.text === ""
                        anchors.verticalCenter: parent.verticalCenter
                        text: "~/Pictures/Wallpapers"
                        color: Theme.colors.outline
                        font: folderInput.font
                    }
                }
            }
        }

        SettingRow {
            label: "Transition"
            description: "Effect when the wallpaper changes"

            SettingChoice {
                options: [
                    {
                        value: "grow",
                        label: "Grow"
                    },
                    {
                        value: "fade",
                        label: "Fade"
                    },
                    {
                        value: "wipe",
                        label: "Wipe"
                    },
                    {
                        value: "wave",
                        label: "Wave"
                    },
                    {
                        value: "outer",
                        label: "Outer"
                    },
                    {
                        value: "random",
                        label: "Random"
                    },
                ]
                current: Config.wallpaper.transition
                onChosen: v => Config.wallpaper.transition = v
            }
        }

        SettingRow {
            label: "Transition length"

            SettingSlider {
                from: 0.2
                to: 3
                step: 0.1
                decimals: 1
                suffix: " s"
                value: Config.wallpaper.transitionDuration
                onEdited: v => Config.wallpaper.transitionDuration = v
            }
        }
    }

    // ── Theme ────────────────────────────────────────────
    SettingsSection {
        title: "Theme"

        SettingRow {
            label: "Mode"
            description: "Auto picks light or dark to contrast with black-and-white wallpapers"

            SettingChoice {
                options: [
                    {
                        value: "auto",
                        label: "Auto"
                    },
                    {
                        value: "light",
                        label: "Light"
                    },
                    {
                        value: "dark",
                        label: "Dark"
                    },
                ]
                current: Theme.modePref
                onChosen: v => Theme.setModePreference(v)
            }
        }

        SettingRow {
            label: "Color style"
            description: "How matugen builds the palette from the wallpaper's color"
        }

        // Many options, so they wrap instead of sitting beside the label
        Flow {
            x: 14
            width: parent.width - 28
            spacing: 4
            bottomPadding: 12

            Repeater {
                model: page.schemes
                delegate: MouseArea {
                    id: sch
                    required property var modelData
                    readonly property bool active: Config.wallpaper.scheme === modelData.value

                    width: schLabel.implicitWidth + 24
                    height: 32
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Config.wallpaper.scheme = modelData.value;
                        reapplySoon.restart();
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: 10
                        color: sch.active ? Theme.colors.primary : sch.containsMouse ? Theme.colors.surfaceContainerHighest ?? Theme.colors.surfaceContainerHigh : Theme.colors.surfaceContainerHigh
                        Behavior on color {
                            ColorAnimation {
                                duration: 120
                            }
                        }
                    }
                    Text {
                        id: schLabel
                        anchors.centerIn: parent
                        text: sch.modelData.label
                        color: sch.active ? Theme.colors.primaryText : Theme.colors.text
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize.small
                        font.weight: Font.Medium
                    }
                }
            }
        }

        SettingRow {
            label: "Black-and-white detection"
            description: "Wallpapers less colorful than this get a grayscale theme (with Auto style)"

            SettingSlider {
                from: 0
                to: 0.3
                step: 0.01
                decimals: 2
                value: Config.wallpaper.monoThreshold
                onEdited: v => {
                    Config.wallpaper.monoThreshold = v;
                    reapplySoon.restart();
                }
            }
        }

        SettingRow {
            label: "Re-apply theme"
            description: "Run setwall again on the current wallpaper"

            Button {
                icon: "refresh"
                label: "Re-apply"
                onClicked: Theme.reapply()
            }
        }
    }
}
