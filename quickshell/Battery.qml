import QtQuick
import Quickshell.Services.UPower

Text {
    readonly property var dev: UPower.displayDevice
    readonly property bool charging: dev.state === UPowerDeviceState.Charging
    readonly property int pct: Math.round(dev.percentage * 100)

    visible: dev.isLaptopBattery   // hides itself on the desktop
    text: (charging ? "󰂄 " : pct > 20 ? "󰁹 " : "󰂃 ") + pct + "%"
    color: pct <= 15 && !charging ? "red" : "white"  // use your matugen colors here
}
