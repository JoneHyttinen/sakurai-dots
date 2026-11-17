pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Screen brightness: the laptop backlight (brightnessctl) and external
// monitors that speak DDC/CI (ddcutil). Each entry in `outputs` has
// `label`, `percent` (0..1) and `set(p)`.
Singleton {
    id: root
    property string device: ""
    property real percent: 0  // 0..1, backlight
    readonly property bool available: device !== ""
    readonly property string label: "Built-in display"

    // Everything the Overview page shows a slider for
    readonly property var outputs: (available ? [root] : []).concat(ddc.instances)

    signal changedByKey()  // shows the OSD

    function set(p) {
        p = Math.max(0.01, Math.min(1, p));  // never fully off
        percent = p;
        Quickshell.execDetached(["brightnessctl", "-q", "-c", "backlight", "set", Math.round(p * 100) + "%"]);
    }
    function step(d) {
        set(percent + d);
        changedByKey();
    }

    // Re-read the monitors, which may have been changed with their own buttons
    function refresh() {
        for (const m of ddc.instances) m.refresh();
    }

    // brightnessctl -m prints "device,class,current,percent,max"
    Process {
        running: true
        command: ["brightnessctl", "-m", "-c", "backlight"]
        stdout: StdioCollector {
            onStreamFinished: {
                const f = (text.trim().split("\n")[0] ?? "").split(",");
                if (f.length >= 5) {
                    root.device = f[0];
                    root.percent = Number(f[2]) / Number(f[4]);
                }
            }
        }
    }

    // ── External monitors over DDC/CI ────────────────────
    property var ddcDisplays: []  // [{ bus, connector, model }]

    // "ddcutil detect --brief" prints a block per display:
    //   Display 1
    //      I2C bus:          /dev/i2c-3
    //      DRM connector:    card1-DP-1
    //      Monitor:          ACI:VG248:JALMQS062862
    Process {
        running: true
        command: ["ddcutil", "detect", "--brief"]
        stdout: StdioCollector {
            onStreamFinished: {
                const found = [];
                for (const block of text.split(/\n(?=\S)/)) {
                    if (!block.startsWith("Display")) continue;  // skips "Invalid display"
                    const bus = block.match(/I2C bus:\s+\/dev\/i2c-(\d+)/);
                    if (!bus) continue;
                    const conn = block.match(/DRM connector:\s+(?:card\d+-)?(\S+)/);
                    const mon = block.match(/Monitor:\s+[^:]*:([^:\n]*)/);
                    found.push({
                        bus: bus[1],
                        connector: conn ? conn[1] : "i2c-" + bus[1],
                        model: mon ? mon[1].trim() : "",
                    });
                }
                root.ddcDisplays = found;
            }
        }
    }

    Variants {
        id: ddc
        model: root.ddcDisplays

        delegate: Scope {
            id: mon
            required property var modelData
            readonly property string label: modelData.model
                ? modelData.model + " · " + modelData.connector
                : modelData.connector
            property real percent: 0
            property int maxValue: 100
            property int pending: -1  // value waiting to be written

            function set(p) {
                p = Math.max(0, Math.min(1, p));
                percent = p;
                pending = Math.round(p * maxValue);
                if (!writer.running) flush();
            }
            // DDC is slow, so run one write at a time and only send the latest value
            function flush() {
                if (pending < 0) return;
                writer.command = ["ddcutil", "--bus", modelData.bus, "--noverify", "setvcp", "10", String(pending)];
                pending = -1;
                writer.running = true;
            }
            function refresh() {
                if (!writer.running && pending < 0) reader.running = true;
            }

            // "VCP 10 C <current> <max>"
            Process {
                id: reader
                running: true
                command: ["ddcutil", "--bus", mon.modelData.bus, "--brief", "getvcp", "10"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        const f = text.trim().split(/\s+/);
                        if (f[0] === "VCP" && f.length >= 5 && Number(f[4]) > 0) {
                            mon.maxValue = Number(f[4]);
                            mon.percent = Number(f[3]) / mon.maxValue;
                        }
                    }
                }
            }
            Process {
                id: writer
                onExited: mon.flush()
            }
        }
    }

    // Brightness keys: qs ipc call brightness up / down
    IpcHandler {
        target: "brightness"
        function up(): void { root.step(0.05) }
        function down(): void { root.step(-0.05) }
    }
}
