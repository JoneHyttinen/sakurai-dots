pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// The dock's pinned apps and app order, saved to disk and shared by every monitor's dock
Singleton {
    id: root
    readonly property var ids: data.pinned
    // Preferred order of running (unpinned) apps, by normalized app id
    readonly property var runningOrder: data.runningOrder

    function isPinned(id) { return data.pinned.includes(id) }

    function toggle(id) {
        const p = data.pinned.slice();
        const i = p.indexOf(id);
        if (i >= 0) p.splice(i, 1);
        else p.push(id);
        data.pinned = p;  // a new array, so the change is saved
    }

    function setOrder(list) {
        data.pinned = list.slice();  // a new array, so the change is saved
    }

    function setPinned(list) { data.pinned = list }
    function setRunningOrder(list) { data.runningOrder = list }

    FileView {
        path: Quickshell.env("HOME") + "/.local/state/quickshell/dock.json"
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) writeAdapter();
        }

        JsonAdapter {
            id: data
            // Used the first time, before dock.json exists
            property var pinned: [
                "firefox",
                "Alacritty",
                "org.kde.dolphin",
                "steam",
                "spotify",
                "discord",
            ]
            property var runningOrder: []
        }
    }
}
