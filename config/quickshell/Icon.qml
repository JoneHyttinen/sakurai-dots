import QtQuick

Text {
    property string name
    text: name
    font.family: "Material Symbols Rounded"
    font.pixelSize: 18
    color: Theme.colors.text
    verticalAlignment: Text.AlignVCenter
}
