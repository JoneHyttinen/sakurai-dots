import QtQuick

// A panel background that merges into the screen frame.
// edge: "top" | "bottom" | "right" | "topRight"
Canvas {
    id: bg
    property string edge: "top"
    property real fillet: Theme.frame.radius
    property real corner: Theme.radius
    property color fill: Theme.colors.surface

    antialiasing: true

    onPaint: {
        const ctx = getContext("2d");
        const w = width, h = height, r = fillet, c = corner;
        const PI = Math.PI;

        ctx.reset();
        ctx.fillStyle = fill.toString();
        ctx.beginPath();

        if (edge === "top") {
            // Hangs down from the top band; body spans x = r..w-r
            ctx.moveTo(0, 0);
            ctx.lineTo(w, 0);
            ctx.arc(w, r, r, -PI / 2, PI, true);
            ctx.lineTo(w - r, h - c);
            ctx.arc(w - r - c, h - c, c, 0, PI / 2, false);
            ctx.lineTo(r + c, h);
            ctx.arc(r + c, h - c, c, PI / 2, PI, false);
            ctx.lineTo(r, r);
            ctx.arc(0, r, r, 0, -PI / 2, true);
        } else if (edge === "bottom") {
            // Rises from the bottom band; body spans x = r..w-r
            ctx.moveTo(0, h);
            ctx.arc(0, h - r, r, PI / 2, 0, true);
            ctx.lineTo(r, c);
            ctx.arc(r + c, c, c, PI, 3 * PI / 2, false);
            ctx.lineTo(w - r - c, 0);
            ctx.arc(w - r - c, c, c, -PI / 2, 0, false);
            ctx.lineTo(w - r, h - r);
            ctx.arc(w, h - r, r, PI, PI / 2, true);
        } else if (edge === "right") {
            // Full-height panel on the right band; body spans x = r..w
            ctx.moveTo(0, 0);
            ctx.lineTo(w, 0);
            ctx.lineTo(w, h);
            ctx.lineTo(0, h);
            ctx.arc(0, h - r, r, PI / 2, 0, true);
            ctx.lineTo(r, r);
            ctx.arc(0, r, r, 0, -PI / 2, true);
        } else if (edge === "topRight") {
            // Tucked into the top-right corner; body spans x = r..w, y = 0..h-r
            ctx.moveTo(0, 0);
            ctx.lineTo(w, 0);
            ctx.lineTo(w, h);
            ctx.arc(w - r, h, r, 0, -PI / 2, true);
            ctx.lineTo(r + c, h - r);
            ctx.arc(r + c, h - r - c, c, PI / 2, PI, false);
            ctx.lineTo(r, r);
            ctx.arc(0, r, r, 0, -PI / 2, true);
        }

        ctx.closePath();
        ctx.fill();
    }

    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onEdgeChanged: requestPaint()
    onFillChanged: requestPaint()  // wallpaper color changes
}
