import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: page
    property bool active: false  // true while this tab is showing

    // ── Data that's only collected while the tab is open ──
    property string kernel: ""
    property var gpu: null        // { util, used, total, temp } or null
    property bool gpuChecked: false
    property var disks: []        // [{ target, size, used }]
    property var procs: []        // [{ pid, cpu, mem, name }]

    function fmtUptime(s) {
        const d = Math.floor(s / 86400), h = Math.floor(s % 86400 / 3600), m = Math.floor(s % 3600 / 60);
        return (d > 0 ? d + "d " : "") + (h > 0 || d > 0 ? h + "h " : "") + m + "m";
    }
    function gb(bytes) { return (bytes / 1073741824).toFixed(0) }

    implicitHeight: col.implicitHeight

    Process {
        running: true
        command: ["uname", "-r"]
        stdout: StdioCollector { onStreamFinished: page.kernel = text.trim() }
    }

    // GPU: NVIDIA through nvidia-smi, AMD through the kernel's sysfs readings.
    // Prints "usage%, usedMiB, totalMiB, temp°C".
    Process {
        id: gpuProc
        command: ["sh", "-c",
            'if command -v nvidia-smi >/dev/null 2>&1; then ' +
            '  nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu --format=csv,noheader,nounits | head -n1; ' +
            'else for d in /sys/class/drm/card*/device; do ' +
            '  if [ -f "$d/gpu_busy_percent" ]; then ' +
            '    echo "$(cat "$d/gpu_busy_percent"), $(( $(cat "$d/mem_info_vram_used") / 1048576 )), ' +
            '$(( $(cat "$d/mem_info_vram_total") / 1048576 )), $(( $(cat "$d"/hwmon/hwmon*/temp1_input) / 1000 ))"; break; ' +
            '  fi; done; fi']
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split(",").map(s => Number(s.trim()));
                page.gpu = f.length === 4 && f.every(isFinite)
                    ? { util: f[0], used: f[1], total: f[2], temp: f[3] } : null;
                page.gpuChecked = true;
            }
        }
    }

    // Real filesystems only
    Process {
        id: diskProc
        command: ["df", "-B1", "--output=target,size,used",
                  "-x", "tmpfs", "-x", "devtmpfs", "-x", "efivarfs", "-x", "overlay", "-x", "squashfs"]
        stdout: StdioCollector {
            onStreamFinished: {
                page.disks = text.trim().split("\n").slice(1)
                    .map(l => l.trim().split(/\s+/))
                    .filter(f => f.length === 3 && !f[0].startsWith("/boot") && f[0] !== "/efi")
                    .map(f => ({ target: f[0], size: Number(f[1]), used: Number(f[2]) }))
                    .slice(0, 4);
            }
        }
    }

    // top's second sample shows current usage (its first one averages since boot).
    // LC_ALL=C keeps decimals as "1.5" instead of "1,5".
    Process {
        id: procProc
        command: ["sh", "-c",
            "LC_ALL=C top -b -n 2 -d 1 -o %CPU -w 512 | " +
            "awk '/^ *PID/ { f++; next } f == 2 && NF >= 12 { print $1 \"\\t\" $9 \"\\t\" $10 \"\\t\" $12 }' | head -n 7"]
        stdout: StdioCollector {
            onStreamFinished: {
                page.procs = text.trim().split("\n").filter(l => l !== "").map(l => {
                    const f = l.split("\t");
                    return { pid: f[0], cpu: Number(f[1]), mem: Number(f[2]), name: f[3] };
                });
            }
        }
    }

    function refresh(fast) {
        if (!gpuProc.running) gpuProc.running = true;
        if (!procProc.running) procProc.running = true;
        if (!fast && !diskProc.running) diskProc.running = true;
    }
    onActiveChanged: if (active) refresh(false)

    Timer {
        interval: 2000
        repeat: true
        running: page.active
        onTriggered: page.refresh(true)
    }
    Timer {
        interval: 30000  // disk usage changes slowly
        repeat: true
        running: page.active
        onTriggered: if (!diskProc.running) diskProc.running = true
    }

    // ── A stats card ─────────────────────────────────────
    component Card: Rectangle {
        id: card
        property string icon
        property string title
        property string value: ""
        property string detail: ""
        default property alias content: extra.data

        radius: Theme.radius
        color: Theme.colors.surfaceContainer
        height: cardCol.implicitHeight + 24

        Column {
            id: cardCol
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
            spacing: 6

            Row {
                spacing: 6
                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: card.icon
                    color: Theme.colors.subtext
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: card.title
                    color: Theme.colors.subtext
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize.small
                    font.weight: Font.Medium
                }
            }

            Row {
                visible: card.value !== ""
                spacing: 8
                Text {
                    id: big
                    text: card.value
                    color: Theme.colors.text
                    font.family: Theme.font
                    font.pixelSize: Math.round(24 * Theme.fontScale)
                    font.weight: Font.Bold
                }
                Text {
                    anchors.baseline: big.baseline
                    text: card.detail
                    color: Theme.colors.subtext
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize.small
                }
            }

            Column {
                id: extra
                width: parent.width
                spacing: 6
            }
        }
    }

    Column {
        id: col
        width: parent.width
        spacing: 12

        // Kernel and uptime
        Text {
            leftPadding: 4
            text: "Linux " + page.kernel + "   ·   up " + page.fmtUptime(SystemStats.uptime)
            color: Theme.colors.subtext
            font.family: Theme.font
            font.pixelSize: Theme.fontSize.small
        }

        // ── CPU, memory, GPU ─────────────────────────────
        Row {
            id: topRow
            width: parent.width
            spacing: 12
            readonly property real cardWidth: (width - spacing * 2) / 3

            Card {
                width: topRow.cardWidth
                icon: "memory"
                title: "CPU"
                value: Math.round(SystemStats.cpuPercent * 100) + "%"
                detail: isFinite(SystemStats.cpuTemp) ? Math.round(SystemStats.cpuTemp) + " °C" : ""

                HistoryGraph {
                    width: parent.width
                    height: 56
                    values: SystemStats.cpuHistory
                }
            }

            Card {
                width: topRow.cardWidth
                icon: "memory_alt"
                title: "Memory"
                value: Math.round(SystemStats.memPercent * 100) + "%"
                detail: SystemStats.gib(SystemStats.memUsed) + " / " + SystemStats.gib(SystemStats.memTotal) + " GB"

                HistoryGraph {
                    width: parent.width
                    height: 56
                    values: SystemStats.memHistory
                    lineColor: Theme.colors.tertiary
                }
            }

            Card {
                width: topRow.cardWidth
                icon: "developer_board"
                title: "GPU"
                value: page.gpu ? page.gpu.util + "%" : ""
                detail: page.gpu ? page.gpu.temp + " °C" : ""

                // VRAM bar
                Column {
                    visible: page.gpu !== null
                    width: parent.width
                    spacing: 4

                    Text {
                        text: page.gpu ? "VRAM  " + (page.gpu.used / 1024).toFixed(1) + " / "
                            + (page.gpu.total / 1024).toFixed(1) + " GB" : ""
                        color: Theme.colors.subtext
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize.small
                    }
                    Rectangle {
                        width: parent.width
                        height: 6
                        radius: 3
                        color: Theme.colors.surfaceContainerHigh
                        Rectangle {
                            width: page.gpu && page.gpu.total > 0 ? parent.width * page.gpu.used / page.gpu.total : 0
                            height: parent.height
                            radius: 3
                            color: Theme.colors.secondary
                        }
                    }
                }

                Text {
                    visible: page.gpu === null
                    width: parent.width
                    wrapMode: Text.Wrap
                    text: page.gpuChecked ? "No GPU readings available" : "Reading…"
                    color: Theme.colors.subtext
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize.small
                }
            }
        }

        // ── Network + disks | processes ──────────────────
        Row {
            id: bottomRow
            width: parent.width
            spacing: 12

            Column {
                width: topRow.cardWidth
                spacing: 12

                Card {
                    width: parent.width
                    icon: "swap_vert"
                    title: "Network"

                    Repeater {
                        model: [
                            { icon: "arrow_downward", label: "Down", value: SystemStats.netDown },
                            { icon: "arrow_upward",   label: "Up",   value: SystemStats.netUp },
                        ]
                        delegate: Item {
                            required property var modelData
                            width: parent.width
                            height: 22

                            Row {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 6
                                Icon {
                                    anchors.verticalCenter: parent.verticalCenter
                                    name: modelData.icon
                                    font.pixelSize: 16
                                    color: Theme.colors.primary
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.label
                                    color: Theme.colors.subtext
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontSize.small
                                }
                            }
                            Text {
                                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                                text: SystemStats.rate(modelData.value)
                                color: Theme.colors.text
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize.body
                                font.weight: Font.Medium
                            }
                        }
                    }
                }

                Card {
                    width: parent.width
                    icon: "hard_drive"
                    title: "Disks"

                    Repeater {
                        model: page.disks
                        delegate: Column {
                            required property var modelData
                            readonly property real frac: modelData.size > 0 ? modelData.used / modelData.size : 0
                            width: parent.width
                            spacing: 4

                            Item {
                                width: parent.width
                                height: 18
                                Text {
                                    anchors.left: parent.left
                                    width: parent.width - usage.width - 8
                                    text: modelData.target
                                    elide: Text.ElideMiddle
                                    color: Theme.colors.text
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontSize.small
                                }
                                Text {
                                    id: usage
                                    anchors.right: parent.right
                                    text: page.gb(modelData.used) + " / " + page.gb(modelData.size) + " GB"
                                    color: Theme.colors.subtext
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontSize.small
                                }
                            }
                            Rectangle {
                                width: parent.width
                                height: 6
                                radius: 3
                                color: Theme.colors.surfaceContainerHigh
                                Rectangle {
                                    width: parent.width * parent.parent.frac
                                    height: parent.height
                                    radius: 3
                                    // Red when nearly full
                                    color: parent.parent.frac > 0.9 ? Theme.colors.error : Theme.colors.primary
                                }
                            }
                        }
                    }
                }
            }

            // Processes using the most CPU
            Card {
                width: bottomRow.width - topRow.cardWidth - bottomRow.spacing
                icon: "list"
                title: "Top processes"

                // Column headers
                Item {
                    width: parent.width
                    height: 18
                    Text {
                        anchors.left: parent.left
                        text: "Name"
                        color: Theme.colors.outline
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize.tiny
                    }
                    Text {
                        anchors { right: parent.right; rightMargin: 70 }
                        text: "CPU"
                        color: Theme.colors.outline
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize.tiny
                    }
                    Text {
                        anchors.right: parent.right
                        text: "Memory"
                        color: Theme.colors.outline
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize.tiny
                    }
                }

                Repeater {
                    model: page.procs
                    delegate: Item {
                        required property var modelData
                        width: parent.width
                        height: 28

                        // Usage bar behind the row
                        Rectangle {
                            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                            height: parent.height - 4
                            width: parent.width * Math.min(1, modelData.cpu / 100)
                            radius: 6
                            color: Theme.colors.primary
                            opacity: 0.15
                        }

                        Text {
                            anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
                            width: parent.width - 160
                            text: modelData.name
                            elide: Text.ElideRight
                            color: Theme.colors.text
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize.body
                        }
                        Text {
                            anchors { right: parent.right; rightMargin: 70; verticalCenter: parent.verticalCenter }
                            text: modelData.cpu.toFixed(1) + "%"
                            color: Theme.colors.text
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize.body
                            font.weight: Font.Medium
                        }
                        Text {
                            anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                            text: modelData.mem.toFixed(1) + "%"
                            color: Theme.colors.subtext
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize.body
                        }
                    }
                }

                Text {
                    visible: page.procs.length === 0
                    text: "Reading…"
                    color: Theme.colors.subtext
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize.small
                }
            }
        }
    }
}
