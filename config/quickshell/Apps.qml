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

    // Terminal editors (nvim, vim, ...) need a terminal; GUI ones open directly.
    // Uses the editor's desktop entry when there is one, else a list of known ones.
    readonly property bool editorInTerminal: {
        const name = editor.split(/\s+/)[0].split("/").pop();
        const entry = DesktopEntries.applications.values.find(e => (e.command?.[0] ?? "").split("/").pop() === name);
        if (entry)
            return entry.runInTerminal;
        return ["nvim", "vim", "vi", "nano", "hx", "helix", "micro", "kak"].includes(name);
    }

    function openFile(path) {
        const args = editor.split(/\s+/).concat([path]);
        if (editorInTerminal)
            runInTerminal(args);
        else
            Quickshell.execDetached(args);
    }
}
