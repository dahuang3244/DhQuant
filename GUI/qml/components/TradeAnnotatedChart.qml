import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property var  bars:     []
    property bool showMa5:  true
    property bool showMa20: true
    property bool showMacd: false
    property real hoverX: -1
    property real hoverY: -1
    property bool hovering: false

    onBarsChanged:    { price.requestPaint(); if (showMacd) macd.requestPaint() }
    onShowMa5Changed:  price.requestPaint()
    onShowMa20Changed: price.requestPaint()
    onShowMacdChanged: { price.requestPaint(); macd.requestPaint() }
    onWidthChanged:   { price.requestPaint(); if (showMacd) macd.requestPaint() }
    onHeightChanged:  { price.requestPaint(); if (showMacd) macd.requestPaint() }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── Price + annotation canvas ─────────────────────────────────
        Canvas {
            id: price
            Layout.fillWidth: true
            Layout.fillHeight: true
            antialiasing: true

            onPaint: {
                var ctx = getContext("2d")
                ctx.reset()
                ctx.clearRect(0, 0, width, height)

                var bars = root.bars
                if (!bars || bars.length === 0) {
                    ctx.fillStyle = Theme.muted
                    ctx.font = "13px sans-serif"
                    ctx.textAlign = "center"
                    ctx.textBaseline = "middle"
                    ctx.fillText("运行回测后显示 K 线与交易标注", width / 2, height / 2)
                    return
                }

                var L = 56, R = 102, T = 20, B = 28
                var cW = width - L - R
                var cH = height - T - B
                var n = bars.length

                // price range
                var minP = bars[0].low, maxP = bars[0].high
                for (var i = 0; i < n; ++i) {
                    minP = Math.min(minP, bars[i].low)
                    maxP = Math.max(maxP, bars[i].high)
                }
                var pad = Math.max(0.01, (maxP - minP) * 0.09)
                minP = Math.max(0.01, minP - pad); maxP += pad

                function toY(p) {
                    if (Math.abs(maxP - minP) < 0.00001) return T + cH / 2
                    return T + cH * (1 - (p - minP) / (maxP - minP))
                }

                function toPrice(y) {
                    return maxP - (y - T) / cH * (maxP - minP)
                }

                function fmtPrice(v) {
                    if (Math.abs(v) >= 1000) return v.toFixed(0)
                    return v.toFixed(2)
                }

                function pctFromEntry(priceValue, entry) {
                    if (!entry || !entry.price) return null
                    var raw = (priceValue - entry.price) / entry.price
                    if (entry.direction !== "多") raw = -raw
                    return raw * 100
                }

                function entryForIndex(targetIndex) {
                    var entry = null
                    for (var ei = 0; ei <= targetIndex && ei < n; ++ei) {
                        if (bars[ei].tradeEntry)
                            entry = bars[ei].tradeEntry
                        if (bars[ei].tradeExit)
                            entry = null
                    }
                    return entry
                }

                function lastEntry() {
                    var entry = null
                    var index = -1
                    for (var li = 0; li < n; ++li) {
                        if (bars[li].tradeEntry) {
                            entry = bars[li].tradeEntry
                            index = li
                        }
                    }
                    return { entry: entry, index: index }
                }

                function roundedRect(x, y, w, h, r) {
                    var radius = Math.min(r, w / 2, h / 2)
                    ctx.moveTo(x + radius, y)
                    ctx.lineTo(x + w - radius, y)
                    ctx.quadraticCurveTo(x + w, y, x + w, y + radius)
                    ctx.lineTo(x + w, y + h - radius)
                    ctx.quadraticCurveTo(x + w, y + h, x + w - radius, y + h)
                    ctx.lineTo(x + radius, y + h)
                    ctx.quadraticCurveTo(x, y + h, x, y + h - radius)
                    ctx.lineTo(x, y + radius)
                    ctx.quadraticCurveTo(x, y, x + radius, y)
                }

                var step = cW / Math.max(1, n)
                var cw2  = Math.max(3, Math.min(10, step * 0.58))

                // Grid
                ctx.font = "10px sans-serif"
                ctx.textAlign = "right"; ctx.textBaseline = "middle"
                for (var g = 0; g <= 5; ++g) {
                    var gy = T + cH / 5 * g
                    var gp = maxP - (maxP - minP) / 5 * g
                    ctx.strokeStyle = "rgba(80,110,118,0.2)"
                    ctx.lineWidth = 0.5
                    ctx.beginPath(); ctx.moveTo(L, gy); ctx.lineTo(L + cW, gy); ctx.stroke()
                    ctx.fillStyle = Theme.faint
                    ctx.fillText(fmtPrice(gp), L - 6, gy)
                }

                // Holding-period background
                for (i = 0; i < n; ++i) {
                    if (bars[i].inPosition) {
                        ctx.fillStyle = "rgba(121,92,255,0.08)"
                        ctx.fillRect(L + step * i, T, step, cH)
                    }
                }

                // Candlesticks
                for (i = 0; i < n; ++i) {
                    var bar = bars[i]
                    var x = L + step * i + step * 0.5
                    var rising = bar.close >= bar.open
                    var col = rising ? "#42d66f" : "#ef5350"
                    ctx.strokeStyle = col; ctx.fillStyle = col; ctx.lineWidth = 1
                    ctx.beginPath(); ctx.moveTo(x, toY(bar.high)); ctx.lineTo(x, toY(bar.low)); ctx.stroke()
                    var bT = Math.min(toY(bar.open), toY(bar.close))
                    var bH = Math.max(1.5, Math.abs(toY(bar.open) - toY(bar.close)))
                    ctx.fillRect(x - cw2 / 2, bT, cw2, bH)
                }

                // MA helper
                function ma(idx, w) {
                    if (idx + 1 < w) return null
                    var s = 0
                    for (var j = idx - w + 1; j <= idx; ++j) s += bars[j].close
                    return s / w
                }
                function drawMa(w, color) {
                    ctx.strokeStyle = color; ctx.lineWidth = 1.4
                    ctx.beginPath(); var started = false
                    for (var k = 0; k < n; ++k) {
                        var v = ma(k, w); if (v === null) continue
                        var px = L + step * k + step * 0.5, py = toY(v)
                        if (!started) { ctx.moveTo(px, py); started = true } else ctx.lineTo(px, py)
                    }
                    ctx.stroke()
                }
                if (root.showMa5)  drawMa(5,  "rgba(245,197,66,0.9)")
                if (root.showMa20) drawMa(20, "rgba(82,184,255,0.82)")

                // Trade markers
                ctx.font = "bold 10px sans-serif"
                for (i = 0; i < n; ++i) {
                    var b2 = bars[i]
                    var cx = L + step * i + step * 0.5

                    if (b2.tradeEntry) {
                        var ey = toY(b2.tradeEntry.price)
                        var long2 = b2.tradeEntry.direction === "多"
                        ctx.fillStyle = long2 ? "#42d66f" : "#ef5350"
                        ctx.beginPath()
                        if (long2) {
                            ctx.moveTo(cx, ey - 12); ctx.lineTo(cx - 6, ey - 2); ctx.lineTo(cx + 6, ey - 2)
                        } else {
                            ctx.moveTo(cx, ey + 12); ctx.lineTo(cx - 6, ey + 2); ctx.lineTo(cx + 6, ey + 2)
                        }
                        ctx.closePath(); ctx.fill()
                        ctx.fillStyle = long2 ? "#42d66f" : "#ef5350"
                        ctx.textAlign = "center"
                        ctx.textBaseline = long2 ? "bottom" : "top"
                        ctx.fillText("开" + b2.tradeEntry.direction, cx, long2 ? ey - 16 : ey + 16)
                    }

                    if (b2.tradeExit) {
                        var xp = b2.tradeExit.pnlPct
                        var xpos = xp >= 0
                        var xy = toY(b2.tradeExit.price)
                        var label = "平" + b2.tradeExit.direction + " " + (xpos ? "+" : "") + xp.toFixed(1) + "%"
                        ctx.font = "bold 10px sans-serif"
                        var tw = ctx.measureText(label).width + 10
                        var ph = 17, py2 = xy - 26
                        var pilX = Math.max(L + 2, Math.min(L + cW - tw - 2, cx - tw / 2))

                        ctx.fillStyle = xpos ? "rgba(66,214,111,0.18)" : "rgba(239,83,80,0.18)"
                        ctx.strokeStyle = xpos ? "rgba(66,214,111,0.72)" : "rgba(239,83,80,0.72)"
                        ctx.lineWidth = 0.8
                        ctx.beginPath()
                        roundedRect(pilX, py2, tw, ph, 4)
                        ctx.fill(); ctx.stroke()

                        ctx.fillStyle = xpos ? "#42d66f" : "#ef5350"
                        ctx.textAlign = "center"; ctx.textBaseline = "middle"
                        ctx.fillText(label, pilX + tw / 2, py2 + ph / 2)
                    }
                }

                // X-axis time labels
                ctx.fillStyle = Theme.faint
                ctx.textAlign = "center"; ctx.textBaseline = "top"; ctx.font = "10px sans-serif"
                var lstep = Math.max(1, Math.floor(n / 6))
                for (i = 0; i < n; i += lstep)
                    ctx.fillText(bars[i].time, L + step * i + step * 0.5, T + cH + 6)

                var hoverInChart = root.hovering && root.hoverX >= L && root.hoverX <= L + cW && root.hoverY >= T && root.hoverY <= T + cH
                var hoverSlot = -1
                var activeEntry = null
                if (hoverInChart) {
                    hoverSlot = Math.max(0, Math.min(n - 1, Math.floor((root.hoverX - L) / step)))
                    activeEntry = entryForIndex(hoverSlot)
                }

                // Entry benchmark marker: default to the latest trade entry, switch to the
                // hovered position's entry while inspecting a historical holding period.
                var latest = lastEntry()
                var benchmarkEntry = activeEntry || latest.entry
                if (benchmarkEntry) {
                    var entryY = toY(benchmarkEntry.price)
                    var entryLong = benchmarkEntry.direction === "多"
                    var entryColor = entryLong ? "#42d66f" : "#ef5350"
                    var entryLabel = (entryLong ? "买 " : "空 ") + fmtPrice(benchmarkEntry.price)
                    ctx.save()
                    ctx.strokeStyle = entryColor
                    ctx.globalAlpha = 0.74
                    ctx.setLineDash([6, 4])
                    ctx.beginPath()
                    ctx.moveTo(L, entryY)
                    ctx.lineTo(L + cW, entryY)
                    ctx.stroke()
                    ctx.setLineDash([])
                    ctx.globalAlpha = 1
                    ctx.fillStyle = entryColor
                    ctx.fillRect(L + cW + 7, entryY - 9, 86, 18)
                    ctx.fillStyle = "#081014"
                    ctx.font = "10px Menlo, Consolas, monospace"
                    ctx.textAlign = "center"
                    ctx.textBaseline = "middle"
                    ctx.fillText(entryLabel, L + cW + 50, entryY)
                    ctx.restore()
                }

                if (hoverInChart) {
                    var hbar = bars[hoverSlot]
                    var hx = L + step * hoverSlot + step * 0.5
                    var hprice = toPrice(root.hoverY)
                    var entryPct = pctFromEntry(hprice, activeEntry)

                    ctx.save()
                    ctx.strokeStyle = "rgba(238,245,242,0.34)"
                    ctx.lineWidth = 1
                    ctx.setLineDash([3, 4])
                    ctx.beginPath()
                    ctx.moveTo(hx, T)
                    ctx.lineTo(hx, T + cH)
                    ctx.moveTo(L, root.hoverY)
                    ctx.lineTo(L + cW, root.hoverY)
                    ctx.stroke()
                    ctx.setLineDash([])

                    var info = hbar.time + "  O " + fmtPrice(hbar.open) + " H " + fmtPrice(hbar.high)
                             + " L " + fmtPrice(hbar.low) + " C " + fmtPrice(hbar.close)
                    if (activeEntry)
                        info += "  距开仓 " + (entryPct >= 0 ? "+" : "") + entryPct.toFixed(2) + "%"
                    if (hbar.tradeEntry)
                        info += "  开" + hbar.tradeEntry.direction + " " + fmtPrice(hbar.tradeEntry.price)
                    if (hbar.tradeExit)
                        info += "  平" + hbar.tradeExit.direction + " " + (hbar.tradeExit.pnlPct >= 0 ? "+" : "") + hbar.tradeExit.pnlPct.toFixed(1) + "%"

                    ctx.font = "10px Menlo, Consolas, monospace"
                    var infoW = Math.min(cW - 12, ctx.measureText(info).width + 16)
                    ctx.fillStyle = "rgba(15,23,28,0.94)"
                    ctx.fillRect(L + 8, T + 8, infoW, 22)
                    ctx.strokeStyle = "rgba(146,163,165,0.28)"
                    ctx.strokeRect(L + 8, T + 8, infoW, 22)
                    ctx.fillStyle = Theme.text
                    ctx.textAlign = "left"
                    ctx.textBaseline = "middle"
                    ctx.fillText(info, L + 16, T + 19)

                    ctx.fillStyle = "rgba(238,245,242,0.88)"
                    ctx.fillRect(L + cW + 7, root.hoverY - 9, 86, 18)
                    ctx.fillStyle = "#0b1115"
                    ctx.textAlign = "center"
                    var hoverLabel = fmtPrice(hprice)
                    if (activeEntry)
                        hoverLabel += " " + (entryPct >= 0 ? "+" : "") + entryPct.toFixed(1) + "%"
                    ctx.fillText(hoverLabel, L + cW + 50, root.hoverY)
                    ctx.restore()
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onPositionChanged: function(mouse) {
                    root.hoverX = mouse.x
                    root.hoverY = mouse.y
                    root.hovering = true
                    price.requestPaint()
                }
                onExited: {
                    root.hovering = false
                    price.requestPaint()
                }
            }
        }

        // ── MACD sub-panel ────────────────────────────────────────────
        Canvas {
            id: macd
            Layout.fillWidth: true
            Layout.preferredHeight: root.showMacd ? 88 : 0
            visible: root.showMacd
            clip: true
            antialiasing: true

            onPaint: {
                var ctx = getContext("2d")
                ctx.reset()
                ctx.clearRect(0, 0, width, height)

                var bars = root.bars
                if (!bars || bars.length < 26) return

                var L = 56, R = 16, T = 6, B = 6
                var cW = width - L - R
                var cH = height - T - B
                var n = bars.length
                var step = cW / Math.max(1, n)

                var k12 = 2 / 13, k26 = 2 / 27
                var e12 = bars[0].close, e26 = bars[0].close
                var vals = []
                for (var i = 0; i < n; ++i) {
                    e12 = bars[i].close * k12 + e12 * (1 - k12)
                    e26 = bars[i].close * k26 + e26 * (1 - k26)
                    vals.push(e12 - e26)
                }

                var maxM = 0.001
                for (i = 0; i < n; ++i) maxM = Math.max(maxM, Math.abs(vals[i]))

                var zeroY = T + cH * 0.5
                ctx.strokeStyle = "rgba(130,150,160,0.3)"
                ctx.lineWidth = 0.5
                ctx.beginPath(); ctx.moveTo(L, zeroY); ctx.lineTo(L + cW, zeroY); ctx.stroke()

                var bW = Math.max(2, step * 0.6)
                for (i = 0; i < n; ++i) {
                    var v = vals[i]
                    var bh = cH * 0.44 * Math.abs(v) / maxM
                    var bx = L + step * i + (step - bW) / 2
                    ctx.fillStyle = v >= 0 ? "rgba(66,214,111,0.75)" : "rgba(239,83,80,0.75)"
                    ctx.fillRect(bx, v >= 0 ? zeroY - bh : zeroY, bW, Math.max(1, bh))
                }

                ctx.fillStyle = Theme.faint
                ctx.font = "10px sans-serif"; ctx.textAlign = "left"; ctx.textBaseline = "top"
                ctx.fillText("MACD", L, T)
            }
        }
    }
}
