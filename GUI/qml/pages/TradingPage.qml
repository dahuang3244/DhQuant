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

    // ── auto-rebalance timer state ───────────────────────────────────────
    property int  rebalanceIntervalSec: 30 * 60
    property int  rebalanceCountdown:   30 * 60
    property int  rebalanceCycle:       0

    function countdownText() {
        var m = Math.floor(rebalanceCountdown / 60)
        var s = rebalanceCountdown % 60
        return m + "分" + (s < 10 ? "0" : "") + s + "秒后"
    }

    Timer {
        id: countdownTick
        interval: 1000
        repeat: true
        running: root.autoTrading && root.connected
        onTriggered: {
            if (root.rebalanceCountdown > 0) {
                root.rebalanceCountdown -= 1
            } else {
                root.rebalanceCycle += 1
                root.executeAutoRebalance()
                root.rebalanceCountdown = root.rebalanceIntervalSec
            }
        }
    }

    // ── account summary ──────────────────────────────────────────────────
    property real equity:        1234567.89
    property real available:      456789.12
    property real unrealizedPnl:   23456.78
    property real dailyPnl:         8234.56
    property real marginRatio:        62.9

    // ── order form state ─────────────────────────────────────────────────
    property string orderSide:   "buy"
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
        ListElement { orderId: "ORD-2847"; symbol: "600036"; name: "招商银行"; side: "买入"; qty: 500;  price: 43.00;  status: "待成交";  statusDetail: "" }
        ListElement { orderId: "ORD-2848"; symbol: "000858"; name: "五粮液";   side: "买入"; qty: 200;  price: 170.00; status: "部分成交"; statusDetail: "100/200" }
        ListElement { orderId: "ORD-2849"; symbol: "002475"; name: "立讯精密"; side: "卖出"; qty: 1000; price: 27.50;  status: "待成交";  statusDetail: "" }
    }

    // ── trade history ─────────────────────────────────────────────────────
    ListModel {
        id: historyModel
        ListElement { time: "10:23:45"; symbol: "600036"; name: "招商银行"; side: "买入"; qty: 500;  fillPrice: 43.12;   amount: 21560  }
        ListElement { time: "09:45:12"; symbol: "000858"; name: "五粮液";   side: "买入"; qty: 300;  fillPrice: 169.50;  amount: 50850  }
        ListElement { time: "09:31:08"; symbol: "600519"; name: "贵州茅台"; side: "买入"; qty: 100;  fillPrice: 1685.00; amount: 168500 }
        ListElement { time: "09:30:55"; symbol: "002475"; name: "立讯精密"; side: "卖出"; qty: 1000; fillPrice: 28.45;   amount: 28450  }
        ListElement { time: "昨日";     symbol: "002475"; name: "立讯精密"; side: "卖出"; qty: 500;  fillPrice: 28.90;   amount: 14450  }
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
        ListElement { time: "14:30:05"; level: "EXEC"; message: "自动调仓已启动，定时器运行中" }
    }

    // ── helpers ───────────────────────────────────────────────────────────
    function fmtMoney(v) {
        var s = v.toFixed(2)
        var parts = s.split(".")
        parts[0] = parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, ",")
        return "¥" + parts.join(".")
    }
    function fmtPnl(v) { return (v >= 0 ? "+" : "") + fmtMoney(v) }
    function pnlColor(v) { return v >= 0 ? "#4caf50" : "#ef5350" }
    function signalColor(s) {
        if (s === "加仓") return "#26a69a"
        if (s === "减仓") return "#ef5350"
        if (s === "持有") return Theme.primary
        return Theme.warning
    }
    function nowTimeStr() {
        var d = new Date()
        var h = d.getHours(), m = d.getMinutes(), s = d.getSeconds()
        return (h<10?"0":"")+h+":"+(m<10?"0":"")+m+":"+(s<10?"0":"")+s
    }

    function executeAutoRebalance() {
        if (!connected || !autoTrading || riskLocked) return
        var t = nowTimeStr()
        ordersModel.append({ orderId: "AUTO-"+(7300+ordersModel.count), symbol: "600036", name: "招商银行", side: "买入",  qty: 800,  price: 43.20, status: "待成交", statusDetail: "策略调仓" })
        ordersModel.append({ orderId: "AUTO-"+(7301+ordersModel.count), symbol: "002475", name: "立讯精密", side: "卖出",  qty: 1200, price: 27.80, status: "待成交", statusDetail: "策略调仓" })
        automationLogModel.insert(0, { time: t, level: "EXEC", message: "已根据目标仓位生成自动委托（第 " + rebalanceCycle + " 轮）" })
    }

    // ── page-level state ─────────────────────────────────────────────────
    property int rightTab: 0   // 0=委托  1=成交

    // ═══════════════════════════════════════════════════════════════════════
    // ROOT LAYOUT
    // ═══════════════════════════════════════════════════════════════════════
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12

        // ══ HEADER ════════════════════════════════════════════════════════
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 72
            radius: Theme.radiusLarge
            color: Theme.surface
            border.color: Theme.line
            clip: true

            Rectangle {
                width: 4
                anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                color: "#26a69a"
            }

            RowLayout {
                anchors { fill: parent; leftMargin: 18; rightMargin: 16; topMargin: 10; bottomMargin: 10 }
                spacing: 14

                // Title
                ColumnLayout {
                    spacing: 2
                    Layout.alignment: Qt.AlignVCenter
                    Text { text: "账户持仓"; color: Theme.text; font.pixelSize: 17; font.weight: Font.DemiBold }
                    Text {
                        text: root.connected
                              ? (root.autoTrading ? "策略运行中 · " + root.countdownText() + "调仓" : "已连接 · 自动交易暂停")
                              : "未连接"
                        color: root.connected && root.autoTrading ? "#4caf50" : Theme.muted
                        font.pixelSize: 11
                    }
                }

                // Strategy
                Column { spacing: 3; Layout.alignment: Qt.AlignVCenter
                    Text { text: "STRATEGY"; color: Theme.faint; font.pixelSize: 9; font.letterSpacing: 1.0 }
                    DarkComboBox { width: 158; height: 30; model: ["MACD金叉-做多策略","多因子轮动","低波动防御","AI日内择时"]; currentIndex: model.indexOf(root.selectedStrategy); onActivated: root.selectedStrategy = currentText }
                }
                Column { spacing: 3; Layout.alignment: Qt.AlignVCenter
                    Text { text: "BROKER"; color: Theme.faint; font.pixelSize: 9; font.letterSpacing: 1.0 }
                    DarkComboBox { width: 118; height: 30; model: ["ChinaBroker","CryptoGateway","UsBroker","Mock"]; currentIndex: model.indexOf(root.broker); onActivated: root.broker = currentText }
                }
                Column { spacing: 3; Layout.alignment: Qt.AlignVCenter
                    Text { text: "ACCOUNT"; color: Theme.faint; font.pixelSize: 9; font.letterSpacing: 1.0 }
                    DarkComboBox { width: 100; height: 30; model: ["DQ-001","DQ-002","模拟账户"]; currentIndex: model.indexOf(root.accountId); onActivated: root.accountId = currentText }
                }

                Item { Layout.fillWidth: true }

                RowLayout {
                    spacing: 8; Layout.alignment: Qt.AlignVCenter

                    // Pause/resume strategy
                    Rectangle {
                        width: 82; height: 30; radius: Theme.radius
                        color: autoMA.pressed ? (root.autoTrading ? Qt.rgba(0.937,0.325,0.314,0.25) : Qt.rgba(0.149,0.651,0.604,0.25))
                             : autoMA.containsMouse ? (root.autoTrading ? Qt.rgba(0.937,0.325,0.314,0.14) : Qt.rgba(0.149,0.651,0.604,0.14))
                             : Theme.panel2
                        border.color: root.autoTrading ? "#ef5350" : "#26a69a"; border.width: 1
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Text { anchors.centerIn: parent; text: root.autoTrading ? "暂停策略" : "启动策略"; color: root.autoTrading ? "#ef5350" : "#26a69a"; font.pixelSize: 12; font.weight: Font.Medium }
                        MouseArea { id: autoMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.autoTrading = !root.autoTrading }
                    }

                    // Connected pill
                    Rectangle {
                        width: _pillRow.implicitWidth + 16; height: 24; radius: 12
                        color: root.connected ? Qt.rgba(0.298,0.686,0.314,0.12) : Qt.rgba(0.937,0.325,0.314,0.12)
                        border.color: root.connected ? "#4caf50" : "#ef5350"; border.width: 1
                        RowLayout { id: _pillRow; anchors.centerIn: parent; spacing: 5
                            Rectangle {
                                width: 6; height: 6; radius: 3; color: root.connected ? "#4caf50" : "#ef5350"
                                SequentialAnimation on opacity {
                                    running: root.connected
                                    loops: Animation.Infinite
                                    NumberAnimation { to: 0.3; duration: 900 }
                                    NumberAnimation { to: 1.0; duration: 900 }
                                }
                            }
                            Text { text: root.connected ? "CONNECTED" : "DISCONNECTED"; color: root.connected ? "#4caf50" : "#ef5350"; font.pixelSize: 10; font.weight: Font.DemiBold; font.letterSpacing: 0.7 }
                        }
                    }

                    // Connect/disconnect
                    Rectangle {
                        width: 82; height: 30; radius: Theme.radius
                        color: connMA.pressed ? (root.connected ? Qt.rgba(0.937,0.325,0.314,0.25) : Qt.rgba(0.149,0.651,0.604,0.25))
                             : connMA.containsMouse ? (root.connected ? Qt.rgba(0.937,0.325,0.314,0.14) : Qt.rgba(0.149,0.651,0.604,0.14))
                             : Theme.panel2
                        border.color: root.connected ? "#ef5350" : "#26a69a"; border.width: 1
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Text { anchors.centerIn: parent; text: root.connected ? "断开连接" : "建立连接"; color: root.connected ? "#ef5350" : "#26a69a"; font.pixelSize: 12; font.weight: Font.Medium }
                        MouseArea { id: connMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.connected = !root.connected }
                    }
                }
            }
        }

        // ══ BODY ══════════════════════════════════════════════════════════
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            // ── LEFT: 账户概览 + 人工干预 (ScrollView) ─────────────────────
            Rectangle {
                Layout.preferredWidth: 246
                Layout.fillHeight: true
                radius: Theme.radiusLarge
                color: Theme.surface
                border.color: Theme.line
                clip: true

                ScrollView {
                    anchors.fill: parent
                    contentWidth: availableWidth
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                    ScrollBar.vertical.policy: ScrollBar.AsNeeded

                    ColumnLayout {
                        width: parent.width
                        spacing: 0

                        // ── 账户概览 ─────────────────────────────────────
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.topMargin: 14; Layout.leftMargin: 14; Layout.rightMargin: 14
                            spacing: 8

                            RowLayout { spacing: 6
                                Rectangle { width: 3; height: 13; radius: 1.5; color: "#26a69a" }
                                Text { text: "账户概览"; color: Theme.text; font.pixelSize: 13; font.weight: Font.DemiBold }
                            }

                            // Total equity
                            Rectangle {
                                Layout.fillWidth: true; height: 52; radius: Theme.radius
                                color: Theme.panel2; border.color: Theme.border
                                ColumnLayout {
                                    anchors { fill: parent; margins: 10 }
                                    spacing: 1
                                    Text { text: "总权益"; color: Theme.faint; font.pixelSize: 10; font.letterSpacing: 1.0 }
                                    Text { text: root.fmtMoney(root.equity); color: Theme.text; font.pixelSize: 19; font.weight: Font.DemiBold }
                                }
                            }

                            // 2×2 grid
                            GridLayout {
                                Layout.fillWidth: true; columns: 2; rowSpacing: 6; columnSpacing: 6
                                Repeater {
                                    model: [
                                        { label: "可用资金", value: root.fmtMoney(root.available),     colored: false },
                                        { label: "浮动盈亏", value: root.fmtPnl(root.unrealizedPnl),   colored: true,  raw: root.unrealizedPnl },
                                        { label: "今日盈亏", value: root.fmtPnl(root.dailyPnl),        colored: true,  raw: root.dailyPnl },
                                        { label: "保证金率", value: root.marginRatio.toFixed(1) + "%", colored: false }
                                    ]
                                    Rectangle {
                                        required property var modelData
                                        Layout.fillWidth: true; height: 42; radius: Theme.radius
                                        color: Theme.panel2; border.color: Theme.border
                                        ColumnLayout {
                                            anchors { fill: parent; margins: 8 }
                                            spacing: 1
                                            Text { text: modelData.label; color: Theme.faint; font.pixelSize: 10; font.letterSpacing: 0.8 }
                                            Text { text: modelData.value; color: modelData.colored ? root.pnlColor(modelData.raw) : Theme.text; font.pixelSize: 12; font.weight: Font.DemiBold }
                                        }
                                    }
                                }
                            }
                        }

                        // Divider
                        Rectangle { Layout.fillWidth: true; Layout.topMargin: 12; Layout.bottomMargin: 12; Layout.leftMargin: 14; Layout.rightMargin: 14; height: 1; color: Theme.line }

                        // ── 人工干预 ─────────────────────────────────────
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: 14; Layout.rightMargin: 14; Layout.bottomMargin: 14
                            spacing: 9

                            RowLayout { spacing: 6
                                Rectangle { width: 3; height: 13; radius: 1.5; color: Theme.warning }
                                Text { text: "人工干预"; color: Theme.text; font.pixelSize: 13; font.weight: Font.DemiBold }
                                Item { Layout.fillWidth: true }
                                Text { text: "兜底"; color: Theme.warning; font.pixelSize: 11; font.weight: Font.DemiBold }
                            }

                            // Symbol
                            Column { Layout.fillWidth: true; spacing: 4
                                Text { text: "SYMBOL"; color: Theme.faint; font.pixelSize: 10; font.letterSpacing: 1.0 }
                                Rectangle {
                                    width: parent.width; height: 32; radius: Theme.radius
                                    color: Theme.panel2; border.color: symField.activeFocus ? Theme.primary : Theme.border
                                    Behavior on border.color { ColorAnimation { duration: 120 } }
                                    TextInput {
                                        id: symField
                                        anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                                        verticalAlignment: TextInput.AlignVCenter
                                        color: Theme.text; font.pixelSize: 13
                                        selectionColor: Qt.rgba(0.149,0.651,0.604,0.35)
                                        text: root.orderSymbol; onTextChanged: root.orderSymbol = text
                                        Text { anchors.fill: parent; verticalAlignment: Text.AlignVCenter; text: "代码 / 名称"; color: Theme.faint; font.pixelSize: 13; visible: symField.text.length === 0 && !symField.activeFocus }
                                    }
                                }
                            }

                            // Buy / Sell toggle
                            RowLayout { Layout.fillWidth: true; spacing: 6
                                Rectangle {
                                    Layout.fillWidth: true; height: 32; radius: Theme.radius
                                    color: root.orderSide === "buy" ? Qt.rgba(0.149,0.651,0.604,0.22) : Theme.panel2
                                    border.color: root.orderSide === "buy" ? "#26a69a" : Theme.border
                                    border.width: root.orderSide === "buy" ? 1.5 : 1
                                    Behavior on color { ColorAnimation { duration: 140 } }
                                    Text { anchors.centerIn: parent; text: "买 入"; color: root.orderSide === "buy" ? "#26a69a" : Theme.muted; font.pixelSize: 13; font.weight: root.orderSide === "buy" ? Font.DemiBold : Font.Normal }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.orderSide = "buy" }
                                }
                                Rectangle {
                                    Layout.fillWidth: true; height: 32; radius: Theme.radius
                                    color: root.orderSide === "sell" ? Qt.rgba(0.937,0.325,0.314,0.22) : Theme.panel2
                                    border.color: root.orderSide === "sell" ? "#ef5350" : Theme.border
                                    border.width: root.orderSide === "sell" ? 1.5 : 1
                                    Behavior on color { ColorAnimation { duration: 140 } }
                                    Text { anchors.centerIn: parent; text: "卖 出"; color: root.orderSide === "sell" ? "#ef5350" : Theme.muted; font.pixelSize: 13; font.weight: root.orderSide === "sell" ? Font.DemiBold : Font.Normal }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.orderSide = "sell" }
                                }
                            }

                            // Order type
                            Column { Layout.fillWidth: true; spacing: 4
                                Text { text: "委托类型"; color: Theme.faint; font.pixelSize: 10; font.letterSpacing: 1.0 }
                                DarkComboBox { width: parent.width; height: 32; model: ["限价","市价","止损限价","止盈限价"]; currentIndex: model.indexOf(root.orderType); onActivated: root.orderType = currentText }
                            }

                            // Price (hidden for market order)
                            Column { Layout.fillWidth: true; spacing: 4; visible: root.orderType !== "市价"
                                Text { text: "委托价格"; color: Theme.faint; font.pixelSize: 10; font.letterSpacing: 1.0 }
                                Rectangle {
                                    width: parent.width; height: 32; radius: Theme.radius
                                    color: Theme.panel2; border.color: priceField.activeFocus ? Theme.primary : Theme.border
                                    Behavior on border.color { ColorAnimation { duration: 120 } }
                                    RowLayout {
                                        anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                                        spacing: 4
                                        TextInput {
                                            id: priceField; Layout.fillWidth: true
                                            verticalAlignment: TextInput.AlignVCenter; color: Theme.text; font.pixelSize: 13
                                            selectionColor: Qt.rgba(0.149,0.651,0.604,0.35)
                                            text: root.orderPrice; onTextChanged: root.orderPrice = text
                                            validator: RegularExpressionValidator { regularExpression: /[0-9]*\.?[0-9]*/ }
                                            Text { anchors.fill: parent; verticalAlignment: Text.AlignVCenter; text: "0.00"; color: Theme.faint; font.pixelSize: 13; visible: priceField.text.length === 0 && !priceField.activeFocus }
                                        }
                                        Text { text: "元"; color: Theme.muted; font.pixelSize: 12 }
                                    }
                                }
                            }

                            // Qty
                            Column { Layout.fillWidth: true; spacing: 4
                                Text { text: "委托数量"; color: Theme.faint; font.pixelSize: 10; font.letterSpacing: 1.0 }
                                Rectangle {
                                    width: parent.width; height: 32; radius: Theme.radius
                                    color: Theme.panel2; border.color: qtyField.activeFocus ? Theme.primary : Theme.border
                                    Behavior on border.color { ColorAnimation { duration: 120 } }
                                    RowLayout {
                                        anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                                        spacing: 4
                                        TextInput {
                                            id: qtyField; Layout.fillWidth: true
                                            verticalAlignment: TextInput.AlignVCenter; color: Theme.text; font.pixelSize: 13
                                            selectionColor: Qt.rgba(0.149,0.651,0.604,0.35)
                                            text: root.orderQty; onTextChanged: root.orderQty = text
                                            validator: RegularExpressionValidator { regularExpression: /[0-9]*/ }
                                            Text { anchors.fill: parent; verticalAlignment: Text.AlignVCenter; text: "0"; color: Theme.faint; font.pixelSize: 13; visible: qtyField.text.length === 0 && !qtyField.activeFocus }
                                        }
                                        Text { text: "股"; color: Theme.muted; font.pixelSize: 12 }
                                    }
                                }
                            }

                            // Estimated amount
                            RowLayout { Layout.fillWidth: true
                                Text { text: "预估金额"; color: Theme.faint; font.pixelSize: 11 }
                                Item { Layout.fillWidth: true }
                                Text { text: root.fmtMoney(root.estimatedAmt); color: root.estimatedAmt > 0 ? Theme.text : Theme.muted; font.pixelSize: 13; font.weight: Font.DemiBold }
                            }

                            // Submit
                            Rectangle {
                                Layout.fillWidth: true; height: 36; radius: Theme.radius
                                color: {
                                    if (!root.connected) return Theme.panel2
                                    if (submitMA.pressed)   return root.orderSide === "buy" ? Qt.rgba(0.149,0.651,0.604,0.60) : Qt.rgba(0.937,0.325,0.314,0.60)
                                    if (submitMA.containsMouse) return root.orderSide === "buy" ? Qt.rgba(0.149,0.651,0.604,0.40) : Qt.rgba(0.937,0.325,0.314,0.40)
                                    return root.orderSide === "buy" ? Qt.rgba(0.149,0.651,0.604,0.28) : Qt.rgba(0.937,0.325,0.314,0.28)
                                }
                                border.color: root.connected ? (root.orderSide === "buy" ? "#26a69a" : "#ef5350") : Theme.border; border.width: 1
                                Behavior on color { ColorAnimation { duration: 130 } }
                                Text {
                                    anchors.centerIn: parent
                                    text: !root.connected ? "请先连接账户" : (root.orderSide === "buy" ? "买 入 下 单" : "卖 出 下 单")
                                    color: root.connected ? (root.orderSide === "buy" ? "#26a69a" : "#ef5350") : Theme.faint
                                    font.pixelSize: 13; font.weight: Font.DemiBold; font.letterSpacing: 1.4
                                }
                                MouseArea {
                                    id: submitMA; anchors.fill: parent; hoverEnabled: true
                                    enabled: root.connected; cursorShape: root.connected ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    onClicked: {
                                        if (!root.connected) return
                                        var sym = root.orderSymbol || "------"
                                        ordersModel.append({ orderId: "ORD-"+(2850+ordersModel.count), symbol: sym, name: sym, side: root.orderSide === "buy" ? "买入" : "卖出", qty: parseInt(root.orderQty)||0, price: parseFloat(root.orderPrice)||0, status: "待成交", statusDetail: "" })
                                        root.orderSymbol=""; root.orderPrice=""; root.orderQty=""
                                        symField.text=""; priceField.text=""; qtyField.text=""
                                    }
                                }
                            }

                            // Divider
                            Rectangle { Layout.fillWidth: true; Layout.topMargin: 2; Layout.bottomMargin: 2; height: 1; color: Theme.line }

                            // Rebalance interval chips
                            RowLayout { Layout.fillWidth: true; spacing: 5
                                Text { text: "间隔"; color: Theme.faint; font.pixelSize: 10 }
                                Repeater {
                                    model: [{ label:"5分", sec:300 },{ label:"15分", sec:900 },{ label:"30分", sec:1800 },{ label:"1时", sec:3600 }]
                                    delegate: Rectangle {
                                        required property var modelData
                                        height: 20; radius: 10; width: _iLabel.implicitWidth + 12
                                        color: root.rebalanceIntervalSec === modelData.sec ? Qt.rgba(0.149,0.651,0.604,0.18) : Theme.panel2
                                        border.color: root.rebalanceIntervalSec === modelData.sec ? "#26a69a" : Theme.border
                                        Behavior on color { ColorAnimation { duration: 120 } }
                                        Text { id: _iLabel; anchors.centerIn: parent; text: modelData.label; color: root.rebalanceIntervalSec === modelData.sec ? "#26a69a" : Theme.muted; font.pixelSize: 10; font.weight: Font.DemiBold }
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { root.rebalanceIntervalSec = modelData.sec; root.rebalanceCountdown = modelData.sec } }
                                    }
                                }
                            }

                            // Execute now
                            Rectangle {
                                Layout.fillWidth: true; height: 34; radius: Theme.radius
                                color: execMA.pressed ? Qt.rgba(0.149,0.651,0.604,0.35) : execMA.containsMouse ? Qt.rgba(0.149,0.651,0.604,0.20) : Qt.rgba(0.149,0.651,0.604,0.10)
                                border.color: root.connected && root.autoTrading && !root.riskLocked ? "#26a69a" : Theme.border
                                opacity: root.connected && root.autoTrading && !root.riskLocked ? 1.0 : 0.45
                                Behavior on color { ColorAnimation { duration: 120 } }
                                RowLayout { anchors.centerIn: parent; spacing: 5
                                    Text { text: "▶"; color: "#26a69a"; font.pixelSize: 10 }
                                    Text { text: "立即执行调仓"; color: "#26a69a"; font.pixelSize: 12; font.weight: Font.DemiBold }
                                }
                                MouseArea {
                                    id: execMA; anchors.fill: parent; hoverEnabled: true
                                    enabled: root.connected && root.autoTrading && !root.riskLocked
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: { root.rebalanceCycle += 1; root.executeAutoRebalance(); root.rebalanceCountdown = root.rebalanceIntervalSec }
                                }
                            }
                        }
                    }
                }
            }

            // ── CENTER: 持仓管理 + 策略引擎状态 ──────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 12

                // Positions table
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Theme.radiusLarge
                    color: Theme.surface
                    border.color: Theme.line
                    clip: true

                    ColumnLayout {
                        anchors { fill: parent; margins: 14 }
                        spacing: 8

                        RowLayout { spacing: 6
                            Rectangle { width: 3; height: 13; radius: 1.5; color: "#26a69a" }
                            Text { text: "持仓管理"; color: Theme.text; font.pixelSize: 13; font.weight: Font.DemiBold }
                            Item { Layout.fillWidth: true }
                            Text { text: positionsModel.count + " 个持仓"; color: Theme.muted; font.pixelSize: 11 }
                        }

                        // Table header
                        Rectangle {
                            Layout.fillWidth: true; height: 26; radius: 4; color: Theme.panel2
                            RowLayout {
                                anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                                spacing: 0
                                Repeater {
                                    model: [
                                        { t: "代码/名称", w: 0,   fill: true  },
                                        { t: "方向",     w: 40,  fill: false },
                                        { t: "持仓量",   w: 64,  fill: false },
                                        { t: "成本价",   w: 70,  fill: false },
                                        { t: "现价",     w: 70,  fill: false },
                                        { t: "浮盈亏",   w: 88,  fill: false },
                                        { t: "盈亏%",    w: 64,  fill: false },
                                        { t: "",         w: 56,  fill: false }
                                    ]
                                    Item {
                                        required property var modelData
                                        Layout.fillWidth: modelData.fill
                                        Layout.preferredWidth: modelData.fill ? -1 : modelData.w
                                        Text { anchors.fill: parent; text: modelData.t; color: Theme.faint; font.pixelSize: 10; font.letterSpacing: 0.7; verticalAlignment: Text.AlignVCenter; horizontalAlignment: modelData.fill ? Text.AlignLeft : Text.AlignRight }
                                    }
                                }
                            }
                        }

                        // Position rows
                        ListView {
                            Layout.fillWidth: true; Layout.fillHeight: true
                            model: positionsModel; spacing: 2; clip: true
                            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

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

                                width: ListView.view.width; height: 40; radius: 6
                                color: posRowMA.containsMouse ? Theme.panel3 : "transparent"
                                Behavior on color { ColorAnimation { duration: 100 } }
                                MouseArea { id: posRowMA; anchors.fill: parent; hoverEnabled: true }

                                RowLayout {
                                    anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                                    spacing: 0
                                    ColumnLayout { Layout.fillWidth: true; spacing: 1
                                        Text { text: posRow.symbol; color: Theme.text; font.pixelSize: 13; font.weight: Font.Medium }
                                        Text { text: posRow.name; color: Theme.muted; font.pixelSize: 11 }
                                    }
                                    Item { Layout.preferredWidth: 40; Layout.fillHeight: true
                                        Rectangle {
                                            width: 26; height: 17; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; radius: 3
                                            color: posRow.direction === "多" ? Qt.rgba(0.149,0.651,0.604,0.18) : Qt.rgba(0.937,0.325,0.314,0.18)
                                            border.color: posRow.direction === "多" ? "#26a69a" : "#ef5350"; border.width: 1
                                            Text { anchors.centerIn: parent; text: posRow.direction; color: posRow.direction === "多" ? "#26a69a" : "#ef5350"; font.pixelSize: 11; font.weight: Font.DemiBold }
                                        }
                                    }
                                    Text { Layout.preferredWidth: 64; horizontalAlignment: Text.AlignRight; text: posRow.qty.toLocaleString(); color: Theme.text; font.pixelSize: 13 }
                                    Text { Layout.preferredWidth: 70; horizontalAlignment: Text.AlignRight; text: posRow.cost.toFixed(2); color: Theme.muted; font.pixelSize: 13 }
                                    Text { Layout.preferredWidth: 70; horizontalAlignment: Text.AlignRight; text: posRow.price.toFixed(2); color: Theme.text; font.pixelSize: 13; font.weight: Font.Medium }
                                    Text { Layout.preferredWidth: 88; horizontalAlignment: Text.AlignRight; text: root.fmtPnl(posRow.pnl); color: root.pnlColor(posRow.pnl); font.pixelSize: 13; font.weight: Font.DemiBold }
                                    Text { Layout.preferredWidth: 64; horizontalAlignment: Text.AlignRight; text: (posRow.pnlPct >= 0 ? "+" : "") + posRow.pnlPct.toFixed(2) + "%"; color: root.pnlColor(posRow.pnlPct); font.pixelSize: 12 }
                                    Item { Layout.preferredWidth: 56; Layout.fillHeight: true
                                        Rectangle {
                                            width: 44; height: 22; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; radius: 4
                                            visible: posRowMA.containsMouse || closePosMA.containsMouse
                                            color: closePosMA.pressed ? Qt.rgba(0.937,0.325,0.314,0.30) : Qt.rgba(0.937,0.325,0.314,0.14)
                                            border.color: "#ef5350"; border.width: 1
                                            Text { anchors.centerIn: parent; text: "平仓"; color: "#ef5350"; font.pixelSize: 11; font.weight: Font.DemiBold }
                                            MouseArea { id: closePosMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: positionsModel.remove(posRow.index) }
                                        }
                                    }
                                }
                                Rectangle {
                                    anchors { bottom: parent.bottom; left: parent.left; right: parent.right; leftMargin: 10; rightMargin: 10 }
                                    height: 1; color: Theme.line; opacity: 0.45; visible: posRow.index < positionsModel.count - 1
                                }
                            }

                            Item { anchors.fill: parent; visible: positionsModel.count === 0
                                ColumnLayout { anchors.centerIn: parent; spacing: 4
                                    Text { text: "暂无持仓"; color: Theme.faint; font.pixelSize: 13; Layout.alignment: Qt.AlignHCenter }
                                    Text { text: "通过左侧下单或策略自动建仓"; color: Theme.faint; font.pixelSize: 11; Layout.alignment: Qt.AlignHCenter }
                                }
                            }
                        }
                    }
                }

                // Automation status bar
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 90
                    radius: Theme.radiusLarge
                    color: Theme.surface
                    border.color: Theme.line
                    clip: true

                    RowLayout {
                        anchors { fill: parent; margins: 12 }
                        spacing: 14

                        // Strategy + status
                        ColumnLayout { spacing: 3; Layout.alignment: Qt.AlignVCenter
                            RowLayout { spacing: 6
                                Rectangle { width: 3; height: 12; radius: 1.5; color: root.autoTrading ? "#26a69a" : Theme.warning }
                                Text { text: "策略引擎"; color: Theme.text; font.pixelSize: 12; font.weight: Font.DemiBold }
                                Rectangle {
                                    width: _sLabel.implicitWidth + 10; height: 16; radius: 8
                                    color: root.autoTrading ? Qt.rgba(0.149,0.651,0.604,0.14) : Qt.rgba(0.98,0.66,0.145,0.14)
                                    border.color: root.autoTrading ? "#26a69a" : Theme.warning; border.width: 1
                                    Text { id: _sLabel; anchors.centerIn: parent; text: root.autoTrading ? "RUNNING" : "PAUSED"; color: root.autoTrading ? "#26a69a" : Theme.warning; font.pixelSize: 9; font.weight: Font.DemiBold; font.letterSpacing: 0.6 }
                                }
                            }
                            Text { text: root.selectedStrategy; color: Theme.muted; font.pixelSize: 12; elide: Text.ElideRight; maximumLineCount: 1 }
                            Text { text: root.executionMode + " · 第 " + root.rebalanceCycle + " 轮"; color: Theme.faint; font.pixelSize: 10 }
                        }

                        Rectangle { width: 1; Layout.fillHeight: true; color: Theme.line; opacity: 0.6 }

                        // Countdown
                        ColumnLayout { spacing: 2; Layout.alignment: Qt.AlignVCenter
                            Text { text: "下次调仓"; color: Theme.faint; font.pixelSize: 10; font.letterSpacing: 0.7 }
                            Text { text: root.autoTrading && root.connected ? root.countdownText() : "已暂停"; color: root.autoTrading && root.connected ? "#26a69a" : Theme.warning; font.pixelSize: 15; font.weight: Font.DemiBold; font.family: "Menlo" }
                        }

                        Rectangle { width: 1; Layout.fillHeight: true; color: Theme.line; opacity: 0.6 }

                        // Risk checks
                        GridLayout { columns: 2; rowSpacing: 3; columnSpacing: 10
                            Repeater {
                                model: riskModel
                                RowLayout {
                                    required property string label
                                    required property string status
                                    spacing: 4
                                    Rectangle { width: 5; height: 5; radius: 2.5; color: status === "通过" ? "#4caf50" : "#ef5350" }
                                    Text { text: label; color: Theme.faint; font.pixelSize: 10 }
                                }
                            }
                        }

                        Item { Layout.fillWidth: true }
                    }
                }
            }

            // ── RIGHT: 委托/成交 + 策略信号 + 持仓权重 ───────────────────────
            ColumnLayout {
                Layout.preferredWidth: 310
                Layout.fillHeight: true
                spacing: 12

                // ── 委托 / 成交 tab panel ─────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 150
                    radius: Theme.radiusLarge
                    color: Theme.surface
                    border.color: Theme.line
                    clip: true

                    ColumnLayout {
                        anchors { fill: parent; margins: 14 }
                        spacing: 8

                        // Tab bar
                        RowLayout { Layout.fillWidth: true; spacing: 0

                            // Tab: 当前委托
                            Rectangle {
                                height: 28; radius: 6
                                width: _tabOrd.implicitWidth + 18
                                color: root.rightTab === 0 ? Qt.rgba(0.149,0.651,0.604,0.14) : "transparent"
                                border.color: root.rightTab === 0 ? "#26a69a" : "transparent"; border.width: 1
                                Behavior on color { ColorAnimation { duration: 120 } }
                                RowLayout { anchors.centerIn: parent; spacing: 5
                                    Rectangle { width: 3; height: 10; radius: 1.5; color: "#f9a825"; visible: root.rightTab === 0 }
                                    Text { id: _tabOrd; text: "当前委托 " + ordersModel.count; color: root.rightTab === 0 ? Theme.text : Theme.muted; font.pixelSize: 12; font.weight: root.rightTab === 0 ? Font.DemiBold : Font.Normal }
                                }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.rightTab = 0 }
                            }

                            Item { width: 6 }

                            // Tab: 成交记录
                            Rectangle {
                                height: 28; radius: 6
                                width: _tabHis.implicitWidth + 18
                                color: root.rightTab === 1 ? Qt.rgba(0.149,0.651,0.604,0.14) : "transparent"
                                border.color: root.rightTab === 1 ? "#26a69a" : "transparent"; border.width: 1
                                Behavior on color { ColorAnimation { duration: 120 } }
                                RowLayout { anchors.centerIn: parent; spacing: 5
                                    Rectangle { width: 3; height: 10; radius: 1.5; color: "#ab47bc"; visible: root.rightTab === 1 }
                                    Text { id: _tabHis; text: "成交记录 " + historyModel.count; color: root.rightTab === 1 ? Theme.text : Theme.muted; font.pixelSize: 12; font.weight: root.rightTab === 1 ? Font.DemiBold : Font.Normal }
                                }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.rightTab = 1 }
                            }

                            Item { Layout.fillWidth: true }

                            // Cancel all (orders tab only)
                            Text {
                                visible: root.rightTab === 0
                                text: "全部撤单"; color: ordersModel.count > 0 ? "#ef5350" : Theme.faint; font.pixelSize: 11
                                font.underline: _cancelAllMA.containsMouse
                                MouseArea { id: _cancelAllMA; anchors.fill: parent; hoverEnabled: true; enabled: ordersModel.count > 0; cursorShape: Qt.PointingHandCursor; onClicked: ordersModel.clear() }
                            }
                        }

                        // ── Orders list ───────────────────────────────────
                        Item {
                            Layout.fillWidth: true; Layout.fillHeight: true
                            visible: root.rightTab === 0

                            ColumnLayout { anchors.fill: parent; spacing: 6

                                // header
                                Rectangle { Layout.fillWidth: true; height: 24; radius: 4; color: Theme.panel2
                                    RowLayout {
                                        anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                                        spacing: 0
                                        Repeater {
                                            model: [{ t:"品种",w:0,fill:true },{ t:"方向",w:34,fill:false },{ t:"数量",w:42,fill:false },{ t:"价格",w:52,fill:false },{ t:"状态",w:58,fill:false },{ t:"",w:38,fill:false }]
                                            Item { required property var modelData; Layout.fillWidth: modelData.fill; Layout.preferredWidth: modelData.fill ? -1 : modelData.w
                                                Text { anchors.fill: parent; text: modelData.t; color: Theme.faint; font.pixelSize: 10; font.letterSpacing: 0.7; verticalAlignment: Text.AlignVCenter; horizontalAlignment: modelData.fill ? Text.AlignLeft : Text.AlignRight }
                                            }
                                        }
                                    }
                                }

                                ListView {
                                    Layout.fillWidth: true; Layout.fillHeight: true
                                    model: ordersModel; spacing: 2; clip: true
                                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                                    remove: Transition {
                                        NumberAnimation { property: "opacity"; to: 0; duration: 200 }
                                        NumberAnimation { property: "height"; to: 0; duration: 200 }
                                    }
                                    removeDisplaced: Transition { NumberAnimation { properties: "y"; duration: 180 } }

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

                                        width: ListView.view.width; height: 44; radius: 6
                                        color: ordRowMA.containsMouse ? Theme.panel3 : "transparent"
                                        Behavior on color { ColorAnimation { duration: 100 } }
                                        MouseArea { id: ordRowMA; anchors.fill: parent; hoverEnabled: true }

                                        RowLayout {
                                            anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                                            spacing: 0
                                            ColumnLayout { Layout.fillWidth: true; spacing: 1
                                                Text { text: ordRow.symbol + " " + ordRow.name; color: Theme.text; font.pixelSize: 12; font.weight: Font.Medium; elide: Text.ElideRight; Layout.fillWidth: true }
                                                Text { text: ordRow.orderId; color: Theme.faint; font.pixelSize: 10 }
                                            }
                                            Item { Layout.preferredWidth: 34; Layout.fillHeight: true
                                                Text { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; text: ordRow.side; color: ordRow.side === "买入" ? "#26a69a" : "#ef5350"; font.pixelSize: 12; font.weight: Font.DemiBold }
                                            }
                                            Text { Layout.preferredWidth: 42; horizontalAlignment: Text.AlignRight; text: ordRow.qty.toLocaleString(); color: Theme.text; font.pixelSize: 12 }
                                            Text { Layout.preferredWidth: 52; horizontalAlignment: Text.AlignRight; text: ordRow.price.toFixed(2); color: Theme.text; font.pixelSize: 12; font.weight: Font.Medium }
                                            Item { Layout.preferredWidth: 58; Layout.fillHeight: true
                                                ColumnLayout { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; spacing: 1
                                                    Text { text: ordRow.status; color: ordRow.status === "待成交" ? "#f9a825" : ordRow.status === "部分成交" ? Theme.primary : Theme.muted; font.pixelSize: 11; font.weight: Font.DemiBold; Layout.alignment: Qt.AlignRight }
                                                    Text { visible: ordRow.statusDetail.length > 0; text: ordRow.statusDetail; color: Theme.faint; font.pixelSize: 10; Layout.alignment: Qt.AlignRight }
                                                }
                                            }
                                            Item { Layout.preferredWidth: 38; Layout.fillHeight: true
                                                Rectangle {
                                                    width: 32; height: 20; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; radius: 4
                                                    color: cancelMA.pressed ? Qt.rgba(0.937,0.325,0.314,0.30) : cancelMA.containsMouse ? Qt.rgba(0.937,0.325,0.314,0.14) : "transparent"
                                                    border.color: cancelMA.containsMouse ? "#ef5350" : Theme.border; border.width: 1
                                                    Behavior on color { ColorAnimation { duration: 100 } }
                                                    Behavior on border.color { ColorAnimation { duration: 100 } }
                                                    Text { anchors.centerIn: parent; text: "撤单"; color: cancelMA.containsMouse ? "#ef5350" : Theme.faint; font.pixelSize: 10; font.weight: Font.DemiBold; Behavior on color { ColorAnimation { duration: 100 } } }
                                                    MouseArea { id: cancelMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: ordersModel.remove(ordRow.index) }
                                                }
                                            }
                                        }
                                        Rectangle {
                                            anchors { bottom: parent.bottom; left: parent.left; right: parent.right; leftMargin: 8; rightMargin: 8 }
                                            height: 1; color: Theme.line; opacity: 0.4; visible: ordRow.index < ordersModel.count - 1
                                        }
                                    }

                                    Item { anchors.fill: parent; visible: ordersModel.count === 0
                                        ColumnLayout { anchors.centerIn: parent; spacing: 4
                                            Text { text: "暂无委托"; color: Theme.faint; font.pixelSize: 13; Layout.alignment: Qt.AlignHCenter }
                                            Text { text: "提交订单后将在此显示"; color: Theme.faint; font.pixelSize: 11; Layout.alignment: Qt.AlignHCenter }
                                        }
                                    }
                                }
                            }
                        }

                        // ── Trade fills ───────────────────────────────────
                        Item {
                            Layout.fillWidth: true; Layout.fillHeight: true
                            visible: root.rightTab === 1

                            ListView {
                                anchors.fill: parent
                                model: historyModel; spacing: 0; clip: true
                                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                                delegate: Rectangle {
                                    id: fillRow
                                    required property int    index
                                    required property string time
                                    required property string symbol
                                    required property string name
                                    required property string side
                                    required property int    qty
                                    required property real   fillPrice
                                    required property int    amount

                                    width: ListView.view.width; height: 40
                                    color: fillMA.containsMouse ? Theme.panel3 : "transparent"
                                    Behavior on color { ColorAnimation { duration: 100 } }
                                    MouseArea { id: fillMA; anchors.fill: parent; hoverEnabled: true }

                                    RowLayout {
                                        anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                                        spacing: 6
                                        Text { text: fillRow.time; color: Theme.muted; font.pixelSize: 11; font.family: "Menlo, monospace"; Layout.preferredWidth: 56 }
                                        ColumnLayout { spacing: 0; Layout.fillWidth: true
                                            Text { text: fillRow.symbol; color: Theme.text; font.pixelSize: 12; font.weight: Font.Medium }
                                            Text { text: fillRow.name; color: Theme.muted; font.pixelSize: 10 }
                                        }
                                        Text { text: fillRow.side; color: fillRow.side === "买入" ? "#26a69a" : "#ef5350"; font.pixelSize: 11; font.weight: Font.DemiBold }
                                        Text { text: fillRow.qty.toLocaleString(); color: Theme.muted; font.pixelSize: 11 }
                                        Text { text: "@" + fillRow.fillPrice.toFixed(2); color: Theme.text; font.pixelSize: 11; font.weight: Font.Medium }
                                    }
                                    Rectangle {
                                        anchors { bottom: parent.bottom; left: parent.left; right: parent.right; leftMargin: 8; rightMargin: 8 }
                                        height: 1; color: Theme.line; opacity: 0.35; visible: fillRow.index < historyModel.count - 1
                                    }
                                }
                            }
                        }
                    }
                }

                // ── 策略信号 ─────────────────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 130
                    radius: Theme.radiusLarge
                    color: Theme.surface
                    border.color: Theme.line
                    clip: true

                    ColumnLayout {
                        anchors { fill: parent; margins: 14 }
                        spacing: 8

                        RowLayout { spacing: 6
                            Rectangle { width: 3; height: 13; radius: 1.5; color: Theme.primary }
                            Text { text: "策略信号"; color: Theme.text; font.pixelSize: 13; font.weight: Font.DemiBold }
                            Item { Layout.fillWidth: true }
                            Text { text: root.autoTrading ? "RUNNING" : "PAUSED"; color: root.autoTrading ? "#26a69a" : Theme.warning; font.pixelSize: 10; font.weight: Font.DemiBold }
                        }

                        ListView {
                            Layout.fillWidth: true; Layout.fillHeight: true
                            model: signalModel; clip: true; spacing: 3
                            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                            delegate: Rectangle {
                                id: sigRow
                                required property int    index
                                required property string symbol
                                required property string name
                                required property string signal
                                required property real   score
                                required property real   targetWeight
                                required property real   currentWeight
                                required property string reason

                                width: ListView.view.width; height: 50; radius: 6
                                color: sigMA.containsMouse ? Theme.panel3 : Theme.panel2
                                Behavior on color { ColorAnimation { duration: 100 } }
                                MouseArea { id: sigMA; anchors.fill: parent; hoverEnabled: true }

                                ColumnLayout {
                                    anchors { fill: parent; leftMargin: 10; rightMargin: 10; topMargin: 6; bottomMargin: 6 }
                                    spacing: 3
                                    RowLayout { Layout.fillWidth: true; spacing: 7
                                        Text { text: sigRow.symbol; color: Theme.text; font.pixelSize: 12; font.weight: Font.DemiBold; font.family: "Menlo" }
                                        Text { text: sigRow.name; color: Theme.muted; font.pixelSize: 12; elide: Text.ElideRight; Layout.fillWidth: true }
                                        Rectangle { width: 32; height: 16; radius: 4; color: Qt.rgba(0.149,0.651,0.604,0.10); border.color: root.signalColor(sigRow.signal)
                                            Text { anchors.centerIn: parent; text: sigRow.signal; color: root.signalColor(sigRow.signal); font.pixelSize: 9; font.weight: Font.DemiBold }
                                        }
                                        Text { text: sigRow.score.toFixed(2); color: sigRow.score >= 0.7 ? "#26a69a" : sigRow.score < 0.45 ? "#ef5350" : Theme.warning; font.pixelSize: 11; font.weight: Font.DemiBold; font.family: "Menlo" }
                                    }
                                    RowLayout { Layout.fillWidth: true; spacing: 7
                                        Text { text: sigRow.currentWeight.toFixed(1) + "% → " + sigRow.targetWeight.toFixed(1) + "%"; color: Theme.primary; font.pixelSize: 11; font.family: "Menlo" }
                                        Text { Layout.fillWidth: true; text: sigRow.reason; color: Theme.faint; font.pixelSize: 11; elide: Text.ElideRight }
                                    }
                                }
                            }
                        }
                    }
                }

                // ── 持仓权重 ─────────────────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 140
                    radius: Theme.radiusLarge
                    color: Theme.surface
                    border.color: Theme.line
                    clip: true

                    ColumnLayout {
                        anchors { fill: parent; margins: 14 }
                        spacing: 8

                        RowLayout { spacing: 6
                            Rectangle { width: 3; height: 13; radius: 1.5; color: Theme.primary }
                            Text { text: "持仓权重"; color: Theme.text; font.pixelSize: 13; font.weight: Font.DemiBold }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: {
                                    var t = 0
                                    for (var i = 0; i < signalModel.count; i++) t += signalModel.get(i).currentWeight
                                    return "已用 " + t.toFixed(1) + "%"
                                }
                                color: Theme.muted; font.pixelSize: 11; font.family: "Menlo"
                            }
                        }

                        ListView {
                            Layout.fillWidth: true; Layout.fillHeight: true
                            model: signalModel; spacing: 8; clip: true
                            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                            delegate: ColumnLayout {
                                required property string symbol
                                required property string name
                                required property string signal
                                required property real   currentWeight
                                required property real   targetWeight

                                width: ListView.view.width; spacing: 4

                                RowLayout { Layout.fillWidth: true; spacing: 5
                                    Text { text: symbol; color: Theme.text; font.pixelSize: 10; font.weight: Font.DemiBold; font.family: "Menlo" }
                                    Text { text: name; color: Theme.muted; font.pixelSize: 10; Layout.fillWidth: true; elide: Text.ElideRight }
                                    Rectangle { width: 26; height: 13; radius: 3; color: Qt.rgba(0.149,0.651,0.604,0.10); border.color: root.signalColor(signal)
                                        Text { anchors.centerIn: parent; text: signal; color: root.signalColor(signal); font.pixelSize: 8; font.weight: Font.DemiBold }
                                    }
                                    Text { text: currentWeight.toFixed(1) + "→" + targetWeight.toFixed(1) + "%"; color: Theme.faint; font.pixelSize: 9; font.family: "Menlo" }
                                }

                                Item { Layout.fillWidth: true; height: 7
                                    Rectangle { anchors.fill: parent; radius: 3; color: Theme.panel2 }
                                    Rectangle {
                                        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                                        width: Math.max(4, parent.width * currentWeight / 20); radius: 3
                                        color: root.signalColor(signal); opacity: 0.8
                                        Behavior on width { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
                                    }
                                    Rectangle {
                                        x: Math.min(parent.width - 2, parent.width * targetWeight / 20) - 1
                                        anchors { top: parent.top; bottom: parent.bottom }
                                        width: 2; radius: 1; color: Theme.primary; opacity: 0.9
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ── DarkComboBox component ────────────────────────────────────────────
    component DarkComboBox: ComboBox {
        id: _cb
        implicitHeight: 42

        contentItem: Text {
            leftPadding: 12; rightPadding: 26
            text: _cb.displayText; color: Theme.text; font.pixelSize: 13
            verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight
        }

        background: Rectangle {
            radius: 10
            color: _cb.pressed ? Theme.panel3 : _cb.hovered ? Theme.panel3 : Theme.panel2
            border.color: _cb.pressed ? Theme.primary : Theme.border
            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }
        }

        indicator: Text {
            x: _cb.width - width - 10; y: (_cb.height - height) / 2
            text: "⌄"; color: Theme.muted; font.pixelSize: 13
        }

        popup: Popup {
            y: _cb.height + 4; width: _cb.width; padding: 4
            background: Rectangle { radius: 10; color: Theme.surface; border.color: Theme.border }
            contentItem: ListView {
                clip: true; implicitHeight: contentHeight
                model: _cb.delegateModel; currentIndex: _cb.highlightedIndex
                boundsBehavior: Flickable.StopAtBounds
            }
        }

        delegate: ItemDelegate {
            id: _del
            required property var modelData
            required property int index
            width: _cb.popup.width - 8; height: 34

            contentItem: Text {
                leftPadding: 12; text: _del.modelData
                color: _del.highlighted ? Theme.text : Theme.muted; font.pixelSize: 13
                verticalAlignment: Text.AlignVCenter
            }

            highlighted: _cb.highlightedIndex === _del.index

            background: Rectangle {
                radius: 7; color: _del.highlighted ? Theme.panel3 : "transparent"
                Behavior on color { ColorAnimation { duration: 120 } }
            }
        }
    }
}
