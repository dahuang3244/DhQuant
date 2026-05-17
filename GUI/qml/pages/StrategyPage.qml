pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Item {
    id: root

    property string factorCat: "全部"
    property bool   addFactorOpen: false
    property bool   addFieldOpen:  false

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 14

        // ── A. Header ───────────────────────────────────────────────────
        Rectangle {
            id: headerRect
            Layout.fillWidth: true
            Layout.preferredHeight: 88
            radius: Theme.radiusLarge
            color: Theme.surface
            border.color: Theme.line

            Rectangle {
                width: 4
                anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                color: Theme.primary; opacity: 0.85
            }

            RowLayout {
                anchors { fill: parent; leftMargin: 20; rightMargin: 16; topMargin: 14; bottomMargin: 14 }
                spacing: 12

                ColumnLayout {
                    spacing: 3; Layout.alignment: Qt.AlignVCenter
                    Text { text: "策略中心"; color: Theme.text; font.pixelSize: 20; font.weight: Font.DemiBold }
                    Text { text: "STRATEGY LAB"; color: Theme.muted; font.pixelSize: 10; font.letterSpacing: 1.1 }
                }

                Item { Layout.fillWidth: true }

                // Strategy library dropdown button — Popup lives inside so x/y are relative to this button
                Button {
                    id: libDropBtn
                    implicitHeight: 34
                    implicitWidth: libRow.implicitWidth + 22
                    onClicked: libDropPopup.visible ? libDropPopup.close() : libDropPopup.open()

                    contentItem: RowLayout {
                        id: libRow
                        anchors.centerIn: parent
                        spacing: 5
                        Text { text: "策略库"; color: Theme.primary; font.pixelSize: 12; font.weight: Font.DemiBold }
                        Text { text: strategy.allStrategies.length + " 个"; color: Theme.muted; font.pixelSize: 11 }
                        Text { text: libDropPopup.visible ? "▴" : "▾"; color: Theme.faint; font.pixelSize: 9 }
                    }
                    background: Rectangle {
                        radius: 10
                        color: libDropPopup.visible ? Theme.panel3 : (parent.hovered ? Theme.panel2 : Theme.panel2)
                        border.color: libDropPopup.visible ? Theme.primary : Theme.border
                        Behavior on border.color { ColorAnimation { duration: 120 } }
                        Behavior on color        { ColorAnimation { duration: 120 } }
                    }

                    // Popup anchored to this button — always aligned regardless of sidebar/window
                    Popup {
                        id: libDropPopup
                        x: parent.width - width     // right edge of popup = right edge of button
                        y: parent.height + 6        // just below the button
                        width: 260
                        padding: 6
                        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

                        background: Rectangle {
                            color: Theme.panel2; radius: Theme.radius; border.color: Theme.border
                        }

                        contentItem: ColumnLayout {
                            spacing: 4

                            Text {
                                text: "策略库 · " + strategy.allStrategies.length + " 个"
                                color: Theme.muted; font.pixelSize: 10; font.letterSpacing: 0.8
                                leftPadding: 4
                            }

                            ScrollView {
                                Layout.fillWidth: true
                                implicitHeight: Math.min(340, libPopupList.contentHeight)
                                clip: true
                                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                                ListView {
                                    id: libPopupList
                                    model: strategy.allStrategies
                                    spacing: 2
                                    delegate: Rectangle {
                                        required property string modelData
                                        width: ListView.view.width; height: 32; radius: 6
                                        color: strategy.currentStrategy === modelData ? Theme.primarySoft : "transparent"
                                        border.color: strategy.currentStrategy === modelData ? Theme.primary : "transparent"
                                        Behavior on color { ColorAnimation { duration: 100 } }

                                        RowLayout {
                                            anchors { fill: parent; leftMargin: 10; rightMargin: 8 }
                                            Text {
                                                text: modelData
                                                color: strategy.currentStrategy === modelData ? Theme.primary : Theme.text
                                                font.pixelSize: 12; elide: Text.ElideRight; Layout.fillWidth: true
                                                verticalAlignment: Text.AlignVCenter
                                            }
                                            Text {
                                                visible: strategy.currentStrategy === modelData
                                                text: "✓"; color: Theme.primary; font.pixelSize: 11
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                strategy.selectStrategy(modelData)
                                                strategy.setTab("code")
                                                libDropPopup.close()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Sync to backtest
                Button {
                    implicitWidth: 108; implicitHeight: 34
                    text: "→ 同步到回测"
                    onClicked: {
                        strategy.saveStrategy()
                        dashboard.setPage("backtest")
                        dashboard.showToast("策略已同步", "策略库已更新，可在回测工作台选择")
                    }
                    contentItem: Text { text: parent.text; color: Theme.text; font.pixelSize: 12; font.weight: Font.DemiBold; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    background: Rectangle {
                        radius: 10; color: parent.hovered ? Theme.panel3 : Theme.panel2
                        border.color: parent.hovered ? Theme.primary : Theme.border
                        Behavior on color        { ColorAnimation { duration: 130 } }
                        Behavior on border.color { ColorAnimation { duration: 130 } }
                    }
                }

                // New strategy
                Button {
                    implicitWidth: 100; implicitHeight: 34
                    text: "+ 新建策略"
                    onClicked: { strategy.newStrategy(); strategy.setTab("code") }
                    scale: pressed ? 0.97 : 1
                    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
                    contentItem: Text { text: parent.text; color: Theme.text; font.pixelSize: 13; font.weight: Font.DemiBold; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    background: Rectangle {
                        radius: 10
                        color: parent.hovered ? Theme.primaryHover : Theme.primary
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }
            }
        }

        // ── B. Pipeline Step Tabs ────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 52
            radius: Theme.radiusLarge
            color: Theme.surface
            border.color: Theme.line

            RowLayout {
                anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                spacing: 4

                Repeater {
                    model: [
                        {tab: "data",     num: "①", label: "数据采集"},
                        {tab: "factor",   num: "②", label: "因子计算"},
                        {tab: "mining",   num: "③", label: "因子挖掘"},
                        {tab: "analysis", num: "④", label: "因子分析"},
                        {tab: "ml",       num: "⑤", label: "机器学习"},
                        {tab: "code",     num: "⑥", label: "策略编写"},
                    ]
                    delegate: Button {
                        required property var modelData
                        implicitHeight: 34
                        implicitWidth: _num.implicitWidth + _lbl.implicitWidth + 20
                        flat: true
                        onClicked: strategy.setTab(modelData.tab)
                        readonly property bool isActive: strategy.activeTab === modelData.tab

                        contentItem: RowLayout {
                            spacing: 5
                            Text { id: _num; text: modelData.num; color: isActive ? Theme.primary : Theme.faint; font.pixelSize: 15; Behavior on color { ColorAnimation { duration: 140 } } }
                            Text { id: _lbl; text: modelData.label; color: isActive ? Theme.text : Theme.muted; font.pixelSize: 13; font.weight: isActive ? Font.DemiBold : Font.Normal; Behavior on color { ColorAnimation { duration: 140 } } }
                        }
                        background: Rectangle {
                            radius: 10
                            color: isActive ? Theme.panel3 : (parent.hovered ? Theme.panel2 : "transparent")
                            border.color: isActive ? Theme.primary : "transparent"
                            Behavior on color        { ColorAnimation { duration: 140 } }
                            Behavior on border.color { ColorAnimation { duration: 140 } }
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Selected factors preview chips
                Repeater {
                    model: strategy.selectedFactors
                    delegate: Rectangle {
                        required property string modelData
                        height: 22; radius: 11; width: _sfTxt.implicitWidth + 14
                        color: Theme.primarySoft; border.color: Theme.primary
                        Text { id: _sfTxt; anchors.centerIn: parent; text: modelData; color: Theme.primary; font.pixelSize: 10; font.weight: Font.DemiBold }
                    }
                }
            }
        }

        // ── C. Content Area ─────────────────────────────────────────────
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // ══ Tab 1: 数据采集 ══════════════════════════════════════════
            RowLayout {
                anchors.fill: parent; spacing: 14
                visible: strategy.activeTab === "data"

                // Source list
                Rectangle {
                    Layout.preferredWidth: 230; Layout.fillHeight: true
                    color: Theme.surface; radius: Theme.radiusLarge; border.color: Theme.line

                    ColumnLayout {
                        anchors { fill: parent; margins: 14 }
                        spacing: 8
                        Text { text: "数据源"; color: Theme.muted; font.pixelSize: 11; font.letterSpacing: 0.8 }

                        Repeater {
                            model: strategy.dataSources
                            delegate: Rectangle {
                                required property var modelData
                                Layout.fillWidth: true; height: 64; radius: Theme.radius
                                color: Theme.panel2; border.color: Theme.border

                                ColumnLayout {
                                    anchors { fill: parent; margins: 10 }
                                    spacing: 4
                                    RowLayout {
                                        Text { text: modelData.name; color: Theme.text; font.pixelSize: 13; font.weight: Font.DemiBold; Layout.fillWidth: true }
                                        Rectangle {
                                            height: 18; radius: 9; width: _dsSt.implicitWidth + 12
                                            color: modelData.status === "已配置" ? "#122820" : "#1c1c14"
                                            border.color: modelData.status === "已配置" ? Theme.positive : Theme.warning
                                            Text { id: _dsSt; anchors.centerIn: parent; text: modelData.status; color: modelData.status === "已配置" ? Theme.positive : Theme.warning; font.pixelSize: 9; font.weight: Font.DemiBold }
                                        }
                                    }
                                    Text { text: modelData.note; color: Theme.faint; font.pixelSize: 10 }
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }
                }

                // Config panel
                Rectangle {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    color: Theme.surface; radius: Theme.radiusLarge; border.color: Theme.line

                    ColumnLayout {
                        anchors { fill: parent; margins: 20 }
                        spacing: 14

                        Text { text: "采集配置"; color: Theme.muted; font.pixelSize: 11; font.letterSpacing: 0.8 }

                        GridLayout {
                            columns: 2; columnSpacing: 14; rowSpacing: 10; Layout.fillWidth: true
                            SgLabel { text: "市场" }
                            SgComboBox { model: ["A股", "美股", "港股", "加密"]; Layout.fillWidth: true }
                            SgLabel { text: "开始日期" }
                            SgTextField { text: "2020-01-01"; Layout.fillWidth: true }
                            SgLabel { text: "结束日期" }
                            SgTextField { text: "2026-01-01"; Layout.fillWidth: true }
                            SgLabel { text: "频率" }
                            SgComboBox { model: ["日K", "小时K", "分钟K"]; Layout.fillWidth: true }
                        }

                        // Fields section
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "采集字段"; color: Theme.muted; font.pixelSize: 11; font.letterSpacing: 0.8; Layout.fillWidth: true }
                            // Custom field add button
                            Button {
                                implicitWidth: 80; implicitHeight: 26; flat: true
                                text: root.addFieldOpen ? "收起" : "+ 自定义"
                                onClicked: root.addFieldOpen = !root.addFieldOpen
                                contentItem: Text { text: parent.text; color: Theme.primary; font.pixelSize: 11; font.weight: Font.DemiBold; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                background: Rectangle { radius: 8; color: parent.hovered ? Theme.primarySoft : "transparent"; border.color: parent.hovered ? Theme.primary : "transparent" }
                            }
                        }

                        // Custom field input row
                        RowLayout {
                            Layout.fillWidth: true
                            visible: root.addFieldOpen
                            spacing: 8
                            TextField {
                                id: newFieldInput
                                Layout.fillWidth: true; implicitHeight: 32
                                placeholderText: "输入字段名，如 TURNOVER"
                                color: Theme.text; placeholderTextColor: Theme.faint
                                font.pixelSize: 12; leftPadding: 10; selectByMouse: true
                                background: Rectangle { radius: 8; color: Theme.background; border.color: parent.activeFocus ? Theme.primary : Theme.border; Behavior on border.color { ColorAnimation { duration: 140 } } }
                                onAccepted: { strategy.addDataField(text); text = ""; root.addFieldOpen = false }
                            }
                            Button {
                                implicitWidth: 52; implicitHeight: 32; text: "添加"
                                onClicked: { strategy.addDataField(newFieldInput.text); newFieldInput.text = ""; root.addFieldOpen = false }
                                contentItem: Text { text: parent.text; color: Theme.text; font.pixelSize: 12; font.weight: Font.DemiBold; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                background: Rectangle { radius: 8; color: parent.hovered ? Theme.primaryHover : Theme.primary; Behavior on color { ColorAnimation { duration: 150 } } }
                            }
                        }

                        Flow {
                            Layout.fillWidth: true; spacing: 6
                            Repeater {
                                model: ["开高低收", "成交量", "换手率", "PE/PB", "ROE", "净利润", "资产负债率", "股息率"]
                                delegate: Rectangle {
                                    required property string modelData
                                    required property int index
                                    height: 26; radius: 13; width: _fldTxt.implicitWidth + 16
                                    color: index < 4 ? Theme.primarySoft : Theme.panel2
                                    border.color: index < 4 ? Theme.primary : Theme.border
                                    Text { id: _fldTxt; anchors.centerIn: parent; text: modelData; color: index < 4 ? Theme.primary : Theme.muted; font.pixelSize: 11 }
                                }
                            }
                            // Custom fields
                            Repeater {
                                model: strategy.customDataFields
                                delegate: Rectangle {
                                    required property string modelData
                                    height: 26; radius: 13; width: _cFldTxt.implicitWidth + 16
                                    color: "#1c1020"; border.color: Theme.primary
                                    Text { id: _cFldTxt; anchors.centerIn: parent; text: modelData; color: Theme.primary; font.pixelSize: 11 }
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }

                        Button {
                            Layout.fillWidth: true; implicitHeight: 40; text: "开始采集"
                            onClicked: dashboard.showToast("数据采集", "后端数据采集服务尚未接入")
                            contentItem: Text { text: parent.text; color: Theme.text; font.pixelSize: 14; font.weight: Font.DemiBold; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                            background: Rectangle { radius: 10; color: parent.hovered ? Theme.primaryHover : Theme.primary; Behavior on color { ColorAnimation { duration: 150 } } }
                        }
                    }
                }
            }

            // ══ Tab 2: 因子计算 ══════════════════════════════════════════
            ColumnLayout {
                anchors.fill: parent; spacing: 10
                visible: strategy.activeTab === "factor"

                // Category + action row
                Rectangle {
                    Layout.fillWidth: true; height: 44
                    color: Theme.surface; radius: Theme.radiusLarge; border.color: Theme.line

                    RowLayout {
                        anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                        spacing: 10

                        SgLabel { text: "分类" }
                        SgComboBox {
                            id: catCombo
                            implicitWidth: 110
                            model: ["全部", "趋势", "震荡", "量价", "基本面", "动量", "反转", "挖掘", "自定义"]
                            currentIndex: model.indexOf(root.factorCat) < 0 ? 0 : model.indexOf(root.factorCat)
                            onActivated: { root.factorCat = currentText; strategy.setFactorCategory(currentText) }
                        }

                        Text { text: strategy.selectedFactors.length + " 个已选"; color: Theme.muted; font.pixelSize: 11 }

                        Item { Layout.fillWidth: true }

                        // Add factor button
                        Button {
                            implicitWidth: 90; implicitHeight: 32; flat: true
                            text: root.addFactorOpen ? "▴ 收起" : "+ 添加因子"
                            onClicked: root.addFactorOpen = !root.addFactorOpen
                            contentItem: Text { text: parent.text; color: Theme.primary; font.pixelSize: 12; font.weight: Font.DemiBold; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                            background: Rectangle { radius: 9; color: parent.hovered ? Theme.primarySoft : "transparent"; border.color: root.addFactorOpen ? Theme.primary : (parent.hovered ? Theme.primary : "transparent"); Behavior on color { ColorAnimation { duration: 120 } } }
                        }

                        // Clear selection
                        Button {
                            implicitWidth: 82; implicitHeight: 32; flat: true
                            text: "× 清除选中"
                            onClicked: strategy.clearSelectedFactors()
                            contentItem: Text { text: parent.text; color: Theme.negative; font.pixelSize: 12; font.weight: Font.DemiBold; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                            background: Rectangle { radius: 9; color: parent.hovered ? "#2b1212" : "transparent"; Behavior on color { ColorAnimation { duration: 120 } } }
                        }
                    }
                }

                // Add factor panel — fixed height, opacity animation avoids clip/height bugs
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 68
                    visible: root.addFactorOpen
                    opacity: root.addFactorOpen ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                    color: Theme.panel2; radius: Theme.radius; border.color: Theme.border

                    RowLayout {
                        anchors { fill: parent; leftMargin: 16; rightMargin: 16; topMargin: 0; bottomMargin: 0 }
                        spacing: 12

                        Text { text: "名称"; color: Theme.muted; font.pixelSize: 12 }

                        TextField {
                            id: newFactorNameInput
                            Layout.preferredWidth: 180
                            implicitHeight: 38
                            placeholderText: "MY_FACTOR_001"
                            color: Theme.text
                            placeholderTextColor: Theme.faint
                            font.pixelSize: 13
                            leftPadding: 12
                            selectByMouse: true
                            background: Rectangle {
                                radius: 9; color: Theme.background
                                border.color: parent.activeFocus ? Theme.primary : Theme.border
                                Behavior on border.color { ColorAnimation { duration: 140 } }
                            }
                        }

                        Text { text: "分类"; color: Theme.muted; font.pixelSize: 12 }

                        ComboBox {
                            id: newFactorCatCombo
                            implicitWidth: 110; implicitHeight: 38
                            model: ["趋势", "震荡", "量价", "基本面", "动量", "反转", "自定义"]
                            contentItem: Text {
                                leftPadding: 10; rightPadding: 22
                                text: newFactorCatCombo.displayText
                                color: Theme.text; font.pixelSize: 13
                                verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight
                            }
                            indicator: Text {
                                x: newFactorCatCombo.width - width - 8
                                anchors.verticalCenter: parent.verticalCenter
                                text: "▾"; color: Theme.faint; font.pixelSize: 9
                            }
                            background: Rectangle {
                                radius: 9; color: Theme.background
                                border.color: newFactorCatCombo.down ? Theme.primary : Theme.border
                            }
                            delegate: ItemDelegate {
                                required property string modelData
                                required property int index
                                width: newFactorCatCombo.width; height: 30
                                contentItem: Text { text: modelData; color: Theme.text; font.pixelSize: 12; verticalAlignment: Text.AlignVCenter; leftPadding: 10 }
                                background: Rectangle { radius: 6; color: parent.hovered ? Theme.panel3 : "transparent" }
                            }
                            popup: Popup {
                                y: newFactorCatCombo.height + 2; width: newFactorCatCombo.width; padding: 4
                                background: Rectangle { color: Theme.panel2; radius: Theme.radius; border.color: Theme.border }
                                contentItem: ListView {
                                    clip: true; implicitHeight: contentHeight
                                    model: newFactorCatCombo.delegateModel
                                }
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Button {
                            implicitWidth: 64; implicitHeight: 38; text: "添加"
                            onClicked: {
                                var name = newFactorNameInput.text.trim()
                                if (name.length > 0) {
                                    strategy.addCustomFactor(name, newFactorCatCombo.currentText)
                                    dashboard.showToast("因子已添加", "「" + name + "」已加入因子列表")
                                    newFactorNameInput.text = ""
                                }
                                root.addFactorOpen = false
                            }
                            contentItem: Text { text: parent.text; color: Theme.text; font.pixelSize: 13; font.weight: Font.DemiBold; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                            background: Rectangle { radius: 9; color: parent.hovered ? Theme.primaryHover : Theme.primary; Behavior on color { ColorAnimation { duration: 150 } } }
                        }
                    }
                }

                // Factor table + selected panel
                RowLayout {
                    Layout.fillWidth: true; Layout.fillHeight: true; spacing: 14

                    Rectangle {
                        Layout.fillWidth: true; Layout.fillHeight: true
                        color: Theme.surface; radius: Theme.radiusLarge; border.color: Theme.line; clip: true

                        ColumnLayout {
                            anchors.fill: parent; spacing: 0

                            // Table header
                            Rectangle {
                                Layout.fillWidth: true; height: 34; color: Theme.panel2
                                RowLayout {
                                    anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                                    spacing: 0
                                    ColH { label: "因子名称"; pw: 110 }
                                    ColH { label: "分类";     pw: 72 }
                                    ColH { label: "IC 均值";  pw: 76 }
                                    ColH { label: "IC 条形";  fw: true }
                                    ColH { label: "Sharpe";   pw: 70 }
                                    ColH { label: "胜率";     pw: 62 }
                                    ColH { label: "状态";     pw: 58 }
                                    ColH { label: "";          pw: 54 }
                                }
                            }

                            ScrollView {
                                Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                                ListView {
                                    model: {
                                        var all = strategy.factors
                                        if (root.factorCat === "全部") return all
                                        return all.filter(function(f){ return f.category === root.factorCat })
                                    }
                                    spacing: 0
                                    delegate: Rectangle {
                                        required property var modelData
                                        required property int index
                                        width: ListView.view.width; height: 38
                                        color: index % 2 === 0 ? "transparent" : Theme.panel
                                        readonly property bool selected: strategy.selectedFactors.indexOf(modelData.name) >= 0

                                        Rectangle {
                                            anchors.left: parent.left; width: 3
                                            anchors.top: parent.top; anchors.bottom: parent.bottom
                                            color: Theme.primary; opacity: selected ? 1 : 0
                                            Behavior on opacity { NumberAnimation { duration: 120 } }
                                        }

                                        RowLayout {
                                            anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                                            spacing: 0

                                            Text { text: modelData.name; color: Theme.text; font.pixelSize: 12; font.weight: Font.DemiBold; font.family: "Menlo"; Layout.preferredWidth: 110; elide: Text.ElideRight }

                                            Item {
                                                Layout.preferredWidth: 72
                                                Rectangle {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    height: 18; radius: 9; width: _catBadge.implicitWidth + 10
                                                    color: {
                                                        var c = modelData.category
                                                        if (c==="趋势") return "#122030"; if (c==="震荡") return "#1a1230"
                                                        if (c==="量价") return "#122820"; if (c==="基本面") return "#1c1a10"
                                                        if (c==="挖掘") return "#1c1020"; return Theme.panel2
                                                    }
                                                    border.color: {
                                                        var c = modelData.category
                                                        if (c==="趋势") return "#4a8fff"; if (c==="震荡") return "#a47fff"
                                                        if (c==="量价") return Theme.positive; if (c==="基本面") return Theme.warning
                                                        if (c==="挖掘") return Theme.primary; return Theme.border
                                                    }
                                                    Text {
                                                        id: _catBadge; anchors.centerIn: parent
                                                        text: modelData.category; font.pixelSize: 9; font.weight: Font.DemiBold
                                                        color: {
                                                            var c = modelData.category
                                                            if (c==="趋势") return "#4a8fff"; if (c==="震荡") return "#a47fff"
                                                            if (c==="量价") return Theme.positive; if (c==="基本面") return Theme.warning
                                                            if (c==="挖掘") return Theme.primary; return Theme.muted
                                                        }
                                                    }
                                                }
                                            }

                                            Text { text: modelData.ic.toFixed(3); color: Theme.text; font.pixelSize: 12; font.family: "Menlo"; Layout.preferredWidth: 76 }

                                            Item {
                                                Layout.fillWidth: true; height: 8
                                                Rectangle {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    width: Math.max(4, modelData.ic * 1400); height: 6; radius: 3
                                                    color: modelData.ic > 0.04 ? Theme.positive : modelData.ic > 0.025 ? Theme.primary : Theme.warning
                                                    Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                                                }
                                            }

                                            Text { text: modelData.sharpe.toFixed(2); color: Theme.text; font.pixelSize: 12; font.family: "Menlo"; Layout.preferredWidth: 70 }
                                            Text { text: modelData.win_rate.toFixed(1) + "%"; color: modelData.win_rate > 52 ? Theme.positive : Theme.muted; font.pixelSize: 12; font.family: "Menlo"; Layout.preferredWidth: 62 }

                                            Item {
                                                Layout.preferredWidth: 58
                                                Rectangle {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    height: 18; radius: 9; width: _stBadge.implicitWidth + 12
                                                    color: modelData.status === "优质" ? "#122820" : "#1c1c14"
                                                    border.color: modelData.status === "优质" ? Theme.positive : Theme.faint
                                                    Text { id: _stBadge; anchors.centerIn: parent; text: modelData.status; color: modelData.status === "优质" ? Theme.positive : Theme.faint; font.pixelSize: 9 }
                                                }
                                            }

                                            Button {
                                                Layout.preferredWidth: 54; implicitHeight: 26; flat: true
                                                text: selected ? "移除" : "选择"
                                                onClicked: strategy.toggleFactor(modelData.name)
                                                contentItem: Text { text: parent.text; color: selected ? Theme.negative : Theme.primary; font.pixelSize: 11; font.weight: Font.DemiBold; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                                background: Rectangle { radius: 8; color: parent.hovered ? (selected ? "#2b1212" : Theme.primarySoft) : "transparent"; Behavior on color { ColorAnimation { duration: 120 } } }
                                            }
                                        }
                                        Rectangle { anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right; height: 1; color: Theme.line; opacity: 0.4 }
                                    }
                                }
                            }
                        }
                    }

                    // Selected factors panel
                    Rectangle {
                        Layout.preferredWidth: 190; Layout.fillHeight: true
                        color: Theme.surface; radius: Theme.radiusLarge; border.color: Theme.line

                        ColumnLayout {
                            anchors { fill: parent; margins: 14 }
                            spacing: 10
                            Text { text: "已选因子"; color: Theme.muted; font.pixelSize: 11; font.letterSpacing: 0.8 }

                            Flow {
                                Layout.fillWidth: true; spacing: 6
                                Repeater {
                                    model: strategy.selectedFactors
                                    delegate: Rectangle {
                                        required property string modelData
                                        height: 28; radius: 14; width: _selFRow.implicitWidth + 16
                                        color: Theme.primarySoft; border.color: Theme.primary

                                        RowLayout {
                                            id: _selFRow; anchors.centerIn: parent; spacing: 4
                                            Text { text: modelData; color: Theme.primary; font.pixelSize: 11; font.weight: Font.DemiBold }
                                            Text {
                                                text: "✕"; color: Theme.primary; font.pixelSize: 9
                                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: strategy.toggleFactor(modelData) }
                                            }
                                        }
                                    }
                                }
                            }

                            Item { Layout.fillHeight: true }

                            Button {
                                Layout.fillWidth: true; implicitHeight: 38; text: "计算选中因子"
                                onClicked: dashboard.showToast("因子计算", "因子计算服务尚未接入")
                                contentItem: Text { text: parent.text; color: Theme.text; font.pixelSize: 13; font.weight: Font.DemiBold; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                background: Rectangle { radius: 10; color: parent.hovered ? Theme.primaryHover : Theme.primary; Behavior on color { ColorAnimation { duration: 150 } } }
                            }
                        }
                    }
                }
            }

            // ══ Tab 3: 因子挖掘 ══════════════════════════════════════════
            RowLayout {
                anchors.fill: parent; spacing: 14
                visible: strategy.activeTab === "mining"

                Rectangle {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    color: Theme.surface; radius: Theme.radiusLarge; border.color: Theme.line; clip: true

                    ColumnLayout {
                        anchors.fill: parent; spacing: 0

                        Rectangle {
                            Layout.fillWidth: true; height: 34; color: Theme.panel2
                            RowLayout {
                                anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
                                spacing: 0
                                ColH { label: "因子公式"; fw: true }
                                ColH { label: "IC 值";    pw: 72 }
                                ColH { label: "来源";     pw: 84 }
                                ColH { label: "状态";     pw: 60 }
                            }
                        }

                        Repeater {
                            model: strategy.minedFactors
                            delegate: Rectangle {
                                required property var modelData
                                required property int index
                                Layout.fillWidth: true; height: 50
                                color: index % 2 === 0 ? "transparent" : Theme.panel

                                RowLayout {
                                    anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
                                    spacing: 8
                                    Text { text: modelData.formula; color: Theme.text; font.pixelSize: 11; font.family: "Menlo"; elide: Text.ElideRight; Layout.fillWidth: true }
                                    Text { text: modelData.ic.toFixed(3); color: modelData.ic > 0.045 ? Theme.positive : Theme.primary; font.pixelSize: 12; font.family: "Menlo"; Layout.preferredWidth: 72 }
                                    Item {
                                        Layout.preferredWidth: 84
                                        Rectangle {
                                            anchors.verticalCenter: parent.verticalCenter
                                            height: 18; radius: 9; width: _srcTxt.implicitWidth + 12
                                            color: modelData.source === "AI 生成" ? "#1c1020" : "#12201a"
                                            border.color: modelData.source === "AI 生成" ? Theme.primary : Theme.positive
                                            Text { id: _srcTxt; anchors.centerIn: parent; text: modelData.source; color: modelData.source === "AI 生成" ? Theme.primary : Theme.positive; font.pixelSize: 9; font.weight: Font.DemiBold }
                                        }
                                    }
                                    Item {
                                        Layout.preferredWidth: 60
                                        Rectangle {
                                            anchors.verticalCenter: parent.verticalCenter
                                            height: 18; radius: 9; width: _minStTxt.implicitWidth + 12
                                            color: modelData.status === "优质" ? "#122820" : "#1c1c14"
                                            border.color: modelData.status === "优质" ? Theme.positive : Theme.faint
                                            Text { id: _minStTxt; anchors.centerIn: parent; text: modelData.status; color: modelData.status === "优质" ? Theme.positive : Theme.faint; font.pixelSize: 9 }
                                        }
                                    }
                                }
                                Rectangle { anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right; height: 1; color: Theme.line; opacity: 0.4 }
                            }
                        }
                        Item { Layout.fillHeight: true }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 220; Layout.fillHeight: true
                    color: Theme.surface; radius: Theme.radiusLarge; border.color: Theme.line

                    ColumnLayout {
                        anchors { fill: parent; margins: 16 }
                        spacing: 14
                        Text { text: "挖掘配置"; color: Theme.muted; font.pixelSize: 11; font.letterSpacing: 0.8 }
                        SgLabel { text: "挖掘方式" }
                        SgComboBox {
                            Layout.fillWidth: true
                            model: ["AI 生成", "遗传算法"]
                            currentIndex: strategy.miningMethod === "AI 生成" ? 0 : 1
                            onActivated: strategy.setMiningMethod(currentText)
                        }
                        SgLabel { text: "候选公式数量" }
                        SgTextField { text: "20"; Layout.fillWidth: true }
                        SgLabel { text: "最小 IC 阈值" }
                        SgTextField { text: "0.03"; Layout.fillWidth: true }
                        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.line }
                        Text { text: "遗传算法参数"; color: Theme.faint; font.pixelSize: 10; opacity: strategy.miningMethod === "遗传算法" ? 1 : 0.3; Behavior on opacity { NumberAnimation { duration: 150 } } }
                        SgLabel { text: "种群大小"; opacity: strategy.miningMethod === "遗传算法" ? 1 : 0.3 }
                        SgTextField { text: "200"; Layout.fillWidth: true; enabled: strategy.miningMethod === "遗传算法"; opacity: enabled ? 1 : 0.4 }
                        SgLabel { text: "进化代数"; opacity: strategy.miningMethod === "遗传算法" ? 1 : 0.3 }
                        SgTextField { text: "50"; Layout.fillWidth: true; enabled: strategy.miningMethod === "遗传算法"; opacity: enabled ? 1 : 0.4 }
                        Item { Layout.fillHeight: true }
                        Button {
                            Layout.fillWidth: true; implicitHeight: 38; text: "开始挖掘"
                            onClicked: dashboard.showToast("因子挖掘", "因子挖掘服务尚未接入")
                            contentItem: Text { text: parent.text; color: Theme.text; font.pixelSize: 13; font.weight: Font.DemiBold; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                            background: Rectangle { radius: 10; color: parent.hovered ? Theme.primaryHover : Theme.primary; Behavior on color { ColorAnimation { duration: 150 } } }
                        }
                    }
                }
            }

            // ══ Tab 4: 因子分析 ══════════════════════════════════════════
            Rectangle {
                anchors.fill: parent
                visible: strategy.activeTab === "analysis"
                color: Theme.surface; radius: Theme.radiusLarge; border.color: Theme.line; clip: true

                ColumnLayout {
                    anchors.fill: parent; spacing: 0

                    Rectangle {
                        Layout.fillWidth: true; height: 36; color: Theme.panel2
                        RowLayout {
                            anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
                            spacing: 0
                            ColH { label: "#";        pw: 32 }
                            ColH { label: "因子名称"; pw: 110 }
                            ColH { label: "分类";     pw: 68 }
                            ColH { label: "IC 均值";  pw: 80 }
                            ColH { label: "IC 分布";  fw: true }
                            ColH { label: "Sharpe";   pw: 74 }
                            ColH { label: "胜率";     pw: 64 }
                            ColH { label: "状态";     pw: 64 }
                        }
                    }

                    ScrollView {
                        Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                        ListView {
                            model: {
                                var arr = strategy.factors.slice()
                                arr.sort(function(a, b){ return b.ic - a.ic })
                                return arr
                            }
                            spacing: 0
                            delegate: Rectangle {
                                required property var modelData
                                required property int index
                                width: ListView.view.width; height: 42
                                color: index % 2 === 0 ? "transparent" : Theme.panel

                                RowLayout {
                                    anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
                                    spacing: 0
                                    Text { text: String(index + 1); color: Theme.faint; font.pixelSize: 11; font.family: "Menlo"; Layout.preferredWidth: 32 }
                                    Text { text: modelData.name; color: Theme.text; font.pixelSize: 12; font.weight: Font.DemiBold; font.family: "Menlo"; Layout.preferredWidth: 110; elide: Text.ElideRight }
                                    Text { text: modelData.category; color: Theme.muted; font.pixelSize: 11; Layout.preferredWidth: 68 }
                                    Text { text: modelData.ic.toFixed(3); color: modelData.ic > 0.04 ? Theme.positive : Theme.primary; font.pixelSize: 12; font.family: "Menlo"; Layout.preferredWidth: 80 }

                                    Item {
                                        Layout.fillWidth: true; height: 24
                                        Row {
                                            anchors.verticalCenter: parent.verticalCenter; spacing: 2
                                            Repeater {
                                                model: 12
                                                delegate: Rectangle {
                                                    required property int index
                                                    width: 7; radius: 2
                                                    height: Math.max(3, Math.min(22, modelData.ic * 320 + 4 + Math.sin(index * 0.9 + modelData.ic * 20) * 6))
                                                    anchors.bottom: parent.bottom
                                                    color: modelData.ic > 0.04 ? Theme.positive : modelData.ic > 0.025 ? Theme.primary : Theme.warning
                                                    opacity: 0.4 + 0.6 * (index / 12)
                                                }
                                            }
                                        }
                                    }

                                    Text { text: modelData.sharpe.toFixed(2); color: Theme.text; font.pixelSize: 12; font.family: "Menlo"; Layout.preferredWidth: 74 }
                                    Text { text: modelData.win_rate.toFixed(1) + "%"; color: modelData.win_rate > 52 ? Theme.positive : Theme.muted; font.pixelSize: 12; font.family: "Menlo"; Layout.preferredWidth: 64 }

                                    Item {
                                        Layout.preferredWidth: 64
                                        Rectangle {
                                            anchors.verticalCenter: parent.verticalCenter
                                            height: 18; radius: 9; width: _anSt.implicitWidth + 12
                                            color: modelData.status === "优质" ? "#122820" : "#1c1c14"
                                            border.color: modelData.status === "优质" ? Theme.positive : Theme.faint
                                            Text { id: _anSt; anchors.centerIn: parent; text: modelData.status; color: modelData.status === "优质" ? Theme.positive : Theme.faint; font.pixelSize: 9 }
                                        }
                                    }
                                }
                                Rectangle { anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right; height: 1; color: Theme.line; opacity: 0.35 }
                            }
                        }
                    }
                }
            }

            // ══ Tab 5: 机器学习 ══════════════════════════════════════════
            RowLayout {
                anchors.fill: parent; spacing: 14
                visible: strategy.activeTab === "ml"

                Rectangle {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    color: Theme.surface; radius: Theme.radiusLarge; border.color: Theme.line

                    ColumnLayout {
                        anchors { fill: parent; margins: 14 }
                        spacing: 10

                        Text { text: "可用模型"; color: Theme.muted; font.pixelSize: 11; font.letterSpacing: 0.8 }

                        Repeater {
                            model: strategy.mlModels
                            delegate: Rectangle {
                                required property var modelData
                                Layout.fillWidth: true; height: 72
                                color: strategy.selectedMlModel === modelData.name ? Theme.panel3 : Theme.panel2
                                radius: Theme.radius
                                border.color: strategy.selectedMlModel === modelData.name ? Theme.primary : Theme.border
                                Behavior on border.color { ColorAnimation { duration: 150 } }
                                Behavior on color        { ColorAnimation { duration: 150 } }

                                RowLayout {
                                    anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
                                    spacing: 12

                                    ColumnLayout {
                                        spacing: 4; Layout.fillWidth: true
                                        RowLayout {
                                            spacing: 8
                                            Text { text: modelData.name; color: Theme.text; font.pixelSize: 15; font.weight: Font.DemiBold }
                                            Rectangle { height: 18; radius: 9; width: _mlType.implicitWidth + 12; color: Theme.panel2; border.color: Theme.border; Text { id: _mlType; anchors.centerIn: parent; text: modelData.type; color: Theme.muted; font.pixelSize: 9 } }
                                            Rectangle {
                                                height: 18; radius: 9; width: _mlSt.implicitWidth + 12
                                                color: modelData.status === "已训练" ? "#122820" : "#1c1c14"
                                                border.color: modelData.status === "已训练" ? Theme.positive : Theme.faint
                                                Text { id: _mlSt; anchors.centerIn: parent; text: modelData.status; color: modelData.status === "已训练" ? Theme.positive : Theme.faint; font.pixelSize: 9; font.weight: Font.DemiBold }
                                            }
                                        }
                                        RowLayout {
                                            spacing: 16
                                            Text { text: modelData.status === "已训练" ? "准确率 " + (modelData.accuracy * 100).toFixed(1) + "%" : "— 未训练"; color: Theme.muted; font.pixelSize: 11; font.family: "Menlo" }
                                            Text { text: modelData.status === "已训练" ? "Sharpe " + modelData.sharpe.toFixed(2) : ""; color: Theme.muted; font.pixelSize: 11; font.family: "Menlo" }
                                        }
                                    }

                                    Button {
                                        implicitWidth: 68; implicitHeight: 32
                                        text: strategy.selectedMlModel === modelData.name ? "已选中" : "选择"
                                        onClicked: strategy.setMlModel(modelData.name)
                                        contentItem: Text { text: parent.text; color: strategy.selectedMlModel === modelData.name ? Theme.primary : Theme.muted; font.pixelSize: 12; font.weight: Font.DemiBold; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                        background: Rectangle { radius: 9; color: strategy.selectedMlModel === modelData.name ? Theme.primarySoft : (parent.hovered ? Theme.panel2 : "transparent"); border.color: strategy.selectedMlModel === modelData.name ? Theme.primary : "transparent"; Behavior on color { ColorAnimation { duration: 120 } } }
                                    }
                                }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: strategy.setMlModel(modelData.name) }
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 220; Layout.fillHeight: true
                    color: Theme.surface; radius: Theme.radiusLarge; border.color: Theme.line

                    ColumnLayout {
                        anchors { fill: parent; margins: 16 }
                        spacing: 14
                        Text { text: "训练配置"; color: Theme.muted; font.pixelSize: 11; font.letterSpacing: 0.8 }
                        SgLabel { text: "预测标签" }
                        SgComboBox { Layout.fillWidth: true; model: ["5日收益率", "10日收益率", "20日收益率"] }
                        SgLabel { text: "训练比例" }
                        SgTextField { text: "70%"; Layout.fillWidth: true }
                        SgLabel { text: "验证比例" }
                        SgTextField { text: "15%"; Layout.fillWidth: true }
                        Text { text: "使用因子 (" + strategy.selectedFactors.length + ")"; color: Theme.faint; font.pixelSize: 10 }
                        Flow {
                            Layout.fillWidth: true; spacing: 4
                            Repeater {
                                model: strategy.selectedFactors
                                delegate: Rectangle {
                                    required property string modelData
                                    height: 20; radius: 10; width: _mlFt.implicitWidth + 10
                                    color: Theme.primarySoft; border.color: Theme.primary
                                    Text { id: _mlFt; anchors.centerIn: parent; text: modelData; color: Theme.primary; font.pixelSize: 9 }
                                }
                            }
                        }
                        Item { Layout.fillHeight: true }
                        Button {
                            Layout.fillWidth: true; implicitHeight: 38; text: "训练模型"
                            onClicked: dashboard.showToast("模型训练", "模型训练服务尚未接入")
                            contentItem: Text { text: parent.text; color: Theme.text; font.pixelSize: 13; font.weight: Font.DemiBold; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                            background: Rectangle { radius: 10; color: parent.hovered ? Theme.primaryHover : Theme.primary; Behavior on color { ColorAnimation { duration: 150 } } }
                        }
                    }
                }
            }

            // ══ Tab 6: 策略编写 ══════════════════════════════════════════
            ColumnLayout {
                anchors.fill: parent; spacing: 10
                visible: strategy.activeTab === "code"

                // Top bar
                Rectangle {
                    Layout.fillWidth: true; height: 52
                    color: Theme.surface; radius: Theme.radiusLarge; border.color: Theme.line

                    RowLayout {
                        anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                        spacing: 10

                        // ── Editable strategy selector ──────────────────
                        Item {
                            id: stratSelectorItem
                            implicitWidth: 280; implicitHeight: 36

                            Connections {
                                target: strategy
                                function onStateChanged() {
                                    if (stratNameInput.text !== strategy.strategyName)
                                        stratNameInput.text = strategy.strategyName
                                }
                            }

                            Rectangle {
                                anchors.fill: parent; radius: 10; color: Theme.background
                                border.color: stratNameInput.activeFocus || stratPickerPopup.visible
                                              ? Theme.primary : Theme.border
                                Behavior on border.color { ColorAnimation { duration: 140 } }

                                RowLayout {
                                    anchors { fill: parent; leftMargin: 10; rightMargin: 4 }
                                    spacing: 4

                                    TextInput {
                                        id: stratNameInput
                                        Layout.fillWidth: true
                                        text: strategy.strategyName
                                        color: Theme.text; font.pixelSize: 13
                                        selectByMouse: true; clip: true
                                        verticalAlignment: TextInput.AlignVCenter
                                        onEditingFinished: strategy.setStrategyName(text)
                                    }

                                    Rectangle {
                                        width: 26; height: 26; radius: 7
                                        color: dropArrowMa.containsMouse ? Theme.panel2 : "transparent"
                                        Behavior on color { ColorAnimation { duration: 100 } }
                                        Text {
                                            anchors.centerIn: parent
                                            text: stratPickerPopup.visible ? "▴" : "▾"
                                            color: Theme.faint; font.pixelSize: 9
                                        }
                                        MouseArea {
                                            id: dropArrowMa
                                            anchors.fill: parent; hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: stratPickerPopup.visible
                                                       ? stratPickerPopup.close()
                                                       : stratPickerPopup.open()
                                        }
                                    }
                                }
                            }

                            Popup {
                                id: stratPickerPopup
                                x: 0; y: parent.height + 4
                                width: parent.width
                                padding: 4
                                closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
                                background: Rectangle {
                                    color: Theme.panel2; radius: Theme.radius
                                    border.color: Theme.border
                                }

                                contentItem: ColumnLayout {
                                    spacing: 2

                                    ScrollView {
                                        Layout.fillWidth: true
                                        implicitHeight: Math.min(240, spList.contentHeight)
                                        clip: true
                                        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                                        ListView {
                                            id: spList
                                            model: strategy.allStrategies
                                            spacing: 2
                                            delegate: Rectangle {
                                                required property string modelData
                                                width: ListView.view.width; height: 30; radius: 6
                                                color: strategy.currentStrategy === modelData
                                                       ? Theme.primarySoft
                                                       : (spItemMa.containsMouse ? Theme.panel3 : "transparent")
                                                Behavior on color { ColorAnimation { duration: 100 } }

                                                RowLayout {
                                                    anchors { fill: parent; leftMargin: 10; rightMargin: 8 }
                                                    Text {
                                                        text: modelData
                                                        color: strategy.currentStrategy === modelData
                                                               ? Theme.primary : Theme.text
                                                        font.pixelSize: 12; elide: Text.ElideRight
                                                        Layout.fillWidth: true
                                                        verticalAlignment: Text.AlignVCenter
                                                    }
                                                    Text {
                                                        visible: strategy.currentStrategy === modelData
                                                        text: "✓"; color: Theme.primary; font.pixelSize: 11
                                                    }
                                                }
                                                MouseArea {
                                                    id: spItemMa
                                                    anchors.fill: parent; hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        strategy.selectStrategy(modelData)
                                                        stratNameInput.text = strategy.strategyName
                                                        stratPickerPopup.close()
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.line; opacity: 0.6 }

                                    Rectangle {
                                        Layout.fillWidth: true; height: 30; radius: 6
                                        color: addNewMa.containsMouse ? Theme.primarySoft : "transparent"
                                        Behavior on color { ColorAnimation { duration: 100 } }
                                        RowLayout {
                                            anchors { fill: parent; leftMargin: 10; rightMargin: 8 }
                                            Text {
                                                text: "+ 新建策略"
                                                color: Theme.primary; font.pixelSize: 12
                                                font.weight: Font.DemiBold
                                            }
                                        }
                                        MouseArea {
                                            id: addNewMa
                                            anchors.fill: parent; hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                strategy.newStrategy()
                                                stratNameInput.text = strategy.strategyName
                                                stratNameInput.forceActiveFocus()
                                                stratNameInput.selectAll()
                                                stratPickerPopup.close()
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        SgLabel { text: "类型" }
                        SgComboBox {
                            implicitWidth: 112
                            model: ["趋势跟踪", "均值回归", "动量策略", "套利策略", "量化多因子", "AI 预测"]
                            currentIndex: model.indexOf(strategy.strategyType) < 0 ? 0 : model.indexOf(strategy.strategyType)
                            onActivated: strategy.setStrategyType(currentText)
                        }

                        Item { Layout.fillWidth: true }

                        Text { text: "因子:"; color: Theme.faint; font.pixelSize: 11 }
                        Repeater {
                            model: strategy.selectedFactors
                            delegate: Rectangle {
                                required property string modelData
                                height: 22; radius: 11; width: _codeF.implicitWidth + 12
                                color: Theme.primarySoft; border.color: Theme.primary
                                Text { id: _codeF; anchors.centerIn: parent; text: modelData; color: Theme.primary; font.pixelSize: 10; font.weight: Font.DemiBold }
                            }
                        }
                    }
                }

                // Code editor
                Rectangle {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    color: "#070d13"; radius: Theme.radiusLarge; border.color: Theme.border; clip: true

                    Rectangle {
                        width: 3
                        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                        color: Theme.primary
                        opacity: 0.7
                        z: 2
                    }

                    Rectangle {
                        id: lineGutter
                        width: 48; anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                        anchors.leftMargin: 3; color: "#0a1018"; z: 1

                        Flickable {
                            anchors.fill: parent; contentY: codeFlick.contentY
                            interactive: false; clip: true

                            Text {
                                topPadding: 14; leftPadding: 0; rightPadding: 6
                                width: parent.width
                                text: {
                                    var n = codeArea.text.split("\n").length
                                    var arr = []
                                    for (var i = 1; i <= n; i++) arr.push(i)
                                    return arr.join("\n")
                                }
                                font.family: "Menlo, Courier New"; font.pixelSize: 13
                                color: Theme.faint
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                        Rectangle { anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom; width: 1; color: Theme.line }
                    }

                    Flickable {
                        id: codeFlick
                        anchors { left: lineGutter.right; right: parent.right; top: parent.top; bottom: parent.bottom }
                        contentWidth:  codeArea.contentWidth + 28
                        contentHeight: codeArea.contentHeight + 28
                        clip: true
                        ScrollBar.vertical:   ScrollBar { policy: ScrollBar.AsNeeded }
                        ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AsNeeded }

                        TextEdit {
                            id: codeArea
                            topPadding: 14; leftPadding: 14; rightPadding: 14; bottomPadding: 14
                            width: Math.max(codeFlick.width, contentWidth + 28)
                            text: strategy.currentCode
                            onTextChanged: if (text !== strategy.currentCode) strategy.setCurrentCode(text)
                            font.family: "Menlo, Courier New"; font.pixelSize: 13
                            color: Theme.text; selectByMouse: true; selectByKeyboard: true
                            wrapMode: TextEdit.NoWrap; cursorVisible: true

                            Connections {
                                target: strategy
                                function onStateChanged() {
                                    if (codeArea.text !== strategy.currentCode)
                                        codeArea.text = strategy.currentCode
                                }
                            }
                        }
                    }

                    // AI loading overlay
                    Rectangle {
                        anchors.fill: parent; radius: Theme.radiusLarge; color: "#070d13"
                        opacity: strategy.aiLoading ? 0.9 : 0
                        visible: opacity > 0
                        Behavior on opacity { NumberAnimation { duration: 200 } }

                        ColumnLayout {
                            anchors.centerIn: parent; spacing: 16
                            Rectangle {
                                Layout.alignment: Qt.AlignHCenter
                                width: 56; height: 56; radius: 28
                                color: Theme.primarySoft; border.color: Theme.primary; border.width: 2
                                SequentialAnimation on scale {
                                    running: strategy.aiLoading; loops: Animation.Infinite
                                    NumberAnimation { to: 1.12; duration: 700; easing.type: Easing.InOutSine }
                                    NumberAnimation { to: 1.0;  duration: 700; easing.type: Easing.InOutSine }
                                }
                                Text { anchors.centerIn: parent; text: "AI"; color: Theme.primary; font.pixelSize: 18; font.weight: Font.Bold }
                            }
                            Text { Layout.alignment: Qt.AlignHCenter; text: "正在生成策略代码..."; color: Theme.text; font.pixelSize: 14; font.weight: Font.DemiBold }
                            Text { Layout.alignment: Qt.AlignHCenter; text: "AI 策略助手"; color: Theme.muted; font.pixelSize: 11 }
                        }
                    }
                }

                // AI + save bar
                Rectangle {
                    Layout.fillWidth: true; height: 52
                    color: Theme.surface; radius: Theme.radiusLarge; border.color: Theme.line

                    RowLayout {
                        anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                        spacing: 10

                        Button {
                            implicitWidth: 148; implicitHeight: 38
                            enabled: !strategy.aiLoading; opacity: enabled ? 1 : 0.5; Behavior on opacity { NumberAnimation { duration: 200 } }
                            onClicked: strategy.aiWriteStrategy()
                            contentItem: RowLayout {
                                spacing: 6
                                anchors.centerIn: parent
                                Text { text: "✦"; color: "#a47fff"; font.pixelSize: 14 }
                                Text { text: "AI 帮我写策略"; color: Theme.text; font.pixelSize: 13; font.weight: Font.DemiBold }
                            }
                            background: Rectangle {
                                radius: 10
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0.0; color: parent.hovered ? "#2a1a3a" : "#1e1030" }
                                    GradientStop { position: 1.0; color: parent.hovered ? "#1a2a3a" : "#102030" }
                                }
                                border.color: parent.hovered ? "#a47fff" : "#4a3a60"; Behavior on border.color { ColorAnimation { duration: 150 } }
                            }
                        }

                        Button {
                            implicitWidth: 130; implicitHeight: 38
                            enabled: !strategy.aiLoading; opacity: enabled ? 1 : 0.5; Behavior on opacity { NumberAnimation { duration: 200 } }
                            onClicked: strategy.aiAnalyzeStrategy()
                            contentItem: RowLayout {
                                spacing: 6
                                anchors.centerIn: parent
                                Text { text: "◈"; color: "#4a9fff"; font.pixelSize: 13 }
                                Text { text: "AI 分析策略"; color: Theme.text; font.pixelSize: 13; font.weight: Font.DemiBold }
                            }
                            background: Rectangle {
                                radius: 10
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0.0; color: parent.hovered ? "#0a1a2a" : "#081420" }
                                    GradientStop { position: 1.0; color: parent.hovered ? "#0a2030" : "#082030" }
                                }
                                border.color: parent.hovered ? "#4a9fff" : "#2a4060"; Behavior on border.color { ColorAnimation { duration: 150 } }
                            }
                        }

                        Rectangle { width: 1; height: 28; color: Theme.line }
                        Item { Layout.fillWidth: true }

                        Button {
                            implicitWidth: 100; implicitHeight: 38; text: "保存策略"
                            onClicked: { strategy.saveStrategy(); dashboard.showToast("策略已保存", "「" + strategy.strategyName + "」已加入策略库") }
                            contentItem: Text { text: parent.text; color: Theme.text; font.pixelSize: 13; font.weight: Font.DemiBold; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                            background: Rectangle { radius: 10; color: parent.hovered ? Theme.primaryHover : Theme.primary; Behavior on color { ColorAnimation { duration: 150 } } }
                        }
                    }
                }
            }
        }
    }

    // ── Inline components ────────────────────────────────────────────────

    // Table column header — use Layout.preferredWidth / Layout.fillWidth for proper alignment
    component ColH: Item {
        property string label: ""
        property int    pw:    0        // fixed preferred width (0 = not set)
        property bool   fw:    false    // fill remaining width

        Layout.preferredWidth: fw ? -1 : pw
        Layout.fillWidth: fw
        implicitHeight: 34

        Text {
            anchors.fill: parent
            text: parent.label
            color: Theme.faint; font.pixelSize: 10; font.letterSpacing: 0.6
            verticalAlignment: Text.AlignVCenter
        }
    }

    component SgLabel: Text {
        color: Theme.muted; font.pixelSize: 11
    }

    component SgTextField: TextField {
        implicitHeight: 34
        color: Theme.text; placeholderTextColor: Theme.faint; font.pixelSize: 13; leftPadding: 10; selectByMouse: true
        background: Rectangle { radius: 9; color: Theme.background; border.color: parent.activeFocus ? Theme.primary : Theme.border; Behavior on border.color { ColorAnimation { duration: 140 } } }
    }

    component SgComboBox: ComboBox {
        id: _sg
        implicitHeight: 34
        contentItem: Text { leftPadding: 10; rightPadding: 24; text: _sg.displayText; color: Theme.text; font.pixelSize: 13; verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
        indicator: Text { x: _sg.width - width - 10; anchors.verticalCenter: parent.verticalCenter; text: "▾"; color: Theme.faint; font.pixelSize: 9 }
        background: Rectangle { radius: 9; color: Theme.background; border.color: _sg.down ? Theme.primary : Theme.border; Behavior on border.color { ColorAnimation { duration: 140 } } }
        delegate: ItemDelegate {
            required property string modelData
            required property int index
            width: _sg.width; height: 30
            contentItem: Text { text: modelData; color: Theme.text; font.pixelSize: 12; verticalAlignment: Text.AlignVCenter; leftPadding: 10 }
            background: Rectangle { radius: 6; color: parent.hovered ? Theme.panel3 : (_sg.currentIndex === index ? Theme.primarySoft : "transparent") }
        }
        popup: Popup {
            y: _sg.height + 2; width: _sg.width; padding: 4
            background: Rectangle { color: Theme.panel2; radius: Theme.radius; border.color: Theme.border }
            contentItem: ListView {
                clip: true; implicitHeight: Math.min(220, contentHeight)
                model: _sg.delegateModel
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
            }
        }
    }
}
