pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// User settings, saved in config/quickshell/settings.json (shared by both machines)
Singleton {
    id: root
    property alias appearance: adapter.appearance

    FileView {
        path: Quickshell.env("HOME") + "/.config/quickshell/settings.json"
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
        }

        JsonAdapter {
            id: adapter

            // Defaults, used until settings.json has a value
            property JsonObject appearance: JsonObject {
                property string font: "Geist"
                property real fontScale: 1.25
                property int radius: 12
                property int frameTop: 40
                property int frameSide: 8
                property int frameRadius: 20
            }
        }
    }
}
