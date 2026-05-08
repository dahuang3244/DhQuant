import QtQuick

Item {
    id: root
    property var bars: []
    property int maxVisibleBars: 180

    onBarsChanged: canvas.requestPaint()
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

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            ctx.clearRect(0, 0, width, height);

            var allBars = root.bars || [];
            if (allBars.length < 26)
                return;
            var left = 12;
            var right = 72;
            var top = 20;
            var bottom = 8;
            var chartW = width - left - right;
            var chartH = height - top - bottom;
            if (chartW <= 10 || chartH <= 10)
                return;
            var difs = [];
            var deas = [];
            var hists = [];
            var ema12 = allBars[0].close;
            var ema26 = allBars[0].close;
            var dea = 0;
            var k12 = 2 / 13;
            var k26 = 2 / 27;
            var k9 = 2 / 10;
            for (var i = 0; i < allBars.length; ++i) {
                ema12 = allBars[i].close * k12 + ema12 * (1 - k12);
                ema26 = allBars[i].close * k26 + ema26 * (1 - k26);
                var dif = ema12 - ema26;
                dea = dif * k9 + dea * (1 - k9);
                difs.push(dif);
                deas.push(dea);
                hists.push((dif - dea) * 2);
            }

            var visibleCount = Math.min(allBars.length, Math.max(24, root.maxVisibleBars));
            var start = Math.max(0, allBars.length - visibleCount);
            var maxAbs = 0.001;
            for (i = start; i < allBars.length; ++i)
                maxAbs = Math.max(maxAbs, Math.abs(difs[i]), Math.abs(deas[i]), Math.abs(hists[i]));

            ctx.fillStyle = "#0d151a";
            ctx.fillRect(left, top, chartW, chartH);

            var zeroY = top + chartH * 0.5;
            ctx.strokeStyle = "rgba(146, 163, 165, 0.25)";
            ctx.lineWidth = 1;
            ctx.beginPath();
            ctx.moveTo(left, Math.round(zeroY) + 0.5);
            ctx.lineTo(left + chartW, Math.round(zeroY) + 0.5);
            ctx.stroke();

            function toY(v) {
                return zeroY - v / maxAbs * chartH * 0.44;
            }

            var n = allBars.length - start;
            var step = chartW / Math.max(1, n);
            var barW = Math.max(2, Math.min(7, step * 0.58));
            for (i = start; i < allBars.length; ++i) {
                var local = i - start;
                var hist = hists[i];
                var h = Math.abs(toY(hist) - zeroY);
                var bx = left + step * local + (step - barW) / 2;
                ctx.fillStyle = hist >= 0 ? "rgba(69, 201, 111, 0.62)" : "rgba(226, 90, 86, 0.62)";
                ctx.fillRect(bx, hist >= 0 ? zeroY - h : zeroY, barW, Math.max(1, h));
            }

            function drawLine(values, color) {
                ctx.strokeStyle = color;
                ctx.lineWidth = 1.25;
                ctx.beginPath();
                for (var k = start; k < allBars.length; ++k) {
                    var px = left + step * (k - start) + step * 0.5;
                    var py = toY(values[k]);
                    k === start ? ctx.moveTo(px, py) : ctx.lineTo(px, py);
                }
                ctx.stroke();
            }

            drawLine(difs, "rgba(82, 184, 255, 0.86)");
            drawLine(deas, "rgba(216, 184, 79, 0.86)");

            ctx.fillStyle = Theme.text;
            ctx.font = "11px sans-serif";
            ctx.textAlign = "left";
            ctx.textBaseline = "top";
            ctx.fillText("MACD", left, 2);

            ctx.font = "10px Menlo, Consolas, monospace";
            ctx.fillStyle = "rgba(82, 184, 255, 0.86)";
            ctx.fillText("DIF", left + 52, 3);
            ctx.fillStyle = "rgba(216, 184, 79, 0.86)";
            ctx.fillText("DEA", left + 86, 3);

            ctx.fillStyle = Theme.faint;
            ctx.textAlign = "left";
            ctx.fillText(maxAbs.toFixed(2), left + chartW + 8, top + 2);
            ctx.fillText((-maxAbs).toFixed(2), left + chartW + 8, top + chartH - 12);
        }
    }
}
