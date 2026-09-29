import QtQuick
import Quickshell
import Quickshell.Networking

MouseArea {
    id: root
    readonly property var win: QsWindow.window
    readonly property var device: Networking.devices.values.find(d => d.connected) ?? null
    readonly property bool wifi: device?.type === DeviceType.Wifi
    readonly property var network: wifi ? (device.networks.values.find(n => n.connected) ?? null) : null
    readonly property real strength: network?.signalStrength ?? 0

    implicitWidth: icon.implicitWidth
    implicitHeight: icon.implicitHeight
    cursorShape: Qt.PointingHandCursor
    onClicked: popup.toggle()

    Icon {
        id: icon
        name: !root.device ? "link_off"
            : !root.wifi ? "lan"
            : root.strength > 0.75 ? "signal_wifi_4_bar"
            : root.strength > 0.5 ? "network_wifi_3_bar"
            : root.strength > 0.25 ? "network_wifi_2_bar"
            : "network_wifi_1_bar"
        color: root.device ? Theme.colors.text : Theme.colors.subtext
    }

    BarPopup {
        id: popup
        anchorItem: root
        barWindow: root.win
        contentWidth: 280

        Text {
            text: "Connections"
            color: Theme.colors.subtext
            font.family: Theme.font
            font.pixelSize: Theme.fontSize.small
            font.weight: Font.Medium
        }

        Column {
            width: parent.width
            spacing: 2
            Repeater {
                model: Networking.devices.values.filter(d => d.name !== "lo")
                delegate: MenuRow {
                    required property var modelData
                    readonly property bool isWifi: modelData.type === DeviceType.Wifi
                    icon: isWifi ? "wifi" : "lan"
                    label: (isWifi ? "Wi-Fi" : "Ethernet") + "  ·  "
                        + (modelData.connected ? "Connected" : "Disconnected")
                    selected: modelData.connected
                    cursorShape: Qt.ArrowCursor
                }
            }
        }

        Rectangle { width: parent.width; height: 1; color: Theme.colors.outlineVariant }

        MenuRow {
            icon: "settings"
            label: "Network settings"
            onClicked: {
                popup.visible = false;
                Quickshell.execDetached(["nm-connection-editor"]);
            }
        }
    }
}
