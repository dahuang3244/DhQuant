import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Item {
    id: root

    function selectedBars(symbol) {
        return watchlist.barsFor(symbol)
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 16

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
                spacing: 12

                // title
                ColumnLayout {
                    spacing: 3
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        text: "实时盯盘"
                        color: Theme.text
                        font.pixelSize: 20
                        font.weight: Font.DemiBold
                    }

                    Text {
                        text: watchlist.searchMode === "Market" ? "扫描全市场报价" : "按标的聚焦报价"
                        color: Theme.muted
                        font.pixelSize: 12
                    }
                }

                // MARKET
                Column {
                    spacing: 5
                    Layout.alignment: Qt.AlignBottom

                    Text {
                        text: "MARKET"
                        color: Theme.faint
                        font.pixelSize: 10
                        font.letterSpacing: 1.1
                    }

                    DarkComboBox {
                        id: marketBox
                        width: 100
                        height: 40
                        model: ["US", "ChinaA", "Crypto"]
                        currentIndex: model.indexOf(watchlist.market)
                        onActivated: watchlist.setMarket(currentText)
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
                        id: brokerBox
                        width: 128
                        height: 40
                        model: ["Mock", "CryptoGateway", "ChinaBroker", "UsBroker"]
                        currentIndex: model.indexOf(watchlist.broker)
                        onActivated: watchlist.setBroker(currentText)
                    }
                }

                // mode toggle
                Button {
                    id: modeButton
                    Layout.preferredWidth: 86
                    Layout.preferredHeight: 40
                    Layout.alignment: Qt.AlignBottom
                    text: watchlist.searchMode === "Symbol" ? "单标的" : "全市场"
                    onClicked: watchlist.setSearchMode(watchlist.searchMode === "Symbol" ? "Market" : "Symbol")
                    scale: pressed ? 0.98 : 1

                    Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }

                    contentItem: Text {
                        text: modeButton.text
                        color: Theme.text
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        radius: 10
                        color: modeButton.hovered ? Theme.panel3 : Theme.panel2
                        border.color: Theme.border
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }

                // search input — fills remaining space
                TextField {
                    id: queryField
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    Layout.alignment: Qt.AlignBottom
                    placeholderText: watchlist.searchMode === "Market" ? "留空搜索整个市场" : "输入代码或名称"
                    text: watchlist.query
                    selectByMouse: true
                    color: Theme.text
                    placeholderTextColor: Theme.faint
                    font.pixelSize: 14
                    leftPadding: 14
                    onEditingFinished: watchlist.setQuery(text)
                    onAccepted: {
                        watchlist.setQuery(text)
                        watchlist.search()
                    }

                    background: Rectangle {
                        radius: 10
                        color: Theme.background
                        border.color: queryField.activeFocus ? Theme.primary : Theme.border
                        Behavior on border.color { ColorAnimation { duration: 140 } }
                    }
                }

                // search button
                Button {
                    id: searchButton
                    Layout.preferredWidth: 76
                    Layout.preferredHeight: 40
                    Layout.alignment: Qt.AlignBottom
                    text: "搜索"
                    onClicked: {
                        watchlist.setQuery(queryField.text)
                        watchlist.search()
                    }
                    scale: pressed ? 0.98 : 1

                    Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }

                    contentItem: Text {
                        text: searchButton.text
                        color: Theme.text
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        radius: 10
                        color: searchButton.hovered ? Theme.primaryHover : Theme.primary
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }

                // refresh button
                Button {
                    id: refreshButton
                    Layout.preferredWidth: 76
                    Layout.preferredHeight: 40
                    Layout.alignment: Qt.AlignBottom
                    text: "刷新"
                    onClicked: watchlist.search()
                    scale: pressed ? 0.98 : 1

                    Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }

                    contentItem: Text {
                        text: refreshButton.text
                        color: Theme.text
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        radius: 10
                        color: refreshButton.hovered ? Theme.panel3 : Theme.panel
                        border.color: Theme.border
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }

                StatusPill {
                    Layout.alignment: Qt.AlignBottom
                    loading: watchlist.loading
                    errorText: watchlist.error
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Theme.radiusLarge
            color: Theme.background
            border.color: Theme.line
            clip: true

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    color: Theme.surface
                    border.color: Theme.line

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 20
                        anchors.rightMargin: 20
                        spacing: 0

                        HeaderCell { text: "代码"; Layout.preferredWidth: 178 }
                        HeaderCell { text: "市场"; Layout.preferredWidth: 74 }
                        HeaderCell { text: "最新价"; Layout.preferredWidth: 116 }
                        HeaderCell { text: "涨跌幅"; Layout.preferredWidth: 106 }
                        HeaderCell { text: "成交量"; Layout.preferredWidth: 132 }
                        HeaderCell { text: "成交额"; Layout.preferredWidth: 132 }
                        HeaderCell { text: "更新时间"; Layout.fillWidth: true }
                    }
                }

                ListView {
                    id: list
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: watchlist.rows
                    boundsBehavior: Flickable.StopAtBounds
                    spacing: 0

                    add: Transition {
                        NumberAnimation { properties: "opacity"; from: 0; to: 1; duration: 220; easing.type: Easing.OutCubic }
                        NumberAnimation { properties: "y"; from: 18; duration: 220; easing.type: Easing.OutCubic }
                    }

                    displaced: Transition {
                        NumberAnimation { properties: "y"; duration: 220; easing.type: Easing.OutCubic }
                    }

                    delegate: Column {
                        id: delegateRoot
                        required property var modelData
                        width: ListView.view.width

                        property bool expanded: watchlist.expandedSymbol === modelData.symbol

                        Rectangle {
                            id: rowShell
                            width: parent.width
                            height: 64
                            color: delegateRoot.expanded ? Theme.panel2 : rowMouse.containsMouse ? Theme.surface : Theme.background
                            border.color: Theme.line
                            scale: rowMouse.pressed ? 0.997 : 1

                            Behavior on color { ColorAnimation { duration: 160 } }
                            Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

                            Rectangle {
                                width: 4
                                height: parent.height - 16
                                radius: 2
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                color: delegateRoot.modelData.changeValue >= 0 ? Theme.positive : Theme.negative
                                opacity: delegateRoot.expanded || rowMouse.containsMouse ? 0.95 : 0.35
                                Behavior on opacity { NumberAnimation { duration: 140 } }
                            }

                            MouseArea {
                                id: rowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: watchlist.toggleExpanded(delegateRoot.modelData.symbol)
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 20
                                anchors.rightMargin: 20
                                spacing: 0

                                ColumnLayout {
                                    Layout.preferredWidth: 178
                                    spacing: 2
                                    Text {
                                        text: delegateRoot.modelData.symbol
                                        color: Theme.text
                                        font.pixelSize: 15
                                        font.weight: Font.DemiBold
                                    }
                                    Text {
                                        text: delegateRoot.modelData.name
                                        color: Theme.muted
                                        font.pixelSize: 12
                                        elide: Text.ElideRight
                                        Layout.maximumWidth: 156
                                    }
                                }

                                BodyCell { text: delegateRoot.modelData.market; Layout.preferredWidth: 74; colorOverride: Theme.muted }
                                BodyCell { text: delegateRoot.modelData.lastPrice; Layout.preferredWidth: 116; strong: true; mono: true }
                                BodyCell {
                                    text: delegateRoot.modelData.changePercent
                                    Layout.preferredWidth: 106
                                    colorOverride: delegateRoot.modelData.changeValue >= 0 ? Theme.positive : Theme.negative
                                    strong: true
                                    mono: true
                                }
                                BodyCell { text: delegateRoot.modelData.volume; Layout.preferredWidth: 132; mono: true; colorOverride: Theme.muted }
                                BodyCell { text: delegateRoot.modelData.turnover; Layout.preferredWidth: 132; mono: true; colorOverride: Theme.muted }
                                BodyCell { text: delegateRoot.modelData.updateTime; Layout.fillWidth: true; colorOverride: Theme.faint; mono: true }
                            }
                        }

                        Rectangle {
                            id: expandedPanel
                            width: parent.width
                            height: delegateRoot.expanded ? 492 : 0
                            opacity: delegateRoot.expanded ? 1 : 0
                            visible: height > 1
                            color: Theme.panel2
                            border.color: Theme.line
                            clip: true

                            Behavior on height {
                                NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
                            }

                            Behavior on opacity {
                                NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 18
                                spacing: 18

                                ColumnLayout {
                                    Layout.preferredWidth: parent.width * 0.6
                                    Layout.fillHeight: true
                                    spacing: 12

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 324
                                        radius: Theme.radiusLarge
                                        color: Theme.background
                                        border.color: Theme.line
                                        clip: true

                                        CandlestickChart {
                                            anchors.fill: parent
                                            anchors.margins: 12
                                            bars: delegateRoot.modelData.bars
                                        }
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        radius: Theme.radiusLarge
                                        color: Theme.background
                                        border.color: Theme.line
                                        clip: true

                                        VolumeChart {
                                            anchors.fill: parent
                                            anchors.margins: 12
                                            bars: delegateRoot.modelData.bars
                                        }
                                    }
                                }

                                IndicatorPanel {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    rowData: delegateRoot.modelData
                                }
                            }
                        }
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: 360
                        height: 168
                        radius: Theme.radiusLarge
                        color: Theme.surface
                        border.color: Theme.line
                        visible: !watchlist.loading && list.count === 0

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 24
                            spacing: 8

                            Text {
                                text: "暂无报价"
                                color: Theme.text
                                font.pixelSize: 20
                                font.weight: Font.DemiBold
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Text {
                                text: "调整市场或输入标的后重新搜索。"
                                color: Theme.muted
                                font.pixelSize: 13
                                horizontalAlignment: Text.AlignHCenter
                                Layout.fillWidth: true
                            }

                            Button {
                                id: emptySearchButton
                                text: "重新搜索"
                                Layout.preferredWidth: 112
                                Layout.preferredHeight: 38
                                Layout.alignment: Qt.AlignHCenter
                                onClicked: watchlist.search()
                                contentItem: Text {
                                    text: emptySearchButton.text
                                    color: Theme.text
                                    font.pixelSize: 13
                                    font.weight: Font.DemiBold
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                background: Rectangle {
                                    radius: 10
                                    color: emptySearchButton.hovered ? Theme.primaryHover : Theme.primary
                                }
                            }
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: Theme.background
                        opacity: watchlist.loading ? 0.88 : 0
                        visible: opacity > 0

                        Behavior on opacity {
                            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                        }

                        ColumnLayout {
                            anchors.centerIn: parent
                            width: 420
                            spacing: 12

                            Repeater {
                                model: 4
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 48
                                    radius: 10
                                    color: index % 2 === 0 ? Theme.surface : Theme.panel
                                    border.color: Theme.line
                                    opacity: 0.72 - index * 0.08

                                    SequentialAnimation on opacity {
                                        running: watchlist.loading
                                        loops: Animation.Infinite
                                        NumberAnimation { to: 0.38; duration: 620; easing.type: Easing.InOutQuad }
                                        NumberAnimation { to: 0.78; duration: 620; easing.type: Easing.InOutQuad }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    component ControlGroup: ColumnLayout {
        property string label: ""
        default property alias content: slot.data
        spacing: 5
        Layout.alignment: Qt.AlignBottom

        Text {
            text: label
            color: Theme.faint
            font.pixelSize: 10
            font.letterSpacing: 1.1
        }

        Item {
            id: slot
            Layout.preferredHeight: 42
            Layout.fillWidth: true
        }
    }

    component StatusPill: Rectangle {
        property bool loading: false
        property string errorText: ""
        width: statusText.implicitWidth + 28
        height: 34
        radius: 17
        color: errorText.length > 0 ? "#2b1b1c" : loading ? Theme.primarySoft : Theme.panel
        border.color: errorText.length > 0 ? Theme.negative : loading ? Theme.primary : Theme.line

        RowLayout {
            anchors.centerIn: parent
            spacing: 8

            Rectangle {
                width: 7
                height: 7
                radius: 4
                color: errorText.length > 0 ? Theme.negative : loading ? Theme.primary : Theme.positive

                SequentialAnimation on opacity {
                    running: loading
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.35; duration: 520; easing.type: Easing.InOutQuad }
                    NumberAnimation { to: 1; duration: 520; easing.type: Easing.InOutQuad }
                }
            }

            Text {
                id: statusText
                text: loading ? "加载中" : errorText.length > 0 ? errorText : "数据就绪"
                color: errorText.length > 0 ? Theme.negative : Theme.muted
                font.pixelSize: 12
                font.weight: Font.DemiBold
            }
        }
    }

    component HeaderCell: Text {
        color: Theme.faint
        font.pixelSize: 11
        font.weight: Font.DemiBold
        font.letterSpacing: 0.8
        verticalAlignment: Text.AlignVCenter
    }

    component BodyCell: Text {
        property bool strong: false
        property bool mono: false
        property color colorOverride: Theme.text
        color: colorOverride
        font.pixelSize: 13
        font.weight: strong ? Font.DemiBold : Font.Normal
        font.family: mono ? "Menlo" : "Arial"
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
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
