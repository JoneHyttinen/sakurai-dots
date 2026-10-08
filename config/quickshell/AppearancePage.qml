import QtQuick

Column {
    id: page
    property bool fontOpen: false

    spacing: 20

    SettingsSection {
        title: "Text"

        SettingRow {
            label: "Font"
            description: "Used everywhere in the shell"

            MouseArea {
                id: fontBtn
                width: fontBtnRow.implicitWidth + 24
                height: 34
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: page.fontOpen = !page.fontOpen

                Rectangle {
                    anchors.fill: parent
                    radius: 10
                    color: fontBtn.containsMouse || page.fontOpen ? Theme.colors.surfaceContainerHighest ?? Theme.colors.surfaceContainerHigh : Theme.colors.surfaceContainerHigh
                }
                Row {
                    id: fontBtnRow
                    anchors.centerIn: parent
                    spacing: 6
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Config.appearance.font
                        color: Theme.colors.text
                        font.family: Config.appearance.font
                        font.pixelSize: Theme.fontSize.body
                    }
                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: page.fontOpen ? "expand_less" : "expand_more"
                        color: Theme.colors.subtext
                    }
                }
            }
        }

        // Font list, opened from the button above
        Item {
            id: picker
            visible: page.fontOpen
            width: parent.width
            height: visible ? 280 : 0

            readonly property var fonts: Qt.fontFamilies().filter(f => f.toLowerCase().includes(fontSearch.text.toLowerCase()))

            Rectangle {
                id: searchBox
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 10
                }
                height: 36
                radius: 10
                color: Theme.colors.surfaceContainerHigh

                Icon {
                    id: searchIcon
                    anchors {
                        left: parent.left
                        leftMargin: 10
                        verticalCenter: parent.verticalCenter
                    }
                    name: "search"
                    color: Theme.colors.subtext
                }
                TextInput {
                    id: fontSearch
                    anchors {
                        left: searchIcon.right
                        leftMargin: 8
                        right: parent.right
                        rightMargin: 10
                        verticalCenter: parent.verticalCenter
                    }
                    color: Theme.colors.text
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize.body
                    clip: true

                    Text {
                        visible: fontSearch.text === ""
                        text: "Search fonts…"
                        color: Theme.colors.subtext
                        font: fontSearch.font
                    }
                }
            }

            ListView {
                anchors {
                    left: parent.left
                    right: parent.right
                    top: searchBox.bottom
                    bottom: parent.bottom
                    margins: 10
                }
                clip: true
                model: picker.fonts
                boundsBehavior: Flickable.StopAtBounds

                delegate: MouseArea {
                    id: fontRow
                    required property string modelData
                    readonly property bool selected: modelData === Config.appearance.font
                    width: ListView.view.width
                    height: 34
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Config.appearance.font = modelData;
                        page.fontOpen = false;
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: 8
                        color: fontRow.selected ? Theme.colors.primary : Theme.colors.surfaceContainerHigh
                        opacity: fontRow.selected || fontRow.containsMouse ? 1 : 0
                    }
                    Text {
                        anchors {
                            left: parent.left
                            leftMargin: 12
                            verticalCenter: parent.verticalCenter
                        }
                        text: fontRow.modelData
                        color: fontRow.selected ? Theme.colors.primaryText : Theme.colors.text
                        font.family: fontRow.modelData  // each font shown in itself
                        font.pixelSize: Theme.fontSize.body
                    }
                }
            }
        }

        SettingRow {
            label: "Text size"
            description: "Scales all text in the shell"

            SettingSlider {
                from: 0.8
                to: 1.6
                step: 0.05
                decimals: 2
                suffix: "×"
                value: Config.appearance.fontScale
                onEdited: v => Config.appearance.fontScale = v
            }
        }
    }

    SettingsSection {
        title: "Shape"

        SettingRow {
            label: "Corner radius"
            description: "Panels, cards, tiles and popups"

            SettingSlider {
                from: 0
                to: 24
                step: 1
                suffix: " px"
                value: Config.appearance.radius
                onEdited: v => Config.appearance.radius = v
            }
        }
    }

    SettingsSection {
        title: "Frame"

        SettingRow {
            label: "Top band"
            description: "Height of the bar"

            SettingSlider {
                from: 32
                to: 56
                step: 1
                suffix: " px"
                value: Config.appearance.frameTop
                onEdited: v => Config.appearance.frameTop = v
            }
        }
        SettingRow {
            label: "Side bands"
            description: "Left, right and bottom edges"

            SettingSlider {
                from: 0
                to: 24
                step: 1
                suffix: " px"
                value: Config.appearance.frameSide
                onEdited: v => Config.appearance.frameSide = v
            }
        }
        SettingRow {
            label: "Inner corners"
            description: "Rounding where windows meet the frame"

            SettingSlider {
                from: 0
                to: 40
                step: 1
                suffix: " px"
                value: Config.appearance.frameRadius
                onEdited: v => Config.appearance.frameRadius = v
            }
        }
    }
}
