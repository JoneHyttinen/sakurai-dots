import QtQuick
import Quickshell
import Quickshell.Hyprland

PopupWindow {
    id: popup
    required property Item anchorItem
    property var barWindow: null
    property int contentWidth: 280
    default property alias content: body.data

    readonly property int fillet: Theme.frame.radius  // concave corners where it meets the frame
    readonly property int corner: Theme.radius         // rounded bottom corners

    // Open/closed state; the window stays visible until the slide-out finishes
    property bool shown: false
    visible: shown || slide.y > -slide.height

    // Horizontal centre of the icon, in bar coordinates; worked out when opening
    property real anchorX: 0

    function toggle() {
        if (!shown) anchorX = anchorItem.mapToItem(null, anchorItem.width / 2, 0).x;
        shown = !shown;
    }
    function close() { shown = false }

    onShownChanged: {
        if (shown) {
            Panels.opened(popup);
            grabDelay.restart();
        } else {
            grab.active = false;
            Panels.closed(popup);
        }
    }

    // Hang from the bar's bottom edge, centred under the icon
    anchor.window: barWindow
    anchor.rect.x: anchorX
    anchor.rect.y: barWindow ? barWindow.height : 0
    anchor.rect.width: 1
    anchor.rect.height: 1
    anchor.edges: Edges.Top
    anchor.gravity: Edges.Bottom

    implicitWidth: contentWidth + fillet * 2
    implicitHeight: body.implicitHeight + 24
    color: "transparent"

    // Close when clicking outside. The bar is included so clicking the
    // same icon again toggles the popup instead of closing and reopening it.
    HyprlandFocusGrab {
        id: grab
        windows: popup.barWindow ? [popup, popup.barWindow] : [popup]
        onCleared: popup.close()
    }
    Timer {
        id: grabDelay
        interval: 50
        onTriggered: grab.active = popup.shown
    }

    // Everything slides together; the window's top edge is the frame's
    // edge, so the popup looks like it comes out of the frame
    Item {
        id: slide
        width: parent.width
        height: parent.height
        y: popup.shown ? 0 : -height
        Behavior on y { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

        FramePanel {
            anchors.fill: parent
            edge: "top"
        }

        Column {
            id: body
            anchors {
                left: parent.left; leftMargin: popup.fillet + 12
                right: parent.right; rightMargin: popup.fillet + 12
                top: parent.top; topMargin: 12
            }
            spacing: 10
        }
    }
}
