pragma Singleton
import QtQuick
import Quickshell

// The default apps chosen in the settings, for the whole shell
Singleton {
    id: root
    readonly property string terminal: Config.apps.terminal || "alacritty"
    readonly property string fileManager: Config.apps.fileManager || "dolphin"
    readonly property string editor: Config.apps.editor || "nvim"

    // A command line for running something inside the terminal.
    // Terminals disagree on how: most use -e, some take the command directly.
    function inTerminal(args) {
        const base = terminal.split(/\s+/);
        const name = base[0].split("/").pop();
        if (name === "kitty" || name === "foot")
            return base.concat(args);
        if (name === "wezterm")
            return base.concat(["start", "--"], args);
        if (name === "gnome-terminal" || name === "kgx")
            return base.concat(["--"], args);
        return base.concat(["-e"], args);
    }

    function runInTerminal(args) {
        Quickshell.execDetached(inTerminal(args));
    }
    function openFolder(path) {
        Quickshell.execDetached([fileManager, path]);
    }
}
