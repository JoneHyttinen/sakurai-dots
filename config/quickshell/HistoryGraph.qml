import QtQuick

Canvas {
    id: graph
    property var values: []   // 0..1, oldest first
    property int capacity: 60
    property string lineColor: Theme.colors.primary

    antialiasing: true
    onValuesChanged: requestPaint()
    onLineColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onAvailableChanged: if (available) requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();

        const n = values.length;
        if (n < 2) return;

        const step = width / (capacity - 1);
        const x0 = width - (n - 1) * step;  // newest value at the right edge
        const y = v => height - Math.max(0, Math.min(1, v)) * (height - 2) - 1;

        // Line
        ctx.beginPath();
        ctx.moveTo(x0, y(values[0]));
        for (let i = 1; i < n; i++) ctx.lineTo(x0 + i * step, y(values[i]));
        ctx.strokeStyle = lineColor;
        ctx.lineWidth = 2;
        ctx.lineJoin = "round";
        ctx.stroke();

        // Soft fill underneath
        ctx.lineTo(width, height);
        ctx.lineTo(x0, height);
        ctx.closePath();
        ctx.globalAlpha = 0.18;
        ctx.fillStyle = lineColor;
        ctx.fill();
    }
}
