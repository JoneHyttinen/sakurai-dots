pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    readonly property int historyLength: 60  // one minute at one reading per second

    // ── Memory (KiB, as /proc/meminfo reports them) ──
    property real memTotal: 0
    property real memUsed: 0
    readonly property real memPercent: memTotal > 0 ? memUsed / memTotal : 0
    property var memHistory: []

    // ── CPU ──
    property real cpuPercent: 0
    property var cpuHistory: []
    property real cpuTemp: NaN
    property var lastCpu: null

    // ── Network (bytes per second, all interfaces except loopback) ──
    property real netDown: 0
    property real netUp: 0
    property var lastNet: null

    property real uptime: 0  // seconds

    function gib(kib) { return (kib / 1048576).toFixed(1) }

    // Append to a history, keeping only the last minute
    function push(arr, v) {
        const a = arr.concat([v]);
        return a.length > historyLength ? a.slice(a.length - historyLength) : a;
    }

    function rate(bytesPerSec) {
        const bits = bytesPerSec * 8;
        if (bits >= 1e9) return (bits / 1e9).toFixed(2) + " Gbit/s";
        if (bits >= 1e6) return (bits / 1e6).toFixed(1) + " Mbit/s";
        if (bits >= 1e3) return (bits / 1e3).toFixed(0) + " kbit/s";
        return Math.round(bits) + " bit/s";
    }

    FileView {
        id: meminfo
        path: "/proc/meminfo"
        onLoaded: {
            const t = text();
            const total = Number(t.match(/MemTotal:\s+(\d+)/)?.[1] ?? 0);
            const avail = Number(t.match(/MemAvailable:\s+(\d+)/)?.[1] ?? 0);
            root.memTotal = total;
            root.memUsed = total - avail;
            root.memHistory = root.push(root.memHistory, root.memPercent);
        }
    }

    // CPU usage = share of non-idle time since the previous reading
    FileView {
        id: stat
        path: "/proc/stat"
        onLoaded: {
            const f = text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
            const idle = f[3] + f[4];  // idle + iowait
            const total = f.reduce((a, b) => a + b, 0);
            if (root.lastCpu) {
                const dt = total - root.lastCpu.total;
                const di = idle - root.lastCpu.idle;
                root.cpuPercent = dt > 0 ? Math.max(0, Math.min(1, 1 - di / dt)) : 0;
                root.cpuHistory = root.push(root.cpuHistory, root.cpuPercent);
            }
            root.lastCpu = { total: total, idle: idle };
        }
    }

    FileView {
        id: netdev
        path: "/proc/net/dev"
        onLoaded: {
            let rx = 0, tx = 0;
            for (const line of text().split("\n").slice(2)) {
                const m = line.trim().match(/^([^:]+):\s*(.*)$/);
                if (!m || m[1] === "lo") continue;
                const f = m[2].split(/\s+/).map(Number);
                rx += f[0];
                tx += f[8];
            }
            const now = Date.now();
            if (root.lastNet) {
                const dt = (now - root.lastNet.t) / 1000;
                if (dt > 0) {
                    root.netDown = Math.max(0, (rx - root.lastNet.rx) / dt);
                    root.netUp = Math.max(0, (tx - root.lastNet.tx) / dt);
                }
            }
            root.lastNet = { rx: rx, tx: tx, t: now };
        }
    }

    FileView {
        id: uptimeFile
        path: "/proc/uptime"
        onLoaded: root.uptime = Number(text().split(" ")[0])
    }

    // CPU temperature: find the CPU's sensor once (AMD: k10temp/zenpower, Intel: coretemp)
    property string tempPath: ""
    Process {
        running: true
        command: ["sh", "-c",
            'for h in /sys/class/hwmon/hwmon*; do case "$(cat "$h/name")" in ' +
            'k10temp|zenpower|coretemp) echo "$h/temp1_input"; exit;; esac; done']
        stdout: StdioCollector { onStreamFinished: root.tempPath = text.trim() }
    }
    FileView {
        id: tempFile
        path: root.tempPath
        onLoaded: root.cpuTemp = Number(text()) / 1000
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            meminfo.reload();
            stat.reload();
            netdev.reload();
            uptimeFile.reload();
            if (root.tempPath !== "") tempFile.reload();
        }
    }
}
