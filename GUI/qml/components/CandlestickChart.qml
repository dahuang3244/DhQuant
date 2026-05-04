import QtQuick

Item {
    id: root
    property var bars: []
    property bool showMa5: true
    property bool showMa20: true

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

        function priceToY(price, minPrice, maxPrice, chartTop, chartHeight) {
            if (Math.abs(maxPrice - minPrice) < 0.00001)
                return chartTop + chartHeight / 2
            return chartTop + chartHeight * (1 - (price - minPrice) / (maxPrice - minPrice))
        }

        function ma(index, window) {
            if (index + 1 < window)
                return null
            var sum = 0
            for (var j = index - window + 1; j <= index; ++j)
                sum += root.bars[j].close
            return sum / window
        }

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            ctx.clearRect(0, 0, width, height)

            if (!root.bars || root.bars.length === 0)
                return

            var left = 54
            var right = 16
            var top = 18
            var bottom = 28
            var chartW = width - left - right
            var chartH = height - top - bottom
            var minP = root.bars[0].low
            var maxP = root.bars[0].high

            for (var i = 0; i < root.bars.length; ++i) {
                minP = Math.min(minP, root.bars[i].low)
                maxP = Math.max(maxP, root.bars[i].high)
            }

            var pad = (maxP - minP) * 0.08
            minP = Math.max(0.01, minP - pad)
            maxP = maxP + pad

            ctx.lineWidth = 1
            ctx.font = "11px sans-serif"
            ctx.textBaseline = "middle"

            for (var g = 0; g <= 5; ++g) {
                var y = top + chartH / 5 * g
                var price = maxP - (maxP - minP) / 5 * g
                ctx.strokeStyle = "rgba(80, 110, 118, 0.28)"
                ctx.beginPath()
                ctx.moveTo(left, y)
                ctx.lineTo(left + chartW, y)
                ctx.stroke()
                ctx.fillStyle = Theme.muted
                ctx.textAlign = "right"
                ctx.fillText(price.toFixed(2), left - 8, y)
            }

            var step = chartW / Math.max(1, root.bars.length)
            var candleW = Math.max(3, Math.min(10, step * 0.58))

            for (i = 0; i < root.bars.length; ++i) {
                var bar = root.bars[i]
                var x = left + step * i + step * 0.5
                var openY = priceToY(bar.open, minP, maxP, top, chartH)
                var closeY = priceToY(bar.close, minP, maxP, top, chartH)
                var highY = priceToY(bar.high, minP, maxP, top, chartH)
                var lowY = priceToY(bar.low, minP, maxP, top, chartH)
                var rising = bar.close >= bar.open
                ctx.strokeStyle = rising ? Theme.positive : Theme.negative
                ctx.fillStyle = rising ? Theme.positive : Theme.negative
                ctx.beginPath()
                ctx.moveTo(x, highY)
                ctx.lineTo(x, lowY)
                ctx.stroke()
                var bodyTop = Math.min(openY, closeY)
                var bodyH = Math.max(1.4, Math.abs(closeY - openY))
                ctx.fillRect(x - candleW / 2, bodyTop, candleW, bodyH)
            }

            function drawMa(window, color) {
                ctx.strokeStyle = color
                ctx.lineWidth = 1.4
                ctx.beginPath()
                var started = false
                for (var k = 0; k < root.bars.length; ++k) {
                    var value = ma(k, window)
                    if (value === null)
                        continue
                    var px = left + step * k + step * 0.5
                    var py = priceToY(value, minP, maxP, top, chartH)
                    if (!started) {
                        ctx.moveTo(px, py)
                        started = true
                    } else {
                        ctx.lineTo(px, py)
                    }
                }
                ctx.stroke()
            }

            if (root.showMa5)
                drawMa(5, "rgba(245, 197, 66, 0.92)")
            if (root.showMa20)
                drawMa(20, "rgba(82, 184, 255, 0.82)")

            ctx.fillStyle = Theme.faint
            ctx.textAlign = "center"
            ctx.textBaseline = "top"
            var labelStep = Math.max(1, Math.floor(root.bars.length / 5))
            for (i = 0; i < root.bars.length; i += labelStep) {
                ctx.fillText(root.bars[i].time, left + step * i + step * 0.5, top + chartH + 8)
            }
        }
    }
}
