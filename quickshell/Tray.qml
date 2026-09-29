import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import Quickshell.Wayland

MouseArea {
    id: root
    readonly property var win: QsWindow.window

    // null = show the icon grid; otherwise show this app's menu
    property var trayItem: null
    // Menu levels for submenu navigation; the last one is the one shown
    property var menuStack: []

    function showMenu(item) { trayItem = item; menuStack = [item.menu]; }
    function closeMenu() { trayItem = null; menuStack = []; }
    // Find an open window belonging to a tray app by comparing its
    // tray id/title with the window's app id (e.g. "steam")
    function findWindow(item) {
        const keys = [item.id, item.title].filter(k => k).map(k => k.toLowerCase());
        return ToplevelManager.toplevels.values.find(t => {
            const app = (t.appId ?? "").toLowerCase();
            return app !== "" && keys.some(k => app.includes(k) || k.includes(app));
        }) ?? null;
    }

    property var pendingItem: null

    function openApp(item) {
        const w = findWindow(item);
        if (w) {
            w.activate();
            return;
        }
        if (!item.onlyMenu) item.activate();
        pendingItem = item;
        launchFallback.restart();
    }

    // If the app ignored the tray request, launch its desktop entry instead
    Timer {
        id: launchFallback
        interval: 600
        onTriggered: {
            const it = root.pendingItem;
            root.pendingItem = null;
            if (!it || root.findWindow(it)) return;
            const entry = DesktopEntries.heuristicLookup(it.id)
                ?? DesktopEntries.heuristicLookup(it.title);
            entry?.execute();
        }
    }
    // Tray menus use "_" to mark keyboard shortcuts, e.g. "_Library"
    function cleanLabel(t) { return (t ?? "").replace(/_([^_])/g, "$1"); }

    visible: SystemTray.items.values.length > 0
    implicitWidth: chevron.implicitWidth
    implicitHeight: chevron.implicitHeight
    cursorShape: Qt.PointingHandCursor
    onClicked: { closeMenu(); popup.toggle(); }

    Icon {
        id: chevron
        name: popup.visible ? "expand_less" : "expand_more"
    }

    // Reads the entries of whichever menu level is currently shown
    QsMenuOpener {
        id: opener
        menu: root.menuStack.length > 0 ? root.menuStack[root.menuStack.length - 1] : null
    }

    BarPopup {
        id: popup
        anchorItem: root
        barWindow: root.win

        readonly property int columns: Math.min(5, SystemTray.items.values.length)
        contentWidth: root.trayItem ? 240 : columns * 32 + (columns - 1) * 4 + 24

        onVisibleChanged: if (!visible) root.closeMenu()

        // Icon grid
        Flow {
            visible: root.trayItem === null
            width: parent.width
            spacing: 4

            Repeater {
                model: SystemTray.items
                delegate: MouseArea {
                    id: item
                    required property SystemTrayItem modelData
                    width: 32
                    height: 32
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor

                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton && modelData.hasMenu)
                            root.showMenu(modelData);
                    }
                    onDoubleClicked: mouse => {
                        if (mouse.button !== Qt.LeftButton) return;
                        popup.visible = false;
                        root.openApp(modelData);
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: 8
                        color: Theme.colors.surfaceContainerHigh
                        opacity: item.containsMouse ? 1 : 0
                    }
                    IconImage {
                        anchors.centerIn: parent
                        implicitSize: 20
                        source: item.modelData.icon
                    }
                }
            }
        }

        // App menu
        Column {
            visible: root.trayItem !== null
            width: parent.width
            spacing: 2

            MenuRow {
                icon: "arrow_back"
                label: root.menuStack.length > 1 ? "Back"
                    : (root.trayItem?.tooltipTitle || root.trayItem?.title || "Back")
                onClicked: {
                    if (root.menuStack.length > 1)
                        root.menuStack = root.menuStack.slice(0, -1);
                    else
                        root.closeMenu();
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.colors.outlineVariant }

            Repeater {
                model: opener.children
                delegate: Item {
                    id: entry
                    required property var modelData
                    width: parent.width
                    height: modelData.isSeparator ? 9 : 36

                    Rectangle {
                        visible: entry.modelData.isSeparator
                        anchors.centerIn: parent
                        width: parent.width
                        height: 1
                        color: Theme.colors.outlineVariant
                    }

                    MenuRow {
                        visible: !entry.modelData.isSeparator
                        anchors.fill: parent
                        enabled: entry.modelData.enabled
                        opacity: enabled ? 1 : 0.4
                        icon: entry.modelData.hasChildren ? "chevron_right"
                            : entry.modelData.checkState === Qt.Checked ? "check"
                            : ""
                        label: root.cleanLabel(entry.modelData.text)

                        onClicked: {
                            if (entry.modelData.hasChildren) {
                                root.menuStack = root.menuStack.concat([entry.modelData]);
                            } else {
                                entry.modelData.triggered();
                                popup.visible = false;
                            }
                        }
                    }
                }
            }
        }
    }
}
