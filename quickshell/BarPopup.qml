import QtQuick
import Quickshell
import Quickshell.Hyprland

PopupWindow {
    id: popup
    required property Item anchorItem
    property var barWindow: null
    property int contentWidth: 280
    default property alias content: body.data

    function toggle() { visible = !visible }
    function close() { visible = false }

    anchor.item: anchorItem
    anchor.rect.width: anchorItem.width
    anchor.rect.height: anchorItem.height + 18  // drop below the bar
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom

    implicitWidth: contentWidth
    implicitHeight: body.implicitHeight + 24
    color: "transparent"
    visible: false

    // Close when clicking outside. The grab is activated a moment after the
    // popup appears, so the popup surface exists when Hyprland sets it up.
    HyprlandFocusGrab {
        id: grab
        windows: popup.barWindow ? [popup, popup.barWindow] : [popup]
        onCleared: popup.visible = false
    }

    Timer {
        id: grabDelay
        interval: 50
        onTriggered: grab.active = popup.visible
    }

    onVisibleChanged: {
      if (visible) {
        Panels.opened(popup);
        grabDelay.restart();
      } else {
        grab.active = false;
        Panels.closed(popup);
      }
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.colors.surfaceContainer
        border.width: 1
        border.color: Theme.colors.outlineVariant

        Column {
            id: body
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
            spacing: 10
        }
    }
}
