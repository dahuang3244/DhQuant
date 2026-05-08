import QtQuick

Item {
    id: root
    property var results: []  // array of result objects, each has .equityCurve []

    // Same palette used in BacktestPage attribution rows — keep in sync
    readonly property var chartPalette: [
        "#42d66f", "#5cb2ff", "#f5c542", "#ef5350", "#c77dff", "#ff9f43"
    ]

    onResultsChanged: canvas.requestPaint()
    onWidthChanged:   canvas.requestPaint()
    onHeightChanged:  canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent
        anchors.margins: 8
        antialiasing: true

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            ctx.clearRect(0, 0, width, height)

            var rs = root.results
            if (!rs || rs.length === 0) {
                ctx.fillStyle = Theme.muted
                ctx.font = "13px sans-serif"
                ctx.textAlign = "center"; ctx.textBaseline = "middle"
                ctx.fillText("运行回测后显示组合权益对比", width / 2, height / 2)
                return
            }

            var L = 74, R = 16, T = 44, B = 30
            var cW = width - L - R
            var cH = height - T - B

            // ── Global Y range across all curves ──────────────────────
            var minV = Infinity, maxV = -Infinity
            for (var r = 0; r < rs.length; r++) {
                var curve = rs[r].equityCurve || []
                for (var i = 0; i < curve.length; i++) {
                    if (curve[i].strategy < minV) minV = curve[i].strategy
                    if (curve[i].strategy > maxV) maxV = curve[i].strategy
                }
            }
            if (!isFinite(minV)) return

            var range = maxV - minV
            if (range < 1) { range = Math.max(1, maxV * 0.1); minV -= range * 0.5; maxV += range * 0.5 }
            var pad = range * 0.14
            minV -= pad; maxV += pad

            function toY(v) { return T + cH * (1 - (v - minV) / (maxV - minV)) }

            // ── Grid ──────────────────────────────────────────────────
            ctx.font = "10px sans-serif"
            ctx.textAlign = "right"; ctx.textBaseline = "middle"
            for (var g = 0; g <= 4; g++) {
                var gv = minV + (maxV - minV) * g / 4
                var gy = toY(gv)
                ctx.strokeStyle = "rgba(80,110,118,0.2)"; ctx.lineWidth = 0.5
                ctx.beginPath(); ctx.moveTo(L, gy); ctx.lineTo(L + cW, gy); ctx.stroke()
                ctx.fillStyle = Theme.faint
                ctx.fillText("$" + Math.round(gv).toLocaleString(), L - 6, gy)
            }

            var pal = root.chartPalette

            // ── Fill areas (back layer) ────────────────────────────────
            for (r = 0; r < rs.length; r++) {
                var fdata = rs[r].equityCurve || []
                if (fdata.length < 2) continue
                var fn = fdata.length
                var fstep = cW / Math.max(1, fn - 1)
                ctx.globalAlpha = 0.05
                ctx.fillStyle = pal[r % pal.length]
                ctx.beginPath()
                ctx.moveTo(L, T + cH)
                for (i = 0; i < fn; i++) ctx.lineTo(L + fstep * i, toY(fdata[i].strategy))
                ctx.lineTo(L + fstep * (fn - 1), T + cH)
                ctx.closePath(); ctx.fill()
                ctx.globalAlpha = 1.0
            }

            // ── Lines + dots ──────────────────────────────────────────
            for (r = 0; r < rs.length; r++) {
                var ldata = rs[r].equityCurve || []
                if (ldata.length < 2) continue
                var ln = ldata.length
                var lstep = cW / Math.max(1, ln - 1)
                var lcol = pal[r % pal.length]

                ctx.strokeStyle = lcol; ctx.lineWidth = 1.9; ctx.globalAlpha = 0.88
                ctx.beginPath()
                for (i = 0; i < ln; i++) {
                    var sx = L + lstep * i, sy = toY(ldata[i].strategy)
                    i === 0 ? ctx.moveTo(sx, sy) : ctx.lineTo(sx, sy)
                }
                ctx.stroke(); ctx.globalAlpha = 1.0

                ctx.fillStyle = lcol
                for (i = 0; i < ln; i++) {
                    ctx.beginPath()
                    ctx.arc(L + lstep * i, toY(ldata[i].strategy), 2.3, 0, Math.PI * 2)
                    ctx.fill()
                }
            }

            // ── Legend (top, wraps if needed) ─────────────────────────
            var lx = L, ly = 10
            ctx.setLineDash([])
            ctx.font = "10px sans-serif"; ctx.textBaseline = "middle"
            for (r = 0; r < rs.length; r++) {
                var lc = pal[r % pal.length]
                var name = rs[r].strategyName || ("策略" + (r + 1))
                if (name.length > 10) name = name.substring(0, 9) + "…"
                ctx.strokeStyle = lc; ctx.lineWidth = 2
                ctx.beginPath(); ctx.moveTo(lx, ly + 6); ctx.lineTo(lx + 16, ly + 6); ctx.stroke()
                ctx.fillStyle = Theme.muted; ctx.textAlign = "left"
                var tw = ctx.measureText(name).width
                ctx.fillText(name, lx + 20, ly + 6)
                lx += tw + 40
                if (lx > L + cW * 0.75) { lx = L; ly += 14 }
            }

            // ── X-axis time labels from first curve ───────────────────
            var fc = rs[0].equityCurve || []
            if (fc.length >= 2) {
                var xn = fc.length
                var xstep = cW / Math.max(1, xn - 1)
                var xlstep = Math.max(1, Math.floor(xn / 5))
                ctx.fillStyle = Theme.faint
                ctx.textAlign = "center"; ctx.textBaseline = "top"; ctx.font = "10px sans-serif"
                for (i = 0; i < xn; i += xlstep)
                    ctx.fillText(fc[i].time, L + xstep * i, T + cH + 6)
            }
        }
    }
}
