import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking

MouseArea {
    id: root
    readonly property var win: QsWindow.window

    // ── Bar icon: current connection ─────────────────────
    readonly property var device: Networking.devices.values.find(d => d.connected) ?? null
    readonly property bool onWifi: device?.type === DeviceType.Wifi
    readonly property var network: onWifi ? (device.networks.values.find(n => n.connected) ?? null) : null
    readonly property real strength: network?.signalStrength ?? 0

    function wifiIcon(s) {
        return s > 0.75 ? "signal_wifi_4_bar" : s > 0.5 ? "network_wifi_3_bar" : s > 0.25 ? "network_wifi_2_bar" : "network_wifi_1_bar";
    }

    implicitWidth: icon.implicitWidth
    implicitHeight: icon.implicitHeight
    cursorShape: Qt.PointingHandCursor
    onClicked: popup.toggle()

    Icon {
        id: icon
        name: !root.device ? "link_off" : !root.onWifi ? "lan" : root.wifiIcon(root.strength)
        color: root.device ? Theme.colors.text : Theme.colors.subtext
    }

    // ── Wi-Fi, through nmcli ─────────────────────────────
    property bool hasWifi: false
    property bool wifiOn: false
    property var networks: []    // [{ ssid, signal, secure, active }]
    property var saved: []       // names of saved Wi-Fi connections
    property string expanded: "" // network whose password field is open
    property string connecting: ""
    property string error: ""

    // nmcli -t separates fields with ":" and escapes ":" inside values as "\:"
    function splitTerse(line) {
        const out = [];
        let cur = "";
        for (let i = 0; i < line.length; i++) {
            const c = line[i];
            if (c === "\\" && i + 1 < line.length)
                cur += line[++i];
            else if (c === ":") {
                out.push(cur);
                cur = "";
            } else
                cur += c;
        }
        out.push(cur);
        return out;
    }

    function refresh() {
        if (!radioProc.running)
            radioProc.running = true;
        if (!savedProc.running)
            savedProc.running = true;
        if (wifiOn && !listProc.running)
            listProc.running = true;
    }

    function run(cmd) {
        actionProc.command = cmd;
        actionProc.running = true;
    }

    function connect(n, password) {
        error = "";
        connecting = n.ssid;
        if (saved.includes(n.ssid))
            run(["nmcli", "connection", "up", "id", n.ssid]);
        else if (!n.secure)
            run(["nmcli", "device", "wifi", "connect", n.ssid]);
        else
            run(["nmcli", "device", "wifi", "connect", n.ssid, "password", password]);
    }

    function forget(ssid) {
        run(["nmcli", "connection", "delete", "id", ssid]);
    }

    function setWifi(on) {
        wifiOn = on;
        if (!on)
            networks = [];
        run(["nmcli", "radio", "wifi", on ? "on" : "off"]);
    }

    // Does this machine have Wi-Fi at all?
    Process {
        running: true
        command: ["nmcli", "-t", "-f", "TYPE", "device"]
        stdout: StdioCollector {
            onStreamFinished: root.hasWifi = text.split("\n").includes("wifi")
        }
    }

    Process {
        id: radioProc
        command: ["nmcli", "radio", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: root.wifiOn = text.trim() === "enabled"
        }
    }

    Process {
        id: savedProc
        command: ["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: root.saved = text.split("\n").filter(l => l !== "").map(root.splitTerse).filter(f => f[1] === "802-11-wireless").map(f => f[0])
        }
    }

    Process {
        id: listProc
        command: ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "device", "wifi", "list", "--rescan", "auto"]
        stdout: StdioCollector {
            onStreamFinished: {
                // One entry per network name: the connected one, or else the strongest
                const best = {};
                for (const l of text.split("\n")) {
                    if (l === "")
                        continue;
                    const f = root.splitTerse(l);
                    const ssid = f[1];
                    if (!ssid)
                        continue;  // hidden networks
                    const n = {
                        ssid: ssid,
                        signal: Number(f[2]),
                        secure: f[3] !== "" && f[3] !== "--",
                        active: f[0] === "*"
                    };
                    const prev = best[ssid];
                    if (!prev || n.active || (!prev.active && n.signal > prev.signal))
                        best[ssid] = n;
                }
                root.networks = Object.values(best).sort((a, b) => (b.active - a.active) || (b.signal - a.signal)).slice(0, 12);
            }
        }
    }

    // Connecting, forgetting and switching Wi-Fi on/off
    Process {
        id: actionProc
        stderr: StdioCollector {
            id: actionErr
        }
        onExited: code => {
            if (code !== 0) {
                // nmcli's last line is the reason, e.g. "Secrets were required, but not provided"
                root.error = actionErr.text.trim().split("\n").pop() || "That didn't work";
            } else {
                root.error = "";
                root.expanded = "";
            }
            root.connecting = "";
            root.refresh();
        }
    }

    // Refresh while the popup is open
    Timer {
        interval: 5000
        repeat: true
        running: popup.shown && root.hasWifi
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    // ── Popup ────────────────────────────────────────────
    BarPopup {
        id: popup
        anchorItem: root
        barWindow: root.win
        contentWidth: 330

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
                model: Networking.devices.values.filter(d => d.name !== "lo" && d.type !== DeviceType.Wifi)
                delegate: MenuRow {
                    required property var modelData
                    icon: "lan"
                    label: "Ethernet  ·  " + (modelData.connected ? "Connected" : "Disconnected")
                    selected: modelData.connected
                    cursorShape: Qt.ArrowCursor
                }
            }
        }

        // ── Wi-Fi section (machines with Wi-Fi only) ─────
        Column {
            visible: root.hasWifi
            width: parent.width
            spacing: 6

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.colors.outlineVariant
            }

            Item {
                width: parent.width
                height: 30

                Text {
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                    }
                    text: "Wi-Fi"
                    color: Theme.colors.subtext
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize.small
                    font.weight: Font.Medium
                }
                SettingSwitch {
                    anchors {
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                    checked: root.wifiOn
                    onToggled: v => root.setWifi(v)
                }
            }

            Text {
                visible: root.wifiOn && root.networks.length === 0
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                topPadding: 6
                bottomPadding: 6
                text: "Looking for networks…"
                color: Theme.colors.subtext
                font.family: Theme.font
                font.pixelSize: Theme.fontSize.small
            }

            // Network list, scrolling when long
            Flickable {
                visible: root.wifiOn && root.networks.length > 0
                width: parent.width
                height: Math.min(listCol.implicitHeight, 300)
                contentHeight: listCol.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: listCol
                    width: parent.width
                    spacing: 2

                    Repeater {
                        model: root.networks
                        delegate: Column {
                            id: net
                            required property var modelData
                            readonly property bool isSaved: root.saved.includes(modelData.ssid)
                            readonly property bool open: root.expanded === modelData.ssid
                            readonly property bool busy: root.connecting === modelData.ssid
                            width: listCol.width
                            spacing: 4

                            MouseArea {
                                id: netRow
                                width: parent.width
                                height: 38
                                hoverEnabled: true
                                cursorShape: net.modelData.active ? Qt.ArrowCursor : Qt.PointingHandCursor
                                onClicked: {
                                    if (net.modelData.active || net.busy)
                                        return;
                                    root.error = "";
                                    if (net.modelData.secure && !net.isSaved)
                                        root.expanded = net.open ? "" : net.modelData.ssid;
                                    else
                                        root.connect(net.modelData, "");
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 8
                                    color: Theme.colors.surfaceContainerHigh
                                    opacity: net.modelData.active || netRow.containsMouse || net.open ? 1 : 0
                                }

                                Icon {
                                    id: sigIcon
                                    anchors {
                                        left: parent.left
                                        leftMargin: 10
                                        verticalCenter: parent.verticalCenter
                                    }
                                    name: root.wifiIcon(net.modelData.signal / 100)
                                    color: net.modelData.active ? Theme.colors.primary : Theme.colors.text
                                }

                                Text {
                                    anchors {
                                        left: sigIcon.right
                                        leftMargin: 10
                                        right: netStatus.left
                                        rightMargin: 8
                                        verticalCenter: parent.verticalCenter
                                    }
                                    text: net.modelData.ssid
                                    elide: Text.ElideRight
                                    color: net.modelData.active ? Theme.colors.primary : Theme.colors.text
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontSize.body
                                    font.weight: net.modelData.active ? Font.Medium : Font.Normal
                                }

                                Row {
                                    id: netStatus
                                    anchors {
                                        right: parent.right
                                        rightMargin: 8
                                        verticalCenter: parent.verticalCenter
                                    }
                                    spacing: 6

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        visible: text !== ""
                                        text: net.busy ? "Connecting…" : net.modelData.active ? "Connected" : net.isSaved ? "Saved" : ""
                                        color: Theme.colors.subtext
                                        font.family: Theme.font
                                        font.pixelSize: Theme.fontSize.tiny
                                    }
                                    Icon {
                                        anchors.verticalCenter: parent.verticalCenter
                                        visible: net.modelData.secure
                                        name: "lock"
                                        font.pixelSize: 14
                                        color: Theme.colors.subtext
                                    }
                                    // Forget a saved network
                                    MouseArea {
                                        id: forgetBtn
                                        visible: net.isSaved
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 24
                                        height: 24
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.forget(net.modelData.ssid)

                                        Rectangle {
                                            anchors.fill: parent
                                            radius: 6
                                            color: Theme.colors.error
                                            opacity: forgetBtn.containsMouse ? 1 : 0
                                        }
                                        Icon {
                                            anchors.centerIn: parent
                                            name: "delete"
                                            font.pixelSize: 16
                                            color: forgetBtn.containsMouse ? Theme.colors.surface : Theme.colors.subtext
                                        }
                                    }
                                }
                            }

                            // Password for a new secured network
                            Row {
                                visible: net.open
                                width: parent.width
                                spacing: 6

                                Rectangle {
                                    width: parent.width - connectBtn.width - 6
                                    height: 34
                                    radius: 8
                                    color: Theme.colors.surfaceContainerHigh

                                    TextInput {
                                        id: pass
                                        anchors {
                                            fill: parent
                                            leftMargin: 10
                                            rightMargin: 10
                                        }
                                        verticalAlignment: TextInput.AlignVCenter
                                        echoMode: TextInput.Password
                                        color: Theme.colors.text
                                        font.family: Theme.font
                                        font.pixelSize: Theme.fontSize.body
                                        clip: true
                                        onVisibleChanged: if (visible) {
                                            text = "";
                                            forceActiveFocus();
                                        }
                                        onAccepted: root.connect(net.modelData, text)

                                        Text {
                                            visible: pass.text === ""
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "Password"
                                            color: Theme.colors.outline
                                            font: pass.font
                                        }
                                    }
                                }

                                MouseArea {
                                    id: connectBtn
                                    width: connectLabel.implicitWidth + 24
                                    height: 34
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.connect(net.modelData, pass.text)

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 8
                                        color: Theme.colors.primary
                                        opacity: connectBtn.containsMouse ? 0.85 : 1
                                    }
                                    Text {
                                        id: connectLabel
                                        anchors.centerIn: parent
                                        text: net.busy ? "…" : "Connect"
                                        color: Theme.colors.primaryText
                                        font.family: Theme.font
                                        font.pixelSize: Theme.fontSize.small
                                        font.weight: Font.Medium
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // What went wrong, if anything
            Text {
                visible: root.error !== ""
                width: parent.width
                wrapMode: Text.Wrap
                text: root.error
                color: Theme.colors.error
                font.family: Theme.font
                font.pixelSize: Theme.fontSize.small
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.colors.outlineVariant
        }

        MenuRow {
            icon: "terminal"
            label: "Open nmtui"
            onClicked: {
                popup.close();
                Apps.runInTerminal(["nmtui"]);
            }
        }
        MenuRow {
            icon: "settings"
            label: "Network settings"
            onClicked: {
                popup.close();
                Quickshell.execDetached(["nm-connection-editor"]);
            }
        }
    }
}
