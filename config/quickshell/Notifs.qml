pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    // Popups on screen right now: [{ n, until, critical }]
    property var popups: []
    property bool dnd: false
    property int unread: 0

    // Receive times, keyed by notification id
    property var receivedAt: ({})
    // Updated regularly so "5m ago" labels stay current
    property real now: Date.now()

    Timer {
        interval: 30000
        repeat: true
        running: true
        onTriggered: root.now = Date.now()
    }

    function ago(n) {
        const t = receivedAt[n.id];
        if (!t) return "";
        const s = Math.floor((now - t) / 1000);
        if (s < 60) return "now";
        const m = Math.floor(s / 60);
        if (m < 60) return m + "m";
        const h = Math.floor(m / 60);
        if (h < 24) return h + "h";
        return Math.floor(h / 24) + "d";
    }

    function clearAll() {
        server.trackedNotifications.values.slice().forEach(n => n.dismiss());
        unread = 0;
    }
    // Everything received this session; for the history sidebar later
    readonly property var history: server.trackedNotifications

    readonly property int timeout: 5000
    readonly property int maxPopups: 5

    function add(n) {
        const critical = n.urgency === NotificationUrgency.Critical;
        const entry = { n: n, until: critical ? Infinity : Date.now() + timeout, critical: critical };
        popups = [entry].concat(popups).slice(0, maxPopups);
    }

    function removePopup(n) {
        popups = popups.filter(p => p.n !== n);
    }

    // Pause the countdown while hovered; resume with a little extra time
    function hold(n, held) {
        const p = popups.find(p => p.n === n);
        if (!p || p.critical) return;
        p.until = held ? Infinity : Date.now() + 3000;
    }

    Timer {
        interval: 500
        repeat: true
        running: root.popups.length > 0
        onTriggered: {
            const now = Date.now();
            const kept = root.popups.filter(p => p.until > now);
            if (kept.length !== root.popups.length) root.popups = kept;
        }
    }

    NotificationServer {
        id: server
        bodySupported: true
        bodyMarkupSupported: true
        actionsSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: n => {
            n.tracked = true;  // keep it in history
            root.receivedAt[n.id] = Date.now();
            root.unread++;
            if (!root.dnd || n.urgency === NotificationUrgency.Critical)
                root.add(n);
            n.closed.connect(() => root.removePopup(n));
        }
    }
}
