import QtQuick

// A rounded CSS-like surface. The Canvas extends outside the layout box for
// spread rings; painting is clipped to the rounded face for inset highlights.
Item {
    id: root
    property real radius: 0
    property color solidColor: baseColor
    property color baseColor: "white"
    property color endColor: baseColor
    property bool gradientEnabled: false
    property bool horizontal: false
    property bool diagonal: false
    property real ringWidth: 0
    property color ringColor: "black"
    property real innerBorderWidth: 0
    property real bottomBorderWidth: 0
    property color bottomBorderColor: solidColor
    property bool dropShadow: false
    property real shadowSize: 0
    property bool insetHighlight: false
    property color highlightColor: "white"
    property real highlightDepth: 0

    // Track all paint inputs in one binding, including colors and geometry.
    readonly property var paintState: [width, height, radius, solidColor, baseColor,
        endColor, gradientEnabled, horizontal, diagonal, ringWidth, ringColor,
        innerBorderWidth, bottomBorderWidth, bottomBorderColor, insetHighlight,
        highlightColor, highlightDepth, dropShadow, shadowSize]
    onPaintStateChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        readonly property real margin: root.ringWidth + (root.dropShadow ? root.shadowSize * 3 : 0) + 1
        x: -margin
        y: -margin
        width: root.width + margin * 2
        height: root.height + margin * 2
        antialiasing: true

        function rounded(ctx, x, y, w, h, radius) {
            const r = Math.max(0, Math.min(radius, w / 2, h / 2));
            ctx.beginPath();
            ctx.moveTo(x + r, y);
            ctx.lineTo(x + w - r, y);
            ctx.arcTo(x + w, y, x + w, y + r, r);
            ctx.lineTo(x + w, y + h - r);
            ctx.arcTo(x + w, y + h, x + w - r, y + h, r);
            ctx.lineTo(x + r, y + h);
            ctx.arcTo(x, y + h, x, y + h - r, r);
            ctx.lineTo(x, y + r);
            ctx.arcTo(x, y, x + r, y, r);
            ctx.closePath();
        }

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            ctx.translate(margin, margin);
            const w = root.width, h = root.height;
            if (w <= 0 || h <= 0) return;
            if (root.dropShadow) {
                rounded(ctx, 0, 0, w, h, root.radius);
                ctx.shadowColor = "#80000000";
                ctx.shadowBlur = root.shadowSize;
                ctx.shadowOffsetY = root.shadowSize;
                ctx.fillStyle = root.solidColor;
                ctx.fill();
                ctx.shadowBlur = 0;
                ctx.shadowOffsetY = 0;
                ctx.save();
                rounded(ctx, 0, 0, w, h, root.radius);
                ctx.clip();
                ctx.clearRect(0, 0, w, h);
                ctx.restore();
            }
            if (root.ringWidth > 0) {
                const b = root.ringWidth;
                rounded(ctx, -b/2, -b/2, w+b, h+b, root.radius+b/2);
                ctx.strokeStyle = root.ringColor;
                ctx.lineWidth = b;
                ctx.stroke();
            }
            rounded(ctx, 0, 0, w, h, root.radius);
            ctx.save();
            ctx.clip();
            if (root.bottomBorderWidth > 0) {
                ctx.fillStyle = root.bottomBorderColor;
                ctx.fillRect(0, h-root.bottomBorderWidth, w, root.bottomBorderWidth);
            }
            if (root.gradientEnabled) {
                // CSS "to bottom right" is perpendicular to the corner diagonal.
                const extent = root.diagonal ? w*h / (w*w + h*h) : 0;
                const dx = root.diagonal ? h*extent : (root.horizontal ? w/2 : 0);
                const dy = root.diagonal ? w*extent : (root.horizontal ? 0 : h/2);
                const gradient = ctx.createLinearGradient(w/2-dx, h/2-dy, w/2+dx, h/2+dy);
                gradient.addColorStop(0, root.baseColor);
                gradient.addColorStop(1, root.endColor);
                ctx.fillStyle = gradient;
            } else {
                ctx.fillStyle = root.solidColor;
            }
            ctx.fillRect(0, 0, w, Math.max(0, h - root.bottomBorderWidth));
            if (root.insetHighlight && root.highlightDepth > 0) {
                // Stroke the whole rounded edge with a blurred, inset highlight.
                const d = root.highlightDepth;
                rounded(ctx, -d/2, -d/2, w+d, h+d, root.radius+d/2);
                ctx.strokeStyle = root.highlightColor;
                ctx.lineWidth = root.highlightDepth;
                ctx.shadowColor = root.highlightColor;
                ctx.shadowBlur = root.highlightDepth;
                ctx.shadowOffsetY = root.shadowSize / 2;
                ctx.stroke();
                ctx.shadowBlur = 0;
                ctx.shadowOffsetY = 0;
            }
            if (root.innerBorderWidth > 0) {
                const b = root.innerBorderWidth;
                rounded(ctx, b/2, b/2, w-b, h-b, Math.max(0, root.radius-b/2));
                ctx.lineWidth = b;
                ctx.strokeStyle = root.ringColor;
                ctx.stroke();
            }
            ctx.restore();
        }
    }
}
