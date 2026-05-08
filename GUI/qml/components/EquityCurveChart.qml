import QtQuick

Item {
    id: root
    property var equityCurve: []

    onEquityCurveChanged: canvas.requestPaint()
    onWidthChanged:       canvas.requestPaint()
    onHeightChanged:      canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent
        anchors.margins: 8
        antialiasing: true

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            ctx.clearRect(0, 0, width, height)

            var data = root.equityCurve
            if (!data || data.length < 2) {
                ctx.fillStyle = Theme.muted
                ctx.font = "13px sans-serif"
                ctx.textAlign = "center"
                ctx.textBaseline = "middle"
                ctx.fillText("运行回测后显示资产走势", width / 2, height / 2)
                return
            }

            var L = 74, R = 16, T = 34, B = 30
            var cW = width - L - R
            var cH = height - T - B
            var n = data.length

            var minV = data[0].strategy, maxV = data[0].strategy
            for (var i = 0; i < n; ++i) {
                minV = Math.min(minV, data[i].strategy, data[i].benchmark)
                maxV = Math.max(maxV, data[i].strategy, data[i].benchmark)
            }
            var pad = (maxV - minV) * 0.1 + 1
            minV -= pad; maxV += pad

            function toY(v) { return T + cH * (1 - (v - minV) / (maxV - minV)) }

            // Grid
            ctx.font = "10px sans-serif"
            ctx.textAlign = "right"
            ctx.textBaseline = "middle"
            for (var g = 0; g <= 4; ++g) {
                var gv = minV + (maxV - minV) * g / 4
                var gy = toY(gv)
                ctx.strokeStyle = "rgba(80,110,118,0.2)"
                ctx.lineWidth = 0.5
                ctx.beginPath(); ctx.moveTo(L, gy); ctx.lineTo(L + cW, gy); ctx.stroke()
                ctx.fillStyle = Theme.faint
                ctx.fillText("$" + Math.round(gv).toLocaleString(), L - 6, gy)
            }

            var step = cW / Math.max(1, n - 1)

            // Benchmark (dashed)
            ctx.strokeStyle = "rgba(82,184,255,0.72)"
            ctx.lineWidth = 1.5
            ctx.setLineDash([5, 4])
            ctx.beginPath()
            for (i = 0; i < n; ++i) {
                var bx = L + step * i, by = toY(data[i].benchmark)
                i === 0 ? ctx.moveTo(bx, by) : ctx.lineTo(bx, by)
            }
            ctx.stroke()
            ctx.setLineDash([])

            // Strategy fill
            ctx.fillStyle = "rgba(66,214,111,0.07)"
            ctx.beginPath()
            ctx.moveTo(L, T + cH)
            for (i = 0; i < n; ++i)
                ctx.lineTo(L + step * i, toY(data[i].strategy))
            ctx.lineTo(L + step * (n - 1), T + cH)
            ctx.closePath(); ctx.fill()

            // Strategy line
            ctx.strokeStyle = "rgba(66,214,111,0.92)"
            ctx.lineWidth = 2
            ctx.beginPath()
            for (i = 0; i < n; ++i) {
                var sx = L + step * i, sy = toY(data[i].strategy)
                i === 0 ? ctx.moveTo(sx, sy) : ctx.lineTo(sx, sy)
            }
            ctx.stroke()

            // Dots
            for (i = 0; i < n; ++i) {
                ctx.fillStyle = "rgba(66,214,111,0.9)"
                ctx.beginPath()
                ctx.arc(L + step * i, toY(data[i].strategy), 2.6, 0, Math.PI * 2)
                ctx.fill()
            }

            // X labels
            ctx.fillStyle = Theme.faint
            ctx.textAlign = "center"
            ctx.textBaseline = "top"
            ctx.font = "10px sans-serif"
            var lstep = Math.max(1, Math.floor(n / 5))
            for (i = 0; i < n; i += lstep)
                ctx.fillText(data[i].time, L + step * i, T + cH + 6)

            // Legend
            var lx = L + cW - 190, ly = 10
            ctx.strokeStyle = "rgba(66,214,111,0.92)"; ctx.lineWidth = 2; ctx.setLineDash([])
            ctx.beginPath(); ctx.moveTo(lx, ly + 6); ctx.lineTo(lx + 22, ly + 6); ctx.stroke()
            ctx.fillStyle = Theme.text
            ctx.textAlign = "left"; ctx.textBaseline = "middle"; ctx.font = "11px sans-serif"
            ctx.fillText("策略总值", lx + 28, ly + 6)

            ctx.strokeStyle = "rgba(82,184,255,0.72)"; ctx.lineWidth = 1.5; ctx.setLineDash([5, 4])
            ctx.beginPath(); ctx.moveTo(lx + 96, ly + 6); ctx.lineTo(lx + 118, ly + 6); ctx.stroke()
            ctx.setLineDash([])
            ctx.fillStyle = Theme.muted
            ctx.fillText("基准持股", lx + 124, ly + 6)
        }
    }
}
