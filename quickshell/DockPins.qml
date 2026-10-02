pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// The dock's pinned apps, saved to disk and shared by every monitor's dock
Singleton {
    id: root
    readonly property var ids: data.pinned

    function isPinned(id) { return data.pinned.includes(id) }

    function toggle(id) {
        const p = data.pinned.slice();
        const i = p.indexOf(id);
        if (i >= 0) p.splice(i, 1);
        else p.push(id);
        data.pinned = p;  // a new array, so the change is saved
    }

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
                "firefox-developer-edition",
                "Alacritty",
                "org.kde.dolphin",
                "steam",
                "spotify",
                "discord",
            ]
        }
    }
}
