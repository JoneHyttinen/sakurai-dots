import QtQuick
import Quickshell
import Quickshell.Services.UPower

MouseArea {
    id: root

    readonly property var dev: UPower.displayDevice
    readonly property bool charging: dev.state === UPowerDeviceState.Charging
    readonly property int pct: Math.round(dev.percentage * 100)
    readonly property bool onBattery: dev.state === UPowerDeviceState.Discharging

    // Warn once each at 20%, 10% and 5%; reset when the charger is plugged in
    property int lastWarned: 101

    onPctChanged: {
        if (!onBattery) return;
        for (const level of [5, 10, 20]) {
            if (pct <= level && lastWarned > level) {
                lastWarned = level;
                Quickshell.execDetached(["notify-send",
                    "-u", level <= 10 ? "critical" : "normal",
                    "-a", "Battery", "-i", "battery-caution",
                    "Battery low", pct + "% remaining"]);
                break;
            }
        }
    }

    // Power-saver on battery, balanced on the charger
    onOnBatteryChanged: {
        if (onBattery) {
            PowerProfiles.profile = PowerProfile.PowerSaver;
        } else {
            lastWarned = 101;
            PowerProfiles.profile = PowerProfile.Balanced;
        }
    }

    // Some machines have no performance profile, so skip it there
    readonly property var profiles: PowerProfiles.hasPerformanceProfile
        ? [PowerProfile.PowerSaver, PowerProfile.Balanced, PowerProfile.Performance]
        : [PowerProfile.PowerSaver, PowerProfile.Balanced]

    function cycle(step) {
        const i = profiles.indexOf(PowerProfiles.profile);
        PowerProfiles.profile = profiles[(i + step + profiles.length) % profiles.length];
    }

    function profileIcon(p) {
        switch (p) {
        case PowerProfile.PowerSaver:  return "󰌪";   // leaf
        case PowerProfile.Performance: return "󱐋";   // bolt
        default:                       return "󰾅";   // balanced
        }
    }

    visible: dev.isLaptopBattery
    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: mouse => cycle(mouse.button === Qt.RightButton ? -1 : 1)

    Text {
        id: label
        text: root.profileIcon(PowerProfiles.profile) + "  "
            + (root.charging ? "󰂄 " : root.pct > 20 ? "󰁹 " : "󰂃 ")
            + root.pct + "%"
        color: root.pct <= 15 && !root.charging ? Theme.colors.error : Theme.colors.text
        font.family: Theme.font
        font.pixelSize: Theme.fontSize.body
    }
}
