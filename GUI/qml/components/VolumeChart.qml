import QtQuick

Item {
    id: root
    property var bars: []

    onBarsChanged: canvas.requestPaint()
    onWidthChanged: canvas.requestPaint()
    onHeightChanged: canvas.requestPaint()

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.panel
        border.color: Theme.border
    }

    Canvas {
        id: canvas
        anchors.fill: parent
        anchors.margins: 10
        antialiasing: true

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            ctx.clearRect(0, 0, width, height)
            if (!root.bars || root.bars.length === 0)
                return

            var left = 42
            var right = 12
            var top = 18
            var bottom = 10
            var chartW = width - left - right
            var chartH = height - top - bottom
            var maxV = 1
            for (var i = 0; i < root.bars.length; ++i)
                maxV = Math.max(maxV, root.bars[i].volume)

            var step = chartW / Math.max(1, root.bars.length)
            var barW = Math.max(2, step * 0.62)
            for (i = 0; i < root.bars.length; ++i) {
                var bar = root.bars[i]
                var h = chartH * bar.volume / maxV
                var rising = bar.close >= bar.open
                ctx.fillStyle = rising ? "rgba(66, 214, 111, 0.62)" : "rgba(239, 83, 80, 0.62)"
                ctx.fillRect(left + step * i + (step - barW) / 2, top + chartH - h, barW, h)
            }

            ctx.fillStyle = Theme.muted
            ctx.font = "12px sans-serif"
            ctx.textAlign = "left"
            ctx.fillText("Volume", left, 12)
        }
    }
}
