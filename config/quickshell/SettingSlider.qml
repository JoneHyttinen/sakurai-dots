import QtQuick

Row {
    id: s
    property real value: 0
    property real from: 0
    property real to: 1
    property real step: 1
    property int decimals: 0
    property string suffix: ""
    signal edited(real v)

    spacing: 12

    SliderBar {
        anchors.verticalCenter: parent.verticalCenter
        width: 200
        value: (s.value - s.from) / (s.to - s.from)
        onMoved: v => {
            const raw = s.from + v * (s.to - s.from);
            const snapped = Math.round(raw / s.step) * s.step;
            s.edited(Number(snapped.toFixed(s.decimals)));
        }
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        width: 56
        horizontalAlignment: Text.AlignRight
        text: s.value.toFixed(s.decimals) + s.suffix
        color: Theme.colors.text
        font.family: Theme.font
        font.pixelSize: Theme.fontSize.body
        font.weight: Font.Medium
    }
}
