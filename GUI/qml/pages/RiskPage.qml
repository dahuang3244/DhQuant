pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Item {
    id: root

    // ── helpers ───────────────────────────────────────────────────────────────
    function statusColor(status) {
        if (status === "fail")     return Theme.negative
        if (status === "warn")     return Theme.warning
        if (status === "disabled") return Theme.faint
        return Theme.primary
    }

    function globalStatusColor() {
        var s = risk.globalStatus
        if (s === "LOCKED") return Theme.negative
        if (s === "WARN")   return Theme.warning
        return Theme.primary
    }

    function barRatio(rule) {
        if (!rule.enabled) return 0.0
        var cur = rule.current, thr = rule.threshold
        var inv = rule.id === "margin_ratio" || rule.id === "net_value_floor" || rule.id === "available_cash"
        if (inv)                     return thr > 0 ? thr / Math.max(cur, 0.01) : 0.0
        if (rule.id === "dup_order") return cur > 0 ? 1.0 : 0.0
        return thr > 0 ? cur / thr : 0.0
    }

    function barColor(rule) {
        if (rule.status === "disabled") return Theme.faint
        var r = root.barRatio(rule)
        if (r >= 1.0)  return Theme.negative
        if (r >= 0.85) return Theme.warning
        return Theme.primary
    }

    function fmtCurrent(rule) {
        if (rule.id === "dup_order")                        return rule.current > 0 ? "发现 " + rule.current + " 条" : "无"
        if (rule.id === "order_size")                       return "¥" + (rule.current / 10000).toFixed(1) + "万"
        if (rule.unit === "次" || rule.unit === "只")       return rule.current.toFixed(0) + rule.unit
        if (rule.unit === "x")                              return rule.current.toFixed(2) + "x"
        return rule.current.toFixed(1) + rule.unit
    }

    function fmtThreshold(rule) {
        if (rule.id === "dup_order")                        return "检测中"
        if (rule.id === "order_size")                       return "¥" + (rule.threshold / 10000).toFixed(0) + "万"
        if (rule.unit === "次" || rule.unit === "只")       return rule.threshold.toFixed(0) + rule.unit
        if (rule.unit === "x")                              return rule.threshold.toFixed(2) + "x"
        return rule.threshold.toFixed(1) + rule.unit
    }

    function exposureBarColor(weight, limit) {
        var r = weight / limit
        if (r >= 1.0)  return Theme.negative
        if (r >= 0.85) return Theme.warning
        return Theme.primary
    }

    function logLevelColor(level) {
        if (level === "RISK") return Theme.negative
        if (level === "WARN") return Theme.warning
        if (level === "PASS") return Theme.primary
        return Theme.muted
    }

    // ── root layout ───────────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 14

        // ══ HEADER ═══════════════════════════════════════════════════════════
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
                color: root.globalStatusColor()
                Behavior on color { ColorAnimation { duration: 300 } }
            }

            RowLayout {
                anchors { fill: parent; leftMargin: 20; rightMargin: 20; topMargin: 14; bottomMargin: 14 }
                spacing: 16

                // Global status pill
                Rectangle {
                    width: statusPillRow.implicitWidth + 22
                    height: 32
                    radius: 16
                    color: {
                        var c = root.globalStatusColor()
                        return Qt.rgba(Qt.color(c).r, Qt.color(c).g, Qt.color(c).b, 0.14)
                    }
                    border.color: root.globalStatusColor()
                    border.width: 1
                    Behavior on color       { ColorAnimation { duration: 300 } }
                    Behavior on border.color { ColorAnimation { duration: 300 } }

                    RowLayout {
                        id: statusPillRow
                        anchors.centerIn: parent
                        spacing: 8

                        Rectangle {
                            width: 8; height: 8; radius: 4
                            color: root.globalStatusColor()
                            Behavior on color { ColorAnimation { duration: 300 } }

                            SequentialAnimation on opacity {
                                running: risk.globalStatus === "LOCKED"
                                loops: Animation.Infinite
                                NumberAnimation { to: 0.2; duration: 600 }
                                NumberAnimation { to: 1.0; duration: 600 }
                            }
                        }

                        Text {
                            text: risk.globalStatus
                            color: root.globalStatusColor()
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.8
                            Behavior on color { ColorAnimation { duration: 300 } }
                        }
                    }
                }

                ColumnLayout {
                    spacing: 2
                    Layout.alignment: Qt.AlignVCenter
                    Text {
                        text: "风控中心"
                        color: Theme.text
                        font.pixelSize: 20
                        font.weight: Font.DemiBold
                    }
                    Text {
                        text: "RISK CONTROL CENTER"
                        color: Theme.faint
                        font.pixelSize: 10
                        font.letterSpacing: 1.1
                    }
                }

                // Stats chips
                Rectangle {
                    height: 40; radius: 10
                    color: Theme.panel2; border.color: Theme.border
                    width: checkStatRow.implicitWidth + 24
                    RowLayout {
                        id: checkStatRow
                        anchors.centerIn: parent
                        spacing: 10
                        ColumnLayout {
                            spacing: 1
                            Text { text: "今日通过"; color: Theme.faint; font.pixelSize: 9; font.letterSpacing: 0.9; Layout.alignment: Qt.AlignHCenter }
                            Text { text: risk.passCount + " 笔"; color: Theme.primary; font.pixelSize: 12; font.weight: Font.DemiBold; font.family: "Menlo"; Layout.alignment: Qt.AlignHCenter }
                        }
                        Rectangle { width: 1; height: 22; color: Theme.border }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "今日拒绝"; color: Theme.faint; font.pixelSize: 9; font.letterSpacing: 0.9; Layout.alignment: Qt.AlignHCenter }
                            Text {
                                text: risk.rejectionCount + " 笔"
                                color: risk.rejectionCount > 0 ? Theme.negative : Theme.muted
                                font.pixelSize: 12; font.weight: Font.DemiBold; font.family: "Menlo"; Layout.alignment: Qt.AlignHCenter
                                Behavior on color { ColorAnimation { duration: 200 } }
                            }
                        }
                    }
                }

                Repeater {
                    model: [
                        { label: "检查延迟", value: risk.checkLatencyMs.toFixed(1) + " ms" },
                        { label: "活跃规则", value: risk.enabledRuleCount + "/" + risk.rulesCount + " 条" },
                    ]

                    Rectangle {
                        required property var modelData
                        height: 40; width: chipCol.implicitWidth + 24
                        radius: 10; color: Theme.panel2; border.color: Theme.border

                        ColumnLayout {
                            id: chipCol
                            anchors.centerIn: parent
                            spacing: 1
                            Text { text: modelData.label; color: Theme.faint; font.pixelSize: 9; font.letterSpacing: 0.9; Layout.alignment: Qt.AlignHCenter }
                            Text { text: modelData.value; color: Theme.text; font.pixelSize: 12; font.weight: Font.DemiBold; font.family: "Menlo"; Layout.alignment: Qt.AlignHCenter }
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                ColumnLayout {
                    spacing: 3
                    Layout.alignment: Qt.AlignVCenter
                    Text {
                        text: "多 " + risk.netLongWeight.toFixed(1) + "%   空 " + risk.netShortWeight.toFixed(1) + "%"
                        color: Theme.muted
                        font.pixelSize: 11
                        font.family: "Menlo"
                        Layout.alignment: Qt.AlignRight
                    }
                    Text {
                        text: "净多头 " + (risk.netLongWeight - risk.netShortWeight).toFixed(1) + "%"
                        color: Theme.primary
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        Layout.alignment: Qt.AlignRight
                    }
                }
            }
        }

        // ══ BODY ═════════════════════════════════════════════════════════════
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 14

            // ── LEFT: rules panel ─────────────────────────────────────────────
            Rectangle {
                Layout.preferredWidth: 292
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
                        Rectangle { width: 3; height: 13; radius: 1.5; color: Theme.primary }
                        Text {
                            text: "风控规则"
                            color: Theme.text
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                        }
                        Item { Layout.fillWidth: true }
                        Rectangle {
                            width: ruleCountTxt.implicitWidth + 12; height: 18; radius: 9
                            color: Theme.panel2; border.color: Theme.border
                            Text {
                                id: ruleCountTxt
                                anchors.centerIn: parent
                                text: risk.enabledRuleCount + "/" + risk.rulesCount
                                color: Theme.muted
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                            }
                        }
                    }

                    ListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        model: risk.rules
                        spacing: 4
                        clip: true

                        section.property: "category"
                        section.criteria: ViewSection.FullString
                        section.delegate: Item {
                            required property string section
                            width: ListView.view.width
                            height: 28

                            Text {
                                text: section
                                color: Theme.faint
                                font.pixelSize: 9
                                font.weight: Font.DemiBold
                                font.letterSpacing: 1.2
                                anchors.verticalCenter: parent.verticalCenter
                                x: 4
                            }
                            Rectangle {
                                height: 1
                                color: Theme.line
                                anchors {
                                    left: parent.left; right: parent.right
                                    verticalCenter: parent.verticalCenter
                                    leftMargin: 50
                                }
                            }
                        }

                        delegate: Rectangle {
                            id: ruleItem
                            required property var modelData
                            required property int index

                            width: ListView.view.width
                            height: 76
                            radius: Theme.radius
                            color: ruleMA.containsMouse ? Theme.panel3 : Theme.panel2
                            border.color: {
                                if (ruleItem.modelData.status === "fail") return Theme.negative
                                if (ruleItem.modelData.status === "warn") return Theme.warning
                                return Theme.border
                            }
                            Behavior on color        { ColorAnimation { duration: 100 } }
                            Behavior on border.color { ColorAnimation { duration: 200 } }

                            MouseArea { id: ruleMA; anchors.fill: parent; hoverEnabled: true }

                            ColumnLayout {
                                anchors { fill: parent; margins: 10 }
                                spacing: 6

                                // Row 1: status dot · name · toggle
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 7

                                    Rectangle {
                                        width: 7; height: 7; radius: 3.5
                                        color: root.statusColor(ruleItem.modelData.status)
                                        Behavior on color { ColorAnimation { duration: 200 } }

                                        SequentialAnimation on opacity {
                                            running: ruleItem.modelData.status === "fail"
                                            loops: Animation.Infinite
                                            NumberAnimation { to: 0.2; duration: 700 }
                                            NumberAnimation { to: 1.0; duration: 700 }
                                        }
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: ruleItem.modelData.name
                                        color: ruleItem.modelData.enabled ? Theme.text : Theme.faint
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                        Behavior on color { ColorAnimation { duration: 200 } }
                                    }

                                    // Toggle switch
                                    Rectangle {
                                        width: 38; height: 20; radius: 10
                                        color: ruleItem.modelData.enabled
                                               ? Qt.rgba(0.098, 0.643, 0.537, 0.22)
                                               : Theme.panel2
                                        border.color: ruleItem.modelData.enabled ? Theme.primary : Theme.border
                                        border.width: 1
                                        Behavior on color        { ColorAnimation { duration: 180 } }
                                        Behavior on border.color { ColorAnimation { duration: 180 } }

                                        Rectangle {
                                            width: 14; height: 14; radius: 7
                                            x: ruleItem.modelData.enabled ? parent.width - width - 3 : 3
                                            y: (parent.height - height) / 2
                                            color: ruleItem.modelData.enabled ? Theme.primary : Theme.faint
                                            Behavior on x     { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                            Behavior on color { ColorAnimation { duration: 180 } }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: risk.toggleRule(ruleItem.modelData.id)
                                        }
                                    }
                                }

                                // Row 2: progress bar
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 5
                                    radius: 2.5
                                    color: Theme.panel3

                                    Rectangle {
                                        width: Math.min(1.0, root.barRatio(ruleItem.modelData)) * parent.width
                                        height: parent.height
                                        radius: 2.5
                                        color: root.barColor(ruleItem.modelData)
                                        Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                                        Behavior on color { ColorAnimation { duration: 300 } }
                                    }
                                }

                                // Row 3: current value · divider · threshold nudge
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 4

                                    Text {
                                        text: root.fmtCurrent(ruleItem.modelData)
                                        color: root.barColor(ruleItem.modelData)
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                        font.family: "Menlo"
                                        Behavior on color { ColorAnimation { duration: 200 } }
                                    }
                                    Text {
                                        text: "/"
                                        color: Theme.faint
                                        font.pixelSize: 10
                                    }
                                    Item { Layout.fillWidth: true }

                                    // − button
                                    Rectangle {
                                        width: 18; height: 18; radius: 4
                                        visible: ruleItem.modelData.step > 0
                                        color: minusMA.containsMouse ? Theme.panel3 : "transparent"
                                        border.color: minusMA.containsMouse ? Theme.border : "transparent"
                                        Behavior on color { ColorAnimation { duration: 100 } }
                                        Text {
                                            anchors.centerIn: parent
                                            text: "−"; color: Theme.faint; font.pixelSize: 13
                                        }
                                        MouseArea {
                                            id: minusMA
                                            anchors.fill: parent; hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: risk.adjustThreshold(ruleItem.modelData.id, -ruleItem.modelData.step)
                                        }
                                    }

                                    Text {
                                        text: root.fmtThreshold(ruleItem.modelData)
                                        color: Theme.muted
                                        font.pixelSize: 11
                                        font.family: "Menlo"
                                    }

                                    // + button
                                    Rectangle {
                                        width: 18; height: 18; radius: 4
                                        visible: ruleItem.modelData.step > 0
                                        color: plusMA.containsMouse ? Theme.panel3 : "transparent"
                                        border.color: plusMA.containsMouse ? Theme.border : "transparent"
                                        Behavior on color { ColorAnimation { duration: 100 } }
                                        Text {
                                            anchors.centerIn: parent
                                            text: "+"; color: Theme.faint; font.pixelSize: 13
                                        }
                                        MouseArea {
                                            id: plusMA
                                            anchors.fill: parent; hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: risk.adjustThreshold(ruleItem.modelData.id, ruleItem.modelData.step)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ── CENTER: position exposure ──────────────────────────────────────
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
                        Rectangle { width: 3; height: 13; radius: 1.5; color: Theme.primary }
                        Text { text: "持仓暴露"; color: Theme.text; font.pixelSize: 13; font.weight: Font.DemiBold }
                    }

                    // ── Single-ticker weight ──────────────────────────────────
                    Text { text: "单票权重"; color: Theme.faint; font.pixelSize: 10; font.letterSpacing: 0.8 }

                    Repeater {
                        model: risk.exposures

                        RowLayout {
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                Layout.preferredWidth: 52
                                text: modelData.symbol
                                color: Theme.text; font.pixelSize: 12; font.weight: Font.Medium
                            }
                            Text {
                                Layout.preferredWidth: 60
                                text: modelData.name
                                color: Theme.muted; font.pixelSize: 11; elide: Text.ElideRight
                            }

                            Rectangle {
                                width: 26; height: 17; radius: 3
                                color: modelData.side === "多"
                                       ? Qt.rgba(0.098, 0.643, 0.537, 0.15)
                                       : Qt.rgba(0.886, 0.353, 0.337, 0.15)
                                border.color: modelData.side === "多" ? Theme.primary : Theme.negative
                                border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.side
                                    color: modelData.side === "多" ? Theme.primary : Theme.negative
                                    font.pixelSize: 10; font.weight: Font.DemiBold
                                }
                            }

                            // Progress bar
                            Item {
                                Layout.fillWidth: true
                                height: 6
                                Rectangle { anchors.fill: parent; radius: 3; color: Theme.panel3 }
                                Rectangle {
                                    width: Math.min(1.0, modelData.weight / modelData.limit) * parent.width
                                    height: parent.height; radius: 3
                                    color: root.exposureBarColor(modelData.weight, modelData.limit)
                                    Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                                    Behavior on color { ColorAnimation { duration: 300 } }
                                }
                            }

                            Text {
                                Layout.preferredWidth: 72
                                horizontalAlignment: Text.AlignRight
                                text: modelData.weight.toFixed(1) + "% / " + modelData.limit.toFixed(0) + "%"
                                color: root.exposureBarColor(modelData.weight, modelData.limit)
                                font.pixelSize: 11; font.family: "Menlo"; font.weight: Font.DemiBold
                                Behavior on color { ColorAnimation { duration: 300 } }
                            }
                        }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.line }

                    // ── Sector concentration ──────────────────────────────────
                    Text { text: "行业集中度"; color: Theme.faint; font.pixelSize: 10; font.letterSpacing: 0.8 }

                    Repeater {
                        model: risk.sectors

                        RowLayout {
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                Layout.preferredWidth: 36
                                text: modelData.sector
                                color: Theme.text; font.pixelSize: 12; font.weight: Font.Medium
                            }

                            Item {
                                Layout.fillWidth: true
                                height: 6
                                Rectangle { anchors.fill: parent; radius: 3; color: Theme.panel3 }
                                Rectangle {
                                    width: Math.min(1.0, modelData.weight / modelData.limit) * parent.width
                                    height: parent.height; radius: 3
                                    color: root.exposureBarColor(modelData.weight, modelData.limit)
                                    Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                                    Behavior on color { ColorAnimation { duration: 300 } }
                                }
                            }

                            Text {
                                Layout.preferredWidth: 80
                                horizontalAlignment: Text.AlignRight
                                text: modelData.weight.toFixed(1) + "% / " + modelData.limit.toFixed(0) + "%"
                                color: root.exposureBarColor(modelData.weight, modelData.limit)
                                font.pixelSize: 11; font.family: "Menlo"; font.weight: Font.DemiBold
                                Behavior on color { ColorAnimation { duration: 300 } }
                            }
                        }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.line }

                    // ── Net long/short gauge ──────────────────────────────────
                    Text { text: "净多空敞口"; color: Theme.faint; font.pixelSize: 10; font.letterSpacing: 0.8 }

                    Item {
                        Layout.fillWidth: true
                        height: 52

                        // Long label (left)
                        ColumnLayout {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1
                            Text {
                                text: "多头"
                                color: Theme.primary; font.pixelSize: 10; font.letterSpacing: 0.6
                            }
                            Text {
                                text: risk.netLongWeight.toFixed(1) + "%"
                                color: Theme.primary; font.pixelSize: 13; font.weight: Font.DemiBold; font.family: "Menlo"
                            }
                        }

                        // Balance track
                        Item {
                            id: gaugeTrack
                            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                            anchors.leftMargin: 62
                            anchors.rightMargin: 62
                            height: 10

                            Rectangle { anchors.fill: parent; radius: 5; color: Theme.panel3 }

                            // Long bar: right-to-center from left edge → center
                            Rectangle {
                                id: longFill
                                readonly property real ratio: Math.min(1.0, risk.netLongWeight / 50.0)
                                width: ratio * (gaugeTrack.width / 2)
                                height: parent.height; radius: 5
                                x: gaugeTrack.width / 2 - width
                                color: Theme.primary; opacity: 0.85
                                Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                            }

                            // Short bar: left-to-right from center → right edge
                            Rectangle {
                                id: shortFill
                                readonly property real ratio: Math.min(1.0, risk.netShortWeight / 50.0)
                                width: ratio * (gaugeTrack.width / 2)
                                height: parent.height; radius: 5
                                x: gaugeTrack.width / 2
                                color: Theme.negative; opacity: 0.85
                                Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                            }

                            // Center divider
                            Rectangle {
                                width: 2; height: parent.height; radius: 1
                                anchors.horizontalCenter: parent.horizontalCenter
                                color: Theme.border
                            }
                        }

                        // Short label (right)
                        ColumnLayout {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1
                            Text {
                                text: "空头"
                                color: Theme.negative; font.pixelSize: 10; font.letterSpacing: 0.6
                                Layout.alignment: Qt.AlignRight
                            }
                            Text {
                                text: risk.netShortWeight.toFixed(1) + "%"
                                color: Theme.negative; font.pixelSize: 13; font.weight: Font.DemiBold; font.family: "Menlo"
                                Layout.alignment: Qt.AlignRight
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }
                }
            }

            // ── RIGHT: rejection log + risk event log ──────────────────────────
            Rectangle {
                Layout.preferredWidth: 322
                Layout.fillHeight: true
                radius: Theme.radiusLarge
                color: Theme.surface
                border.color: Theme.line
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 10

                    // ── Order check log (pass + reject) ──────────────────────
                    RowLayout {
                        spacing: 7
                        Rectangle { width: 3; height: 13; radius: 1.5; color: Theme.primary }
                        Text { text: "委托检查记录"; color: Theme.text; font.pixelSize: 13; font.weight: Font.DemiBold }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: "清空"
                            color: risk.checkLogCount > 0 ? Theme.faint : Theme.border
                            font.pixelSize: 11
                            font.underline: clearChkMA.containsMouse && risk.checkLogCount > 0
                            MouseArea {
                                id: clearChkMA
                                anchors.fill: parent
                                enabled: risk.checkLogCount > 0
                                hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: risk.clearCheckLog()
                            }
                        }
                    }

                    ListView {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.min(contentHeight, 220)
                        model: risk.checkLog
                        spacing: 3
                        clip: true

                        delegate: Rectangle {
                            id: chkRow
                            required property var modelData
                            required property int index

                            width: ListView.view.width
                            // passed rows are slim; rejected rows have a second detail line
                            height: chkRow.modelData.passed ? 38 : 56
                            radius: 7
                            color: chkRowMA.containsMouse ? Theme.panel3 : Theme.panel2
                            border.color: chkRow.modelData.passed ? Theme.line : Qt.rgba(0.886, 0.353, 0.337, 0.35)
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 100 } }

                            MouseArea { id: chkRowMA; anchors.fill: parent; hoverEnabled: true }

                            ColumnLayout {
                                anchors { fill: parent; leftMargin: 10; rightMargin: 10; topMargin: 7; bottomMargin: 7 }
                                spacing: 4

                                // Row 1: time · symbol · side chip · status chip
                                RowLayout {
                                    spacing: 6
                                    Text {
                                        text: chkRow.modelData.time
                                        color: Theme.faint; font.pixelSize: 10; font.family: "Menlo"
                                    }
                                    Text {
                                        text: chkRow.modelData.symbol + " " + chkRow.modelData.name
                                        color: Theme.text; font.pixelSize: 11; font.weight: Font.DemiBold
                                    }
                                    // side chip
                                    Rectangle {
                                        width: sideChipTxt.implicitWidth + 8; height: 15; radius: 3
                                        color: chkRow.modelData.side === "买入"
                                               ? Qt.rgba(0.098, 0.643, 0.537, 0.13)
                                               : Qt.rgba(0.886, 0.353, 0.337, 0.13)
                                        border.color: chkRow.modelData.side === "买入" ? Theme.primary : Theme.negative
                                        border.width: 1
                                        Text {
                                            id: sideChipTxt
                                            anchors.centerIn: parent
                                            text: chkRow.modelData.side
                                            color: chkRow.modelData.side === "买入" ? Theme.primary : Theme.negative
                                            font.pixelSize: 10; font.weight: Font.DemiBold
                                        }
                                    }
                                    Item { Layout.fillWidth: true }
                                    // pass / reject status chip
                                    Rectangle {
                                        width: statusTxt.implicitWidth + 10; height: 17; radius: 3
                                        color: chkRow.modelData.passed
                                               ? Qt.rgba(0.098, 0.643, 0.537, 0.15)
                                               : Qt.rgba(0.886, 0.353, 0.337, 0.20)
                                        border.color: chkRow.modelData.passed ? Theme.primary : Theme.negative
                                        border.width: 1
                                        Text {
                                            id: statusTxt
                                            anchors.centerIn: parent
                                            text: chkRow.modelData.passed ? "通过" : "拒绝"
                                            color: chkRow.modelData.passed ? Theme.primary : Theme.negative
                                            font.pixelSize: 10; font.weight: Font.DemiBold
                                        }
                                    }
                                }

                                // Row 2 (rejected only): which rule triggered + values
                                RowLayout {
                                    visible: !chkRow.modelData.passed
                                    spacing: 4
                                    Text {
                                        text: chkRow.modelData.ruleName
                                        color: Theme.warning; font.pixelSize: 10
                                    }
                                    Text { text: "·"; color: Theme.faint; font.pixelSize: 10 }
                                    Text {
                                        text: chkRow.modelData.checkVal + " / " + chkRow.modelData.limit
                                        color: Theme.negative; font.pixelSize: 10
                                        font.family: "Menlo"; font.weight: Font.DemiBold
                                    }
                                    Item { Layout.fillWidth: true }
                                    Text {
                                        text: chkRow.modelData.qty.toLocaleString() + "股"
                                        color: Theme.faint; font.pixelSize: 10; font.family: "Menlo"
                                    }
                                }
                            }
                        }

                        Item {
                            anchors.fill: parent
                            visible: risk.checkLogCount === 0
                            Text {
                                anchors.centerIn: parent
                                text: "暂无委托检查记录"
                                color: Theme.faint; font.pixelSize: 12
                            }
                        }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.line }

                    // ── Risk event log ────────────────────────────────────────
                    RowLayout {
                        spacing: 7
                        Rectangle { width: 3; height: 13; radius: 1.5; color: Theme.warning }
                        Text { text: "风控日志"; color: Theme.text; font.pixelSize: 13; font.weight: Font.DemiBold }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: "清空"
                            color: risk.logsCount > 0 ? Theme.faint : Theme.border
                            font.pixelSize: 11
                            font.underline: clearLogMA.containsMouse && risk.logsCount > 0

                            MouseArea {
                                id: clearLogMA
                                anchors.fill: parent
                                enabled: risk.logsCount > 0
                                hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: risk.clearLogs()
                            }
                        }
                    }

                    ListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        model: risk.logs
                        spacing: 2
                        clip: true

                        delegate: Rectangle {
                            id: logRow
                            required property var modelData
                            required property int index

                            width: ListView.view.width
                            height: 30
                            radius: 4
                            color: logRowMA.containsMouse ? Theme.panel3 : "transparent"
                            Behavior on color { ColorAnimation { duration: 100 } }

                            MouseArea { id: logRowMA; anchors.fill: parent; hoverEnabled: true }

                            RowLayout {
                                anchors { fill: parent; leftMargin: 4; rightMargin: 4 }
                                spacing: 7

                                Text {
                                    Layout.preferredWidth: 50
                                    text: logRow.modelData.time
                                    color: Theme.faint; font.pixelSize: 10; font.family: "Menlo"
                                    verticalAlignment: Text.AlignVCenter
                                }

                                Rectangle {
                                    width: 34; height: 14; radius: 3
                                    color: {
                                        var l = logRow.modelData.level
                                        if (l === "RISK") return Qt.rgba(0.886, 0.353, 0.337, 0.22)
                                        if (l === "WARN") return Qt.rgba(0.847, 0.722, 0.310, 0.22)
                                        if (l === "PASS") return Qt.rgba(0.098, 0.643, 0.537, 0.18)
                                        return "transparent"
                                    }
                                    Text {
                                        anchors.centerIn: parent
                                        text: logRow.modelData.level
                                        color: root.logLevelColor(logRow.modelData.level)
                                        font.pixelSize: 9; font.weight: Font.DemiBold; font.letterSpacing: 0.4
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: logRow.modelData.message
                                    color: Theme.muted; font.pixelSize: 11
                                    elide: Text.ElideRight; verticalAlignment: Text.AlignVCenter
                                }
                            }

                            Rectangle {
                                anchors { bottom: parent.bottom; left: parent.left; right: parent.right; leftMargin: 4; rightMargin: 4 }
                                height: 1; color: Theme.line; opacity: 0.4
                                visible: logRow.index < risk.logsCount - 1
                            }
                        }

                        Item {
                            anchors.fill: parent
                            visible: risk.logsCount === 0
                            Text {
                                anchors.centerIn: parent
                                text: "日志已清空"
                                color: Theme.faint; font.pixelSize: 12
                            }
                        }
                    }
                }
            }
        }
    }
}
