pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Item {
    id: root

    // ── system states ────────────────────────────────────────────────────
    property bool assistMode:     false
    property bool autonomousMode: false

    // ── analysis config ──────────────────────────────────────────────────
    property string analysisInterval: "5分"
    property real   signalThreshold:  0.65
    property real   confidenceThresh: 0.80
    property real   maxPosPct:        5.0

    // ── factor weights ───────────────────────────────────────────────────
    property real wTech:  0.40
    property real wSent:  0.25
    property real wMicro: 0.20
    property real wMacro: 0.15

    // ── live scores ──────────────────────────────────────────────────────
    property real scoreTech:      0.0
    property real scoreSent:      0.0
    property real scoreMicro:     0.0
    property real scoreMacro:     0.0
    property real scoreComposite: 0.0

    // ── models ───────────────────────────────────────────────────────────
    ListModel { id: signalQueueModel }
    ListModel { id: reasoningModel }

    // ── sim ──────────────────────────────────────────────────────────────
    property int tickN: 0
    Timer {
        interval: 3800; repeat: true
        running: root.assistMode || root.autonomousMode
        onTriggered: root.tick()
    }

    function tick() {
        tickN += 1
        scoreTech  = 0.38 + Math.random() * 0.58
        scoreSent  = 0.28 + Math.random() * 0.60
        scoreMicro = 0.35 + Math.random() * 0.50
        scoreMacro = 0.32 + Math.random() * 0.48
        scoreComposite = wTech * scoreTech + wSent * scoreSent +
                         wMicro * scoreMicro + wMacro * scoreMacro

        var msgs = [
            "技术分析完成：MACD金叉信号，RSI=" + (45+Math.floor(Math.random()*35)) + "，布林带位置正常",
            "情绪扫描：正面新闻占比 " + (scoreSent*100).toFixed(1) + "%，市场情绪偏" + (scoreSent>0.55?"乐观":"谨慎"),
            "微观结构：买卖价差=" + (0.02+Math.random()*0.08).toFixed(3) + "，大单净流入检测中",
            "宏观因子：利率预期稳定，风险偏好指数 " + scoreComposite.toFixed(3),
            "综合评分：" + scoreComposite.toFixed(4) + "  阈值=" + signalThreshold.toFixed(2) + (scoreComposite >= signalThreshold ? "  ★ 超越阈值" : "")
        ]
        reasoningModel.insert(0, {
            ts: nowStr(),
            msg: msgs[tickN % msgs.length],
            lvl: scoreComposite >= signalThreshold ? "sig" : "info"
        })
        if (reasoningModel.count > 24) reasoningModel.remove(24)

        if (scoreComposite >= signalThreshold && tickN % 4 === 0) {
            var syms = ["000001.SZ","600036.SH","300750.SZ","000858.SZ","601318.SH"]
            var sym  = syms[Math.floor(Math.random() * syms.length)]
            var dir  = scoreComposite > 0.70 ? "买入" : "卖出"
            signalQueueModel.insert(0, {
                sigId: "SIG-" + (1000 + tickN),
                symbol: sym,
                direction: dir,
                confidence: scoreComposite,
                reason: pickReason(dir, scoreTech, scoreSent),
                ts: nowStr()
            })
            if (signalQueueModel.count > 12) signalQueueModel.remove(12)
        }
    }

    function pickReason(dir, tech, sent) {
        if (dir === "买入") {
            if (tech > 0.75) return "技术形态强势突破，动量信号确认"
            if (sent > 0.70) return "新闻情绪积极，资金流入信号"
            return "多因子综合评分超越买入阈值"
        }
        if (tech < 0.42) return "技术指标走弱，趋势转空"
        return "综合因子评分低于持仓阈值，建议减仓"
    }

    function nowStr() {
        var d = new Date()
        var h = d.getHours(), m = d.getMinutes(), s = d.getSeconds()
        return (h<10?"0":"")+h+":"+(m<10?"0":"")+m+":"+(s<10?"0":"")+s
    }

    function scoreColor(v) {
        if (v >= 0.70) return Theme.positive
        if (v >= 0.50) return Theme.warning
        return Theme.negative
    }

    // ════════════════════════════════════════════════════════════════════
    // LAYOUT
    // ════════════════════════════════════════════════════════════════════
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12

        // ═══ HEADER ════════════════════════════════════════════════════
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
                color: root.autonomousMode ? Theme.positive : Theme.primary
                Behavior on color { ColorAnimation { duration: 300 } }
            }

            RowLayout {
                anchors { fill: parent; leftMargin: 18; rightMargin: 16; topMargin: 10; bottomMargin: 10 }
                spacing: 16

                ColumnLayout {
                    spacing: 2; Layout.alignment: Qt.AlignVCenter
                    Text { text: "AI 决策台"; color: Theme.text; font.pixelSize: 17; font.weight: Font.DemiBold }
                    Text {
                        text: root.autonomousMode ? "全自主模式 · AI 正在独立决策中"
                            : root.assistMode    ? "辅助分析模式 · AI 生成参考信号"
                            : "所有 AI 系统待机"
                        color: root.autonomousMode ? Theme.positive
                             : root.assistMode    ? Theme.primary
                             : Theme.muted
                        font.pixelSize: 11
                        Behavior on color { ColorAnimation { duration: 250 } }
                    }
                }

                Item { Layout.fillWidth: true }

                // ── System 1 pill ─────────────────────────────────────
                Rectangle {
                    width: _p1.implicitWidth + 22; height: 28; radius: 14
                    color: root.assistMode ? Qt.rgba(0.102,0.643,0.533,0.13) : Qt.rgba(0.37,0.51,0.51,0.07)
                    border.color: root.assistMode ? Theme.primary : Theme.border; border.width: 1
                    Behavior on color { ColorAnimation { duration: 200 } }
                    RowLayout { id: _p1; anchors.centerIn: parent; spacing: 6
                        Rectangle { width: 6; height: 6; radius: 3; color: root.assistMode ? Theme.primary : Theme.faint }
                        Text { text: "辅助分析"; color: root.assistMode ? Theme.primary : Theme.muted; font.pixelSize: 11; font.weight: Font.DemiBold }
                    }
                }

                // ── System 2 pill ─────────────────────────────────────
                Rectangle {
                    width: _p2.implicitWidth + 22; height: 28; radius: 14
                    color: root.autonomousMode ? Qt.rgba(0.271,0.788,0.435,0.13) : Qt.rgba(0.37,0.51,0.51,0.07)
                    border.color: root.autonomousMode ? Theme.positive : Theme.border; border.width: 1
                    Behavior on color { ColorAnimation { duration: 200 } }
                    RowLayout { id: _p2; anchors.centerIn: parent; spacing: 6
                        Rectangle {
                            width: 6; height: 6; radius: 3; color: root.autonomousMode ? Theme.positive : Theme.faint
                            SequentialAnimation on opacity {
                                running: root.autonomousMode; loops: Animation.Infinite
                                NumberAnimation { to: 0.25; duration: 650 }
                                NumberAnimation { to: 1.00; duration: 650 }
                            }
                        }
                        Text { text: "全自主"; color: root.autonomousMode ? Theme.positive : Theme.muted; font.pixelSize: 11; font.weight: Font.DemiBold }
                    }
                }
            }
        }

        // ═══ BODY ══════════════════════════════════════════════════════
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            // ── LEFT: Mode Control ─────────────────────────────────────
            Rectangle {
                Layout.preferredWidth: 272
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

                        // ─── System 1 ─────────────────────────────────
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.topMargin: 14; Layout.leftMargin: 14; Layout.rightMargin: 14
                            spacing: 10

                            RowLayout { Layout.fillWidth: true; spacing: 8
                                ColumnLayout { spacing: 2; Layout.fillWidth: true
                                    RowLayout { spacing: 6
                                        Rectangle { width: 3; height: 13; radius: 1.5; color: Theme.primary }
                                        Text { text: "AI 辅助分析"; color: Theme.text; font.pixelSize: 13; font.weight: Font.DemiBold }
                                    }
                                    Text { text: "加权评分 · 生成参考信号"; color: Theme.muted; font.pixelSize: 10 }
                                }
                                SwitchToggle { checked: root.assistMode; onToggled: root.assistMode = !root.assistMode; activeColor: Theme.primary }
                            }

                            // AI model selector
                            Column { Layout.fillWidth: true; spacing: 4
                                Text { text: "AI 模型"; color: Theme.faint; font.pixelSize: 10; font.letterSpacing: 1.0 }
                                AgentCombo { id: modelCombo; Layout.fillWidth: true; width: parent.width; height: 30; model: ["GPT-4o","Claude Sonnet","DeepSeek-V3","Gemini 1.5 Pro"] }
                            }

                            // Interval chips
                            RowLayout { Layout.fillWidth: true; spacing: 0
                                Text { text: "分析间隔"; color: Theme.faint; font.pixelSize: 11; Layout.fillWidth: true }
                                Repeater {
                                    model: ["1分","5分","15分","30分"]
                                    delegate: Rectangle {
                                        required property string modelData
                                        height: 22; radius: 4; width: _iLabel.implicitWidth + 10
                                        color: root.analysisInterval === modelData ? Qt.rgba(0.102,0.643,0.533,0.18) : Theme.panel2
                                        border.color: root.analysisInterval === modelData ? Theme.primary : Theme.border
                                        Behavior on color { ColorAnimation { duration: 120 } }
                                        Text { id: _iLabel; anchors.centerIn: parent; text: parent.modelData; color: root.analysisInterval === parent.modelData ? Theme.primary : Theme.muted; font.pixelSize: 10; font.weight: Font.DemiBold }
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.analysisInterval = parent.modelData }
                                    }
                                }
                            }

                            // Signal threshold
                            RowLayout { Layout.fillWidth: true
                                Text { text: "信号阈值"; color: Theme.faint; font.pixelSize: 11; Layout.fillWidth: true }
                                Text { text: root.signalThreshold.toFixed(2); color: Theme.primary; font.pixelSize: 12; font.weight: Font.DemiBold; font.family: "Menlo" }
                            }
                            Slider {
                                id: sliderSigThresh
                                Layout.fillWidth: true
                                from: 0.50; to: 0.95; value: root.signalThreshold; stepSize: 0.01
                                onMoved: root.signalThreshold = value
                                background: Rectangle {
                                    x: sliderSigThresh.leftPadding; y: sliderSigThresh.topPadding + sliderSigThresh.availableHeight / 2 - height / 2
                                    width: sliderSigThresh.availableWidth; height: 4; radius: 2; color: Theme.panel2
                                    Rectangle { width: sliderSigThresh.visualPosition * parent.width; height: 4; radius: 2; color: Theme.primary; opacity: 0.85 }
                                }
                                handle: Rectangle {
                                    x: sliderSigThresh.leftPadding + sliderSigThresh.visualPosition * (sliderSigThresh.availableWidth - width)
                                    y: sliderSigThresh.topPadding + sliderSigThresh.availableHeight / 2 - height / 2
                                    width: 13; height: 13; radius: 7; color: Theme.primary; border.color: Theme.background; border.width: 2
                                }
                            }

                            // Factor weights header
                            RowLayout { spacing: 6; Layout.topMargin: 2
                                Rectangle { width: 3; height: 11; radius: 1.5; color: Theme.warning }
                                Text { text: "因子权重"; color: Theme.text; font.pixelSize: 12; font.weight: Font.DemiBold }
                                Item { Layout.fillWidth: true }
                                Text {
                                    property real total: root.wTech + root.wSent + root.wMicro + root.wMacro
                                    text: total.toFixed(2)
                                    color: Math.abs(total - 1.0) < 0.02 ? Theme.positive : Theme.negative
                                    font.pixelSize: 10; font.family: "Menlo"
                                }
                            }

                            // Tech weight
                            RowLayout { Layout.fillWidth: true
                                Text { text: "技术指标"; color: Theme.muted; font.pixelSize: 11; Layout.fillWidth: true }
                                Text { text: (root.wTech * 100).toFixed(0) + "%"; color: "#19a489"; font.pixelSize: 11; font.weight: Font.DemiBold; font.family: "Menlo" }
                            }
                            Slider {
                                id: slWT; Layout.fillWidth: true
                                from: 0; to: 1; value: root.wTech; stepSize: 0.01; onMoved: root.wTech = value
                                background: Rectangle { x: slWT.leftPadding; y: slWT.topPadding + slWT.availableHeight/2 - height/2; width: slWT.availableWidth; height: 3; radius: 1.5; color: Theme.panel2; Rectangle { width: slWT.visualPosition * parent.width; height: 3; radius: 1.5; color: "#19a489"; opacity: 0.8 } }
                                handle: Rectangle { x: slWT.leftPadding + slWT.visualPosition*(slWT.availableWidth-width); y: slWT.topPadding+slWT.availableHeight/2-height/2; width: 12; height: 12; radius: 6; color: "#19a489"; border.color: Theme.background; border.width: 1.5 }
                            }

                            // Sent weight
                            RowLayout { Layout.fillWidth: true
                                Text { text: "新闻情绪"; color: Theme.muted; font.pixelSize: 11; Layout.fillWidth: true }
                                Text { text: (root.wSent * 100).toFixed(0) + "%"; color: "#d8b84f"; font.pixelSize: 11; font.weight: Font.DemiBold; font.family: "Menlo" }
                            }
                            Slider {
                                id: slWS; Layout.fillWidth: true
                                from: 0; to: 1; value: root.wSent; stepSize: 0.01; onMoved: root.wSent = value
                                background: Rectangle { x: slWS.leftPadding; y: slWS.topPadding+slWS.availableHeight/2-height/2; width: slWS.availableWidth; height: 3; radius: 1.5; color: Theme.panel2; Rectangle { width: slWS.visualPosition*parent.width; height: 3; radius: 1.5; color: "#d8b84f"; opacity: 0.8 } }
                                handle: Rectangle { x: slWS.leftPadding+slWS.visualPosition*(slWS.availableWidth-width); y: slWS.topPadding+slWS.availableHeight/2-height/2; width: 12; height: 12; radius: 6; color: "#d8b84f"; border.color: Theme.background; border.width: 1.5 }
                            }

                            // Micro weight
                            RowLayout { Layout.fillWidth: true
                                Text { text: "微观结构"; color: Theme.muted; font.pixelSize: 11; Layout.fillWidth: true }
                                Text { text: (root.wMicro * 100).toFixed(0) + "%"; color: "#ab47bc"; font.pixelSize: 11; font.weight: Font.DemiBold; font.family: "Menlo" }
                            }
                            Slider {
                                id: slWM; Layout.fillWidth: true
                                from: 0; to: 1; value: root.wMicro; stepSize: 0.01; onMoved: root.wMicro = value
                                background: Rectangle { x: slWM.leftPadding; y: slWM.topPadding+slWM.availableHeight/2-height/2; width: slWM.availableWidth; height: 3; radius: 1.5; color: Theme.panel2; Rectangle { width: slWM.visualPosition*parent.width; height: 3; radius: 1.5; color: "#ab47bc"; opacity: 0.8 } }
                                handle: Rectangle { x: slWM.leftPadding+slWM.visualPosition*(slWM.availableWidth-width); y: slWM.topPadding+slWM.availableHeight/2-height/2; width: 12; height: 12; radius: 6; color: "#ab47bc"; border.color: Theme.background; border.width: 1.5 }
                            }

                            // Macro weight
                            RowLayout { Layout.fillWidth: true
                                Text { text: "宏观因子"; color: Theme.muted; font.pixelSize: 11; Layout.fillWidth: true }
                                Text { text: (root.wMacro * 100).toFixed(0) + "%"; color: "#42a5f5"; font.pixelSize: 11; font.weight: Font.DemiBold; font.family: "Menlo" }
                            }
                            Slider {
                                id: slWMa; Layout.fillWidth: true
                                from: 0; to: 1; value: root.wMacro; stepSize: 0.01; onMoved: root.wMacro = value
                                background: Rectangle { x: slWMa.leftPadding; y: slWMa.topPadding+slWMa.availableHeight/2-height/2; width: slWMa.availableWidth; height: 3; radius: 1.5; color: Theme.panel2; Rectangle { width: slWMa.visualPosition*parent.width; height: 3; radius: 1.5; color: "#42a5f5"; opacity: 0.8 } }
                                handle: Rectangle { x: slWMa.leftPadding+slWMa.visualPosition*(slWMa.availableWidth-width); y: slWMa.topPadding+slWMa.availableHeight/2-height/2; width: 12; height: 12; radius: 6; color: "#42a5f5"; border.color: Theme.background; border.width: 1.5 }
                            }
                        }

                        Rectangle { Layout.fillWidth: true; Layout.topMargin: 14; Layout.bottomMargin: 14; Layout.leftMargin: 14; Layout.rightMargin: 14; height: 1; color: Theme.line }

                        // ─── System 2 ─────────────────────────────────
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: 14; Layout.rightMargin: 14; Layout.bottomMargin: 16
                            spacing: 10

                            RowLayout { Layout.fillWidth: true; spacing: 8
                                ColumnLayout { spacing: 2; Layout.fillWidth: true
                                    RowLayout { spacing: 6
                                        Rectangle { width: 3; height: 13; radius: 1.5; color: Theme.positive }
                                        Text { text: "AI 全自主交易"; color: Theme.text; font.pixelSize: 13; font.weight: Font.DemiBold }
                                    }
                                    Text { text: "AI 独立决策 · 信号经风控执行"; color: Theme.muted; font.pixelSize: 10 }
                                }
                                SwitchToggle { checked: root.autonomousMode; onToggled: root.autonomousMode = !root.autonomousMode; activeColor: Theme.positive }
                            }

                            // Warning box
                            Rectangle {
                                Layout.fillWidth: true; height: _warnCol.implicitHeight + 14; radius: Theme.radius
                                color: Qt.rgba(0.886,0.353,0.337,0.07); border.color: Qt.rgba(0.886,0.353,0.337,0.32); border.width: 1
                                ColumnLayout {
                                    id: _warnCol
                                    anchors { fill: parent; margins: 8 }
                                    spacing: 2
                                    Text { text: "全自主模式下 AI 直接触发交易"; color: Theme.negative; font.pixelSize: 10; font.weight: Font.DemiBold }
                                    Text { text: "所有信号仍强制经由风控网关过滤，无法绕过"; color: Theme.muted; font.pixelSize: 10; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                                }
                            }

                            // Confidence threshold
                            RowLayout { Layout.fillWidth: true
                                Text { text: "置信度门槛"; color: Theme.faint; font.pixelSize: 11; Layout.fillWidth: true }
                                Text { text: root.confidenceThresh.toFixed(2); color: Theme.positive; font.pixelSize: 12; font.weight: Font.DemiBold; font.family: "Menlo" }
                            }
                            Slider {
                                id: slConf; Layout.fillWidth: true
                                from: 0.60; to: 0.99; value: root.confidenceThresh; stepSize: 0.01; onMoved: root.confidenceThresh = value
                                background: Rectangle { x: slConf.leftPadding; y: slConf.topPadding+slConf.availableHeight/2-height/2; width: slConf.availableWidth; height: 4; radius: 2; color: Theme.panel2; Rectangle { width: slConf.visualPosition*parent.width; height: 4; radius: 2; color: Theme.positive; opacity: 0.85 } }
                                handle: Rectangle { x: slConf.leftPadding+slConf.visualPosition*(slConf.availableWidth-width); y: slConf.topPadding+slConf.availableHeight/2-height/2; width: 13; height: 13; radius: 7; color: Theme.positive; border.color: Theme.background; border.width: 2 }
                            }

                            // Max position
                            RowLayout { Layout.fillWidth: true
                                Text { text: "单信号仓位上限"; color: Theme.faint; font.pixelSize: 11; Layout.fillWidth: true }
                                Text { text: root.maxPosPct.toFixed(1) + "%"; color: Theme.warning; font.pixelSize: 12; font.weight: Font.DemiBold; font.family: "Menlo" }
                            }
                            Slider {
                                id: slMaxPos; Layout.fillWidth: true
                                from: 1.0; to: 20.0; value: root.maxPosPct; stepSize: 0.5; onMoved: root.maxPosPct = value
                                background: Rectangle { x: slMaxPos.leftPadding; y: slMaxPos.topPadding+slMaxPos.availableHeight/2-height/2; width: slMaxPos.availableWidth; height: 4; radius: 2; color: Theme.panel2; Rectangle { width: slMaxPos.visualPosition*parent.width; height: 4; radius: 2; color: Theme.warning; opacity: 0.85 } }
                                handle: Rectangle { x: slMaxPos.leftPadding+slMaxPos.visualPosition*(slMaxPos.availableWidth-width); y: slMaxPos.topPadding+slMaxPos.availableHeight/2-height/2; width: 13; height: 13; radius: 7; color: Theme.warning; border.color: Theme.background; border.width: 2 }
                            }
                        }
                    }
                }
            }

            // ── CENTER: Analysis Console ────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 12

                // ─ Factor scores + composite row ──────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 200
                    radius: Theme.radiusLarge
                    color: Theme.surface
                    border.color: Theme.line

                    ColumnLayout {
                        anchors { fill: parent; margins: 14 }
                        spacing: 8

                        // Header row
                        RowLayout { spacing: 6
                            Rectangle { width: 3; height: 13; radius: 1.5; color: Theme.primary }
                            Text { text: "实时因子评分"; color: Theme.text; font.pixelSize: 13; font.weight: Font.DemiBold }
                            Item { Layout.fillWidth: true }
                            Repeater {
                                model: [{ t:"行情", ok: true },{ t:"新闻", ok: true },{ t:"宏观", ok: false }]
                                RowLayout {
                                    required property var modelData
                                    spacing: 4
                                    Rectangle { width: 5; height: 5; radius: 2.5; color: parent.modelData.ok ? Theme.positive : Theme.negative }
                                    Text { text: parent.modelData.t; color: parent.modelData.ok ? Theme.muted : Theme.negative; font.pixelSize: 10 }
                                }
                            }
                        }

                        // 4 factor columns
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 14

                            // Tech
                            ColumnLayout { Layout.fillWidth: true; spacing: 4
                                RowLayout {
                                    Text { text: "技术指标"; color: Theme.muted; font.pixelSize: 10; Layout.fillWidth: true; elide: Text.ElideRight }
                                    Text { text: root.scoreTech.toFixed(2); color: "#19a489"; font.pixelSize: 12; font.weight: Font.DemiBold; font.family: "Menlo"; Layout.preferredWidth: 34 }
                                }
                                Item { Layout.fillWidth: true; height: 7
                                    Rectangle { anchors.fill: parent; radius: 3; color: Theme.panel2 }
                                    Rectangle { anchors { left: parent.left; top: parent.top; bottom: parent.bottom } width: Math.max(4, parent.width * root.scoreTech); radius: 3; color: "#19a489"; opacity: 0.8; Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } } }
                                }
                                Text { text: (root.wTech*100).toFixed(0) + "%  ·  " + (root.scoreTech*root.wTech).toFixed(3); color: Theme.faint; font.pixelSize: 9; font.family: "Menlo" }
                            }

                            // Sentiment
                            ColumnLayout { Layout.fillWidth: true; spacing: 4
                                RowLayout {
                                    Text { text: "新闻情绪"; color: Theme.muted; font.pixelSize: 10; Layout.fillWidth: true; elide: Text.ElideRight }
                                    Text { text: root.scoreSent.toFixed(2); color: "#d8b84f"; font.pixelSize: 12; font.weight: Font.DemiBold; font.family: "Menlo"; Layout.preferredWidth: 34 }
                                }
                                Item { Layout.fillWidth: true; height: 7
                                    Rectangle { anchors.fill: parent; radius: 3; color: Theme.panel2 }
                                    Rectangle { anchors { left: parent.left; top: parent.top; bottom: parent.bottom } width: Math.max(4, parent.width * root.scoreSent); radius: 3; color: "#d8b84f"; opacity: 0.8; Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } } }
                                }
                                Text { text: (root.wSent*100).toFixed(0) + "%  ·  " + (root.scoreSent*root.wSent).toFixed(3); color: Theme.faint; font.pixelSize: 9; font.family: "Menlo" }
                            }

                            // Micro
                            ColumnLayout { Layout.fillWidth: true; spacing: 4
                                RowLayout {
                                    Text { text: "微观结构"; color: Theme.muted; font.pixelSize: 10; Layout.fillWidth: true; elide: Text.ElideRight }
                                    Text { text: root.scoreMicro.toFixed(2); color: "#ab47bc"; font.pixelSize: 12; font.weight: Font.DemiBold; font.family: "Menlo"; Layout.preferredWidth: 34 }
                                }
                                Item { Layout.fillWidth: true; height: 7
                                    Rectangle { anchors.fill: parent; radius: 3; color: Theme.panel2 }
                                    Rectangle { anchors { left: parent.left; top: parent.top; bottom: parent.bottom } width: Math.max(4, parent.width * root.scoreMicro); radius: 3; color: "#ab47bc"; opacity: 0.8; Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } } }
                                }
                                Text { text: (root.wMicro*100).toFixed(0) + "%  ·  " + (root.scoreMicro*root.wMicro).toFixed(3); color: Theme.faint; font.pixelSize: 9; font.family: "Menlo" }
                            }

                            // Macro
                            ColumnLayout { Layout.fillWidth: true; spacing: 4
                                RowLayout {
                                    Text { text: "宏观因子"; color: Theme.muted; font.pixelSize: 10; Layout.fillWidth: true; elide: Text.ElideRight }
                                    Text { text: root.scoreMacro.toFixed(2); color: "#42a5f5"; font.pixelSize: 12; font.weight: Font.DemiBold; font.family: "Menlo"; Layout.preferredWidth: 34 }
                                }
                                Item { Layout.fillWidth: true; height: 7
                                    Rectangle { anchors.fill: parent; radius: 3; color: Theme.panel2 }
                                    Rectangle { anchors { left: parent.left; top: parent.top; bottom: parent.bottom } width: Math.max(4, parent.width * root.scoreMacro); radius: 3; color: "#42a5f5"; opacity: 0.8; Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } } }
                                }
                                Text { text: (root.wMacro*100).toFixed(0) + "%  ·  " + (root.scoreMacro*root.wMacro).toFixed(3); color: Theme.faint; font.pixelSize: 9; font.family: "Menlo" }
                            }
                        }

                        // ─── Composite score inline row ────────────────
                        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.line; opacity: 0.5 }

                        RowLayout { Layout.fillWidth: true; spacing: 10
                            RowLayout { spacing: 6
                                Rectangle {
                                    width: 3; height: 11; radius: 1.5
                                    color: root.scoreColor(root.scoreComposite)
                                    Behavior on color { ColorAnimation { duration: 300 } }
                                }
                                Text { text: "综合得分"; color: Theme.muted; font.pixelSize: 10 }
                            }

                            Item { Layout.fillWidth: true; height: 8
                                Rectangle { anchors.fill: parent; radius: 3; color: Theme.panel2 }
                                Rectangle {
                                    anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                                    width: Math.max(5, parent.width * root.scoreComposite); radius: 3
                                    color: root.scoreColor(root.scoreComposite); opacity: 0.75
                                    Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                                    Behavior on color { ColorAnimation { duration: 300 } }
                                }
                                Rectangle {
                                    x: Math.min(parent.width - 2, parent.width * root.signalThreshold) - 1
                                    anchors { top: parent.top; bottom: parent.bottom }
                                    width: 2; radius: 1; color: Theme.primary; opacity: 0.85
                                }
                            }

                            Text {
                                text: root.scoreComposite.toFixed(4)
                                color: root.scoreColor(root.scoreComposite)
                                font.pixelSize: 14; font.weight: Font.DemiBold; font.family: "Menlo"
                                Layout.preferredWidth: 58
                                Behavior on color { ColorAnimation { duration: 300 } }
                            }

                            Text {
                                text: root.scoreComposite >= root.signalThreshold ? "↑ 超阈值" : "低于阈值"
                                color: root.scoreComposite >= root.signalThreshold ? Theme.positive : Theme.faint
                                font.pixelSize: 10; font.weight: Font.DemiBold
                                Behavior on color { ColorAnimation { duration: 300 } }
                            }

                            Rectangle {
                                width: _statusPill.implicitWidth + 16; height: 20; radius: 10
                                color: (root.assistMode || root.autonomousMode) ? Qt.rgba(0.102,0.643,0.533,0.14) : Qt.rgba(0.37,0.51,0.51,0.07)
                                border.color: (root.assistMode || root.autonomousMode) ? Theme.primary : Theme.border
                                Behavior on color { ColorAnimation { duration: 200 } }
                                Text {
                                    id: _statusPill; anchors.centerIn: parent
                                    text: (root.assistMode || root.autonomousMode) ? "分析运行中" : "系统待机"
                                    color: (root.assistMode || root.autonomousMode) ? Theme.primary : Theme.muted
                                    font.pixelSize: 10; font.weight: Font.DemiBold
                                }
                            }
                        }
                    }
                }

                // ─ AI Reasoning log (full width, fills remaining) ──────
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
                            Rectangle { width: 3; height: 13; radius: 1.5; color: Theme.faint }
                            Text { text: "AI 推理日志"; color: Theme.text; font.pixelSize: 12; font.weight: Font.DemiBold }
                            Item { Layout.fillWidth: true }
                            Text { text: reasoningModel.count + " 条"; color: Theme.faint; font.pixelSize: 10 }
                        }

                        ListView {
                            Layout.fillWidth: true; Layout.fillHeight: true
                            model: reasoningModel; spacing: 4; clip: true
                            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                            add: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 280 } }

                            delegate: RowLayout {
                                required property string ts
                                required property string msg
                                required property string lvl
                                width: ListView.view.width; spacing: 8

                                Text { text: ts; color: Theme.faint; font.pixelSize: 10; font.family: "Menlo"; Layout.alignment: Qt.AlignTop; Layout.topMargin: 1 }
                                Rectangle { width: 2; height: _rText.implicitHeight; radius: 1; color: lvl === "sig" ? Theme.positive : Theme.faint; opacity: 0.7; Layout.alignment: Qt.AlignTop; Layout.topMargin: 1 }
                                Text { id: _rText; text: msg; color: lvl === "sig" ? Theme.positive : Theme.muted; font.pixelSize: 11; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                            }

                            Item { anchors.fill: parent; visible: reasoningModel.count === 0
                                Text { anchors.centerIn: parent; text: "启动 AI 分析后将显示推理过程"; color: Theme.faint; font.pixelSize: 12 }
                            }
                        }
                    }
                }
            }

            // ── RIGHT: Signal Intent Queue ──────────────────────────────
            Rectangle {
                Layout.preferredWidth: 288
                Layout.fillHeight: true
                radius: Theme.radiusLarge
                color: Theme.surface
                border.color: Theme.line
                clip: true

                ColumnLayout {
                    anchors { fill: parent; margins: 14 }
                    spacing: 8

                    // Header
                    RowLayout { spacing: 6
                        Rectangle { width: 3; height: 13; radius: 1.5; color: Theme.warning }
                        Text { text: "AI 信号队列"; color: Theme.text; font.pixelSize: 12; font.weight: Font.DemiBold }
                        Item { Layout.fillWidth: true }
                        Rectangle {
                            visible: signalQueueModel.count > 0
                            width: _sqBadge.implicitWidth + 10; height: 18; radius: 9
                            color: Qt.rgba(0.847,0.722,0.310,0.14); border.color: Theme.warning; border.width: 1
                            Text { id: _sqBadge; anchors.centerIn: parent; text: signalQueueModel.count + " 意图"; color: Theme.warning; font.pixelSize: 10; font.weight: Font.DemiBold }
                        }
                    }

                    // Hint text
                    Text {
                        text: "以下信号为 AI 决策意图，由风控中心页面审核执行"
                        color: Theme.faint; font.pixelSize: 10
                        wrapMode: Text.WordWrap; Layout.fillWidth: true
                    }

                    // Signal list
                    ListView {
                        Layout.fillWidth: true; Layout.fillHeight: true
                        model: signalQueueModel; spacing: 6; clip: true
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                        add: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 260 } }
                        remove: Transition { NumberAnimation { property: "opacity"; to: 0; duration: 180 } }

                        delegate: Rectangle {
                            id: sigCard
                            required property int    index
                            required property string sigId
                            required property string symbol
                            required property string direction
                            required property real   confidence
                            required property string reason
                            required property string ts

                            width: ListView.view.width
                            height: _sigCol.implicitHeight + 16
                            radius: Theme.radius
                            color: Theme.panel2
                            border.color: sigCard.direction === "买入"
                                        ? Qt.rgba(0.149,0.651,0.604,0.25)
                                        : Qt.rgba(0.937,0.325,0.314,0.25)
                            border.width: 1

                            ColumnLayout {
                                id: _sigCol
                                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                                spacing: 5

                                RowLayout { spacing: 6
                                    Rectangle {
                                        width: 38; height: 18; radius: 4
                                        color: sigCard.direction === "买入" ? Qt.rgba(0.149,0.651,0.604,0.18) : Qt.rgba(0.937,0.325,0.314,0.18)
                                        border.color: sigCard.direction === "买入" ? "#26a69a" : "#ef5350"; border.width: 1
                                        Text { anchors.centerIn: parent; text: sigCard.direction; color: sigCard.direction === "买入" ? "#26a69a" : "#ef5350"; font.pixelSize: 10; font.weight: Font.DemiBold }
                                    }
                                    Text { text: sigCard.symbol; color: Theme.text; font.pixelSize: 13; font.weight: Font.DemiBold; font.family: "Menlo"; Layout.fillWidth: true }
                                    Text { text: (sigCard.confidence * 100).toFixed(1) + "%"; color: root.scoreColor(sigCard.confidence); font.pixelSize: 12; font.weight: Font.DemiBold; font.family: "Menlo" }
                                }

                                Text { text: sigCard.reason; color: Theme.muted; font.pixelSize: 10; wrapMode: Text.WordWrap; Layout.fillWidth: true }

                                RowLayout { spacing: 4
                                    Text { text: sigCard.ts; color: Theme.faint; font.pixelSize: 10; font.family: "Menlo"; Layout.fillWidth: true }
                                    Text { text: sigCard.sigId; color: Theme.faint; font.pixelSize: 10; font.family: "Menlo" }
                                    Text { text: "→ 风控中心"; color: Theme.faint; font.pixelSize: 10; opacity: 0.7 }
                                }
                            }
                        }

                        Item { anchors.fill: parent; visible: signalQueueModel.count === 0
                            ColumnLayout { anchors.centerIn: parent; spacing: 4
                                Text { text: "无待处理信号意图"; color: Theme.faint; font.pixelSize: 12; Layout.alignment: Qt.AlignHCenter }
                                Text { text: "AI 生成的意图将在此排队"; color: Theme.faint; font.pixelSize: 10; Layout.alignment: Qt.AlignHCenter }
                            }
                        }
                    }
                }
            }
        }
    }

    // ── SwitchToggle ─────────────────────────────────────────────────────
    component SwitchToggle: Item {
        id: sw
        property bool  checked:     false
        property color activeColor: Theme.primary
        signal toggled()
        width: 42; height: 24

        Rectangle {
            anchors.fill: parent; radius: 12
            color: sw.checked ? Qt.rgba(sw.activeColor.r, sw.activeColor.g, sw.activeColor.b, 0.22) : Theme.panel2
            border.color: sw.checked ? sw.activeColor : Theme.border; border.width: 1.5
            Behavior on color       { ColorAnimation { duration: 180 } }
            Behavior on border.color { ColorAnimation { duration: 180 } }
        }
        Rectangle {
            width: 18; height: 18; radius: 9
            x: sw.checked ? 21 : 3
            y: 3
            color: sw.checked ? sw.activeColor : Theme.faint
            Behavior on x     { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 180 } }
        }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: sw.toggled() }
    }

    // ── AgentCombo ───────────────────────────────────────────────────────
    component AgentCombo: ComboBox {
        id: _ac
        implicitHeight: 30

        contentItem: Text {
            leftPadding: 10; rightPadding: 22
            text: _ac.displayText; color: Theme.text; font.pixelSize: 12
            verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight
        }
        background: Rectangle {
            radius: 8; color: _ac.hovered ? Theme.panel3 : Theme.panel2
            border.color: _ac.pressed ? Theme.primary : Theme.border
            Behavior on color       { ColorAnimation { duration: 120 } }
            Behavior on border.color { ColorAnimation { duration: 120 } }
        }
        indicator: Text { x: _ac.width - width - 8; y: (_ac.height - height) / 2; text: "⌄"; color: Theme.muted; font.pixelSize: 11 }
        popup: Popup {
            y: _ac.height + 4; width: _ac.width; padding: 4
            background: Rectangle { radius: 8; color: Theme.surface; border.color: Theme.border }
            contentItem: ListView { clip: true; implicitHeight: contentHeight; model: _ac.delegateModel; currentIndex: _ac.highlightedIndex; boundsBehavior: Flickable.StopAtBounds }
        }
        delegate: ItemDelegate {
            id: _acd; required property var modelData; required property int index
            width: _ac.popup.width - 8; height: 30
            contentItem: Text { leftPadding: 10; text: _acd.modelData; color: _acd.highlighted ? Theme.text : Theme.muted; font.pixelSize: 12; verticalAlignment: Text.AlignVCenter }
            highlighted: _ac.highlightedIndex === _acd.index
            background: Rectangle { radius: 6; color: _acd.highlighted ? Theme.panel3 : "transparent" }
        }
    }
}
