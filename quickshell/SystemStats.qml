pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // In KiB, as /proc/meminfo reports them
    property real memTotal: 0
    property real memUsed: 0
    readonly property real memPercent: memTotal > 0 ? memUsed / memTotal : 0

    function gib(kib) { return (kib / 1048576).toFixed(1) }

    FileView {
        id: meminfo
        path: "/proc/meminfo"
        onLoaded: {
            const t = text();
            const total = Number(t.match(/MemTotal:\s+(\d+)/)?.[1] ?? 0);
            const avail = Number(t.match(/MemAvailable:\s+(\d+)/)?.[1] ?? 0);
            root.memTotal = total;
            root.memUsed = total - avail;
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: meminfo.reload()
    }
}
