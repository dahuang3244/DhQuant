pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Item {
    id: root

    // which result card is expanded (-1 = none)
    property int expandedIdx: -1
    property var compareStrategies: []
    property var pm: ({})   // combine mode: aggregated portfolio metrics

    Component.onCompleted: {
        var next = []
        var count = Math.min(4, backtest.strategies.length)
        for (var i = 0; i < count; i++)
            next.push(backtest.strategies[i])
        compareStrategies = next
    }

    function toggleCompareStrategy(strategy) {
        var next = compareStrategies.slice()
        var idx = next.indexOf(strategy)
        if (idx >= 0) {
            if (next.length <= 1)
                return
            next.splice(idx, 1)
        } else {
            next.push(strategy)
        }
        compareStrategies = next
    }

    function _recomputePm() {
        var rs = backtest.results
        if (!rs || rs.length === 0) { root.pm = {}; return }
        var n = rs.length, ret = 0, wr = 0, dd = 0, tc = 0
        for (var i = 0; i < n; i++) {
            ret += (rs[i].returnPct  || 0) / n
            wr  += (rs[i].winRate    || 0) / n
            dd   = Math.max(dd, rs[i].maxDrawdown || 0)
            tc  += (rs[i].tradeCount || 0)
        }
        root.pm = { returnPct: ret, winRate: wr, maxDrawdown: dd, tradeCount: tc }
    }

    Connections {
        target: backtest
        function onResultsChanged() {
            root.expandedIdx = -1
            root._recomputePm()
        }
    }

    // ── main layout ─────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 14

        // ── A. Header / search bar ───────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 88
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
                anchors.topMargin: 12
                anchors.bottomMargin: 12
                spacing: 10

                ColumnLayout {
                    spacing: 3
                    Layout.alignment: Qt.AlignVCenter
                    Text { text: "回测工作台"; color: Theme.text; font.pixelSize: 20; font.weight: Font.DemiBold }
                    Text { text: "STRATEGY BACKTEST"; color: Theme.muted; font.pixelSize: 10; font.letterSpacing: 1.1 }
                }

                BtControlGroup {
                    label: "股票代码"
                    TextField {
                        id: symbolInput
                        implicitWidth: 110; implicitHeight: 40
                        text: backtest.query
                        placeholderText: "AAPL / 600519"
                        color: Theme.text; placeholderTextColor: Theme.faint
                        font.pixelSize: 14; leftPadding: 12; selectByMouse: true
                        onEditingFinished: backtest.setQuery(text)
                        onAccepted: { backtest.setQuery(text); backtest.search() }
                        background: Rectangle {
                            radius: 10; color: Theme.background
                            border.color: parent.activeFocus ? Theme.primary : Theme.border
                            Behavior on border.color { ColorAnimation { duration: 140 } }
                        }
                    }
                }

                BtControlGroup {
                    label: "市场"
                    BtComboBox {
                        implicitWidth: 90
                        model: ["美股", "A股", "港股", "加密"]
                        currentIndex: model.indexOf(backtest.market)
                        onActivated: backtest.setMarket(currentText)
                    }
                }

                BtControlGroup {
                    label: "周期"
                    BtComboBox {
                        implicitWidth: 82
                        model: ["分钟K", "小时K", "日K", "周K", "月K"]
                        currentIndex: model.indexOf(backtest.period)
                        onActivated: backtest.setPeriod(currentText)
                    }
                }

                BtControlGroup {
                    label: "开始日期"
                    TextField {
                        implicitWidth: 110; implicitHeight: 40
                        text: backtest.startDate
                        placeholderText: "YYYY-MM-DD"
                        color: Theme.text; placeholderTextColor: Theme.faint
                        font.pixelSize: 13; leftPadding: 10; selectByMouse: true
                        onEditingFinished: backtest.setStartDate(text)
                        background: Rectangle {
                            radius: 10; color: Theme.background
                            border.color: parent.activeFocus ? Theme.primary : Theme.border
                            Behavior on border.color { ColorAnimation { duration: 140 } }
                        }
                    }
                }

                BtControlGroup {
                    label: "结束日期"
                    TextField {
                        implicitWidth: 110; implicitHeight: 40
                        text: backtest.endDate
                        placeholderText: "YYYY-MM-DD"
                        color: Theme.text; placeholderTextColor: Theme.faint
                        font.pixelSize: 13; leftPadding: 10; selectByMouse: true
                        onEditingFinished: backtest.setEndDate(text)
                        background: Rectangle {
                            radius: 10; color: Theme.background
                            border.color: parent.activeFocus ? Theme.primary : Theme.border
                            Behavior on border.color { ColorAnimation { duration: 140 } }
                        }
                    }
                }

                Button {
                    id: searchBtn
                    Layout.preferredWidth: 72; Layout.preferredHeight: 40
                    Layout.alignment: Qt.AlignBottom
                    text: "查询"
                    onClicked: { backtest.setQuery(symbolInput.text); backtest.search() }
                    scale: pressed ? 0.97 : 1
                    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
                    contentItem: Text {
                        text: searchBtn.text; color: Theme.text
                        font.pixelSize: 14; font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        radius: 10
                        color: searchBtn.hovered ? Theme.primaryHover : Theme.primary
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }

                Rectangle {
                    Layout.alignment: Qt.AlignBottom
                    visible: backtest.error !== ""
                    implicitWidth: errText.implicitWidth + 22; implicitHeight: 34
                    radius: 17; color: "#2b1b1c"; border.color: Theme.negative
                    Text {
                        id: errText; anchors.centerIn: parent
                        text: backtest.error; color: Theme.negative; font.pixelSize: 12
                    }
                }
            }
        }

        // ── B. Cached symbol chips ───────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 50
            visible: backtest.cachedSymbols.length > 0
            radius: Theme.radiusLarge; color: Theme.surface; border.color: Theme.line

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16; anchors.rightMargin: 16
                spacing: 0

                Text { text: "缓存标的"; color: Theme.faint; font.pixelSize: 11; font.letterSpacing: 0.8; Layout.rightMargin: 12 }

                ScrollView {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    ScrollBar.vertical.policy: ScrollBar.AlwaysOff; clip: true

                    RowLayout {
                        spacing: 8
                        anchors.verticalCenter: parent.verticalCenter
                        Repeater {
                            model: backtest.cachedSymbols
                            SymbolChip {
                                required property var modelData
                                chipKey: modelData.key; symbol: modelData.symbol
                                market: modelData.market; active: modelData.key === backtest.activeKey
                            }
                        }
                    }
                }
            }
        }

        // ── C. Content area ──────────────────────────────────────────────
        Item {
            Layout.fillWidth: true; Layout.fillHeight: true

            Rectangle {
                anchors.fill: parent
                visible: backtest.activeKey === ""
                radius: Theme.radiusLarge; color: Theme.surface; border.color: Theme.line
                ColumnLayout {
                    anchors.centerIn: parent; spacing: 10
                    Text { text: "尚未选择标的"; color: Theme.text; font.pixelSize: 20; font.weight: Font.DemiBold; Layout.alignment: Qt.AlignHCenter }
                    Text { text: "在上方输入股票代码并点击查询，即可开始回测。"; color: Theme.muted; font.pixelSize: 13; Layout.alignment: Qt.AlignHCenter }
                }
            }

            ColumnLayout {
                anchors.fill: parent; spacing: 10
                visible: backtest.activeKey !== ""

                // C1. Strategy config bar
                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 60
                    radius: Theme.radiusLarge; color: Theme.surface; border.color: Theme.line

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16; anchors.rightMargin: 16
                        spacing: 8

                        ColumnLayout {
                            spacing: 1
                            Text { text: "共 " + backtest.barCount + " 条数据"; color: Theme.muted; font.pixelSize: 11 }
                            Text { text: backtest.tradeCount + " 笔交易";       color: Theme.faint; font.pixelSize: 10 }
                        }

                        Rectangle { width: 1; height: 28; color: Theme.line }

                        StrategyPicker {
                            visible: backtest.mode !== "combine"
                            Layout.fillWidth: true
                            selectedItems: root.compareStrategies
                            onToggleStrategy: function(strategy) {
                                root.toggleCompareStrategy(strategy)
                                backtest.setStrategy(strategy)
                            }
                        }

                        StrategyPicker {
                            visible: backtest.mode === "combine"
                            Layout.fillWidth: true
                            selectedItems: backtest.selectedStrategies
                            onToggleStrategy: function(strategy) {
                                if (backtest.selectedStrategies.indexOf(strategy) >= 0) {
                                    backtest.removeStrategy(strategy)
                                } else {
                                    backtest.addStrategy(strategy)
                                }
                            }
                        }

                        BtLabeledInput {
                            label: "初始资金"; inputWidth: 82
                            text: String(backtest.initialCapital)
                            onCommit: function(v) { backtest.setInitialCapital(v) }
                        }

                        BtLabeledInput {
                            label: "杠杆"; inputWidth: 46
                            text: String(backtest.leverage)
                            onCommit: function(v) { backtest.setLeverage(v) }
                        }

                        BtLabeledInput {
                            label: "手续费 %"; inputWidth: 46
                            text: String(backtest.commission)
                            onCommit: function(v) { backtest.setCommission(v) }
                        }

                        Rectangle { width: 1; height: 28; color: Theme.line }

                        RowLayout {
                            spacing: 4
                            ModeBtn { text: "组合"; active: backtest.mode === "combine"; onClicked: backtest.setMode("combine") }
                            ModeBtn { text: "对比"; active: backtest.mode === "compare"; onClicked: backtest.setMode("compare") }
                        }

                        Rectangle { width: 1; height: 28; color: Theme.line }

                        Button {
                            id: runBtn
                            implicitWidth: 80; implicitHeight: 34
                            text: "运行回测"
                            onClicked: backtest.runBacktest()
                            scale: pressed ? 0.97 : 1
                            Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
                            contentItem: Text {
                                text: runBtn.text; color: Theme.text
                                font.pixelSize: 12; font.weight: Font.DemiBold
                                horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                            }
                            background: Rectangle {
                                radius: 9
                                color: runBtn.hovered ? Theme.primaryHover : Theme.primary
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                        }

                        Button {
                            id: clearBtn
                            implicitWidth: 52; implicitHeight: 34
                            text: "清除"
                            onClicked: backtest.clearResults()
                            scale: pressed ? 0.97 : 1
                            Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
                            contentItem: Text {
                                text: clearBtn.text; color: Theme.muted
                                font.pixelSize: 12; font.weight: Font.DemiBold
                                horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                            }
                            background: Rectangle {
                                radius: 9
                                color: clearBtn.hovered ? Theme.panel3 : Theme.panel2
                                border.color: Theme.border
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                        }
                    }
                }

                // C2. Full-width accordion result list
                Rectangle {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    radius: Theme.radiusLarge; color: Theme.surface; border.color: Theme.line
                    clip: true

                    ColumnLayout {
                        anchors.fill: parent; anchors.margins: 12; spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "策略结果"; color: Theme.text; font.pixelSize: 13; font.weight: Font.DemiBold; Layout.fillWidth: true }
                            Text { text: backtest.mode === "compare" ? "对比模式" : "组合模式"; color: Theme.faint; font.pixelSize: 10; font.letterSpacing: 0.7 }
                        }

                        Item {
                            Layout.fillWidth: true; Layout.fillHeight: true
                            visible: backtest.results.length === 0
                            ColumnLayout {
                                anchors.centerIn: parent; spacing: 6
                                Text { text: "暂无结果"; color: Theme.muted; font.pixelSize: 14; Layout.alignment: Qt.AlignHCenter }
                                Text { text: "点击「运行回测」开始"; color: Theme.faint; font.pixelSize: 11; Layout.alignment: Qt.AlignHCenter }
                            }
                        }

                        // ── 对比模式：可折叠的独立策略卡片 ───────────────
                        ScrollView {
                            Layout.fillWidth: true
                            Layout.fillHeight: backtest.mode === "compare"
                            visible: backtest.mode === "compare" && backtest.results.length > 0
                            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                            clip: true

                            ListView {
                                id: resultList
                                model: backtest.results
                                spacing: 8
                                boundsBehavior: Flickable.StopAtBounds
                                cacheBuffer: 640

                                displaced: Transition {
                                    NumberAnimation {
                                        properties: "y"
                                        duration: 220
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                delegate: ResultCard {
                                    required property var modelData
                                    required property int index
                                    result:      modelData
                                    resultIndex: index
                                    width: ListView.view.width
                                    expanded: root.expandedIdx === index
                                    onToggleExpand: root.expandedIdx = (root.expandedIdx === index) ? -1 : index
                                }
                            }
                        }

                        // ── 组合模式：组合绩效卡 + 策略归因表 ────────────
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: backtest.mode === "combine"
                            visible: backtest.mode === "combine" && backtest.results.length > 0
                            spacing: 8

                            // Portfolio overview card (chart fills remaining space)
                            Rectangle {
                                Layout.fillWidth: true; Layout.fillHeight: true
                                radius: 11; color: Theme.panel2; border.color: Theme.line; clip: true

                                ColumnLayout {
                                    anchors.fill: parent; anchors.margins: 14; spacing: 8

                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 12

                                        ColumnLayout {
                                            spacing: 3
                                            Text { text: "组合绩效"; color: Theme.text; font.pixelSize: 14; font.weight: Font.DemiBold }
                                            RowLayout {
                                                spacing: 5
                                                Rectangle { width: 6; height: 6; radius: 3; color: Theme.primary }
                                                Text { text: "等权分配 · " + backtest.results.length + " 个策略"; color: Theme.faint; font.pixelSize: 10 }
                                            }
                                        }

                                        Rectangle { width: 1; height: 34; color: Theme.line; opacity: 0.6 }

                                        PmMetric {
                                            label: "平均收益"
                                            value: { var v = root.pm.returnPct || 0; return (v >= 0 ? "+" : "") + v.toFixed(2) + "%" }
                                            valueColor: (root.pm.returnPct || 0) >= 0 ? Theme.positive : Theme.negative
                                        }
                                        PmMetric { label: "综合胜率";   value: (root.pm.winRate     || 0).toFixed(1) + "%" }
                                        PmMetric { label: "最大回撤";   value: (root.pm.maxDrawdown || 0).toFixed(2) + "%"; valueColor: Theme.negative }
                                        PmMetric { label: "总交易次数"; value: String(root.pm.tradeCount || 0) }

                                        Item { Layout.fillWidth: true }

                                        Rectangle {
                                            implicitWidth: _noteText.implicitWidth + 16; implicitHeight: 22; radius: 11
                                            color: Theme.panel3; border.color: Theme.border; opacity: 0.85
                                            Text { id: _noteText; anchors.centerIn: parent; text: "各策略等权平均（模拟）"; color: Theme.faint; font.pixelSize: 9 }
                                        }
                                    }

                                    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.line; opacity: 0.5 }

                                    CombinedEquityChart {
                                        Layout.fillWidth: true; Layout.fillHeight: true
                                        results: backtest.results
                                    }
                                }
                            }

                            // Attribution table
                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: backtest.results.length * 38 + 50
                                radius: 11; color: Theme.panel2; border.color: Theme.line; clip: true

                                ColumnLayout {
                                    anchors.fill: parent; anchors.margins: 10; spacing: 0

                                    RowLayout {
                                        Layout.fillWidth: true; Layout.bottomMargin: 4; spacing: 0
                                        Item { implicitWidth: 14 }
                                        Text { text: "策略名称"; color: Theme.faint; font.pixelSize: 9; font.letterSpacing: 0.6; Layout.fillWidth: true; leftPadding: 8 }
                                        Text { text: "权重";     color: Theme.faint; font.pixelSize: 9; font.letterSpacing: 0.6; Layout.preferredWidth: 40;  horizontalAlignment: Text.AlignRight }
                                        Text { text: "收益率";   color: Theme.faint; font.pixelSize: 9; font.letterSpacing: 0.6; Layout.preferredWidth: 66;  horizontalAlignment: Text.AlignRight }
                                        Text { text: "胜率";     color: Theme.faint; font.pixelSize: 9; font.letterSpacing: 0.6; Layout.preferredWidth: 48;  horizontalAlignment: Text.AlignRight }
                                        Text { text: "交易次数"; color: Theme.faint; font.pixelSize: 9; font.letterSpacing: 0.6; Layout.preferredWidth: 52;  horizontalAlignment: Text.AlignRight }
                                        Text { text: "最大回撤"; color: Theme.faint; font.pixelSize: 9; font.letterSpacing: 0.6; Layout.preferredWidth: 58;  horizontalAlignment: Text.AlignRight }
                                    }

                                    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.line; opacity: 0.4; Layout.bottomMargin: 2 }

                                    Repeater {
                                        model: backtest.results
                                        delegate: AttributionRow {
                                            required property var modelData
                                            required property int index
                                            result: modelData; rowIndex: index
                                            totalCount: backtest.results.length
                                            dotColor: ["#42d66f","#5cb2ff","#f5c542","#ef5350","#c77dff","#ff9f43"][index % 6]
                                            width: parent ? parent.width : 0
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ════════════════════════════════════════════════════════════════════
    //  INLINE COMPONENTS
    // ════════════════════════════════════════════════════════════════════

    component StrategyPicker: Item {
        id: _picker
        property var selectedItems: []
        signal toggleStrategy(string strategy)

        implicitHeight: 34
        implicitWidth: 260

        function summaryText() {
            if (!selectedItems || selectedItems.length === 0)
                return "选择策略"
            if (selectedItems.length === 1)
                return selectedItems[0]
            if (selectedItems.length === 2)
                return selectedItems[0] + " / " + selectedItems[1]
            return selectedItems[0] + " 等 " + selectedItems.length + " 个策略"
        }

        Rectangle {
            id: _pickerButton
            anchors.fill: parent
            radius: 10
            color: _pickerMA.containsMouse || _pickerPopup.opened ? Theme.panel3 : Theme.panel2
            border.color: _pickerPopup.opened ? Theme.primary : Theme.border
            Behavior on color { ColorAnimation { duration: 140 } }
            Behavior on border.color { ColorAnimation { duration: 140 } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 10
                spacing: 8

                Text {
                    text: _picker.summaryText()
                    color: Theme.text
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    text: "⌄"
                    color: _pickerPopup.opened ? Theme.primary : Theme.muted
                    font.pixelSize: 13
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            MouseArea {
                id: _pickerMA
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: _pickerPopup.opened ? _pickerPopup.close() : _pickerPopup.open()
            }
        }

        Popup {
            id: _pickerPopup
            x: 0
            y: _picker.height + 4
            width: _picker.width
            height: Math.min(384, backtest.strategies.length * 38 + 8)
            padding: 4
            modal: false
            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

            background: Rectangle {
                radius: 10
                color: Theme.surface
                border.color: Theme.border
            }

            contentItem: ListView {
                clip: true
                model: backtest.strategies
                boundsBehavior: Flickable.StopAtBounds

                delegate: ItemDelegate {
                    id: _strategyOption
                    required property string modelData
                    required property int index
                    readonly property bool selected: _picker.selectedItems.indexOf(modelData) >= 0

                    width: ListView.view.width
                    height: 38

                    contentItem: RowLayout {
                        spacing: 8

                        Text {
                            text: _strategyOption.modelData
                            color: _strategyOption.selected ? Theme.text : (_strategyOption.hovered ? Theme.text : Theme.muted)
                            font.pixelSize: 12
                            font.weight: _strategyOption.selected ? Font.DemiBold : Font.Normal
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            verticalAlignment: Text.AlignVCenter
                            Behavior on color { ColorAnimation { duration: 110 } }
                        }

                        Text {
                            text: "✓"
                            visible: _strategyOption.selected
                            color: Theme.primary
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }

                    background: Rectangle {
                        radius: 7
                        color: _strategyOption.selected ? Theme.primarySoft : (_strategyOption.hovered ? Theme.panel3 : "transparent")
                        border.color: _strategyOption.selected ? Theme.primary : "transparent"
                        Behavior on color { ColorAnimation { duration: 110 } }
                        Behavior on border.color { ColorAnimation { duration: 110 } }
                    }

                    onClicked: _picker.toggleStrategy(_strategyOption.modelData)
                }
            }
        }
    }

    component BtControlGroup: ColumnLayout {
        id: controlGroup
        default property alias content: slot.data
        property string label: ""
        spacing: 4; Layout.alignment: Qt.AlignBottom
        Text { text: controlGroup.label; color: Theme.faint; font.pixelSize: 10; font.letterSpacing: 1.0 }
        Item { id: slot; implicitHeight: 40; implicitWidth: childrenRect.width }
    }

    component BtComboBox: ComboBox {
        id: _cb
        implicitHeight: 40
        contentItem: Text {
            leftPadding: 12; rightPadding: 26
            text: _cb.displayText; color: Theme.text
            font.pixelSize: 13; verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight
        }
        background: Rectangle {
            radius: 10
            color: _cb.pressed ? Theme.panel3 : _cb.hovered ? Theme.panel3 : Theme.panel2
            border.color: _cb.pressed ? Theme.primary : Theme.border
            Behavior on color { ColorAnimation { duration: 150 } }
        }
        indicator: Text {
            x: _cb.width - width - 9; y: (_cb.height - height) / 2
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
                color: _del.highlighted ? Theme.text : Theme.muted
                font.pixelSize: 13; verticalAlignment: Text.AlignVCenter
            }
            highlighted: _cb.highlightedIndex === _del.index
            background: Rectangle {
                radius: 7
                color: _del.highlighted ? Theme.panel3 : "transparent"
                Behavior on color { ColorAnimation { duration: 110 } }
            }
        }
    }

    component BtLabeledInput: ColumnLayout {
        property string label: ""
        property string text: ""
        property int    inputWidth: 70
        signal commit(string value)
        spacing: 2
        Text { text: parent.label; color: Theme.faint; font.pixelSize: 10; font.letterSpacing: 0.8 }
        TextField {
            implicitWidth: parent.inputWidth; implicitHeight: 34
            text: parent.text; color: Theme.text
            font.pixelSize: 13; leftPadding: 8; selectByMouse: true
            onEditingFinished: parent.commit(text)
            background: Rectangle {
                radius: 8; color: Theme.background
                border.color: parent.activeFocus ? Theme.primary : Theme.border
                Behavior on border.color { ColorAnimation { duration: 140 } }
            }
        }
    }

    component ModeBtn: Button {
        id: _mb
        property bool active: false
        implicitWidth: 52; implicitHeight: 34
        scale: pressed ? 0.97 : 1
        Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
        contentItem: Text {
            text: _mb.text; color: _mb.active ? Theme.text : Theme.muted
            font.pixelSize: 12; font.weight: _mb.active ? Font.DemiBold : Font.Normal
            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle {
            radius: 9
            color: _mb.active ? Theme.primarySoft : _mb.hovered ? Theme.panel3 : Theme.panel2
            border.color: _mb.active ? Theme.primary : Theme.border
            Behavior on color { ColorAnimation { duration: 140 } }
            Behavior on border.color { ColorAnimation { duration: 140 } }
        }
    }

    component ChartTab: Button {
        id: _ct
        property bool active: false
        implicitHeight: 28
        scale: pressed ? 0.97 : 1
        Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
        contentItem: Text {
            text: _ct.text; color: _ct.active ? Theme.primary : Theme.muted
            font.pixelSize: 12; font.weight: _ct.active ? Font.DemiBold : Font.Normal
            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
            leftPadding: 10; rightPadding: 10
        }
        background: Rectangle {
            radius: 8
            color: _ct.active ? Theme.primarySoft : _ct.hovered ? Theme.panel3 : "transparent"
            border.color: _ct.active ? Theme.primary : "transparent"
            Behavior on color { ColorAnimation { duration: 130 } }
        }
    }

    component ToggleChip: Button {
        id: _tc
        property bool active: false
        implicitHeight: 26
        scale: pressed ? 0.96 : 1
        Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
        contentItem: Text {
            text: _tc.text; color: _tc.active ? Theme.primary : Theme.faint
            font.pixelSize: 11; font.weight: _tc.active ? Font.DemiBold : Font.Normal
            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
            leftPadding: 8; rightPadding: 8
        }
        background: Rectangle {
            radius: 7
            color: _tc.active ? Theme.primarySoft : _tc.hovered ? Theme.panel3 : Theme.panel2
            border.color: _tc.active ? Theme.primary : Theme.line
            Behavior on color { ColorAnimation { duration: 120 } }
        }
    }

    component SymbolChip: Rectangle {
        id: _chip
        property string chipKey: ""
        property string symbol:  ""
        property string market:  ""
        property bool   active:  false
        implicitHeight: 32; implicitWidth: _chipLabel.implicitWidth + 52
        radius: 16
        color: active ? Theme.primarySoft : _chipMA.containsMouse ? Theme.panel3 : Theme.panel2
        border.color: active ? Theme.primary : Theme.border
        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }
        Text {
            id: _chipLabel
            anchors.left: parent.left; anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            text: _chip.symbol + "  " + _chip.market
            color: _chip.active ? Theme.text : Theme.muted
            font.pixelSize: 12; font.weight: _chip.active ? Font.DemiBold : Font.Normal
        }
        Rectangle {
            id: _closeArea
            width: 20; height: 20; radius: 10
            anchors.right: parent.right; anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            color: _closeMA.containsMouse ? Theme.panel3 : "transparent"
            Text { anchors.centerIn: parent; text: "×"; color: _closeMA.containsMouse ? Theme.text : Theme.faint; font.pixelSize: 14 }
            MouseArea {
                id: _closeMA; anchors.fill: parent
                hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: backtest.removeSymbol(_chip.chipKey)
            }
        }
        MouseArea {
            id: _chipMA
            anchors { left: parent.left; right: _closeArea.left; top: parent.top; bottom: parent.bottom }
            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            onClicked: backtest.selectSymbol(_chip.chipKey)
        }
    }

    // ── Expandable result card ────────────────────────────────────────────
    component ResultCard: Rectangle {
        id: _card
        property var    result:      ({})
        property int    resultIndex: 0
        property bool   expanded:    false
        signal toggleExpand()

        property string cardChartTab: "kline"
        property bool   cardMa5:  true
        property bool   cardMa20: true
        property bool   cardMacd: false

        readonly property int _headerH: 118
        readonly property int _chartH:  390

        height: expanded ? _headerH + _chartH : _headerH
        clip: true
        Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        radius: 11
        color: expanded ? Theme.panel3 : _headerMA.containsMouse ? Theme.surface : Theme.panel2
        border.color: expanded ? Theme.primary : Theme.line
        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        // ── Header area (always visible) ─────────────────────────────────
        Item {
            id: _headerArea
            anchors { left: parent.left; right: parent.right; top: parent.top }
            height: _card._headerH

            MouseArea {
                id: _headerMA; anchors.fill: parent
                hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: _card.toggleExpand()
            }

            ColumnLayout {
                anchors.fill: parent; anchors.margins: 12; spacing: 7

                // Strategy name row
                RowLayout {
                    Layout.fillWidth: true; spacing: 8
                    Rectangle {
                        width: 3; height: 13; radius: 2
                        color: (_card.result.returnPct || 0) >= 0 ? Theme.positive : Theme.negative
                    }
                    Text {
                        text: _card.result.strategyName || "—"
                        color: Theme.text; font.pixelSize: 12; font.weight: Font.DemiBold
                        Layout.fillWidth: true; elide: Text.ElideRight
                    }
                    // Expand/collapse chevron
                    Text {
                        text: _card.expanded ? "⌃" : "⌄"
                        color: Theme.faint; font.pixelSize: 13
                        Behavior on text {} // suppress binding warning
                    }
                }

                // Capital row
                RowLayout {
                    Layout.fillWidth: true; spacing: 6
                    Text { text: "$" + (_card.result.initialCapital || 0).toLocaleString(); color: Theme.muted; font.pixelSize: 11; font.family: "Menlo" }
                    Text { text: "→"; color: Theme.faint; font.pixelSize: 11 }
                    Text { text: "$" + Math.round(_card.result.finalCapital || 0).toLocaleString(); color: Theme.text; font.pixelSize: 11; font.weight: Font.DemiBold; font.family: "Menlo" }
                    Text {
                        text: ((_card.result.returnPct || 0) >= 0 ? "+" : "") + (_card.result.returnPct || 0).toFixed(2) + "%"
                        color: (_card.result.returnPct || 0) >= 0 ? Theme.positive : Theme.negative
                        font.pixelSize: 12; font.weight: Font.DemiBold
                    }
                    Item { Layout.fillWidth: true }
                }

                // Metrics grid
                GridLayout {
                    Layout.fillWidth: true; columns: 6; rowSpacing: 4; columnSpacing: 6
                    MetricPill { label: "交易次数"; value: String(_card.result.tradeCount || 0) }
                    MetricPill { label: "胜率";    value: (_card.result.winRate || 0).toFixed(1) + "%" }
                    MetricPill { label: "最大回撤"; value: (_card.result.maxDrawdown || 0).toFixed(2) + "%" }
                    MetricPill { label: "最深浮亏"; value: (_card.result.maxFloatLoss || 0).toFixed(2) + "%" }
                    MetricPill { label: "均持仓";  value: (_card.result.avgHoldDays || 0).toFixed(1) + "天" }
                    MetricPill { label: "最长持仓"; value: String(_card.result.maxHoldDays || 0) + "天" }
                }
            }
        }

        // ── Expandable chart section ──────────────────────────────────────
        Item {
            id: _chartSection
            anchors { left: parent.left; right: parent.right; top: _headerArea.bottom }
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            height: _card._chartH - 12
            visible: _card.height > _card._headerH + 1
            opacity: _card.expanded ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 180 } }

            ColumnLayout {
                anchors.fill: parent; spacing: 6

                // Separator
                Rectangle { Layout.fillWidth: true; height: 1; color: Theme.line; opacity: 0.6 }

                // Chart tab bar + indicator toggles
                RowLayout {
                    Layout.fillWidth: true; spacing: 4
                    ChartTab { text: "K线+标注"; active: _card.cardChartTab === "kline";  onClicked: _card.cardChartTab = "kline"  }
                    ChartTab { text: "交易盈亏"; active: _card.cardChartTab === "pnl";    onClicked: _card.cardChartTab = "pnl"    }
                    ChartTab { text: "资产走势"; active: _card.cardChartTab === "equity"; onClicked: _card.cardChartTab = "equity" }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 4; visible: _card.cardChartTab === "kline"
                        ToggleChip { text: "MA5";  active: _card.cardMa5;  onClicked: _card.cardMa5  = !_card.cardMa5  }
                        ToggleChip { text: "MA20"; active: _card.cardMa20; onClicked: _card.cardMa20 = !_card.cardMa20 }
                        ToggleChip { text: "MACD"; active: _card.cardMacd; onClicked: _card.cardMacd = !_card.cardMacd }
                    }
                }

                // Chart canvas
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 300

                    TradeAnnotatedChart {
                        anchors.fill: parent
                        visible: _chartSection.visible && _card.cardChartTab === "kline"
                        bars:     _card.result.annotatedBars || []
                        showMa5:  _card.cardMa5
                        showMa20: _card.cardMa20
                        showMacd: _card.cardMacd
                    }

                    PnlBarChart {
                        anchors.fill: parent
                        visible: _chartSection.visible && _card.cardChartTab === "pnl"
                        trades: _card.result.trades || []
                    }

                    EquityCurveChart {
                        anchors.fill: parent
                        visible: _chartSection.visible && _card.cardChartTab === "equity"
                        equityCurve: _card.result.equityCurve || []
                    }
                }
            }
        }
    }

    component MetricPill: ColumnLayout {
        property string label: ""
        property string value: "—"
        spacing: 1
        Text { text: parent.label; color: Theme.faint; font.pixelSize: 9; font.letterSpacing: 0.5 }
        Text { text: parent.value; color: Theme.text; font.pixelSize: 11; font.weight: Font.DemiBold; font.family: "Menlo" }
    }

    // Portfolio-level metric block (combine overview header)
    component PmMetric: ColumnLayout {
        property string label: ""; property string value: "—"; property color valueColor: Theme.text
        spacing: 2
        Text { text: parent.label; color: Theme.faint; font.pixelSize: 9; font.letterSpacing: 0.7 }
        Text { text: parent.value; color: parent.valueColor; font.pixelSize: 17; font.weight: Font.DemiBold; font.family: "Menlo" }
    }

    // Attribution table row (combine mode)
    component AttributionRow: Item {
        property var   result:     ({})
        property int   rowIndex:   0
        property int   totalCount: 1
        property color dotColor:   "#42d66f"
        implicitHeight: 38

        Rectangle {
            anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
            height: 1; color: Theme.line; opacity: 0.3
            visible: rowIndex < totalCount - 1
        }

        RowLayout {
            anchors { fill: parent; leftMargin: 2; rightMargin: 2 }
            spacing: 0
            Rectangle { width: 7; height: 7; radius: 3.5; color: dotColor; Layout.rightMargin: 8 }
            Text { text: result.strategyName || "—"; color: Theme.text; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight; Layout.rightMargin: 6 }
            Text { text: Math.round(100 / totalCount) + "%"; color: Theme.faint; font.pixelSize: 10; font.family: "Menlo"; Layout.preferredWidth: 40; horizontalAlignment: Text.AlignRight; Layout.rightMargin: 8 }
            Text {
                text: ((result.returnPct || 0) >= 0 ? "+" : "") + (result.returnPct || 0).toFixed(2) + "%"
                color: (result.returnPct || 0) >= 0 ? Theme.positive : Theme.negative
                font.pixelSize: 11; font.weight: Font.DemiBold; font.family: "Menlo"
                Layout.preferredWidth: 66; horizontalAlignment: Text.AlignRight; Layout.rightMargin: 8
            }
            Text { text: (result.winRate    || 0).toFixed(1) + "%"; color: Theme.muted;    font.pixelSize: 11; font.family: "Menlo"; Layout.preferredWidth: 48; horizontalAlignment: Text.AlignRight; Layout.rightMargin: 8 }
            Text { text: String(result.tradeCount || 0);             color: Theme.muted;    font.pixelSize: 11; font.family: "Menlo"; Layout.preferredWidth: 52; horizontalAlignment: Text.AlignRight; Layout.rightMargin: 8 }
            Text { text: (result.maxDrawdown || 0).toFixed(2) + "%"; color: Theme.negative; font.pixelSize: 11; font.family: "Menlo"; Layout.preferredWidth: 58; horizontalAlignment: Text.AlignRight }
        }
    }
}
