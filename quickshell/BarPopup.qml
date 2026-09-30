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

    // Horizontal centre of the icon, in bar coordinates; worked out when opening
    property real anchorX: 0

    function toggle() {
        if (!visible) anchorX = anchorItem.mapToItem(null, anchorItem.width / 2, 0).x;
        visible = !visible;
    }
    function close() { visible = false }

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
    visible: false

    // Close when clicking outside. The bar is included so clicking the
    // same icon again toggles the popup instead of closing and reopening it.
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

    // Flat top, concave corners where it meets the frame, rounded bottom
    Canvas {
        id: bg
        anchors.fill: parent
        antialiasing: true

        onPaint: {
            const ctx = getContext("2d");
            const w = width, h = height;
            const r = popup.fillet, c = popup.corner;

            ctx.reset();
            ctx.fillStyle = Theme.colors.surface;
            ctx.beginPath();
            ctx.moveTo(0, 0);
            ctx.lineTo(w, 0);
            ctx.arc(w, r, r, -Math.PI / 2, Math.PI, true);            // concave top-right
            ctx.lineTo(w - r, h - c);
            ctx.arc(w - r - c, h - c, c, 0, Math.PI / 2, false);      // rounded bottom-right
            ctx.lineTo(r + c, h);
            ctx.arc(r + c, h - c, c, Math.PI / 2, Math.PI, false);    // rounded bottom-left
            ctx.lineTo(r, r);
            ctx.arc(0, r, r, 0, -Math.PI / 2, true);                  // concave top-left
            ctx.closePath();
            ctx.fill();
        }

        // Redraw when the popup resizes or the wallpaper colors change
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        Connections {
            target: Theme.colors
            function onSurfaceChanged() { bg.requestPaint() }
        }
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
