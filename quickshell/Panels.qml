pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // The popup or sidebar currently open; opening another closes it
    property var current: null
    property bool nightLight: false
    property bool keepAwake: false
    property bool dockForced: false

    function opened(p) {
        if (current && current !== p) current.close();
        current = p;
    }
    function closed(p) {
        if (current === p) current = null;
    }

    // Night light runs while this process runs
    Process {
        command: ["hyprsunset", "-t", "4500"]
        running: root.nightLight
    }
}
