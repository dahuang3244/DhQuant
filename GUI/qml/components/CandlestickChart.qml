import QtQuick

Item {
    id: root

    property var bars: []
    property var forecast: []
    property int forecastStartIndex: bars ? bars.length : 0
    property bool showMa5: true
    property bool showMa20: true
    property int maxVisibleBars: 180

    property real hoverX: -1
    property real hoverY: -1
    property bool hovering: false

    onBarsChanged: canvas.requestPaint()
    onForecastChanged: canvas.requestPaint()
    onForecastStartIndexChanged: canvas.requestPaint()
    onShowMa5Changed: canvas.requestPaint()
    onShowMa20Changed: canvas.requestPaint()
    onMaxVisibleBarsChanged: canvas.requestPaint()
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
                return chartTop + chartHeight / 2;
            return chartTop + chartHeight * (1 - (price - minPrice) / (maxPrice - minPrice));
        }

        function fmtPrice(v) {
            if (Math.abs(v) >= 1000)
                return v.toFixed(0);
            return v.toFixed(2);
        }

        function ma(allBars, index, window) {
            if (index + 1 < window)
                return null;
            var sum = 0;
            for (var j = index - window + 1; j <= index; ++j)
                sum += allBars[j].close;
            return sum / window;
        }

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            ctx.clearRect(0, 0, width, height);

            var allBars = root.bars || [];
            if (allBars.length === 0)
                return;
            var left = 12;
            var right = 72;
            var top = 28;
            var bottom = 30;
            var chartW = width - left - right;
            var chartH = height - top - bottom;
            if (chartW <= 10 || chartH <= 10)
                return;
            var visibleCount = Math.min(allBars.length, Math.max(24, root.maxVisibleBars));
            var start = Math.max(0, allBars.length - visibleCount);
            var visibleBars = allBars.slice(start);
            var visibleForecast = root.forecast || [];
            var forecastStart = Math.max(0, root.forecastStartIndex - start);
            var includeForecast = visibleForecast.length > 0 && root.forecastStartIndex >= start;

            var minP = visibleBars[0].low;
            var maxP = visibleBars[0].high;
            for (var i = 0; i < visibleBars.length; ++i) {
                minP = Math.min(minP, visibleBars[i].low);
                maxP = Math.max(maxP, visibleBars[i].high);
            }
            if (includeForecast) {
                for (i = 0; i < visibleForecast.length; ++i) {
                    minP = Math.min(minP, visibleForecast[i].low);
                    maxP = Math.max(maxP, visibleForecast[i].high);
                }
            }

            var range = Math.max(0.01, maxP - minP);
            var pad = range * 0.08;
            minP = Math.max(0.01, minP - pad);
            maxP = maxP + pad;
            var totalSlots = visibleBars.length;
            if (includeForecast)
                totalSlots = Math.max(totalSlots, forecastStart + visibleForecast.length);
            var step = chartW / Math.max(1, totalSlots);
            var candleW = Math.max(2.5, Math.min(8.5, step * 0.58));

            ctx.fillStyle = "#0d151a";
            ctx.fillRect(left, top, chartW, chartH);

            if (includeForecast && forecastStart <= totalSlots) {
                var separatorX = left + step * forecastStart;
                ctx.fillStyle = "rgba(216, 184, 79, 0.055)";
                ctx.fillRect(separatorX, top, left + chartW - separatorX, chartH);
            }

            ctx.lineWidth = 1;
            ctx.font = "10px Menlo, Consolas, monospace";
            ctx.textBaseline = "middle";

            for (var g = 0; g <= 5; ++g) {
                var y = Math.round(top + chartH / 5 * g) + 0.5;
                var price = maxP - (maxP - minP) / 5 * g;
                ctx.strokeStyle = g === 5 ? "rgba(146, 163, 165, 0.18)" : "rgba(80, 110, 118, 0.22)";
                ctx.beginPath();
                ctx.moveTo(left, y);
                ctx.lineTo(left + chartW, y);
                ctx.stroke();
                ctx.fillStyle = Theme.faint;
                ctx.textAlign = "left";
                ctx.fillText(fmtPrice(price), left + chartW + 8, y);
            }

            for (i = 0; i < visibleBars.length; ++i) {
                var bar = visibleBars[i];
                var x = left + step * i + step * 0.5;
                var openY = priceToY(bar.open, minP, maxP, top, chartH);
                var closeY = priceToY(bar.close, minP, maxP, top, chartH);
                var highY = priceToY(bar.high, minP, maxP, top, chartH);
                var lowY = priceToY(bar.low, minP, maxP, top, chartH);
                var rising = bar.close >= bar.open;
                var up = "#45c96f";
                var down = "#e25a56";
                var col = rising ? up : down;
                ctx.strokeStyle = col;
                ctx.fillStyle = rising ? "rgba(69, 201, 111, 0.12)" : down;
                ctx.lineWidth = 1;
                ctx.beginPath();
                ctx.moveTo(Math.round(x) + 0.5, highY);
                ctx.lineTo(Math.round(x) + 0.5, lowY);
                ctx.stroke();
                var bodyTop = Math.min(openY, closeY);
                var bodyH = Math.max(1.4, Math.abs(closeY - openY));
                ctx.fillRect(x - candleW / 2, bodyTop, candleW, bodyH);
                ctx.strokeRect(x - candleW / 2, bodyTop, candleW, bodyH);
            }

            function drawMa(window, color, labelY) {
                ctx.strokeStyle = color;
                ctx.lineWidth = 1.35;
                ctx.beginPath();
                var started = false;
                for (var k = 0; k < visibleBars.length; ++k) {
                    var absoluteIndex = start + k;
                    var value = ma(allBars, absoluteIndex, window);
                    if (value === null)
                        continue;
                    var px = left + step * k + step * 0.5;
                    var py = priceToY(value, minP, maxP, top, chartH);
                    if (!started) {
                        ctx.moveTo(px, py);
                        started = true;
                    } else {
                        ctx.lineTo(px, py);
                    }
                }
                ctx.stroke();

                var last = ma(allBars, allBars.length - 1, window);
                if (last !== null) {
                    ctx.fillStyle = color;
                    ctx.font = "10px Menlo, Consolas, monospace";
                    ctx.textAlign = "left";
                    ctx.textBaseline = "top";
                    ctx.fillText("MA" + window + " " + fmtPrice(last), left + 84 + labelY, 9);
                }
            }

            ctx.fillStyle = Theme.text;
            ctx.font = "11px sans-serif";
            ctx.textAlign = "left";
            ctx.textBaseline = "top";
            ctx.fillText("OHLC", left, 8);
            if (root.showMa5)
                drawMa(5, "rgba(216, 184, 79, 0.92)", 0);
            if (root.showMa20)
                drawMa(20, "rgba(82, 184, 255, 0.82)", 92);

            if (includeForecast) {
                ctx.save();
                ctx.strokeStyle = "rgba(216, 184, 79, 0.9)";
                ctx.lineWidth = 1.6;
                ctx.setLineDash([6, 4]);
                ctx.beginPath();
                var lastRealIndex = Math.min(visibleBars.length - 1, forecastStart - 1);
                if (lastRealIndex < 0)
                    lastRealIndex = visibleBars.length - 1;
                var startPrice = visibleBars[lastRealIndex].close;
                ctx.moveTo(left + step * lastRealIndex + step * 0.5, priceToY(startPrice, minP, maxP, top, chartH));
                for (var f = 0; f < visibleForecast.length; ++f) {
                    var fx = left + step * (forecastStart + f) + step * 0.5;
                    var fy = priceToY(visibleForecast[f].close, minP, maxP, top, chartH);
                    ctx.lineTo(fx, fy);
                }
                ctx.stroke();
                ctx.setLineDash([]);
                var sep = left + step * forecastStart;
                ctx.strokeStyle = "rgba(216, 184, 79, 0.58)";
                ctx.beginPath();
                ctx.moveTo(sep, top);
                ctx.lineTo(sep, top + chartH);
                ctx.stroke();
                ctx.restore();
            }

            var lastBar = allBars[allBars.length - 1];
            var lastY = priceToY(lastBar.close, minP, maxP, top, chartH);
            var lastRising = lastBar.close >= lastBar.open;
            var lastColor = lastRising ? "#45c96f" : "#e25a56";
            ctx.strokeStyle = lastColor;
            ctx.globalAlpha = 0.65;
            ctx.setLineDash([4, 4]);
            ctx.beginPath();
            ctx.moveTo(left, lastY);
            ctx.lineTo(left + chartW, lastY);
            ctx.stroke();
            ctx.setLineDash([]);
            ctx.globalAlpha = 1;
            ctx.fillStyle = lastColor;
            ctx.fillRect(left + chartW + 6, lastY - 9, 58, 18);
            ctx.fillStyle = "#081014";
            ctx.font = "10px Menlo, Consolas, monospace";
            ctx.textAlign = "center";
            ctx.textBaseline = "middle";
            ctx.fillText(fmtPrice(lastBar.close), left + chartW + 35, lastY);

            ctx.fillStyle = Theme.faint;
            ctx.textAlign = "center";
            ctx.textBaseline = "top";
            ctx.font = "10px Menlo, Consolas, monospace";
            var labelStep = Math.max(1, Math.floor(visibleBars.length / 5));
            for (i = 0; i < visibleBars.length; i += labelStep) {
                ctx.fillText(visibleBars[i].time, left + step * i + step * 0.5, top + chartH + 8);
            }

            if (root.hovering && root.hoverX >= left && root.hoverX <= left + chartW && root.hoverY >= top && root.hoverY <= top + chartH) {
                var slot = Math.max(0, Math.min(visibleBars.length - 1, Math.floor((root.hoverX - left) / step)));
                var hbar = visibleBars[slot];
                var hx = left + step * slot + step * 0.5;
                var hprice = maxP - (root.hoverY - top) / chartH * (maxP - minP);

                ctx.strokeStyle = "rgba(238, 245, 242, 0.32)";
                ctx.lineWidth = 1;
                ctx.setLineDash([3, 4]);
                ctx.beginPath();
                ctx.moveTo(hx, top);
                ctx.lineTo(hx, top + chartH);
                ctx.moveTo(left, root.hoverY);
                ctx.lineTo(left + chartW, root.hoverY);
                ctx.stroke();
                ctx.setLineDash([]);

                var info = hbar.time + "  O " + fmtPrice(hbar.open) + " H " + fmtPrice(hbar.high) + " L " + fmtPrice(hbar.low) + " C " + fmtPrice(hbar.close);
                ctx.font = "10px Menlo, Consolas, monospace";
                var infoW = Math.min(chartW - 12, ctx.measureText(info).width + 16);
                ctx.fillStyle = "rgba(15, 23, 28, 0.94)";
                ctx.fillRect(left + 8, top + 8, infoW, 22);
                ctx.strokeStyle = "rgba(146, 163, 165, 0.28)";
                ctx.strokeRect(left + 8, top + 8, infoW, 22);
                ctx.fillStyle = Theme.text;
                ctx.textAlign = "left";
                ctx.textBaseline = "middle";
                ctx.fillText(info, left + 16, top + 19);

                ctx.fillStyle = "rgba(238, 245, 242, 0.86)";
                ctx.fillRect(left + chartW + 6, root.hoverY - 9, 58, 18);
                ctx.fillStyle = "#0b1115";
                ctx.textAlign = "center";
                ctx.fillText(fmtPrice(hprice), left + chartW + 35, root.hoverY);
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onPositionChanged: function (mouse) {
                root.hoverX = mouse.x;
                root.hoverY = mouse.y;
                root.hovering = true;
                canvas.requestPaint();
            }
            onExited: {
                root.hovering = false;
                canvas.requestPaint();
            }
        }
    }
}
