import QtQuick

Item {
    id: root
    property var trades: []

    onTradesChanged: canvas.requestPaint()
    onWidthChanged:  canvas.requestPaint()
    onHeightChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent
        anchors.margins: 8
        antialiasing: true

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            ctx.clearRect(0, 0, width, height)

            var trades = root.trades
            if (!trades || trades.length === 0) {
                ctx.fillStyle = Theme.muted
                ctx.font = "13px sans-serif"
                ctx.textAlign = "center"
                ctx.textBaseline = "middle"
                ctx.fillText("运行回测后显示盈亏分布", width / 2, height / 2)
                return
            }

            var L = 56, R = 16, T = 28, B = 32
            var cW = width - L - R
            var cH = height - T - B
            var n = trades.length

            var maxA = 0.01
            for (var i = 0; i < n; ++i)
                maxA = Math.max(maxA, Math.abs(trades[i].pnlPct))

            var zeroY = T + cH * 0.5

            // Grid
            ctx.font = "10px sans-serif"
            ctx.textAlign = "right"
            ctx.textBaseline = "middle"
            for (var g = -2; g <= 2; ++g) {
                var gv = g / 2 * maxA
                var gy = T + cH * (0.5 - g * 0.9 / 2)
                ctx.strokeStyle = "rgba(80,110,118,0.2)"
                ctx.lineWidth = 0.5
                ctx.beginPath(); ctx.moveTo(L, gy); ctx.lineTo(L + cW, gy); ctx.stroke()
                ctx.fillStyle = Theme.faint
                ctx.fillText(gv.toFixed(1) + "%", L - 6, gy)
            }

            // Zero line
            ctx.strokeStyle = "rgba(140,160,170,0.55)"
            ctx.lineWidth = 1
            ctx.beginPath(); ctx.moveTo(L, zeroY); ctx.lineTo(L + cW, zeroY); ctx.stroke()

            var step = cW / n
            var bW = Math.max(4, Math.min(26, step * 0.7))

            for (i = 0; i < n; ++i) {
                var pct = trades[i].pnlPct
                var pos = pct >= 0
                var barH = cH * 0.45 * Math.abs(pct) / maxA
                var bx = L + step * i + (step - bW) / 2
                var by = pos ? zeroY - barH : zeroY

                ctx.fillStyle = pos ? "rgba(66,214,111,0.85)" : "rgba(239,83,80,0.85)"
                ctx.fillRect(bx, by, bW, Math.max(1, barH))

                if (barH > 16) {
                    ctx.fillStyle = "rgba(255,255,255,0.92)"
                    ctx.font = "10px sans-serif"
                    ctx.textAlign = "center"
                    ctx.textBaseline = pos ? "bottom" : "top"
                    ctx.fillText(pct.toFixed(1) + "%", bx + bW / 2, pos ? by - 1 : by + barH + 1)
                }
            }

            // X-axis labels
            ctx.fillStyle = Theme.faint
            ctx.textAlign = "center"
            ctx.textBaseline = "top"
            ctx.font = "10px sans-serif"
            var lstep = Math.max(1, Math.floor(n / 8))
            for (i = 0; i < n; i += lstep)
                ctx.fillText("#" + (i + 1), L + step * (i + 0.5), T + cH + 6)

            // Title
            ctx.fillStyle = Theme.muted
            ctx.textAlign = "left"
            ctx.textBaseline = "top"
            ctx.font = "11px sans-serif"
            ctx.fillText("交易盈亏分布", L, 8)
        }
    }
}
