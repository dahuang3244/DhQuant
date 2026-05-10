pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Item {
    id: root

    readonly property int journalIndentW: 13
    readonly property int journalTimeW: 190
    readonly property int journalTypeW: 120
    readonly property int journalSymbolW: 150
    readonly property int journalSideW: 96
    readonly property int journalExpandW: 28

    // ── Helpers ───────────────────────────────────────────────────────────────
    function mapTopic(t) {
        var map = {
            "trade.filled": "成交回报",
            "order.updated": "订单更新",
            "risk.note": "风控提示",
            "position.adjusted": "仓位调整",
            "position.adjust...": "仓位调整",
            "system.heartbeat": "系统心跳",
            "system.error": "系统异常",
            "strategy.signal": "策略信号"
        }
        return map[t] || t
    }
    
    function pnlColor(v)  { return Number(v || 0) >= 0 ? Theme.positive : Theme.negative }
    function sideColor(s) { return s === "买入" ? Theme.primary : s === "卖出" ? Theme.negative : Theme.warning }

    function fmtMoney(v) {
        var n = Number(v || 0)
        return (n >= 0 ? "+" : "") + n.toLocaleString(Qt.locale(), "f", 2)
    }

    function fmtPct(v) {
        var n = Number(v || 0)
        return (n >= 0 ? "+" : "") + n.toFixed(2) + "%"
    }

    function deltaArrow(v) { return Number(v) >= 0 ? "▲" : "▼" }
    function deltaColor(v, higherIsBetter) {
        var n = Number(v)
        if (n === 0) return Theme.faint
        var good = higherIsBetter ? n > 0 : n < 0
        return good ? Theme.positive : Theme.negative
    }

    function resultTone(row) {
        if (!row.analysisReady) return Theme.faint
        return root.pnlColor(row.pnl || 0)
    }

    // ── Main layout ──────────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 14

        // ── Header ───────────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 72
            radius: Theme.radiusLarge
            color: Theme.surface
            border.color: Theme.line
            clip: true

            Rectangle {
                width: 4
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                color: Theme.primary
                opacity: 0.85
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 16
                spacing: 14

                ColumnLayout {
                    spacing: 2
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        text: "交易日志"
                        color: Theme.text
                        font.pixelSize: 20
                        font.weight: Font.DemiBold
                    }

                    Text {
                        text: "数据源: " + journal.source
                        color: Theme.muted
                        font.pixelSize: 12
                        elide: Text.ElideMiddle
                        Layout.fillWidth: true
                    }
                }

                Item { Layout.fillWidth: true }

                SmallButton {
                    label: "刷新"
                    onClicked: journal.refresh()
                }
            }
        }

        // ── Toolbar: time filter + analysis button ────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            radius: Theme.radius
            color: Theme.surface
            border.color: Theme.line

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 6

                // Quick filter pills
                Repeater {
                    model: [
                        { key: "1D", label: "近1日" },
                        { key: "1W", label: "近1周" },
                        { key: "1M", label: "近1月" },
                        { key: "3M", label: "近3月" },
                        { key: "ALL", label: "全部" }
                    ]

                    FilterPill {
                        required property var modelData
                        label: modelData.label
                        active: journal.quickFilter === modelData.key
                        onClicked: journal.setQuickFilter(modelData.key)
                    }
                }

                // Separator
                Rectangle {
                    width: 1
                    height: 22
                    color: Theme.line
                    Layout.alignment: Qt.AlignVCenter
                }

                Item { Layout.fillWidth: true }

                SmallButton {
                    label: "分析"
                    onClicked: journal.runAnalysis()
                }

                SmallButton {
                    label: "分析总结"
                    enabled: journal.eventCount > 0
                    onClicked: journal.openSummary()
                }
            }
        }

        // ── Unified collapsible list ──────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Theme.radiusLarge
            color: Theme.surface
            border.color: Theme.line
            clip: true

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // List header row
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    color: Theme.panel
                    radius: Theme.radiusLarge

                    // Flatten bottom corners
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: Theme.radiusLarge
                        color: Theme.panel
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        spacing: 0

                        // Placeholder for side color bar (3px) + margin (10px)
                        Item { Layout.preferredWidth: root.journalIndentW }
                        
                        ColHeader { text: "时间";     Layout.preferredWidth: root.journalTimeW }
                        ColHeader { text: "类型";     Layout.preferredWidth: root.journalTypeW }
                        ColHeader { text: "标的";     Layout.preferredWidth: root.journalSymbolW }
                        ColHeader { text: "方向";     Layout.preferredWidth: root.journalSideW }
                        ColHeader { text: "数量 / 价格"; Layout.fillWidth: true  }
                        Item      { Layout.preferredWidth: root.journalExpandW }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Theme.line
                }

                // The list itself
                ListView {
                    id: tradeList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: journal.unifiedRows
                    spacing: 0
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                    delegate: TradeRow {
                        required property int index
                        required property var time
                        required property var topic
                        required property var level
                        required property var symbol
                        required property var name
                        required property var side
                        required property var qty
                        required property var price
                        required property var currentPrice
                        required property var message
                        required property var hasPnl
                        required property var pnl
                        required property var pnlPct
                        required property var status
                        required property var analysisReady
                        required property var analysisScore
                        required property var riskLevel
                        required property var analysisTitle
                        required property var analysisText
                        required property var actionHint
                        required property var analysisPnlText
                        required property var analysisPnlPctText
                        required property var analysisMarketValueText
                        required property var analysisContributionText
                        required property var analysisResultText
                        required property var analysisPricePairText
                        required property var analysisFormulaText
                        required property var signalStrategy

                        width: tradeList.width
                        isOdd: index % 2 === 1
                        rowData: ({
                            "time": time,
                            "topic": topic,
                            "level": level,
                            "symbol": symbol,
                            "name": name,
                            "side": side,
                            "qty": qty,
                            "price": price,
                            "currentPrice": currentPrice,
                            "message": message,
                            "hasPnl": hasPnl,
                            "pnl": pnl,
                            "pnlPct": pnlPct,
                            "status": status,
                            "analysisReady": analysisReady,
                            "analysisScore": analysisScore,
                            "riskLevel": riskLevel,
                            "analysisTitle": analysisTitle,
                            "analysisText": analysisText,
                            "actionHint": actionHint,
                            "analysisPnlText": analysisPnlText,
                            "analysisPnlPctText": analysisPnlPctText,
                            "analysisMarketValueText": analysisMarketValueText,
                            "analysisContributionText": analysisContributionText,
                            "analysisResultText": analysisResultText,
                            "analysisPricePairText": analysisPricePairText,
                            "analysisFormulaText": analysisFormulaText,
                            "signalStrategy": signalStrategy
                        })
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: 260
                        height: 80
                        radius: Theme.radiusLarge
                        color: Theme.panel2
                        border.color: Theme.line
                        visible: tradeList.count === 0

                        Text {
                            anchors.centerIn: parent
                            text: "当前筛选窗口暂无数据"
                            color: Theme.muted
                            font.pixelSize: 13
                        }
                    }
                }
            }
        }
    }

    // ── Summary panel overlay ────────────────────────────────────────────────
    Rectangle {
        id: compareOverlay
        anchors.fill: parent
        z: 60
        color: Qt.rgba(0, 0, 0, 0.52)
        visible: journal.panelOpen
        opacity: visible ? 1 : 0

        Behavior on opacity { NumberAnimation { duration: 200 } }

        MouseArea {
            anchors.fill: parent
            onClicked: journal.closePanel()
        }

        Rectangle {
            id: compareCard
            anchors.centerIn: parent
            width: Math.min(parent.width - 80, 760)
            height: Math.min(parent.height - 60, 520)
            radius: Theme.radiusLarge
            color: Theme.surface
            border.color: Theme.line

            MouseArea { anchors.fill: parent }  // block backdrop click

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 16

                RowLayout {
                    Layout.fillWidth: true

                    ColumnLayout {
                        spacing: 2
                        Layout.fillWidth: true

                        Text {
                            text: "分析总结"
                            color: Theme.text
                            font.pixelSize: 18
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: "当前筛选: " + ((journal.summaryResult || {})["filterLabel"] || "—")
                            color: Theme.faint
                            font.pixelSize: 12
                        }
                    }

                    Item { Layout.preferredWidth: 16 }

                    Rectangle {
                        width: 28; height: 28; radius: 8
                        color: closeMa.containsMouse ? Theme.panel3 : "transparent"
                        border.color: closeMa.containsMouse ? Theme.border : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            color: Theme.muted
                            font.pixelSize: 13
                        }

                        MouseArea {
                            id: closeMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: journal.closePanel()
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 70
                    radius: Theme.radius
                    color: Theme.panel3
                    border.color: Theme.line

                    Text {
                        anchors.fill: parent
                        anchors.margins: 14
                        text: (journal.summaryResult || {})["conclusion"] || "当前筛选窗口暂无可汇总数据。"
                        color: Theme.text
                        font.pixelSize: 13
                        wrapMode: Text.WordWrap
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 4
                    columnSpacing: 10
                    rowSpacing: 10

                    StatTile { title: "日志项"; value: String((journal.summaryResult || {})["eventCount"] || 0); Layout.fillWidth: true; Layout.preferredHeight: 76 }
                    StatTile { title: "可分析交易"; value: String((journal.summaryResult || {})["tradeCount"] || 0); Layout.fillWidth: true; Layout.preferredHeight: 76 }
                    StatTile { title: "胜率"; value: Number((journal.summaryResult || {})["winRate"] || 0).toFixed(1) + "%"; Layout.fillWidth: true; Layout.preferredHeight: 76; tone: Theme.primary }
                    StatTile { title: "合计盈亏"; value: root.fmtMoney((journal.summaryResult || {})["totalPnl"] || 0); Layout.fillWidth: true; Layout.preferredHeight: 76; tone: root.pnlColor((journal.summaryResult || {})["totalPnl"] || 0) }

                    StatTile { title: "平均单笔"; value: root.fmtMoney((journal.summaryResult || {})["avgPnl"] || 0); Layout.fillWidth: true; Layout.preferredHeight: 76; tone: root.pnlColor((journal.summaryResult || {})["avgPnl"] || 0) }
                    StatTile { title: "最佳单笔"; value: root.fmtMoney((journal.summaryResult || {})["bestPnl"] || 0); Layout.fillWidth: true; Layout.preferredHeight: 76; tone: Theme.positive }
                    StatTile { title: "最差单笔"; value: root.fmtMoney((journal.summaryResult || {})["worstPnl"] || 0); Layout.fillWidth: true; Layout.preferredHeight: 76; tone: Theme.negative }
                    StatTile { title: "敞口市值"; value: Number((journal.summaryResult || {})["totalExposure"] || 0).toLocaleString(Qt.locale(), "f", 2); Layout.fillWidth: true; Layout.preferredHeight: 76 }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    SummaryRow {
                        label: "盈利 / 亏损笔数"
                        value: String((journal.summaryResult || {})["winCount"] || 0) + " / " + String((journal.summaryResult || {})["lossCount"] || 0)
                        Layout.fillWidth: true
                    }

                    SummaryRow {
                        label: "盈亏比"
                        value: Number((journal.summaryResult || {})["profitLossRatio"] || 0).toFixed(2)
                        Layout.fillWidth: true
                    }

                    SummaryRow {
                        label: "最大贡献 / 最大拖累"
                        value: String((journal.summaryResult || {})["bestSymbol"] || "—") + " / " + String((journal.summaryResult || {})["worstSymbol"] || "—")
                        Layout.fillWidth: true
                    }

                    SummaryRow {
                        label: "缺少成交字段"
                        value: String((journal.summaryResult || {})["missingCount"] || 0)
                        Layout.fillWidth: true
                    }
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // Inline components
    // ═══════════════════════════════════════════════════════════════════════

    component TradeRow: Item {
        id: rowRoot
        property var rowData: ({})
        property bool isOdd: false

        readonly property int collapsedH: 52
        readonly property int expandedH:  collapsedH + 156
        property bool expanded: false

        height: expanded ? expandedH : collapsedH
        clip: true

        Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        // Row background
        Rectangle {
            anchors.fill: parent
            color: rowRoot.expanded
                   ? Theme.panel3
                   : rowMA.containsMouse
                     ? Theme.panel2
                     : rowRoot.isOdd ? Qt.rgba(1,1,1,0.012) : "transparent"

            Behavior on color { ColorAnimation { duration: 120 } }

            // Bottom divider
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: Theme.line
                opacity: 0.6
            }
        }

        // ── Collapsed summary row ─────────────────────────────────────────────
        RowLayout {
            id: summaryRow
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            anchors.top: parent.top
            height: rowRoot.collapsedH
            spacing: 0

            // Side color bar
            Item {
                Layout.preferredWidth: root.journalIndentW
                Layout.fillHeight: true

                Rectangle {
                    width: 3
                    height: 26
                    radius: 2
                    color: root.sideColor(rowRoot.rowData.side || "")
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            // Time
            Text {
                text: rowRoot.rowData.time || ""
                color: Theme.muted
                font.pixelSize: 12
                font.family: "Menlo"
                Layout.preferredWidth: root.journalTimeW
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }

            // Topic badge
            Item {
                Layout.preferredWidth: root.journalTypeW
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignVCenter

                Rectangle {
                    width: 86
                    height: 22
                    radius: 6
                    color: Theme.panel2
                    border.color: Theme.border
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        anchors.centerIn: parent
                        anchors.leftMargin: 6
                        anchors.rightMargin: 6
                        text: root.mapTopic(rowRoot.rowData.topic || "")
                        color: Theme.faint
                        font.pixelSize: 10
                        elide: Text.ElideRight
                        width: parent.width - 12
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            // Symbol + name
            Item {
                Layout.preferredWidth: root.journalSymbolW
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1
                    clip: true

                    Text {
                        text: rowRoot.rowData.symbol || "—"
                        color: Theme.text
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        text: rowRoot.rowData.name || ""
                        color: Theme.faint
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
            }

            // Side badge
            Item {
                Layout.preferredWidth: root.journalSideW
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignVCenter

                Rectangle {
                    width: 46
                    height: 20
                    radius: 5
                    color: Qt.rgba(
                        root.sideColor(rowRoot.rowData.side || "").r,
                        root.sideColor(rowRoot.rowData.side || "").g,
                        root.sideColor(rowRoot.rowData.side || "").b,
                        0.14
                    )
                    border.color: root.sideColor(rowRoot.rowData.side || "")
                    border.width: 0.8
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        anchors.centerIn: parent
                        text: rowRoot.rowData.side || "事件"
                        color: root.sideColor(rowRoot.rowData.side || "")
                        font.pixelSize: 11
                        font.weight: Font.Medium
                    }
                }
            }

            // Qty / price
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                RowLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Text {
                        visible: Number(rowRoot.rowData.qty || 0) <= 0
                        text: rowRoot.rowData.level || ""
                        color: Theme.muted
                        font.pixelSize: 12
                        font.family: "Menlo"
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        visible: Number(rowRoot.rowData.qty || 0) > 0
                        text: String(rowRoot.rowData.qty || "")
                        color: Theme.text
                        font.pixelSize: 12
                        font.family: "Menlo"
                        font.weight: Font.DemiBold
                    }

                    Text {
                        visible: Number(rowRoot.rowData.qty || 0) > 0
                        text: "@"
                        color: Theme.faint
                        font.pixelSize: 12
                        font.family: "Menlo"
                    }

                    Text {
                        visible: Number(rowRoot.rowData.qty || 0) > 0
                        text: Number(rowRoot.rowData.price || 0).toFixed(2)
                        color: Theme.primary
                        font.pixelSize: 12
                        font.family: "Menlo"
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
            }

            // Expand chevron
            Item {
                Layout.preferredWidth: root.journalExpandW
                height: parent.height
                Layout.alignment: Qt.AlignVCenter

                Text {
                    anchors.centerIn: parent
                    text: rowRoot.expanded ? "▾" : "›"
                    color: rowRoot.expanded ? Theme.primary : Theme.faint
                    font.pixelSize: rowRoot.expanded ? 14 : 16

                    Behavior on color { ColorAnimation { duration: 120 } }
                }
            }
        }

        // ── Expanded detail section ───────────────────────────────────────────
        Item {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: summaryRow.bottom
            anchors.leftMargin: 32
            anchors.rightMargin: 16
            height: rowRoot.expandedH - rowRoot.collapsedH
            opacity: rowRoot.expanded ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 180 } }

            Rectangle {
                anchors.fill: parent
                anchors.topMargin: 6
                anchors.bottomMargin: 10
                radius: Theme.radius
                color: Theme.panel2
                border.color: Theme.line

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 10

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: Theme.radius
                        color: Theme.panel3
                        border.color: Theme.line

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 12

                            GridLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                columns: 4
                                columnSpacing: 10

                                AnalysisMetric {
                                    title: "盈亏"
                                    value: rowRoot.rowData.analysisReady ? (rowRoot.rowData.analysisPnlText || "—") : "点击分析"
                                    hint: String(rowRoot.rowData.qty || 0) + " 股"
                                    tone: rowRoot.rowData.analysisReady ? root.pnlColor(rowRoot.rowData.pnl || 0) : Theme.text
                                    Layout.fillWidth: true
                                }

                                AnalysisMetric {
                                    title: "收益率"
                                    value: rowRoot.rowData.analysisReady ? (rowRoot.rowData.analysisPnlPctText || "—") : "—"
                                    hint: rowRoot.rowData.analysisReady ? (rowRoot.rowData.analysisFormulaText || "价格对比") : "—"
                                    tone: rowRoot.rowData.analysisReady ? root.pnlColor(rowRoot.rowData.pnl || 0) : Theme.text
                                    Layout.fillWidth: true
                                }

                                AnalysisMetric {
                                    title: "成交价 -> 今日价"
                                    value: rowRoot.rowData.analysisReady ? (rowRoot.rowData.analysisPricePairText || "—") : (Number(rowRoot.rowData.price || 0).toFixed(2) + " -> " + Number(rowRoot.rowData.currentPrice || 0).toFixed(2))
                                    hint: rowRoot.rowData.side === "卖出" ? "卖出后对比今日价格" : "买入后对比今日价格"
                                    mono: true
                                    Layout.fillWidth: true
                                }

                                AnalysisMetric {
                                    title: "买卖信号"
                                    value: rowRoot.rowData.signalStrategy || "未标注策略"
                                    hint: (rowRoot.rowData.side || "交易") + "信号"
                                    tone: Theme.primary
                                    Layout.fillWidth: true
                                }
                            }
                        }
                    }
                }
            }
        }

        MouseArea {
            id: rowMA
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: rowRoot.expanded = !rowRoot.expanded
        }
    }

    // ── Sub-components ─────────────────────────────────────────────────────────

    component FilterPill: Rectangle {
        id: pillRoot
        signal clicked()
        property string label: ""
        property bool active: false

        Layout.preferredHeight: 28
        width: pillText.implicitWidth + 20
        radius: 7
        color: active ? Theme.primarySoft : pillMA.containsMouse ? Theme.panel2 : "transparent"
        border.color: active ? Theme.primary : "transparent"

        Behavior on color { ColorAnimation { duration: 110 } }
        Behavior on border.color { ColorAnimation { duration: 110 } }

        Text {
            id: pillText
            anchors.centerIn: parent
            text: pillRoot.label
            color: pillRoot.active ? Theme.primary : Theme.muted
            font.pixelSize: 13
            font.weight: pillRoot.active ? Font.DemiBold : Font.Normal
            Behavior on color { ColorAnimation { duration: 110 } }
        }

        MouseArea {
            id: pillMA
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: pillRoot.clicked()
        }
    }

    component StatTile: Rectangle {
        property string title: ""
        property string value: ""
        property color  tone:  Theme.text

        radius: Theme.radiusLarge
        color: Theme.panel
        border.color: Theme.line

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 4

            Text {
                text: title
                color: Theme.muted
                font.pixelSize: 12
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                text: value
                color: tone
                font.pixelSize: 20
                font.weight: Font.DemiBold
                font.family: "Menlo"
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }
    }

    component ColHeader: Text {
        property bool alignRight: false
        color: Theme.faint
        font.pixelSize: 11
        font.weight: Font.DemiBold
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: alignRight ? Text.AlignRight : Text.AlignLeft
        elide: Text.ElideRight
    }

    component SmallButton: Rectangle {
        id: btnRoot
        signal clicked()
        property string label: ""

        implicitWidth: btnLabel.implicitWidth + 24
        implicitHeight: 32
        radius: Theme.radius
        opacity: enabled ? 1.0 : 0.45
        color: enabled && btnMA.containsMouse ? Theme.primarySoft : Theme.panel2
        border.color: enabled && btnMA.containsMouse ? Theme.primary : Theme.border

        Behavior on color { ColorAnimation { duration: 110 } }
        Behavior on border.color { ColorAnimation { duration: 110 } }

        Text {
            id: btnLabel
            anchors.centerIn: parent
            text: btnRoot.label
            color: Theme.text
            font.pixelSize: 13
            font.weight: Font.Medium
        }

        MouseArea {
            id: btnMA
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: btnRoot.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: if (btnRoot.enabled) btnRoot.clicked()
        }
    }

    component ModeTab: Rectangle {
        id: tabRoot
        signal clicked()
        property string label: ""
        property bool   active: false
        property bool   small: false

        implicitWidth:  tabLabel.implicitWidth + (small ? 14 : 18)
        implicitHeight: small ? 26 : 30
        radius: 7
        color: active ? Theme.primarySoft : tabMA.containsMouse ? Theme.panel2 : Theme.panel
        border.color: active ? Theme.primary : Theme.border

        Behavior on color { ColorAnimation { duration: 110 } }
        Behavior on border.color { ColorAnimation { duration: 110 } }

        Text {
            id: tabLabel
            anchors.centerIn: parent
            text: tabRoot.label
            color: tabRoot.active ? Theme.primary : Theme.muted
            font.pixelSize: tabRoot.small ? 12 : 13
            font.weight: tabRoot.active ? Font.DemiBold : Font.Normal
            Behavior on color { ColorAnimation { duration: 110 } }
        }

        MouseArea {
            id: tabMA
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: tabRoot.clicked()
        }
    }

    component DropdownItem: Rectangle {
        id: dropItem
        signal clicked()
        property string label: ""
        property string description: ""

        height: dropCol.implicitHeight + 12
        radius: Theme.radius
        color: dropMA.containsMouse ? Theme.panel3 : "transparent"

        Behavior on color { ColorAnimation { duration: 100 } }

        ColumnLayout {
            id: dropCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 2

            Text {
                text: dropItem.label
                color: Theme.text
                font.pixelSize: 13
                font.weight: Font.Medium
            }

            Text {
                text: dropItem.description
                color: Theme.faint
                font.pixelSize: 11
            }
        }

        MouseArea {
            id: dropMA
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: dropItem.clicked()
        }
    }

    component AnalysisMetric: Rectangle {
        id: metricRoot
        property string title: ""
        property string value: ""
        property string hint: ""
        property color tone: Theme.text
        property bool mono: false

        Layout.preferredHeight: 66
        radius: Theme.radius
        color: Theme.panel2
        border.color: Theme.line

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 3

            Text {
                text: metricRoot.title
                color: Theme.faint
                font.pixelSize: 10
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                text: metricRoot.value
                color: metricRoot.tone
                font.pixelSize: 16
                font.weight: Font.DemiBold
                font.family: metricRoot.mono ? "Menlo" : "Arial"
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                text: metricRoot.hint
                color: Theme.faint
                font.pixelSize: 10
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }
    }

    component DetailItem: ColumnLayout {
        property string label: ""
        property string value: ""
        property bool   mono:  false
        spacing: 2

        Text {
            text: label
            color: Theme.faint
            font.pixelSize: 11
        }

        Text {
            text: value
            color: Theme.text
            font.pixelSize: 13
            font.weight: Font.Medium
            font.family: mono ? "Menlo" : "Arial"
        }
    }

    component SummaryRow: Rectangle {
        property string label: ""
        property string value: ""

        height: 34
        radius: Theme.radius
        color: Theme.panel2
        border.color: Theme.line

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12

            Text {
                text: label
                color: Theme.muted
                font.pixelSize: 12
                Layout.fillWidth: true
                verticalAlignment: Text.AlignVCenter
            }

            Text {
                text: value
                color: Theme.text
                font.pixelSize: 13
                font.weight: Font.DemiBold
                font.family: "Menlo"
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter
            }
        }
    }

    component CompareRow: Rectangle {
        id: cmpRow
        property string label:          ""
        property string curVal:         ""
        property string refVal:         ""
        property string deltaVal:       ""
        property string deltaPct:       ""
        property bool   higherIsBetter: true
        property real   rawDelta:       0

        height: 42
        radius: Theme.radius
        color: cmpRowMA.containsMouse ? Theme.panel2 : "transparent"

        Behavior on color { ColorAnimation { duration: 100 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 0

            Text {
                text: cmpRow.label
                color: Theme.muted
                font.pixelSize: 13
                Layout.fillWidth: true
                verticalAlignment: Text.AlignVCenter
            }

            Text {
                text: cmpRow.curVal
                color: Theme.text
                font.pixelSize: 14
                font.weight: Font.DemiBold
                font.family: "Menlo"
                Layout.preferredWidth: 130
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter
            }

            Text {
                text: cmpRow.refVal
                color: Theme.muted
                font.pixelSize: 13
                font.family: "Menlo"
                Layout.preferredWidth: 130
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter
            }

            RowLayout {
                Layout.preferredWidth: 140
                spacing: 4
                layoutDirection: Qt.RightToLeft

                Text {
                    text: {
                        var pct = cmpRow.deltaPct
                        return pct ? ("(" + pct + ")") : ""
                    }
                    color: root.deltaColor(cmpRow.rawDelta, cmpRow.higherIsBetter)
                    font.pixelSize: 11
                    font.family: "Menlo"
                    visible: cmpRow.deltaPct !== ""
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    text: (cmpRow.deltaVal !== "" ? root.deltaArrow(cmpRow.rawDelta) + " " : "") + cmpRow.deltaVal
                    color: root.deltaColor(cmpRow.rawDelta, cmpRow.higherIsBetter)
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    font.family: "Menlo"
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: Theme.line
            opacity: 0.5
        }

        MouseArea {
            id: cmpRowMA
            anchors.fill: parent
            hoverEnabled: true
        }
    }
}
