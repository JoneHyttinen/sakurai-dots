pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Screen backlight; only available on machines that have one (laptops)
Singleton {
    id: root
    property string device: ""
    property real percent: 0  // 0..1
    readonly property bool available: device !== ""

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

    // Brightness keys: qs ipc call brightness up / down
    IpcHandler {
        target: "brightness"
        function up(): void { root.step(0.05) }
        function down(): void { root.step(-0.05) }
    }
}
