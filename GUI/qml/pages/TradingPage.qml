pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Item {
    id: root

    // ── connection / account state ───────────────────────────────────────
    property bool   connected:   true
    property string broker:      "ChinaBroker"
    property string accountId:   "DQ-001"
    property bool   autoTrading: true
    property bool   riskLocked:  false
    property string selectedStrategy: "MACD金叉-做多策略"
    property string executionMode: "自动调仓"
    property string nextRebalance: "14:55"

    // ── account summary ──────────────────────────────────────────────────
    property real equity:        1234567.89
    property real available:      456789.12
    property real unrealizedPnl:   23456.78
    property real dailyPnl:         8234.56
    property real marginRatio:        62.9

    // ── order form state ─────────────────────────────────────────────────
    property string orderSide:   "buy"    // "buy" | "sell"
    property string orderType:   "限价"
    property string orderSymbol: ""
    property string orderPrice:  ""
    property string orderQty:    ""
    property real   estimatedAmt: {
        var p = parseFloat(orderPrice)
        var q = parseFloat(orderQty)
        return (isNaN(p) || isNaN(q)) ? 0 : p * q
    }

    // ── positions ────────────────────────────────────────────────────────
    ListModel {
        id: positionsModel
        ListElement { symbol: "600036"; name: "招商银行"; direction: "多"; qty: 1000; cost: 41.23; price: 43.56; pnl: 2330;  pnlPct: 5.65 }
        ListElement { symbol: "000858"; name: "五粮液";   direction: "多"; qty:  500; cost: 168.90; price: 172.45; pnl: 1775; pnlPct: 2.10 }
        ListElement { symbol: "600519"; name: "贵州茅台"; direction: "多"; qty:  100; cost: 1680.00; price: 1695.30; pnl: 1530; pnlPct: 0.91 }
        ListElement { symbol: "002475"; name: "立讯精密"; direction: "空"; qty: 2000; cost: 28.56; price: 27.89; pnl: 1340; pnlPct: 2.35 }
    }

    // ── active orders ─────────────────────────────────────────────────────
    ListModel {
        id: ordersModel
        ListElement { orderId: "ORD-2847"; symbol: "600036"; name: "招商银行"; side: "买入"; qty: 500;  price: 43.00;  status: "待成交";       statusDetail: "" }
        ListElement { orderId: "ORD-2848"; symbol: "000858"; name: "五粮液";   side: "买入"; qty: 200;  price: 170.00; status: "部分成交";      statusDetail: "100/200" }
        ListElement { orderId: "ORD-2849"; symbol: "002475"; name: "立讯精密"; side: "卖出"; qty: 1000; price: 27.50;  status: "待成交";       statusDetail: "" }
    }

    // ── trade history ─────────────────────────────────────────────────────
    ListModel {
        id: historyModel
        ListElement { time: "10:23:45"; symbol: "600036"; name: "招商银行"; side: "买入"; qty: 500;  fillPrice: 43.12;  amount: 21560 }
        ListElement { time: "09:45:12"; symbol: "000858"; name: "五粮液";   side: "买入"; qty: 300;  fillPrice: 169.50; amount: 50850 }
        ListElement { time: "09:31:08"; symbol: "600519"; name: "贵州茅台"; side: "买入"; qty: 100;  fillPrice: 1685.00; amount: 168500 }
        ListElement { time: "09:30:55"; symbol: "002475"; name: "立讯精密"; side: "卖出"; qty: 1000; fillPrice: 28.45;  amount: 28450 }
        ListElement { time: "昨日";     symbol: "002475"; name: "立讯精密"; side: "卖出"; qty: 500;  fillPrice: 28.90;  amount: 14450 }
    }

    // ── automated strategy state ─────────────────────────────────────────
    ListModel {
        id: signalModel
        ListElement { symbol: "600036"; name: "招商银行"; signal: "加仓"; score: 0.84; targetWeight: 12.0; currentWeight: 8.5; reason: "趋势延续 / 量能确认" }
        ListElement { symbol: "600519"; name: "贵州茅台"; signal: "持有"; score: 0.71; targetWeight: 9.0;  currentWeight: 9.2; reason: "动量稳定 / 波动可控" }
        ListElement { symbol: "002475"; name: "立讯精密"; signal: "减仓"; score: 0.32; targetWeight: 3.0;  currentWeight: 7.4; reason: "短期动量转弱" }
        ListElement { symbol: "000858"; name: "五粮液";   signal: "观察"; score: 0.55; targetWeight: 6.0;  currentWeight: 5.8; reason: "等待突破确认" }
    }

    ListModel {
        id: riskModel
        ListElement { label: "账户连接"; status: "通过"; detail: "行情与交易通道在线" }
        ListElement { label: "单票权重"; status: "通过"; detail: "最大目标权重 12.0%" }
        ListElement { label: "回撤限制"; status: "通过"; detail: "日内回撤 0.7% / 阈值 3.0%" }
        ListElement { label: "订单重复"; status: "通过"; detail: "无重复挂单" }
    }

    ListModel {
        id: automationLogModel
        ListElement { time: "14:30:02"; level: "INFO"; message: "策略信号刷新完成，生成 3 条调仓建议" }
        ListElement { time: "14:30:03"; level: "RISK"; message: "风控检查通过，允许自动执行" }
        ListElement { time: "14:30:05"; level: "EXEC"; message: "等待下一次调仓窗口 14:55" }
    }

    // ── helpers ───────────────────────────────────────────────────────────
    function fmtMoney(v) {
        var s = v.toFixed(2)
        var parts = s.split(".")
        parts[0] = parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, ",")
        return "¥" + parts.join(".")
    }
    function fmtPnl(v) {
        return (v >= 0 ? "+" : "") + fmtMoney(v)
    }
    function pnlColor(v) { return v >= 0 ? "#4caf50" : "#ef5350" }
    function signalColor(s) {
        if (s === "加仓") return "#26a69a"
        if (s === "减仓") return "#ef5350"
        if (s === "持有") return Theme.primary
        return Theme.warning
    }
    function executeAutoRebalance() {
        if (!connected || !autoTrading || riskLocked)
            return

        ordersModel.append({
            orderId: "AUTO-" + (7300 + ordersModel.count),
            symbol: "600036",
            name: "招商银行",
            side: "买入",
            qty: 800,
            price: 43.20,
            status: "待成交",
            statusDetail: "策略调仓"
        })
        ordersModel.append({
            orderId: "AUTO-" + (7301 + ordersModel.count),
            symbol: "002475",
            name: "立讯精密",
            side: "卖出",
            qty: 1200,
            price: 27.80,
            status: "待成交",
            statusDetail: "策略调仓"
        })
        automationLogModel.insert(0, {
            time: "现在",
            level: "EXEC",
            message: "已根据目标仓位生成自动委托"
        })
    }

    // ── root layout ───────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 14

        // ══ HEADER ══════════════════════════════════════════════════════
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 88
            radius: Theme.radiusLarge
            color: Theme.surface
            border.color: Theme.line
            clip: true

            // left accent
            Rectangle {
                width: 4
                anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                color: "#26a69a"
                opacity: 0.9
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                anchors.topMargin: 12
                anchors.bottomMargin: 12
                spacing: 16

                // title
                ColumnLayout {
                    spacing: 3
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        text: "自动交易控制台"
                        color: Theme.text
                        font.pixelSize: 20
                        font.weight: Font.DemiBold
                    }
                    Text {
                        text: root.connected
                              ? (root.autoTrading ? "策略运行中 · 风控在线 · 下一次调仓 " + root.nextRebalance : "已连接 · 自动交易暂停")
                              : "未连接 · 请先建立连接"
                        color: root.connected && root.autoTrading ? "#4caf50" : Theme.muted
                        font.pixelSize: 12
                    }
                }

                // STRATEGY
                Column {
                    spacing: 5
                    Layout.alignment: Qt.AlignBottom
                    Text {
                        text: "STRATEGY"
                        color: Theme.faint
                        font.pixelSize: 10
                        font.letterSpacing: 1.1
                    }
                    DarkComboBox {
                        width: 170
                        height: 36
                        model: ["MACD金叉-做多策略", "多因子轮动", "低波动防御", "AI日内择时"]
                        currentIndex: model.indexOf(root.selectedStrategy)
                        onActivated: root.selectedStrategy = currentText
                    }
                }

                // BROKER
                Column {
                    spacing: 5
                    Layout.alignment: Qt.AlignBottom
                    Text {
                        text: "BROKER"
                        color: Theme.faint
                        font.pixelSize: 10
                        font.letterSpacing: 1.1
                    }
                    DarkComboBox {
                        width: 130
                        height: 36
                        model: ["ChinaBroker", "CryptoGateway", "UsBroker", "Mock"]
                        currentIndex: model.indexOf(root.broker)
                        onActivated: root.broker = currentText
                    }
                }

                // ACCOUNT
                Column {
                    spacing: 5
                    Layout.alignment: Qt.AlignBottom
                    Text {
                        text: "ACCOUNT"
                        color: Theme.faint
                        font.pixelSize: 10
                        font.letterSpacing: 1.1
                    }
                    DarkComboBox {
                        width: 110
                        height: 36
                        model: ["DQ-001", "DQ-002", "模拟账户"]
                        currentIndex: model.indexOf(root.accountId)
                        onActivated: root.accountId = currentText
                    }
                }

                Item { Layout.fillWidth: true }

                // automation and connection controls
                RowLayout {
                    spacing: 10
                    Layout.alignment: Qt.AlignVCenter

                    Rectangle {
                        width: 88; height: 36
                        radius: Theme.radius
                        color: autoMA.pressed
                               ? (root.autoTrading ? Qt.rgba(0.937,0.325,0.314,0.25) : Qt.rgba(0.149,0.651,0.604,0.25))
                               : (autoMA.containsMouse
                                  ? (root.autoTrading ? Qt.rgba(0.937,0.325,0.314,0.15) : Qt.rgba(0.149,0.651,0.604,0.15))
                                  : Theme.panel2)
                        border.color: root.autoTrading ? "#ef5350" : "#26a69a"
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            anchors.centerIn: parent
                            text: root.autoTrading ? "暂停策略" : "启动策略"
                            color: root.autoTrading ? "#ef5350" : "#26a69a"
                            font.pixelSize: 13
                            font.weight: Font.Medium
                        }

                        MouseArea {
                            id: autoMA
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.autoTrading = !root.autoTrading
                        }
                    }

                    // status pill
                    Rectangle {
                        width: statusRow.implicitWidth + 20
                        height: 28
                        radius: 14
                        color: root.connected ? Qt.rgba(0.298, 0.686, 0.314, 0.14)
                                              : Qt.rgba(0.937, 0.325, 0.314, 0.14)
                        border.color: root.connected ? "#4caf50" : "#ef5350"
                        border.width: 1

                        RowLayout {
                            id: statusRow
                            anchors.centerIn: parent
                            spacing: 6

                            Rectangle {
                                width: 7; height: 7; radius: 3.5
                                color: root.connected ? "#4caf50" : "#ef5350"

                                SequentialAnimation on opacity {
                                    running: root.connected
                                    loops: Animation.Infinite
                                    NumberAnimation { to: 0.3; duration: 900 }
                                    NumberAnimation { to: 1.0; duration: 900 }
                                }
                            }

                            Text {
                                text: root.connected ? "CONNECTED" : "DISCONNECTED"
                                color: root.connected ? "#4caf50" : "#ef5350"
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                font.letterSpacing: 0.8
                            }
                        }
                    }

                    // connect / disconnect button
                    Rectangle {
                        width: 88; height: 36
                        radius: Theme.radius
                        color: connectMA.pressed
                               ? (root.connected ? Qt.rgba(0.937,0.325,0.314,0.25) : Qt.rgba(0.149,0.651,0.604,0.25))
                               : (connectMA.containsMouse
                                  ? (root.connected ? Qt.rgba(0.937,0.325,0.314,0.15) : Qt.rgba(0.149,0.651,0.604,0.15))
                                  : Theme.panel2)
                        border.color: root.connected ? "#ef5350" : "#26a69a"
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            anchors.centerIn: parent
                            text: root.connected ? "断开连接" : "建立连接"
                            color: root.connected ? "#ef5350" : "#26a69a"
                            font.pixelSize: 13
                            font.weight: Font.Medium
                        }

                        MouseArea {
                            id: connectMA
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.connected = !root.connected
                        }
                    }
                }
            }
        }

        // ══ AUTOMATION OVERVIEW ══════════════════════════════════════════
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 236
            radius: Theme.radiusLarge
            color: Theme.surface
            border.color: Theme.line
            clip: true

            RowLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 14

                ColumnLayout {
                    Layout.preferredWidth: 260
                    Layout.fillHeight: true
                    spacing: 10

                    RowLayout {
                        spacing: 7
                        Rectangle { width: 3; height: 13; radius: 1.5; color: root.autoTrading ? "#26a69a" : Theme.warning }
                        Text {
                            text: "策略引擎"
                            color: Theme.text
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: root.autoTrading ? "RUNNING" : "PAUSED"
                            color: root.autoTrading ? "#26a69a" : Theme.warning
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                        }
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        rowSpacing: 8
                        columnSpacing: 8

                        Repeater {
                            model: [
                                { label: "当前策略", value: root.selectedStrategy },
                                { label: "执行模式", value: root.executionMode },
                                { label: "信号数量", value: signalModel.count + " 条" },
                                { label: "下次调仓", value: root.nextRebalance }
                            ]

                            Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                height: 58
                                radius: Theme.radius
                                color: Theme.panel2
                                border.color: Theme.border

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 2
                                    Text {
                                        text: modelData.label
                                        color: Theme.faint
                                        font.pixelSize: 10
                                        font.letterSpacing: 0.8
                                    }
                                    Text {
                                        text: modelData.value
                                        color: Theme.text
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 38
                        radius: Theme.radius
                        color: executeMA.pressed ? Qt.rgba(0.149,0.651,0.604,0.35)
                              : executeMA.containsMouse ? Qt.rgba(0.149,0.651,0.604,0.22)
                              : Qt.rgba(0.149,0.651,0.604,0.14)
                        border.color: root.connected && root.autoTrading && !root.riskLocked ? "#26a69a" : Theme.border
                        opacity: root.connected && root.autoTrading && !root.riskLocked ? 1.0 : 0.55

                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            anchors.centerIn: parent
                            text: "执行本轮自动调仓"
                            color: "#26a69a"
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                        }

                        MouseArea {
                            id: executeMA
                            anchors.fill: parent
                            enabled: root.connected && root.autoTrading && !root.riskLocked
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.executeAutoRebalance()
                        }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 1
                    Layout.fillHeight: true
                    color: Theme.line
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 10

                    RowLayout {
                        spacing: 7
                        Rectangle { width: 3; height: 13; radius: 1.5; color: Theme.primary }
                        Text {
                            text: "最新策略信号"
                            color: Theme.text
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                        }
                    }

                    ListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        model: signalModel
                        clip: true
                        spacing: 2

                        delegate: Rectangle {
                            id: sigRow
                            required property int index
                            required property string symbol
                            required property string name
                            required property string signal
                            required property real score
                            required property real targetWeight
                            required property real currentWeight
                            required property string reason

                            width: ListView.view.width
                            height: 38
                            radius: 6
                            color: sigMA.containsMouse ? Theme.panel3 : Theme.panel2
                            border.color: "transparent"

                            Behavior on color { ColorAnimation { duration: 100 } }
                            MouseArea { id: sigMA; anchors.fill: parent; hoverEnabled: true }

                            RowLayout {
                                anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                                spacing: 10

                                Text {
                                    Layout.preferredWidth: 58
                                    text: sigRow.symbol
                                    color: Theme.text
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                }
                                Text {
                                    Layout.preferredWidth: 62
                                    text: sigRow.name
                                    color: Theme.muted
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                }
                                Rectangle {
                                    Layout.preferredWidth: 44
                                    height: 22
                                    radius: 4
                                    color: Qt.rgba(0.149, 0.651, 0.604, 0.10)
                                    border.color: root.signalColor(sigRow.signal)
                                    Text {
                                        anchors.centerIn: parent
                                        text: sigRow.signal
                                        color: root.signalColor(sigRow.signal)
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                    }
                                }
                                Text {
                                    Layout.preferredWidth: 56
                                    horizontalAlignment: Text.AlignRight
                                    text: (sigRow.currentWeight).toFixed(1) + "% → " + (sigRow.targetWeight).toFixed(1) + "%"
                                    color: Theme.text
                                    font.pixelSize: 12
                                }
                                Text {
                                    Layout.preferredWidth: 46
                                    horizontalAlignment: Text.AlignRight
                                    text: sigRow.score.toFixed(2)
                                    color: sigRow.score >= 0.7 ? "#26a69a" : sigRow.score < 0.45 ? "#ef5350" : Theme.warning
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: sigRow.reason
                                    color: Theme.faint
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 1
                    Layout.fillHeight: true
                    color: Theme.line
                }

                ColumnLayout {
                    Layout.preferredWidth: 300
                    Layout.fillHeight: true
                    spacing: 10

                    RowLayout {
                        spacing: 7
                        Rectangle { width: 3; height: 13; radius: 1.5; color: root.riskLocked ? "#ef5350" : "#26a69a" }
                        Text {
                            text: "风控与执行日志"
                            color: Theme.text
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: root.riskLocked ? "LOCKED" : "PASS"
                            color: root.riskLocked ? "#ef5350" : "#26a69a"
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                        }
                    }

                    Repeater {
                        model: riskModel
                        delegate: RowLayout {
                            required property string label
                            required property string status
                            required property string detail
                            Layout.fillWidth: true
                            spacing: 8

                            Rectangle {
                                width: 7
                                height: 7
                                radius: 3.5
                                color: status === "通过" ? "#26a69a" : "#ef5350"
                            }
                            Text {
                                Layout.preferredWidth: 58
                                text: label
                                color: Theme.text
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                            }
                            Text {
                                Layout.fillWidth: true
                                text: detail
                                color: Theme.faint
                                font.pixelSize: 11
                                elide: Text.ElideRight
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: Theme.line
                    }

                    ListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        model: automationLogModel
                        clip: true
                        spacing: 2

                        delegate: RowLayout {
                            required property string time
                            required property string level
                            required property string message
                            width: ListView.view.width
                            height: 22
                            spacing: 8

                            Text {
                                Layout.preferredWidth: 50
                                text: time
                                color: Theme.faint
                                font.pixelSize: 10
                                font.family: "Menlo"
                            }
                            Text {
                                Layout.preferredWidth: 34
                                text: level
                                color: level === "RISK" ? Theme.warning : level === "EXEC" ? "#26a69a" : Theme.muted
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                            }
                            Text {
                                Layout.fillWidth: true
                                text: message
                                color: Theme.muted
                                font.pixelSize: 11
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
        }

        // ══ BODY: 3 columns ══════════════════════════════════════════════
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 14

            // ── LEFT COLUMN ──────────────────────────────────────────────
            ColumnLayout {
                Layout.preferredWidth: 264
                Layout.fillHeight: true
                spacing: 12

                // ── Account overview ─────────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: acctColumn.implicitHeight + 28
                    radius: Theme.radiusLarge
                    color: Theme.surface
                    border.color: Theme.line

                    ColumnLayout {
                        id: acctColumn
                        anchors { left: parent.left; right: parent.right; top: parent.top }
                        anchors.margins: 16
                        spacing: 10

                        // section title
                        RowLayout {
                            spacing: 7
                            Rectangle { width: 3; height: 13; radius: 1.5; color: "#26a69a" }
                            Text {
                                text: "账户概览"
                                color: Theme.text
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                            }
                        }

                        // total equity – hero number
                        Rectangle {
                            Layout.fillWidth: true
                            height: 58
                            radius: Theme.radius
                            color: Theme.panel2
                            border.color: Theme.border

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 2

                                Text {
                                    text: "总权益"
                                    color: Theme.faint
                                    font.pixelSize: 10
                                    font.letterSpacing: 1.0
                                }
                                Text {
                                    text: root.fmtMoney(root.equity)
                                    color: Theme.text
                                    font.pixelSize: 22
                                    font.weight: Font.DemiBold
                                }
                            }
                        }

                        // 2x2 metric grid
                        GridLayout {
                            Layout.fillWidth: true
                            columns: 2
                            rowSpacing: 8
                            columnSpacing: 8

                            Repeater {
                                model: [
                                    { label: "可用资金", value: root.fmtMoney(root.available),         colored: false },
                                    { label: "浮动盈亏", value: root.fmtPnl(root.unrealizedPnl),       colored: true,  raw: root.unrealizedPnl },
                                    { label: "今日盈亏", value: root.fmtPnl(root.dailyPnl),            colored: true,  raw: root.dailyPnl },
                                    { label: "保证金率", value: root.marginRatio.toFixed(1) + "%",     colored: false }
                                ]

                                Rectangle {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    height: 48
                                    radius: Theme.radius
                                    color: Theme.panel2
                                    border.color: Theme.border

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 10
                                        spacing: 2
                                        Text {
                                            text: modelData.label
                                            color: Theme.faint
                                            font.pixelSize: 10
                                            font.letterSpacing: 0.9
                                        }
                                        Text {
                                            text: modelData.value
                                            color: modelData.colored
                                                   ? root.pnlColor(modelData.raw)
                                                   : Theme.text
                                            font.pixelSize: 13
                                            font.weight: Font.DemiBold
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // ── Manual Intervention ─────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Theme.radiusLarge
                    color: Theme.surface
                    border.color: Theme.line
                    clip: true

                    ColumnLayout {
                        anchors { left: parent.left; right: parent.right; top: parent.top }
                        anchors.margins: 16
                        spacing: 12

                        RowLayout {
                            spacing: 7
                            Rectangle { width: 3; height: 13; radius: 1.5; color: Theme.warning }
                            Text {
                                text: "人工干预"
                                color: Theme.text
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: "兜底"
                                color: Theme.warning
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                            }
                        }

                        // SYMBOL
                        Column {
                            Layout.fillWidth: true
                            spacing: 5
                            Text { text: "SYMBOL"; color: Theme.faint; font.pixelSize: 10; font.letterSpacing: 1.1 }
                            Rectangle {
                                width: parent.width; height: 36
                                radius: Theme.radius
                                color: Theme.panel2
                                border.color: symField.activeFocus ? Theme.primary : Theme.border

                                Behavior on border.color { ColorAnimation { duration: 120 } }

                                TextInput {
                                    id: symField
                                    anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                                    verticalAlignment: TextInput.AlignVCenter
                                    color: Theme.text
                                    font.pixelSize: 14
                                    selectionColor: Qt.rgba(0.149, 0.651, 0.604, 0.35)
                                    text: root.orderSymbol
                                    onTextChanged: root.orderSymbol = text

                                    Text {
                                        anchors.fill: parent
                                        verticalAlignment: Text.AlignVCenter
                                        text: "代码 / 名称"
                                        color: Theme.faint
                                        font.pixelSize: 14
                                        visible: symField.text.length === 0 && !symField.activeFocus
                                    }
                                }
                            }
                        }

                        // BUY / SELL toggle
                        Column {
                            Layout.fillWidth: true
                            spacing: 5
                            Text { text: "方向"; color: Theme.faint; font.pixelSize: 10; font.letterSpacing: 1.1 }
                            RowLayout {
                                width: parent.width
                                spacing: 6

                                // BUY
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 36
                                    radius: Theme.radius
                                    color: root.orderSide === "buy"
                                           ? Qt.rgba(0.149, 0.651, 0.604, 0.22)
                                           : Theme.panel2
                                    border.color: root.orderSide === "buy" ? "#26a69a" : Theme.border
                                    border.width: root.orderSide === "buy" ? 1.5 : 1

                                    Behavior on color { ColorAnimation { duration: 140 } }
                                    Behavior on border.color { ColorAnimation { duration: 140 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "买 入"
                                        color: root.orderSide === "buy" ? "#26a69a" : Theme.muted
                                        font.pixelSize: 14
                                        font.weight: root.orderSide === "buy" ? Font.DemiBold : Font.Normal

                                        Behavior on color { ColorAnimation { duration: 140 } }
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.orderSide = "buy"
                                    }
                                }

                                // SELL
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 36
                                    radius: Theme.radius
                                    color: root.orderSide === "sell"
                                           ? Qt.rgba(0.937, 0.325, 0.314, 0.22)
                                           : Theme.panel2
                                    border.color: root.orderSide === "sell" ? "#ef5350" : Theme.border
                                    border.width: root.orderSide === "sell" ? 1.5 : 1

                                    Behavior on color { ColorAnimation { duration: 140 } }
                                    Behavior on border.color { ColorAnimation { duration: 140 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "卖 出"
                                        color: root.orderSide === "sell" ? "#ef5350" : Theme.muted
                                        font.pixelSize: 14
                                        font.weight: root.orderSide === "sell" ? Font.DemiBold : Font.Normal

                                        Behavior on color { ColorAnimation { duration: 140 } }
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.orderSide = "sell"
                                    }
                                }
                            }
                        }

                        // ORDER TYPE
                        Column {
                            Layout.fillWidth: true
                            spacing: 5
                            Text { text: "委托类型"; color: Theme.faint; font.pixelSize: 10; font.letterSpacing: 1.1 }
                            DarkComboBox {
                                width: parent.width
                                height: 36
                                model: ["限价", "市价", "止损限价", "止盈限价"]
                                currentIndex: model.indexOf(root.orderType)
                                onActivated: root.orderType = currentText
                            }
                        }

                        // PRICE  (hide for market order)
                        Column {
                            id: priceCol
                            Layout.fillWidth: true
                            spacing: 5
                            visible: root.orderType !== "市价"

                            Text { text: "委托价格"; color: Theme.faint; font.pixelSize: 10; font.letterSpacing: 1.1 }
                            Rectangle {
                                width: parent.width; height: 36
                                radius: Theme.radius
                                color: Theme.panel2
                                border.color: priceField.activeFocus ? Theme.primary : Theme.border

                                Behavior on border.color { ColorAnimation { duration: 120 } }

                                RowLayout {
                                    anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                                    spacing: 4

                                    TextInput {
                                        id: priceField
                                        Layout.fillWidth: true
                                        verticalAlignment: TextInput.AlignVCenter
                                        color: Theme.text
                                        font.pixelSize: 14
                                        selectionColor: Qt.rgba(0.149, 0.651, 0.604, 0.35)
                                        text: root.orderPrice
                                        onTextChanged: root.orderPrice = text
                                        validator: RegularExpressionValidator { regularExpression: /[0-9]*\.?[0-9]*/ }

                                        Text {
                                            anchors.fill: parent
                                            verticalAlignment: Text.AlignVCenter
                                            text: "0.00"
                                            color: Theme.faint
                                            font.pixelSize: 14
                                            visible: priceField.text.length === 0 && !priceField.activeFocus
                                        }
                                    }
                                    Text { text: "元"; color: Theme.muted; font.pixelSize: 12 }
                                }
                            }
                        }

                        // QTY
                        Column {
                            Layout.fillWidth: true
                            spacing: 5
                            Text { text: "委托数量"; color: Theme.faint; font.pixelSize: 10; font.letterSpacing: 1.1 }
                            Rectangle {
                                width: parent.width; height: 36
                                radius: Theme.radius
                                color: Theme.panel2
                                border.color: qtyField.activeFocus ? Theme.primary : Theme.border

                                Behavior on border.color { ColorAnimation { duration: 120 } }

                                RowLayout {
                                    anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                                    spacing: 4

                                    TextInput {
                                        id: qtyField
                                        Layout.fillWidth: true
                                        verticalAlignment: TextInput.AlignVCenter
                                        color: Theme.text
                                        font.pixelSize: 14
                                        selectionColor: Qt.rgba(0.149, 0.651, 0.604, 0.35)
                                        text: root.orderQty
                                        onTextChanged: root.orderQty = text
                                        validator: RegularExpressionValidator { regularExpression: /[0-9]*/ }

                                        Text {
                                            anchors.fill: parent
                                            verticalAlignment: Text.AlignVCenter
                                            text: "0"
                                            color: Theme.faint
                                            font.pixelSize: 14
                                            visible: qtyField.text.length === 0 && !qtyField.activeFocus
                                        }
                                    }
                                    Text { text: "股"; color: Theme.muted; font.pixelSize: 12 }
                                }
                            }
                        }

                        // estimated amount
                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: "预估金额"
                                color: Theme.faint
                                font.pixelSize: 11
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: root.fmtMoney(root.estimatedAmt)
                                color: root.estimatedAmt > 0 ? Theme.text : Theme.muted
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                            }
                        }

                        // SUBMIT BUTTON
                        Rectangle {
                            Layout.fillWidth: true
                            height: 40
                            radius: Theme.radius
                            color: {
                                if (!root.connected) return Theme.panel2
                                if (submitMA.pressed)
                                    return root.orderSide === "buy"
                                           ? Qt.rgba(0.149, 0.651, 0.604, 0.60)
                                           : Qt.rgba(0.937, 0.325, 0.314, 0.60)
                                if (submitMA.containsMouse)
                                    return root.orderSide === "buy"
                                           ? Qt.rgba(0.149, 0.651, 0.604, 0.42)
                                           : Qt.rgba(0.937, 0.325, 0.314, 0.42)
                                return root.orderSide === "buy"
                                       ? Qt.rgba(0.149, 0.651, 0.604, 0.30)
                                       : Qt.rgba(0.937, 0.325, 0.314, 0.30)
                            }
                            border.color: root.connected
                                          ? (root.orderSide === "buy" ? "#26a69a" : "#ef5350")
                                          : Theme.border
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: 130 } }

                            Text {
                                anchors.centerIn: parent
                                text: {
                                    if (!root.connected) return "请先连接账户"
                                    return root.orderSide === "buy" ? "买 入 下 单" : "卖 出 下 单"
                                }
                                color: root.connected
                                       ? (root.orderSide === "buy" ? "#26a69a" : "#ef5350")
                                       : Theme.faint
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                                font.letterSpacing: 1.5
                            }

                            MouseArea {
                                id: submitMA
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: root.connected
                                cursorShape: root.connected ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: {
                                    if (!root.connected) return
                                    // add mock order
                                    var sym = root.orderSymbol || "------"
                                    var id  = "ORD-" + (2850 + ordersModel.count)
                                    ordersModel.append({
                                        orderId: id,
                                        symbol:  sym,
                                        name:    sym,
                                        side:    root.orderSide === "buy" ? "买入" : "卖出",
                                        qty:     parseInt(root.orderQty) || 0,
                                        price:   parseFloat(root.orderPrice) || 0,
                                        status:  "待成交",
                                        statusDetail: ""
                                    })
                                    // clear form
                                    root.orderSymbol = ""
                                    root.orderPrice  = ""
                                    root.orderQty    = ""
                                    symField.text   = ""
                                    priceField.text = ""
                                    qtyField.text   = ""
                                }
                            }
                        }

                        Item { height: 4 }
                    }
                }
            }

            // ── CENTER COLUMN ────────────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 12

                // ── Positions ────────────────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Theme.radiusLarge
                    color: Theme.surface
                    border.color: Theme.line
                    clip: true

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 10

                        // title row
                        RowLayout {
                            spacing: 7
                            Rectangle { width: 3; height: 13; radius: 1.5; color: "#26a69a" }
                            Text {
                                text: "持仓管理"
                                color: Theme.text
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: positionsModel.count + " 个持仓"
                                color: Theme.muted
                                font.pixelSize: 11
                            }
                        }

                        // table header
                        Rectangle {
                            Layout.fillWidth: true
                            height: 28
                            radius: 4
                            color: Theme.panel2

                            RowLayout {
                                anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                                spacing: 0

                                Repeater {
                                    model: [
                                        { t: "代码/名称",  w: 0,    fill: true  },
                                        { t: "方向",      w: 40,   fill: false },
                                        { t: "持仓量",    w: 64,   fill: false },
                                        { t: "成本价",    w: 72,   fill: false },
                                        { t: "现价",      w: 72,   fill: false },
                                        { t: "浮盈亏",    w: 96,   fill: false },
                                        { t: "盈亏%",     w: 72,   fill: false },
                                        { t: "",          w: 64,   fill: false }
                                    ]

                                    Item {
                                        required property var modelData
                                        Layout.fillWidth: modelData.fill
                                        Layout.preferredWidth: modelData.fill ? -1 : modelData.w

                                        Text {
                                            anchors.fill: parent
                                            text: modelData.t
                                            color: Theme.faint
                                            font.pixelSize: 10
                                            font.letterSpacing: 0.8
                                            verticalAlignment: Text.AlignVCenter
                                            horizontalAlignment: modelData.fill ? Text.AlignLeft : Text.AlignRight
                                        }
                                    }
                                }
                            }
                        }

                        // position rows
                        ListView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            model: positionsModel
                            spacing: 2
                            clip: true

                            delegate: Rectangle {
                                id: posRow
                                required property int    index
                                required property string symbol
                                required property string name
                                required property string direction
                                required property int    qty
                                required property real   cost
                                required property real   price
                                required property real   pnl
                                required property real   pnlPct

                                width: ListView.view.width
                                height: 40
                                radius: 6
                                color: posRowMA.containsMouse ? Theme.panel3 : "transparent"

                                Behavior on color { ColorAnimation { duration: 100 } }

                                MouseArea {
                                    id: posRowMA
                                    anchors.fill: parent
                                    hoverEnabled: true
                                }

                                RowLayout {
                                    anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                                    spacing: 0

                                    // symbol + name (fill)
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 1
                                        Text {
                                            text: posRow.symbol
                                            color: Theme.text
                                            font.pixelSize: 13
                                            font.weight: Font.Medium
                                        }
                                        Text {
                                            text: posRow.name
                                            color: Theme.muted
                                            font.pixelSize: 11
                                        }
                                    }

                                    // 方向 chip
                                    Item {
                                        Layout.preferredWidth: 40
                                        Layout.fillHeight: true
                                        Rectangle {
                                            width: 28; height: 18
                                            anchors.right: parent.right
                                            anchors.verticalCenter: parent.verticalCenter
                                            radius: 3
                                            color: posRow.direction === "多"
                                                   ? Qt.rgba(0.149,0.651,0.604,0.18)
                                                   : Qt.rgba(0.937,0.325,0.314,0.18)
                                            border.color: posRow.direction === "多" ? "#26a69a" : "#ef5350"
                                            border.width: 1
                                            Text {
                                                anchors.centerIn: parent
                                                text: posRow.direction
                                                color: posRow.direction === "多" ? "#26a69a" : "#ef5350"
                                                font.pixelSize: 11
                                                font.weight: Font.DemiBold
                                            }
                                        }
                                    }

                                    Text {
                                        Layout.preferredWidth: 64
                                        horizontalAlignment: Text.AlignRight
                                        text: posRow.qty.toLocaleString()
                                        color: Theme.text
                                        font.pixelSize: 13
                                    }
                                    Text {
                                        Layout.preferredWidth: 72
                                        horizontalAlignment: Text.AlignRight
                                        text: posRow.cost.toFixed(2)
                                        color: Theme.muted
                                        font.pixelSize: 13
                                    }
                                    Text {
                                        Layout.preferredWidth: 72
                                        horizontalAlignment: Text.AlignRight
                                        text: posRow.price.toFixed(2)
                                        color: Theme.text
                                        font.pixelSize: 13
                                        font.weight: Font.Medium
                                    }
                                    Text {
                                        Layout.preferredWidth: 96
                                        horizontalAlignment: Text.AlignRight
                                        text: root.fmtPnl(posRow.pnl)
                                        color: root.pnlColor(posRow.pnl)
                                        font.pixelSize: 13
                                        font.weight: Font.DemiBold
                                    }
                                    Text {
                                        Layout.preferredWidth: 72
                                        horizontalAlignment: Text.AlignRight
                                        text: (posRow.pnlPct >= 0 ? "+" : "") + posRow.pnlPct.toFixed(2) + "%"
                                        color: root.pnlColor(posRow.pnlPct)
                                        font.pixelSize: 12
                                    }

                                    // close button
                                    Item {
                                        Layout.preferredWidth: 64
                                        Layout.fillHeight: true

                                        Rectangle {
                                            width: 52; height: 24
                                            anchors.right: parent.right
                                            anchors.verticalCenter: parent.verticalCenter
                                            radius: 4
                                            visible: posRowMA.containsMouse || closePosMA.containsMouse
                                            color: closePosMA.pressed
                                                   ? Qt.rgba(0.937,0.325,0.314,0.30)
                                                   : Qt.rgba(0.937,0.325,0.314,0.15)
                                            border.color: "#ef5350"
                                            border.width: 1

                                            Text {
                                                anchors.centerIn: parent
                                                text: "平仓"
                                                color: "#ef5350"
                                                font.pixelSize: 11
                                                font.weight: Font.DemiBold
                                            }

                                            MouseArea {
                                                id: closePosMA
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: positionsModel.remove(posRow.index)
                                            }
                                        }
                                    }
                                }

                                // bottom separator
                                Rectangle {
                                    anchors { bottom: parent.bottom; left: parent.left; right: parent.right; leftMargin: 10; rightMargin: 10 }
                                    height: 1
                                    color: Theme.line
                                    opacity: 0.5
                                    visible: posRow.index < positionsModel.count - 1
                                }
                            }
                        }
                    }
                }

                // ── Trade History ────────────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 224
                    radius: Theme.radiusLarge
                    color: Theme.surface
                    border.color: Theme.line
                    clip: true

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 10

                        RowLayout {
                            spacing: 7
                            Rectangle { width: 3; height: 13; radius: 1.5; color: Theme.primary }
                            Text {
                                text: "今日成交"
                                color: Theme.text
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: historyModel.count + " 笔"
                                color: Theme.muted
                                font.pixelSize: 11
                            }
                        }

                        // header
                        Rectangle {
                            Layout.fillWidth: true
                            height: 26
                            radius: 4
                            color: Theme.panel2

                            RowLayout {
                                anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                                spacing: 0

                                Repeater {
                                    model: [
                                        { t: "时间",    w: 72,   fill: false },
                                        { t: "代码/名称", w: 0,  fill: true  },
                                        { t: "方向",    w: 40,   fill: false },
                                        { t: "成交量",  w: 64,   fill: false },
                                        { t: "成交价",  w: 80,   fill: false },
                                        { t: "成交额",  w: 90,   fill: false }
                                    ]
                                    Item {
                                        required property var modelData
                                        Layout.fillWidth: modelData.fill
                                        Layout.preferredWidth: modelData.fill ? -1 : modelData.w
                                        Text {
                                            anchors.fill: parent
                                            text: modelData.t
                                            color: Theme.faint
                                            font.pixelSize: 10
                                            font.letterSpacing: 0.8
                                            verticalAlignment: Text.AlignVCenter
                                            horizontalAlignment: modelData.fill ? Text.AlignLeft : Text.AlignRight
                                        }
                                    }
                                }
                            }
                        }

                        ListView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            model: historyModel
                            spacing: 0
                            clip: true

                            delegate: Rectangle {
                                id: histRow
                                required property int    index
                                required property string time
                                required property string symbol
                                required property string name
                                required property string side
                                required property int    qty
                                required property real   fillPrice
                                required property int    amount

                                width: ListView.view.width
                                height: 34
                                color: histRowMA.containsMouse ? Theme.panel3 : "transparent"

                                Behavior on color { ColorAnimation { duration: 100 } }

                                MouseArea { id: histRowMA; anchors.fill: parent; hoverEnabled: true }

                                RowLayout {
                                    anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                                    spacing: 0

                                    Text {
                                        Layout.preferredWidth: 72
                                        text: histRow.time
                                        color: Theme.muted
                                        font.pixelSize: 12
                                        font.family: "Menlo, monospace"
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 1
                                        Text { text: histRow.symbol; color: Theme.text; font.pixelSize: 12; font.weight: Font.Medium }
                                        Text { text: histRow.name;   color: Theme.muted; font.pixelSize: 10 }
                                    }

                                    Item {
                                        Layout.preferredWidth: 40
                                        Layout.fillHeight: true
                                        Text {
                                            anchors.right: parent.right
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: histRow.side
                                            color: histRow.side === "买入" ? "#26a69a" : "#ef5350"
                                            font.pixelSize: 12
                                            font.weight: Font.DemiBold
                                        }
                                    }
                                    Text {
                                        Layout.preferredWidth: 64
                                        horizontalAlignment: Text.AlignRight
                                        text: histRow.qty.toLocaleString()
                                        color: Theme.text
                                        font.pixelSize: 12
                                    }
                                    Text {
                                        Layout.preferredWidth: 80
                                        horizontalAlignment: Text.AlignRight
                                        text: histRow.fillPrice.toFixed(2)
                                        color: Theme.text
                                        font.pixelSize: 12
                                        font.weight: Font.Medium
                                    }
                                    Text {
                                        Layout.preferredWidth: 90
                                        horizontalAlignment: Text.AlignRight
                                        text: root.fmtMoney(histRow.amount)
                                        color: Theme.muted
                                        font.pixelSize: 12
                                    }
                                }

                                Rectangle {
                                    anchors { bottom: parent.bottom; left: parent.left; right: parent.right; leftMargin: 10; rightMargin: 10 }
                                    height: 1; color: Theme.line; opacity: 0.4
                                    visible: histRow.index < historyModel.count - 1
                                }
                            }
                        }
                    }
                }
            }

            // ── RIGHT COLUMN ─────────────────────────────────────────────
            ColumnLayout {
                Layout.preferredWidth: 340
                Layout.fillHeight: true
                spacing: 12

                // ── Active Orders ────────────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Theme.radiusLarge
                    color: Theme.surface
                    border.color: Theme.line
                    clip: true

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 10

                        RowLayout {
                            spacing: 7
                            Rectangle { width: 3; height: 13; radius: 1.5; color: "#f9a825" }
                            Text {
                                text: "当前委托"
                                color: Theme.text
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                            }
                            Item { Layout.fillWidth: true }
                            // cancel all
                            Text {
                                text: "全部撤单"
                                color: ordersModel.count > 0 ? "#ef5350" : Theme.faint
                                font.pixelSize: 11
                                font.underline: cancelAllMA.containsMouse

                                MouseArea {
                                    id: cancelAllMA
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    enabled: ordersModel.count > 0
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: ordersModel.clear()
                                }
                            }
                        }

                        // header
                        Rectangle {
                            Layout.fillWidth: true
                            height: 26
                            radius: 4
                            color: Theme.panel2

                            RowLayout {
                                anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                                spacing: 0

                                Repeater {
                                    model: [
                                        { t: "品种",   w: 0,   fill: true  },
                                        { t: "方向",   w: 36,  fill: false },
                                        { t: "数量",   w: 44,  fill: false },
                                        { t: "价格",   w: 56,  fill: false },
                                        { t: "状态",   w: 64,  fill: false },
                                        { t: "",       w: 44,  fill: false }
                                    ]
                                    Item {
                                        required property var modelData
                                        Layout.fillWidth: modelData.fill
                                        Layout.preferredWidth: modelData.fill ? -1 : modelData.w
                                        Text {
                                            anchors.fill: parent
                                            text: modelData.t
                                            color: Theme.faint
                                            font.pixelSize: 10
                                            font.letterSpacing: 0.8
                                            verticalAlignment: Text.AlignVCenter
                                            horizontalAlignment: modelData.fill ? Text.AlignLeft : Text.AlignRight
                                        }
                                    }
                                }
                            }
                        }

                        // orders list
                        ListView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            model: ordersModel
                            spacing: 2
                            clip: true

                            remove: Transition {
                                NumberAnimation { property: "opacity"; to: 0; duration: 220 }
                                NumberAnimation { property: "height";  to: 0; duration: 220 }
                            }
                            removeDisplaced: Transition {
                                NumberAnimation { properties: "y"; duration: 200 }
                            }

                            delegate: Rectangle {
                                id: ordRow
                                required property int    index
                                required property string orderId
                                required property string symbol
                                required property string name
                                required property string side
                                required property int    qty
                                required property real   price
                                required property string status
                                required property string statusDetail

                                width: ListView.view.width
                                height: 48
                                radius: 6
                                color: ordRowMA.containsMouse ? Theme.panel3 : "transparent"

                                Behavior on color { ColorAnimation { duration: 100 } }

                                MouseArea { id: ordRowMA; anchors.fill: parent; hoverEnabled: true }

                                RowLayout {
                                    anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                                    spacing: 0

                                    // symbol + order id
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 1
                                        Text {
                                            text: ordRow.symbol + " " + ordRow.name
                                            color: Theme.text
                                            font.pixelSize: 12
                                            font.weight: Font.Medium
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                        Text {
                                            text: ordRow.orderId
                                            color: Theme.faint
                                            font.pixelSize: 10
                                        }
                                    }

                                    // side
                                    Item {
                                        Layout.preferredWidth: 36
                                        Layout.fillHeight: true
                                        Text {
                                            anchors.right: parent.right
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: ordRow.side
                                            color: ordRow.side === "买入" ? "#26a69a" : "#ef5350"
                                            font.pixelSize: 12
                                            font.weight: Font.DemiBold
                                        }
                                    }

                                    Text {
                                        Layout.preferredWidth: 44
                                        horizontalAlignment: Text.AlignRight
                                        text: ordRow.qty.toLocaleString()
                                        color: Theme.text
                                        font.pixelSize: 12
                                    }
                                    Text {
                                        Layout.preferredWidth: 56
                                        horizontalAlignment: Text.AlignRight
                                        text: ordRow.price.toFixed(2)
                                        color: Theme.text
                                        font.pixelSize: 12
                                        font.weight: Font.Medium
                                    }

                                    // status
                                    Item {
                                        Layout.preferredWidth: 64
                                        Layout.fillHeight: true

                                        ColumnLayout {
                                            anchors.right: parent.right
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 1

                                            Text {
                                                text: ordRow.status
                                                color: ordRow.status === "待成交"  ? "#f9a825"
                                                     : ordRow.status === "部分成交" ? Theme.primary
                                                     : Theme.muted
                                                font.pixelSize: 11
                                                font.weight: Font.DemiBold
                                                Layout.alignment: Qt.AlignRight
                                            }
                                            Text {
                                                visible: ordRow.statusDetail.length > 0
                                                text: ordRow.statusDetail
                                                color: Theme.faint
                                                font.pixelSize: 10
                                                Layout.alignment: Qt.AlignRight
                                            }
                                        }
                                    }

                                    // cancel button
                                    Item {
                                        Layout.preferredWidth: 44
                                        Layout.fillHeight: true

                                        Rectangle {
                                            width: 36; height: 22
                                            anchors.right: parent.right
                                            anchors.verticalCenter: parent.verticalCenter
                                            radius: 4
                                            color: cancelMA.pressed  ? Qt.rgba(0.937,0.325,0.314,0.30)
                                                 : cancelMA.containsMouse ? Qt.rgba(0.937,0.325,0.314,0.15)
                                                 : "transparent"
                                            border.color: cancelMA.containsMouse ? "#ef5350" : Theme.border
                                            border.width: 1

                                            Behavior on color { ColorAnimation { duration: 100 } }
                                            Behavior on border.color { ColorAnimation { duration: 100 } }

                                            Text {
                                                anchors.centerIn: parent
                                                text: "撤单"
                                                color: cancelMA.containsMouse ? "#ef5350" : Theme.faint
                                                font.pixelSize: 10
                                                font.weight: Font.DemiBold

                                                Behavior on color { ColorAnimation { duration: 100 } }
                                            }

                                            MouseArea {
                                                id: cancelMA
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: ordersModel.remove(ordRow.index)
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    anchors { bottom: parent.bottom; left: parent.left; right: parent.right; leftMargin: 8; rightMargin: 8 }
                                    height: 1; color: Theme.line; opacity: 0.4
                                    visible: ordRow.index < ordersModel.count - 1
                                }
                            }

                            // empty state
                            Item {
                                anchors.fill: parent
                                visible: ordersModel.count === 0

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 6
                                    Text {
                                        text: "暂无委托"
                                        color: Theme.faint
                                        font.pixelSize: 13
                                        Layout.alignment: Qt.AlignHCenter
                                    }
                                    Text {
                                        text: "提交订单后将在此显示"
                                        color: Theme.faint
                                        font.pixelSize: 11
                                        Layout.alignment: Qt.AlignHCenter
                                    }
                                }
                            }
                        }
                    }
                }

                // ── Trade Fills (right side) ─────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 224
                    radius: Theme.radiusLarge
                    color: Theme.surface
                    border.color: Theme.line
                    clip: true

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 10

                        RowLayout {
                            spacing: 7
                            Rectangle { width: 3; height: 13; radius: 1.5; color: "#ab47bc" }
                            Text {
                                text: "成交记录"
                                color: Theme.text
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                            }
                        }

                        ListView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            model: historyModel
                            spacing: 0
                            clip: true

                            delegate: Rectangle {
                                id: rFillRow
                                required property int    index
                                required property string time
                                required property string symbol
                                required property string name
                                required property string side
                                required property int    qty
                                required property real   fillPrice

                                width: ListView.view.width
                                height: 34
                                color: rFillMA.containsMouse ? Theme.panel3 : "transparent"
                                Behavior on color { ColorAnimation { duration: 100 } }

                                MouseArea { id: rFillMA; anchors.fill: parent; hoverEnabled: true }

                                RowLayout {
                                    anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                                    spacing: 6

                                    Text {
                                        text: rFillRow.time
                                        color: Theme.muted
                                        font.pixelSize: 11
                                        font.family: "Menlo, monospace"
                                        Layout.preferredWidth: 58
                                    }
                                    Text {
                                        text: rFillRow.symbol
                                        color: Theme.text
                                        font.pixelSize: 12
                                        font.weight: Font.Medium
                                    }
                                    Item { Layout.fillWidth: true }
                                    Text {
                                        text: rFillRow.side
                                        color: rFillRow.side === "买入" ? "#26a69a" : "#ef5350"
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                    }
                                    Text {
                                        text: rFillRow.qty.toLocaleString()
                                        color: Theme.muted
                                        font.pixelSize: 11
                                    }
                                    Text {
                                        text: "@" + rFillRow.fillPrice.toFixed(2)
                                        color: Theme.text
                                        font.pixelSize: 11
                                        font.weight: Font.Medium
                                    }
                                }

                                Rectangle {
                                    anchors { bottom: parent.bottom; left: parent.left; right: parent.right; leftMargin: 8; rightMargin: 8 }
                                    height: 1; color: Theme.line; opacity: 0.35
                                    visible: rFillRow.index < historyModel.count - 1
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    component DarkComboBox: ComboBox {
        id: _cb
        implicitHeight: 42

        contentItem: Text {
            leftPadding: 12
            rightPadding: 28
            text: _cb.displayText
            color: Theme.text
            font.pixelSize: 14
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        background: Rectangle {
            radius: 11
            color: _cb.pressed ? Theme.panel3 : _cb.hovered ? Theme.panel3 : Theme.panel2
            border.color: _cb.pressed ? Theme.primary : Theme.border

            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }
        }

        indicator: Text {
            x: _cb.width - width - 10
            y: (_cb.height - height) / 2
            text: "⌄"
            color: Theme.muted
            font.pixelSize: 14
        }

        popup: Popup {
            y: _cb.height + 4
            width: _cb.width
            padding: 4

            background: Rectangle {
                radius: 11
                color: Theme.surface
                border.color: Theme.border
            }

            contentItem: ListView {
                clip: true
                implicitHeight: contentHeight
                model: _cb.delegateModel
                currentIndex: _cb.highlightedIndex
                boundsBehavior: Flickable.StopAtBounds
            }
        }

        delegate: ItemDelegate {
            id: _del
            required property var modelData
            required property int index
            width: _cb.popup.width - 8
            height: 36

            contentItem: Text {
                leftPadding: 12
                text: _del.modelData
                color: _del.highlighted ? Theme.text : Theme.muted
                font.pixelSize: 14
                verticalAlignment: Text.AlignVCenter
            }

            highlighted: _cb.highlightedIndex === _del.index

            background: Rectangle {
                radius: 8
                color: _del.highlighted ? Theme.panel3 : "transparent"
                Behavior on color { ColorAnimation { duration: 120 } }
            }
        }
    }
}
