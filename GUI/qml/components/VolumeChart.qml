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

        function fmtVolume(v) {
            if (v >= 1000000000)
                return (v / 1000000000).toFixed(1) + "B";
            if (v >= 1000000)
                return (v / 1000000).toFixed(1) + "M";
            if (v >= 1000)
                return (v / 1000).toFixed(1) + "K";
            return v.toFixed(0);
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
            var top = 20;
            var bottom = 8;
            var chartW = width - left - right;
            var chartH = height - top - bottom;
            if (chartW <= 10 || chartH <= 10)
                return;
            var visibleCount = Math.min(allBars.length, Math.max(24, root.maxVisibleBars));
            var start = Math.max(0, allBars.length - visibleCount);
            var bars = allBars.slice(start);
            var maxV = 1;
            for (var i = 0; i < bars.length; ++i)
                maxV = Math.max(maxV, bars[i].volume);

            ctx.fillStyle = "#0d151a";
            ctx.fillRect(left, top, chartW, chartH);

            ctx.strokeStyle = "rgba(80, 110, 118, 0.20)";
            ctx.lineWidth = 1;
            for (var g = 0; g <= 2; ++g) {
                var y = Math.round(top + chartH * g / 2) + 0.5;
                ctx.beginPath();
                ctx.moveTo(left, y);
                ctx.lineTo(left + chartW, y);
                ctx.stroke();
            }

            var step = chartW / Math.max(1, bars.length);
            var barW = Math.max(2, Math.min(7, step * 0.62));
            for (i = 0; i < bars.length; ++i) {
                var bar = bars[i];
                var h = chartH * bar.volume / maxV;
                var rising = bar.close >= bar.open;
                ctx.fillStyle = rising ? "rgba(69, 201, 111, 0.58)" : "rgba(226, 90, 86, 0.58)";
                ctx.fillRect(left + step * i + (step - barW) / 2, top + chartH - h, barW, Math.max(1, h));
            }

            ctx.strokeStyle = "rgba(216, 184, 79, 0.82)";
            ctx.lineWidth = 1.2;
            ctx.beginPath();
            var started = false;
            for (i = 0; i < bars.length; ++i) {
                var absoluteIndex = start + i;
                if (absoluteIndex < 4)
                    continue;
                var sum = 0;
                for (var j = absoluteIndex - 4; j <= absoluteIndex; ++j)
                    sum += allBars[j].volume;
                var ma5 = sum / 5;
                var px = left + step * i + step * 0.5;
                var py = top + chartH * (1 - ma5 / maxV);
                if (!started) {
                    ctx.moveTo(px, py);
                    started = true;
                } else {
                    ctx.lineTo(px, py);
                }
            }
            ctx.stroke();

            ctx.fillStyle = Theme.text;
            ctx.font = "11px sans-serif";
            ctx.textAlign = "left";
            ctx.textBaseline = "top";
            ctx.fillText("Volume", left, 2);
            ctx.fillStyle = Theme.faint;
            ctx.font = "10px Menlo, Consolas, monospace";
            ctx.textAlign = "left";
            ctx.fillText(fmtVolume(maxV), left + chartW + 8, top + 2);
            ctx.fillText(fmtVolume(maxV / 2), left + chartW + 8, top + chartH / 2);
        }
    }
}
