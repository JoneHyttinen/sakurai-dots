pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Wayland

// Brings a media player's window to the front, or reopens it if it's
// hidden in the tray (e.g. Spotify closed to tray)
Singleton {
    id: root

    // Names to match the player against: desktop entry, name, and the
    // end of its bus name (org.mpris.MediaPlayer2.spotify -> spotify)
    function keys(player) {
        const bus = (player.dbusName ?? "").replace("org.mpris.MediaPlayer2.", "").split(".")[0];
        return [player.desktopEntry, player.identity, bus]
            .filter(k => k).map(k => k.toLowerCase());
    }
    function matches(name, ks) {
        name = (name ?? "").toLowerCase();
        return name !== "" && ks.some(k => name.includes(k) || k.includes(name));
    }
    function findWindow(player) {
        const ks = keys(player);
        return ToplevelManager.toplevels.values.find(t => matches(t.appId, ks)) ?? null;
    }

    property var pending: null

    function focus(player) {
        if (!player) return;
        const w = findWindow(player);
        if (w) {
            w.activate();
            return;
        }
        // No open window: ask the player to show itself
        if (player.canRaise) player.raise();
        pending = player;
        fallback.restart();
    }

    // If no window showed up, try the tray icon, then launching the app
    // (single-instance apps like Spotify just reopen their window)
    Timer {
        id: fallback
        interval: 600
        onTriggered: {
            const p = root.pending;
            root.pending = null;
            if (!p || root.findWindow(p)) return;
            const ks = root.keys(p);
            const tray = SystemTray.items.values.find(i => root.matches(i.id, ks) || root.matches(i.title, ks));
            if (tray && !tray.onlyMenu) {
                tray.activate();
                return;
            }
            const entry = DesktopEntries.heuristicLookup(p.desktopEntry ?? "")
                ?? DesktopEntries.heuristicLookup(ks[ks.length - 1] ?? "");
            entry?.execute();
        }
    }
}
