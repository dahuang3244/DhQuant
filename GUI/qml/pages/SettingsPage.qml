pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Item {
    id: root

    property string settingsTab: "ai"

    // AI state
    property string aiProvider: "openai"
    property string selectedModel: ""
    property var    availableModels: []
    property bool   fetchingModels: false

    // Broker / DataSource expand state
    property int expandedBroker: -1
    property int expandedDataSource: -1

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 14

        // ── Header ───────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 88
            radius: Theme.radiusLarge; color: Theme.surface; border.color: Theme.line

            Rectangle {
                width: 4; anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                color: Theme.primary; opacity: 0.85
            }

            RowLayout {
                anchors { fill: parent; leftMargin: 20; rightMargin: 16; topMargin: 14; bottomMargin: 14 }
                spacing: 12
                ColumnLayout {
                    spacing: 3; Layout.alignment: Qt.AlignVCenter
                    Text { text: "系统设置"; color: Theme.text; font.pixelSize: 20; font.weight: Font.DemiBold }
                    Text { text: "SETTINGS"; color: Theme.muted; font.pixelSize: 10; font.letterSpacing: 1.1 }
                }
                Item { Layout.fillWidth: true }
            }
        }

        // ── Body ─────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true; Layout.fillHeight: true; spacing: 14

            // Left section nav
            Rectangle {
                Layout.preferredWidth: 180; Layout.fillHeight: true
                color: Theme.surface; radius: Theme.radiusLarge; border.color: Theme.line

                ColumnLayout {
                    anchors { fill: parent; margins: 12 }
                    spacing: 4

                    Text {
                        text: "配置分类"
                        color: Theme.muted; font.pixelSize: 10; font.letterSpacing: 0.8
                        bottomPadding: 4
                    }

                    Repeater {
                        model: [
                            { id: "ai",         label: "AI 接口配置", icon: "" },
                            { id: "datasource", label: "数据源",         icon: "" },
                            { id: "broker",     label: "券商接入",     icon: "" },
                            { id: "general", label: "通用设置",     icon: "" },
                        ]
                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true; height: 40; radius: 10
                            color: root.settingsTab === modelData.id ? Theme.panel3
                                 : secNavMa.containsMouse ? Theme.panel2 : "transparent"
                            border.color: root.settingsTab === modelData.id ? Theme.primary : "transparent"
                            Behavior on color        { ColorAnimation { duration: 130 } }
                            Behavior on border.color { ColorAnimation { duration: 130 } }

                            RowLayout {
                                anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                                spacing: 8

                                Rectangle {
                                    width: 3; height: 18; radius: 2; color: Theme.primary
                                    opacity: root.settingsTab === modelData.id ? 1 : 0
                                    Behavior on opacity { NumberAnimation { duration: 130 } }
                                }

                                Text {
                                    text: modelData.icon
                                    font.family: "Material Icons Round"; font.pixelSize: 18
                                    color: root.settingsTab === modelData.id ? Theme.primary : Theme.faint
                                    verticalAlignment: Text.AlignVCenter
                                    Behavior on color { ColorAnimation { duration: 130 } }
                                }

                                Text {
                                    text: modelData.label; Layout.fillWidth: true
                                    color: root.settingsTab === modelData.id ? Theme.text : Theme.muted
                                    font.pixelSize: 13
                                    font.weight: root.settingsTab === modelData.id ? Font.DemiBold : Font.Normal
                                    Behavior on color { ColorAnimation { duration: 130 } }
                                }
                            }

                            MouseArea {
                                id: secNavMa; anchors.fill: parent
                                hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: root.settingsTab = modelData.id
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    Text {
                        text: "DhQuant v0.1.0"
                        color: Theme.faint; font.pixelSize: 10
                        horizontalAlignment: Text.AlignHCenter
                        Layout.fillWidth: true
                    }
                }
            }

            // Right content area
            Item {
                Layout.fillWidth: true; Layout.fillHeight: true

                // ══ AI 接口配置 ══════════════════════════════════════════════
                ColumnLayout {
                    anchors.fill: parent; spacing: 14
                    visible: root.settingsTab === "ai"

                    // Provider tabs
                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 52
                        color: Theme.surface; radius: Theme.radiusLarge; border.color: Theme.line

                        RowLayout {
                            anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                            spacing: 4

                            Repeater {
                                model: [
                                    { id: "openai",    label: "OpenAI",    url: "https://api.openai.com/v1" },
                                    { id: "anthropic", label: "Anthropic", url: "https://api.anthropic.com" },
                                    { id: "deepseek",  label: "DeepSeek",  url: "https://api.deepseek.com/v1" },
                                    { id: "custom",    label: "自定义",     url: "" },
                                ]
                                delegate: Button {
                                    required property var modelData
                                    implicitHeight: 34
                                    implicitWidth: _pvLbl.implicitWidth + 22
                                    flat: true
                                    readonly property bool isActive: root.aiProvider === modelData.id
                                    onClicked: {
                                        root.aiProvider = modelData.id
                                        if (modelData.id !== "custom") baseUrlField.text = modelData.url
                                        root.availableModels = []; root.selectedModel = ""
                                    }
                                    contentItem: Text {
                                        id: _pvLbl; text: modelData.label
                                        color: isActive ? Theme.text : Theme.muted
                                        font.pixelSize: 13; font.weight: isActive ? Font.DemiBold : Font.Normal
                                        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                                        Behavior on color { ColorAnimation { duration: 140 } }
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
                        }
                    }

                    // Credentials
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: credCol.implicitHeight + 32
                        color: Theme.surface; radius: Theme.radiusLarge; border.color: Theme.line

                        ColumnLayout {
                            id: credCol
                            anchors { fill: parent; margins: 20 }
                            spacing: 14

                            Text { text: "API 凭证"; color: Theme.muted; font.pixelSize: 11; font.letterSpacing: 0.8 }

                            GridLayout {
                                columns: 2; columnSpacing: 14; rowSpacing: 12; Layout.fillWidth: true

                                Text { text: "API Key"; color: Theme.muted; font.pixelSize: 12 }
                                TextField {
                                    id: apiKeyField
                                    Layout.fillWidth: true; implicitHeight: 36
                                    placeholderText: root.aiProvider === "anthropic" ? "sk-ant-..." : "sk-..."
                                    echoMode: TextInput.Password
                                    color: Theme.text; placeholderTextColor: Theme.faint
                                    font.pixelSize: 13; leftPadding: 10; selectByMouse: true
                                    background: Rectangle {
                                        radius: 9; color: Theme.background
                                        border.color: parent.activeFocus ? Theme.primary : Theme.border
                                        Behavior on border.color { ColorAnimation { duration: 140 } }
                                    }
                                }

                                Text { text: "Base URL"; color: Theme.muted; font.pixelSize: 12 }
                                TextField {
                                    id: baseUrlField
                                    Layout.fillWidth: true; implicitHeight: 36
                                    text: root.aiProvider === "openai"    ? "https://api.openai.com/v1"
                                        : root.aiProvider === "anthropic" ? "https://api.anthropic.com"
                                        : root.aiProvider === "deepseek"  ? "https://api.deepseek.com/v1" : ""
                                    placeholderText: "https://api.example.com/v1"
                                    enabled: root.aiProvider === "custom"
                                    opacity: enabled ? 1 : 0.5
                                    color: Theme.text; placeholderTextColor: Theme.faint
                                    font.pixelSize: 13; leftPadding: 10; selectByMouse: true
                                    background: Rectangle {
                                        radius: 9; color: Theme.background
                                        border.color: parent.activeFocus ? Theme.primary : Theme.border
                                        Behavior on border.color { ColorAnimation { duration: 140 } }
                                    }
                                }
                            }
                        }
                    }

                    // Model selector
                    Rectangle {
                        Layout.fillWidth: true; Layout.fillHeight: true
                        color: Theme.surface; radius: Theme.radiusLarge; border.color: Theme.line

                        ColumnLayout {
                            anchors { fill: parent; margins: 20 }
                            spacing: 14

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: "可用模型"
                                    color: Theme.muted; font.pixelSize: 11; font.letterSpacing: 0.8
                                    Layout.fillWidth: true
                                }
                                Button {
                                    implicitWidth: 108; implicitHeight: 30
                                    enabled: !root.fetchingModels && apiKeyField.text.length > 0
                                    opacity: enabled ? 1 : 0.5
                                    text: root.fetchingModels ? "获取中..." : "获取模型列表"
                                    onClicked: { root.fetchingModels = true; modelFetchTimer.restart() }

                                    Timer {
                                        id: modelFetchTimer; interval: 1400
                                        onTriggered: {
                                            root.fetchingModels = false
                                            if (root.aiProvider === "openai")
                                                root.availableModels = ["gpt-4o", "gpt-4o-mini", "gpt-4-turbo", "gpt-3.5-turbo"]
                                            else if (root.aiProvider === "anthropic")
                                                root.availableModels = ["claude-opus-4-7", "claude-sonnet-4-6", "claude-haiku-4-5"]
                                            else if (root.aiProvider === "deepseek")
                                                root.availableModels = ["deepseek-chat", "deepseek-reasoner"]
                                            else
                                                root.availableModels = ["custom-model-1", "custom-model-2"]
                                            if (root.availableModels.length > 0 && root.selectedModel === "")
                                                root.selectedModel = root.availableModels[0]
                                        }
                                    }

                                    contentItem: Text {
                                        text: parent.text; color: Theme.text
                                        font.pixelSize: 11; font.weight: Font.DemiBold
                                        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                                    }
                                    background: Rectangle {
                                        radius: 8; color: parent.hovered ? Theme.primaryHover : Theme.primary
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                    }
                                }
                            }

                            // Progress bar while fetching
                            Item {
                                Layout.fillWidth: true; height: 2
                                visible: root.fetchingModels
                                clip: true
                                Rectangle {
                                    height: 2; radius: 1; color: Theme.primary; width: 80
                                    SequentialAnimation on x {
                                        running: root.fetchingModels; loops: Animation.Infinite
                                        NumberAnimation { from: -80; to: parent.parent.width; duration: 900; easing.type: Easing.InOutQuad }
                                    }
                                }
                            }

                            // Empty state
                            Item {
                                Layout.fillWidth: true; Layout.fillHeight: true
                                visible: root.availableModels.length === 0 && !root.fetchingModels
                                ColumnLayout {
                                    anchors.centerIn: parent; spacing: 10
                                    Text { Layout.alignment: Qt.AlignHCenter; text: ""; font.family: "Material Icons Round"; font.pixelSize: 36; color: Theme.faint; opacity: 0.5 }
                                    Text { Layout.alignment: Qt.AlignHCenter; text: "输入 API Key 后点击「获取模型列表」"; color: Theme.faint; font.pixelSize: 12 }
                                }
                            }

                            // Model list
                            ScrollView {
                                Layout.fillWidth: true; Layout.fillHeight: true
                                visible: root.availableModels.length > 0
                                clip: true
                                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                                ColumnLayout {
                                    width: parent.width; spacing: 6

                                    Repeater {
                                        model: root.availableModels
                                        delegate: Rectangle {
                                            required property string modelData
                                            Layout.fillWidth: true; height: 46; radius: 10
                                            color: root.selectedModel === modelData ? Theme.panel3
                                                 : mdMa.containsMouse ? Theme.panel2 : "transparent"
                                            border.color: root.selectedModel === modelData ? Theme.primary : Theme.border
                                            Behavior on color        { ColorAnimation { duration: 120 } }
                                            Behavior on border.color { ColorAnimation { duration: 120 } }

                                            RowLayout {
                                                anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                                                spacing: 12

                                                Rectangle {
                                                    width: 10; height: 10; radius: 5
                                                    color: root.selectedModel === modelData ? Theme.primary : "transparent"
                                                    border.color: root.selectedModel === modelData ? Theme.primary : Theme.border
                                                    border.width: 2
                                                    Behavior on color { ColorAnimation { duration: 120 } }
                                                }

                                                Text {
                                                    text: modelData; Layout.fillWidth: true
                                                    color: root.selectedModel === modelData ? Theme.text : Theme.muted
                                                    font.pixelSize: 13; font.family: "Menlo"
                                                    font.weight: root.selectedModel === modelData ? Font.DemiBold : Font.Normal
                                                    Behavior on color { ColorAnimation { duration: 120 } }
                                                }

                                                Rectangle {
                                                    visible: root.selectedModel === modelData
                                                    height: 18; radius: 9; width: _curLbl.implicitWidth + 12
                                                    color: Theme.primarySoft; border.color: Theme.primary
                                                    Text { id: _curLbl; anchors.centerIn: parent; text: "当前"; color: Theme.primary; font.pixelSize: 9; font.weight: Font.DemiBold }
                                                }
                                            }

                                            MouseArea {
                                                id: mdMa; anchors.fill: parent
                                                hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                onClicked: root.selectedModel = modelData
                                            }
                                        }
                                    }
                                }
                            }

                            Button {
                                Layout.fillWidth: true; implicitHeight: 40
                                text: "保存 API 配置"
                                visible: root.selectedModel.length > 0
                                onClicked: dashboard.showToast("API 配置已保存", "当前模型：" + root.selectedModel)
                                contentItem: Text { text: parent.text; color: Theme.text; font.pixelSize: 14; font.weight: Font.DemiBold; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                background: Rectangle { radius: 10; color: parent.hovered ? Theme.primaryHover : Theme.primary; Behavior on color { ColorAnimation { duration: 150 } } }
                            }
                        }
                    }
                }


                // ══ 数据源 ══════════════════════════════════════════════════
                ColumnLayout {
                    anchors.fill: parent; spacing: 14
                    visible: root.settingsTab === "datasource"

                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 52
                        color: Theme.surface; radius: Theme.radiusLarge; border.color: Theme.line
                        RowLayout {
                            anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
                            ColumnLayout {
                                spacing: 2; Layout.fillWidth: true
                                Text { text: "数据源接入"; color: Theme.text; font.pixelSize: 15; font.weight: Font.DemiBold }
                                Text { text: "行情 · 基本面 · 宏观数据，独立于交易账户"; color: Theme.faint; font.pixelSize: 11 }
                            }
                            Item { Layout.fillWidth: true }
                        }
                    }

                    ScrollView {
                        Layout.fillWidth: true; Layout.fillHeight: true
                        clip: true; ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                        ColumnLayout {
                            width: parent.width; spacing: 10

                            Repeater {
                                model: [
                                    { id: "akshare",  name: "AkShare",       tag: "开源免费", auth: "none",    connected: true,  pip: "akshare",
                                      desc: "覆盖 A股 · 港股 · 美股 · 期货 · 外汇 · 宏观经济数据",
                                      types: ["K线行情", "实时报价", "财务数据", "宏观指标"] },
                                    { id: "tushare",  name: "Tushare Pro",   tag: "Token 认证", auth: "token",   connected: false, pip: "tushare",
                                      desc: "A股高质量数据，行情 · 财务 · 公告 · 股东信息",
                                      types: ["日K/分钟K", "利润表", "资产负债", "股东追踪"] },
                                    { id: "yfinance", name: "Yahoo Finance",  tag: "开源免费", auth: "none",    connected: false, pip: "yfinance",
                                      desc: "美股 · 港股 · ETF · 外汇全球历史行情",
                                      types: ["历史K线", "实时报价", "财务数据", "期权数据"] },
                                    { id: "baostock", name: "BaoStock",       tag: "开源免费", auth: "none",    connected: false, pip: "baostock",
                                      desc: "沪深 A股历史数据，支持日/周/月/分钟 K线及复权",
                                      types: ["日K/分钟K", "复权数据", "股票列表", "指数成分"] },
                                    { id: "wind",     name: "Wind 万得",       tag: "授权订阅", auth: "license", connected: false, pip: "WindPy",
                                      desc: "专业金融终端，机构级全品种数据",
                                      types: ["全品种行情", "深度财务", "研报数据", "衍生品"] },
                                ]

                                delegate: Rectangle {
                                    required property var modelData
                                    required property int index
                                    Layout.fillWidth: true
                                    height: root.expandedDataSource === index
                                            ? (modelData.auth !== "none" ? 234 : 196)
                                            : 80
                                    radius: Theme.radiusLarge; clip: true
                                    color: Theme.surface
                                    border.color: modelData.connected ? Theme.positive : Theme.line
                                    Behavior on height       { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                                    Behavior on border.color { ColorAnimation  { duration: 200 } }

                                    ColumnLayout {
                                        anchors { fill: parent; margins: 16 }
                                        spacing: 12

                                        // ── Main row ───────────────────
                                        RowLayout {
                                            Layout.fillWidth: true; spacing: 12

                                            Rectangle {
                                                width: 44; height: 44; radius: 12
                                                color: modelData.connected
                                                       ? (modelData.auth === "none" ? "#122820" : "#122030")
                                                       : Theme.panel2
                                                border.color: modelData.connected ? Theme.positive : Theme.border
                                                Behavior on color { ColorAnimation { duration: 200 } }
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: modelData.id === "akshare"  ? "AK"
                                                        : modelData.id === "tushare"  ? "TS"
                                                        : modelData.id === "yfinance" ? "YF"
                                                        : modelData.id === "baostock" ? "BS" : "W"
                                                    color: modelData.connected ? Theme.positive : Theme.muted
                                                    font.pixelSize: 12; font.weight: Font.Bold
                                                }
                                            }

                                            ColumnLayout {
                                                spacing: 4; Layout.fillWidth: true
                                                RowLayout {
                                                    spacing: 8
                                                    Text { text: modelData.name; color: Theme.text; font.pixelSize: 14; font.weight: Font.DemiBold }
                                                    Rectangle {
                                                        height: 18; radius: 9; width: _dsTag.implicitWidth + 12
                                                        color: modelData.auth === "none"    ? "#122820"
                                                             : modelData.auth === "token"   ? "#122030" : "#1c1c14"
                                                        border.color: modelData.auth === "none"    ? Theme.positive
                                                                    : modelData.auth === "token"   ? "#4a9fff" : Theme.warning
                                                        Text { id: _dsTag; anchors.centerIn: parent; text: modelData.tag; font.pixelSize: 9; font.weight: Font.DemiBold
                                                            color: modelData.auth === "none"    ? Theme.positive
                                                                 : modelData.auth === "token"   ? "#4a9fff" : Theme.warning }
                                                    }
                                                    Rectangle {
                                                        height: 18; radius: 9; width: _dsPip.implicitWidth + 12
                                                        color: Theme.panel2; border.color: Theme.border
                                                        Text { id: _dsPip; anchors.centerIn: parent; text: "pip: " + modelData.pip; color: Theme.faint; font.pixelSize: 9; font.family: "Menlo" }
                                                    }
                                                }
                                                Text { text: modelData.desc; color: Theme.muted; font.pixelSize: 11 }
                                            }

                                            Rectangle {
                                                height: 22; radius: 11; width: _dsStat.implicitWidth + 14
                                                color: modelData.connected ? "#122820" : "#1c1c14"
                                                border.color: modelData.connected ? Theme.positive : Theme.faint
                                                Text { id: _dsStat; anchors.centerIn: parent
                                                    text: modelData.connected ? "● 已接入" : "○ 未接入"
                                                    color: modelData.connected ? Theme.positive : Theme.faint
                                                    font.pixelSize: 10; font.weight: Font.DemiBold }
                                            }

                                            Button {
                                                implicitWidth: 58; implicitHeight: 30
                                                text: root.expandedDataSource === index ? "收起"
                                                    : modelData.connected ? "管理" : "接入"
                                                onClicked: root.expandedDataSource =
                                                    (root.expandedDataSource === index ? -1 : index)
                                                contentItem: Text { text: parent.text; color: Theme.text; font.pixelSize: 11; font.weight: Font.DemiBold; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                                background: Rectangle { radius: 8; color: parent.hovered ? Theme.primaryHover : Theme.primary; Behavior on color { ColorAnimation { duration: 130 } } }
                                            }
                                        }

                                        // ── Expanded config ───────────
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 10
                                            visible: root.expandedDataSource === index
                                            opacity: root.expandedDataSource === index ? 1 : 0
                                            Behavior on opacity { NumberAnimation { duration: 180 } }

                                            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.line; opacity: 0.6 }

                                            // Token row (only for non-free sources)
                                            RowLayout {
                                                Layout.fillWidth: true; spacing: 10
                                                visible: modelData.auth !== "none"
                                                Text { text: "Token"; color: Theme.muted; font.pixelSize: 12; Layout.preferredWidth: 56 }
                                                TextField {
                                                    Layout.fillWidth: true; implicitHeight: 34
                                                    placeholderText: modelData.id === "tushare" ? "tu_xxxxxxxx..." : "输入授权码"
                                                    echoMode: TextInput.Password
                                                    color: Theme.text; placeholderTextColor: Theme.faint
                                                    font.pixelSize: 12; leftPadding: 10; selectByMouse: true
                                                    background: Rectangle { radius: 8; color: Theme.background; border.color: parent.activeFocus ? Theme.primary : Theme.border; Behavior on border.color { ColorAnimation { duration: 140 } } }
                                                }
                                            }

                                            // Data type chips
                                            RowLayout {
                                                Layout.fillWidth: true
                                                Text { text: "数据类型"; color: Theme.muted; font.pixelSize: 11; font.letterSpacing: 0.6 }
                                            }
                                            Flow {
                                                Layout.fillWidth: true; spacing: 6
                                                Repeater {
                                                    model: modelData.types
                                                    delegate: Rectangle {
                                                        required property string modelData
                                                        height: 22; radius: 11; width: _typeTxt.implicitWidth + 14
                                                        color: Theme.primarySoft; border.color: Theme.primary
                                                        Text { id: _typeTxt; anchors.centerIn: parent; text: modelData; color: Theme.primary; font.pixelSize: 10 }
                                                    }
                                                }
                                            }

                                            Button {
                                                Layout.fillWidth: true; implicitHeight: 34
                                                text: modelData.connected ? "测试连接" : "安装并接入 " + modelData.name
                                                onClicked: {
                                                    dashboard.showToast(
                                                        (modelData.connected ? "测试 " : "正在接入 ") + modelData.name,
                                                        modelData.auth === "none"
                                                            ? "检测本地 Python 环境，pip install " + modelData.pip + "..."
                                                            : "验证 Token 中，请稍候..."
                                                    )
                                                    root.expandedDataSource = -1
                                                }
                                                contentItem: Text { text: parent.text; color: Theme.text; font.pixelSize: 12; font.weight: Font.DemiBold; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                                background: Rectangle { radius: 9; color: parent.hovered ? Theme.primaryHover : Theme.primary; Behavior on color { ColorAnimation { duration: 150 } } }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // ══ 券商接入 ═════════════════════════════════════════════════
                ColumnLayout {
                    anchors.fill: parent; spacing: 14
                    visible: root.settingsTab === "broker"

                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 52
                        color: Theme.surface; radius: Theme.radiusLarge; border.color: Theme.line
                        RowLayout {
                            anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
                            Text { text: "券商接入"; color: Theme.text; font.pixelSize: 15; font.weight: Font.DemiBold; Layout.fillWidth: true }
                            Text { text: "支持多账户并行连接"; color: Theme.faint; font.pixelSize: 11 }
                        }
                    }

                    ScrollView {
                        Layout.fillWidth: true; Layout.fillHeight: true
                        clip: true; ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                        ColumnLayout {
                            width: parent.width; spacing: 10

                            Repeater {
                                model: [
                                    { id: "longbridge", name: "长桥证券",  tag: "Longbridge",          connected: false, markets: "港股 · 美股 · A股",  appKeyHint: "App Key",    secretHint: "App Secret",  extraLabel: "",       extraHint: "" },
                                    { id: "futu",       name: "富途证券",  tag: "Futu",                connected: true,  markets: "港股 · 美股",        appKeyHint: "App ID",     secretHint: "App Secret",  extraLabel: "",       extraHint: "" },
                                    { id: "ibkr",       name: "盈透证券",  tag: "Interactive Brokers", connected: false, markets: "全球多市场",          appKeyHint: "账户号",      secretHint: "密码",         extraLabel: "TWS端口", extraHint: "7496 / 7497" },
                                    { id: "tiger",      name: "老虎证券",  tag: "Tiger Brokers",       connected: false, markets: "美股 · 港股 · A股",   appKeyHint: "Tiger ID",   secretHint: "License Key", extraLabel: "",       extraHint: "" },
                                    { id: "eastmoney",  name: "东方财富",  tag: "East Money",          connected: false, markets: "A股 · 基金",         appKeyHint: "账户号",      secretHint: "密码",         extraLabel: "",       extraHint: "" },
                                ]

                                delegate: Rectangle {
                                    required property var modelData
                                    required property int index
                                    Layout.fillWidth: true
                                    height: root.expandedBroker === index
                                            ? (modelData.extraLabel !== "" ? 282 : 246)
                                            : 72
                                    radius: Theme.radiusLarge; clip: true
                                    color: Theme.surface
                                    border.color: modelData.connected ? Theme.positive : Theme.line
                                    Behavior on height       { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                                    Behavior on border.color { ColorAnimation  { duration: 200 } }

                                    ColumnLayout {
                                        anchors { fill: parent; margins: 16 }
                                        spacing: 12

                                        // ── Main row ─────────────────────────────
                                        RowLayout {
                                            Layout.fillWidth: true; spacing: 12

                                            // Logo badge
                                            Rectangle {
                                                width: 40; height: 40; radius: 10
                                                color: modelData.connected ? "#122820" : Theme.panel2
                                                border.color: modelData.connected ? Theme.positive : Theme.border
                                                Behavior on color { ColorAnimation { duration: 200 } }
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: modelData.id === "longbridge" ? "LB"
                                                        : modelData.id === "futu"       ? "FT"
                                                        : modelData.id === "ibkr"       ? "IB"
                                                        : modelData.id === "tiger"      ? "TG" : "EM"
                                                    color: modelData.connected ? Theme.positive : Theme.muted
                                                    font.pixelSize: 12; font.weight: Font.Bold
                                                }
                                            }

                                            ColumnLayout {
                                                spacing: 3; Layout.fillWidth: true
                                                RowLayout {
                                                    spacing: 8
                                                    Text { text: modelData.name; color: Theme.text; font.pixelSize: 15; font.weight: Font.DemiBold }
                                                    Text { text: modelData.tag;  color: Theme.faint; font.pixelSize: 10 }
                                                }
                                                Text { text: modelData.markets; color: Theme.muted; font.pixelSize: 11 }
                                            }

                                            Rectangle {
                                                height: 22; radius: 11; width: _brkSt.implicitWidth + 14
                                                color: modelData.connected ? "#122820" : "#1c1c14"
                                                border.color: modelData.connected ? Theme.positive : Theme.faint
                                                Text { id: _brkSt; anchors.centerIn: parent; text: modelData.connected ? "● 已连接" : "○ 未连接"; color: modelData.connected ? Theme.positive : Theme.faint; font.pixelSize: 10; font.weight: Font.DemiBold }
                                            }

                                            Button {
                                                implicitWidth: 58; implicitHeight: 30
                                                text: root.expandedBroker === index ? "收起"
                                                    : modelData.connected ? "配置" : "接入"
                                                onClicked: root.expandedBroker = (root.expandedBroker === index ? -1 : index)
                                                contentItem: Text { text: parent.text; color: Theme.text; font.pixelSize: 11; font.weight: Font.DemiBold; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                                background: Rectangle { radius: 8; color: parent.hovered ? Theme.primaryHover : Theme.primary; Behavior on color { ColorAnimation { duration: 130 } } }
                                            }

                                            Button {
                                                visible: modelData.connected
                                                implicitWidth: 48; implicitHeight: 30; text: "断开"
                                                onClicked: dashboard.showToast("已断开 " + modelData.name, "账户连接已断开")
                                                contentItem: Text { text: parent.text; color: Theme.negative; font.pixelSize: 11; font.weight: Font.DemiBold; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                                background: Rectangle { radius: 8; color: parent.hovered ? "#2b1212" : "transparent"; border.color: parent.hovered ? Theme.negative : "transparent"; Behavior on color { ColorAnimation { duration: 130 } } }
                                            }
                                        }

                                        // ── Expanded config form ──────────────────
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 12
                                            visible: root.expandedBroker === index
                                            opacity: root.expandedBroker === index ? 1 : 0
                                            Behavior on opacity { NumberAnimation { duration: 180 } }

                                            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.line; opacity: 0.6 }

                                            GridLayout {
                                                columns: 2; columnSpacing: 14; rowSpacing: 10; Layout.fillWidth: true

                                                Text { text: modelData.appKeyHint; color: Theme.muted; font.pixelSize: 12 }
                                                TextField {
                                                    Layout.fillWidth: true; implicitHeight: 34
                                                    placeholderText: "输入 " + modelData.appKeyHint
                                                    echoMode: TextInput.Password
                                                    color: Theme.text; placeholderTextColor: Theme.faint
                                                    font.pixelSize: 12; leftPadding: 10; selectByMouse: true
                                                    background: Rectangle { radius: 8; color: Theme.background; border.color: parent.activeFocus ? Theme.primary : Theme.border; Behavior on border.color { ColorAnimation { duration: 140 } } }
                                                }

                                                Text { text: modelData.secretHint; color: Theme.muted; font.pixelSize: 12 }
                                                TextField {
                                                    Layout.fillWidth: true; implicitHeight: 34
                                                    placeholderText: "输入 " + modelData.secretHint
                                                    echoMode: TextInput.Password
                                                    color: Theme.text; placeholderTextColor: Theme.faint
                                                    font.pixelSize: 12; leftPadding: 10; selectByMouse: true
                                                    background: Rectangle { radius: 8; color: Theme.background; border.color: parent.activeFocus ? Theme.primary : Theme.border; Behavior on border.color { ColorAnimation { duration: 140 } } }
                                                }

                                                Text { visible: modelData.extraLabel !== ""; text: modelData.extraLabel; color: Theme.muted; font.pixelSize: 12 }
                                                TextField {
                                                    visible: modelData.extraLabel !== ""
                                                    Layout.fillWidth: true; implicitHeight: 34
                                                    placeholderText: modelData.extraHint
                                                    color: Theme.text; placeholderTextColor: Theme.faint
                                                    font.pixelSize: 12; leftPadding: 10; selectByMouse: true
                                                    background: Rectangle { radius: 8; color: Theme.background; border.color: parent.activeFocus ? Theme.primary : Theme.border; Behavior on border.color { ColorAnimation { duration: 140 } } }
                                                }
                                            }

                                            Button {
                                                Layout.fillWidth: true; implicitHeight: 36
                                                text: modelData.connected ? "更新配置" : "连接 " + modelData.name
                                                onClicked: {
                                                    dashboard.showToast("正在连接 " + modelData.name, "验证凭证中，请稍候...")
                                                    root.expandedBroker = -1
                                                }
                                                contentItem: Text { text: parent.text; color: Theme.text; font.pixelSize: 13; font.weight: Font.DemiBold; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                                background: Rectangle { radius: 9; color: parent.hovered ? Theme.primaryHover : Theme.primary; Behavior on color { ColorAnimation { duration: 150 } } }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // ══ 通用设置 ═════════════════════════════════════════════════
                Rectangle {
                    anchors.fill: parent
                    visible: root.settingsTab === "general"
                    color: Theme.surface; radius: Theme.radiusLarge; border.color: Theme.line

                    ColumnLayout {
                        anchors { fill: parent; margins: 20 }
                        spacing: 12

                        Text { text: "通用设置"; color: Theme.muted; font.pixelSize: 11; font.letterSpacing: 0.8 }

                        Repeater {
                            model: [
                                { label: "启动时自动连接上次券商",  desc: "记住连接状态，下次启动自动恢复",      on: true  },
                                { label: "价格提醒通知",            desc: "当监控标的触发预警条件时推送桌面通知", on: true  },
                                { label: "实盘模式二次确认弹窗",    desc: "实盘下单前需要弹窗确认，防止误触",    on: true  },
                                { label: "自动保存策略草稿",        desc: "编辑策略代码时每 30 秒自动保存",      on: false },
                                { label: "显示量化收益曲线水印",     desc: "在图表背景显示品牌水印",              on: false },
                            ]
                            delegate: Rectangle {
                                required property var modelData
                                Layout.fillWidth: true; height: 58; radius: 10
                                color: Theme.panel2; border.color: Theme.border

                                RowLayout {
                                    anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
                                    spacing: 12

                                    ColumnLayout {
                                        spacing: 3; Layout.fillWidth: true
                                        Text { text: modelData.label; color: Theme.text; font.pixelSize: 13; font.weight: Font.DemiBold }
                                        Text { text: modelData.desc;  color: Theme.faint; font.pixelSize: 11 }
                                    }

                                    Rectangle {
                                        id: tog
                                        property bool on: modelData.on
                                        width: 44; height: 24; radius: 12
                                        color: on ? Theme.primary : Theme.border
                                        Behavior on color { ColorAnimation { duration: 160 } }

                                        Rectangle {
                                            x: parent.on ? parent.width - width - 3 : 3
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: 18; height: 18; radius: 9; color: "white"
                                            Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                                        }

                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: tog.on = !tog.on
                                        }
                                    }
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }
                }
            }
        }
    }
}
