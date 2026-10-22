import QtQuick
import Quickshell
import Quickshell.Io

Column {
    id: page
    property bool active: false  // true while this tab is showing
    spacing: 20

    property var info: ({})

    // One script collects everything, as "key<TAB>value" lines
    Process {
        id: gather
        command: ["sh", "-c", 'printf "host\\t%s\\n" "$(cat /etc/hostname)"; ' + 'printf "os\\t%s\\n" "$(. /etc/os-release; echo "$PRETTY_NAME")"; ' + 'printf "kernel\\t%s\\n" "$(uname -r)"; ' + 'printf "quickshell\\t%s\\n" "$(qs --version 2>/dev/null | head -n1)"; ' + 'printf "hyprland\\t%s\\n" "$(hyprctl version 2>/dev/null | head -n1 | cut -d" " -f1,2)"; ' + 'printf "matugen\\t%s\\n" "$(matugen --version 2>/dev/null | head -n1)"; ' + 'printf "nix\\t%s\\n" "$(nix --version 2>/dev/null | head -n1)"; ' + 'cd "$HOME/dotfiles" 2>/dev/null && { ' + '  printf "commit\\t%s\\n" "$(git log -1 --format="%h  ·  %s")"; ' + '  printf "when\\t%s\\n" "$(git log -1 --format=%cr)"; ' + '  printf "changes\\t%s\\n" "$(git status --porcelain | wc -l)"; ' + '  printf "ahead\\t%s\\n" "$(git rev-list --count @{u}..HEAD 2>/dev/null || echo 0)"; ' + '}']
        stdout: StdioCollector {
            onStreamFinished: {
                const out = {};
                for (const line of text.split("\n")) {
                    const tab = line.indexOf("\t");
                    if (tab > 0)
                        out[line.slice(0, tab)] = line.slice(tab + 1).trim();
                }
                page.info = out;
            }
        }
    }

    onActiveChanged: if (active)
        gather.running = true

    // A row with a value on the right, selectable so it can be copied
    component InfoRow: SettingRow {
        id: ir
        property string value: ""

        TextEdit {
            readOnly: true
            selectByMouse: true
            text: ir.value || "—"
            color: Theme.colors.text
            selectionColor: Theme.colors.primary
            selectedTextColor: Theme.colors.primaryText
            font.family: Theme.font
            font.pixelSize: Theme.fontSize.body
        }
    }

    // A button with an icon
    component ActionButton: MouseArea {
        id: ab
        property string icon
        property string label
        width: abRow.implicitWidth + 24
        height: 36
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        Rectangle {
            anchors.fill: parent
            radius: 10
            color: ab.containsMouse ? Theme.colors.primary : Theme.colors.surfaceContainerHigh
            Behavior on color {
                ColorAnimation {
                    duration: 120
                }
            }
        }
        Row {
            id: abRow
            anchors.centerIn: parent
            spacing: 8
            Icon {
                anchors.verticalCenter: parent.verticalCenter
                name: ab.icon
                font.pixelSize: 18
                color: ab.containsMouse ? Theme.colors.primaryText : Theme.colors.text
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: ab.label
                color: ab.containsMouse ? Theme.colors.primaryText : Theme.colors.text
                font.family: Theme.font
                font.pixelSize: Theme.fontSize.small
                font.weight: Font.Medium
            }
        }
    }

    SettingsSection {
        title: "This machine"

        InfoRow {
            label: "Name"
            value: page.info.host ?? ""
        }
        InfoRow {
            label: "System"
            value: page.info.os ?? ""
        }
        InfoRow {
            label: "Kernel"
            value: page.info.kernel ?? ""
        }
    }

    SettingsSection {
        title: "Versions"

        InfoRow {
            label: "Quickshell"
            value: page.info.quickshell ?? ""
        }
        InfoRow {
            label: "Hyprland"
            value: page.info.hyprland ?? ""
        }
        InfoRow {
            label: "matugen"
            value: page.info.matugen ?? ""
        }
        InfoRow {
            label: "Nix"
            value: page.info.nix ?? ""
        }
    }

    SettingsSection {
        title: "Dotfiles"

        InfoRow {
            label: "Latest commit"
            description: page.info.when ?? ""
            value: page.info.commit ?? ""
        }
        InfoRow {
            label: "Not committed yet"
            description: "Changed files in ~/dotfiles"
            value: (page.info.changes ?? "") === "0" ? "Nothing" : (page.info.changes ?? "") + " files"
        }
        InfoRow {
            label: "Not pushed yet"
            description: "Commits the other machine doesn't have"
            value: (page.info.ahead ?? "") === "0" ? "Nothing" : (page.info.ahead ?? "") + " commits"
        }
    }

    SettingsSection {
        title: "Shortcuts"

        Flow {
            x: 12
            width: parent.width - 24
            spacing: 8
            topPadding: 12
            bottomPadding: 12

            ActionButton {
                icon: "folder_open"
                label: "Open dotfiles"
                onClicked: Quickshell.execDetached(["dolphin", Quickshell.env("HOME") + "/dotfiles"])
            }
            ActionButton {
                icon: "sync"
                label: "Run dots-sync"
                // Keeps the terminal open afterwards, so you can read the output
                onClicked: Quickshell.execDetached(["alacritty", "-e", "fish", "-c", "dots-sync; read -P 'Done. Press Enter to close'"])
            }
            ActionButton {
                icon: "refresh"
                label: "Reload Hyprland"
                onClicked: Quickshell.execDetached(["hyprctl", "reload"])
            }
            ActionButton {
                icon: "restart_alt"
                label: "Restart Quickshell"
                onClicked: Quickshell.reload(true)
            }
        }
    }
}
