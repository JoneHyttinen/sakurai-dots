pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    // Popups on screen right now: [{ n, until, critical }]
    property var popups: []
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
            root.add(n);
            n.closed.connect(() => root.removePopup(n));
        }
    }
}
