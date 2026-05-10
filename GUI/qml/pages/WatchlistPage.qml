pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes
import "../components"

Item {
    id: root

    readonly property int tableHPadding: 14
    readonly property int symbolColWidth: 156
    readonly property int favoriteColWidth: 40
    readonly property int marketColWidth: 54
    readonly property int priceColWidth: 98
    readonly property int changeColWidth: 92
    readonly property int volumeColWidth: 104
    readonly property int turnoverColWidth: 112
    readonly property int updateColWidth: 92
    readonly property int timeControlWidth: 112
    readonly property int forecastControlWidth: 78
    readonly property int controlGap: 6

    function selectedBars(symbol) {
        return watchlist.barsFor(symbol);
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

                    Behavior on scale {
                        NumberAnimation {
                            duration: 110
                            easing.type: Easing.OutCubic
                        }
                    }

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
                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                            }
                        }
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
                        watchlist.setQuery(text);
                        watchlist.search();
                    }

                    background: Rectangle {
                        radius: 10
                        color: Theme.background
                        border.color: queryField.activeFocus ? Theme.primary : Theme.border
                        Behavior on border.color {
                            ColorAnimation {
                                duration: 140
                            }
                        }
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
                        watchlist.setQuery(queryField.text);
                        watchlist.search();
                    }
                    scale: pressed ? 0.98 : 1

                    Behavior on scale {
                        NumberAnimation {
                            duration: 110
                            easing.type: Easing.OutCubic
                        }
                    }

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
                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                            }
                        }
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

                    Behavior on scale {
                        NumberAnimation {
                            duration: 110
                            easing.type: Easing.OutCubic
                        }
                    }

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
                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                            }
                        }
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
                        anchors.leftMargin: root.tableHPadding
                        anchors.rightMargin: root.tableHPadding
                        spacing: 0

                        HeaderCell {
                            text: "代码"
                            Layout.preferredWidth: root.symbolColWidth
                        }
                        HeaderCell {
                            text: "关注"
                            Layout.preferredWidth: root.favoriteColWidth
                            horizontalAlignment: Text.AlignHCenter
                        }
                        HeaderCell {
                            text: "市场"
                            Layout.preferredWidth: root.marketColWidth
                        }
                        HeaderCell {
                            text: "最新价"
                            Layout.preferredWidth: root.priceColWidth
                        }
                        HeaderCell {
                            text: "涨跌幅"
                            Layout.preferredWidth: root.changeColWidth
                        }
                        HeaderCell {
                            text: "成交量"
                            Layout.preferredWidth: root.volumeColWidth
                        }
                        HeaderCell {
                            text: "成交额"
                            Layout.preferredWidth: root.turnoverColWidth
                        }
                        HeaderCell {
                            text: "更新时间"
                            Layout.preferredWidth: root.updateColWidth
                        }

                        RowLayout {
                            Layout.preferredWidth: root.timeControlWidth + root.controlGap + root.forecastControlWidth
                            Layout.minimumWidth: Layout.preferredWidth
                            Layout.maximumWidth: Layout.preferredWidth
                            spacing: root.controlGap

                            HeaderCell {
                                text: "图表控制"
                                Layout.preferredWidth: root.timeControlWidth
                                Layout.minimumWidth: root.timeControlWidth
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Item {
                                Layout.preferredWidth: root.forecastControlWidth
                                Layout.minimumWidth: root.forecastControlWidth
                            }
                        }
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
                        NumberAnimation {
                            properties: "opacity"
                            from: 0
                            to: 1
                            duration: 220
                            easing.type: Easing.OutCubic
                        }
                        NumberAnimation {
                            properties: "y"
                            from: 18
                            duration: 220
                            easing.type: Easing.OutCubic
                        }
                    }

                    displaced: Transition {
                        NumberAnimation {
                            properties: "y"
                            duration: 220
                            easing.type: Easing.OutCubic
                        }
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

                            Behavior on color {
                                ColorAnimation {
                                    duration: 160
                                }
                            }
                            Behavior on scale {
                                NumberAnimation {
                                    duration: 100
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Rectangle {
                                width: 4
                                height: parent.height - 16
                                radius: 2
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                color: delegateRoot.modelData.changeValue >= 0 ? Theme.positive : Theme.negative
                                opacity: delegateRoot.expanded || rowMouse.containsMouse ? 0.95 : 0.35
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 140
                                    }
                                }
                            }

                            MouseArea {
                                id: rowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: watchlist.toggleExpanded(delegateRoot.modelData.symbol)
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: root.tableHPadding
                                anchors.rightMargin: root.tableHPadding
                                spacing: 0

                                ColumnLayout {
                                    Layout.preferredWidth: root.symbolColWidth
                                    Layout.minimumWidth: root.symbolColWidth
                                    Layout.maximumWidth: root.symbolColWidth
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
                                        Layout.maximumWidth: root.symbolColWidth - 8
                                    }
                                }

                                FavoriteButton {
                                    symbol: delegateRoot.modelData.symbol
                                    favorite: delegateRoot.modelData.isFavorite === true
                                    Layout.preferredWidth: root.favoriteColWidth
                                    Layout.minimumWidth: root.favoriteColWidth
                                    Layout.maximumWidth: root.favoriteColWidth
                                    Layout.preferredHeight: 64
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                BodyCell {
                                    text: delegateRoot.modelData.market
                                    Layout.preferredWidth: root.marketColWidth
                                    colorOverride: Theme.muted
                                }
                                BodyCell {
                                    text: delegateRoot.modelData.lastPrice
                                    Layout.preferredWidth: root.priceColWidth
                                    strong: true
                                    mono: true
                                }
                                BodyCell {
                                    text: delegateRoot.modelData.changePercent
                                    Layout.preferredWidth: root.changeColWidth
                                    colorOverride: delegateRoot.modelData.changeValue >= 0 ? Theme.positive : Theme.negative
                                    strong: true
                                    mono: true
                                }
                                BodyCell {
                                    text: delegateRoot.modelData.volume
                                    Layout.preferredWidth: root.volumeColWidth
                                    mono: true
                                    colorOverride: Theme.muted
                                }
                                BodyCell {
                                    text: delegateRoot.modelData.turnover
                                    Layout.preferredWidth: root.turnoverColWidth
                                    mono: true
                                    colorOverride: Theme.muted
                                }
                                BodyCell {
                                    text: delegateRoot.modelData.updateTime
                                    Layout.preferredWidth: root.updateColWidth
                                    colorOverride: Theme.faint
                                    mono: true
                                }

                                RowLayout {
                                    Layout.preferredWidth: root.timeControlWidth + root.controlGap + root.forecastControlWidth
                                    Layout.minimumWidth: Layout.preferredWidth
                                    Layout.maximumWidth: Layout.preferredWidth
                                    Layout.preferredHeight: 64
                                    spacing: root.controlGap

                                    TimeMenuButton {
                                        symbol: delegateRoot.modelData.symbol
                                        currentFrame: delegateRoot.modelData.timeFrame
                                        customCount: delegateRoot.modelData.customCount
                                        Layout.preferredWidth: root.timeControlWidth
                                        Layout.minimumWidth: root.timeControlWidth
                                        Layout.preferredHeight: 34
                                        Layout.alignment: Qt.AlignVCenter
                                    }

                                    ForecastMenuButton {
                                        symbol: delegateRoot.modelData.symbol
                                        currentUnit: delegateRoot.modelData.predictionUnit
                                        currentAmount: delegateRoot.modelData.predictionAmount
                                        Layout.preferredWidth: root.forecastControlWidth
                                        Layout.minimumWidth: root.forecastControlWidth
                                        Layout.preferredHeight: 34
                                        Layout.alignment: Qt.AlignVCenter
                                    }
                                }
                            }
                        }

                        Rectangle {
                            id: expandedPanel
                            width: parent.width
                            height: delegateRoot.expanded ? 570 : 0
                            opacity: delegateRoot.expanded ? 1 : 0
                            visible: height > 1
                            color: Theme.panel2
                            border.color: Theme.line
                            clip: true

                            Behavior on height {
                                NumberAnimation {
                                    duration: 260
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 180
                                    easing.type: Easing.OutCubic
                                }
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
                                        Layout.preferredHeight: 270
                                        radius: Theme.radiusLarge
                                        color: Theme.background
                                        border.color: Theme.line
                                        clip: true

                                        CandlestickChart {
                                            anchors.fill: parent
                                            anchors.margins: 12
                                            bars: delegateRoot.modelData.bars
                                            forecast: delegateRoot.modelData.forecast
                                            forecastStartIndex: delegateRoot.modelData.forecastStartIndex
                                            maxVisibleBars: 180
                                        }
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 124
                                        radius: Theme.radiusLarge
                                        color: Theme.background
                                        border.color: Theme.line
                                        clip: true

                                        VolumeChart {
                                            anchors.fill: parent
                                            anchors.margins: 12
                                            bars: delegateRoot.modelData.bars
                                            maxVisibleBars: 180
                                        }
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        radius: Theme.radiusLarge
                                        color: Theme.background
                                        border.color: Theme.line
                                        clip: true

                                        MacdChart {
                                            anchors.fill: parent
                                            anchors.margins: 12
                                            bars: delegateRoot.modelData.bars
                                            maxVisibleBars: 180
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
                            NumberAnimation {
                                duration: 180
                                easing.type: Easing.OutCubic
                            }
                        }

                        ColumnLayout {
                            anchors.centerIn: parent
                            width: 420
                            spacing: 12

                            Repeater {
                                model: 4
                                Rectangle {
                                    required property int index

                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 48
                                    radius: 10
                                    color: index % 2 === 0 ? Theme.surface : Theme.panel
                                    border.color: Theme.line
                                    opacity: 0.72 - index * 0.08

                                    SequentialAnimation on opacity {
                                        running: watchlist.loading
                                        loops: Animation.Infinite
                                        NumberAnimation {
                                            to: 0.38
                                            duration: 620
                                            easing.type: Easing.InOutQuad
                                        }
                                        NumberAnimation {
                                            to: 0.78
                                            duration: 620
                                            easing.type: Easing.InOutQuad
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

    component TimeMenuButton: Button {
        id: timeButton
        property string symbol: ""
        property string currentFrame: "分钟"
        property int customCount: 72

        function _frameShort(f) {
            if (f === "分钟")
                return "分钟";
            if (f === "小时")
                return "时";
            if (f === "日")
                return "日";
            if (f === "月")
                return "月";
            if (f === "年")
                return "年";
            return f;
        }

        text: "K线 " + _frameShort(currentFrame) + "·" + customCount
        onClicked: timePopup.open()
        scale: pressed ? 0.97 : 1

        Behavior on scale {
            NumberAnimation {
                duration: 100
                easing.type: Easing.OutCubic
            }
        }

        contentItem: Text {
            text: timeButton.text
            color: Theme.text
            font.pixelSize: 11
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        background: Rectangle {
            radius: 10
            color: timeButton.hovered || timePopup.opened ? Theme.panel3 : Theme.panel2
            border.color: timePopup.opened ? Theme.primary : Theme.border
            Behavior on color {
                ColorAnimation {
                    duration: 140
                }
            }
            Behavior on border.color {
                ColorAnimation {
                    duration: 140
                }
            }
        }

        Popup {
            id: timePopup
            y: timeButton.height + 6
            x: timeButton.width - timePopup.width
            width: 264
            padding: 10
            modal: false
            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

            onOpened: {
                customFrameBox.currentIndex = Math.max(0, customFrameBox.model.indexOf(timeButton.currentFrame));
                customCountInput.text = String(timeButton.customCount);
            }

            background: Rectangle {
                radius: 12
                color: Theme.surface
                border.color: Theme.border
            }

            contentItem: ColumnLayout {
                spacing: 8

                Text {
                    text: "K线周期 & 时间跨度"
                    color: Theme.text
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 4
                    rowSpacing: 5
                    columnSpacing: 5

                    Repeater {
                        model: [
                            {
                                label: "今日分钟",
                                frame: "分钟",
                                count: 72
                            },
                            {
                                label: "近3日",
                                frame: "小时",
                                count: 72
                            },
                            {
                                label: "近1月",
                                frame: "日",
                                count: 30
                            },
                            {
                                label: "近3月",
                                frame: "日",
                                count: 90
                            },
                            {
                                label: "近1年",
                                frame: "日",
                                count: 252
                            },
                            {
                                label: "近5年",
                                frame: "日",
                                count: 1260
                            },
                            {
                                label: "近10年",
                                frame: "日",
                                count: 2520
                            },
                            {
                                label: "近30年",
                                frame: "月",
                                count: 360
                            }
                        ]

                        Button {
                            id: presetBtn
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.preferredHeight: 28

                            property bool isActive: timeButton.currentFrame === presetBtn.modelData.frame && timeButton.customCount === presetBtn.modelData.count

                            text: presetBtn.modelData.label
                            onClicked: {
                                watchlist.setTimeFrame(timeButton.symbol, presetBtn.modelData.frame, presetBtn.modelData.count);
                                timePopup.close();
                            }

                            contentItem: Text {
                                text: presetBtn.text
                                color: presetBtn.isActive ? Theme.primary : Theme.muted
                                font.pixelSize: 11
                                font.weight: presetBtn.isActive ? Font.DemiBold : Font.Normal
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            background: Rectangle {
                                radius: 7
                                color: presetBtn.isActive ? Theme.primarySoft : presetBtn.hovered ? Theme.panel3 : Theme.background
                                border.color: presetBtn.isActive ? Theme.primary : Theme.line
                                Behavior on color {
                                    ColorAnimation {
                                        duration: 120
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Theme.line
                }

                Text {
                    text: "自定义根数"
                    color: Theme.faint
                    font.pixelSize: 11
                    font.letterSpacing: 0.8
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    DarkComboBox {
                        id: customFrameBox
                        Layout.preferredWidth: 78
                        Layout.preferredHeight: 32
                        model: ["分钟", "小时", "日", "月", "年"]
                    }

                    TextField {
                        id: customCountInput
                        Layout.fillWidth: true
                        Layout.preferredHeight: 32
                        validator: IntValidator {
                            bottom: 1
                            top: 6000
                        }
                        selectByMouse: true
                        color: Theme.text
                        placeholderText: "根数"
                        placeholderTextColor: Theme.faint
                        font.pixelSize: 12
                        leftPadding: 8

                        background: Rectangle {
                            radius: 8
                            color: Theme.background
                            border.color: customCountInput.activeFocus ? Theme.primary : Theme.border
                        }
                    }

                    Button {
                        id: applyCustomBtn
                        Layout.preferredWidth: 44
                        Layout.preferredHeight: 32
                        text: "应用"
                        onClicked: {
                            watchlist.setTimeFrame(timeButton.symbol, customFrameBox.currentText, parseInt(customCountInput.text || "30"));
                            timePopup.close();
                        }

                        contentItem: Text {
                            text: applyCustomBtn.text
                            color: Theme.text
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        background: Rectangle {
                            radius: 8
                            color: applyCustomBtn.hovered ? Theme.primaryHover : Theme.primary
                        }
                    }
                }
            }
        }
    }

    component ForecastMenuButton: Button {
        id: forecastButton
        property string symbol: ""
        property string currentUnit: "天"
        property int currentAmount: 1

        text: "预测"
        onClicked: forecastPopup.open()
        scale: pressed ? 0.97 : 1

        Behavior on scale {
            NumberAnimation {
                duration: 100
                easing.type: Easing.OutCubic
            }
        }

        contentItem: Text {
            text: forecastButton.text
            color: Theme.text
            font.pixelSize: 12
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        background: Rectangle {
            radius: 10
            color: forecastPopup.opened ? Theme.primarySoft : forecastButton.hovered ? Theme.panel3 : Theme.panel2
            border.color: forecastPopup.opened ? Theme.primary : Theme.border
            Behavior on color {
                ColorAnimation {
                    duration: 140
                }
            }
            Behavior on border.color {
                ColorAnimation {
                    duration: 140
                }
            }
        }

        Popup {
            id: forecastPopup
            y: forecastButton.height + 6
            x: forecastButton.width - forecastPopup.width
            width: 236
            padding: 10
            modal: false
            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
            onOpened: {
                unitBox.currentIndex = Math.max(0, unitBox.model.indexOf(forecastButton.currentUnit));
                amountInput.text = String(Math.max(1, forecastButton.currentAmount));
            }

            background: Rectangle {
                radius: 12
                color: Theme.surface
                border.color: Theme.border
            }

            contentItem: ColumnLayout {
                spacing: 8

                Text {
                    text: "Kronos 预测区间"
                    color: Theme.text
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    DarkComboBox {
                        id: unitBox
                        Layout.preferredWidth: 82
                        Layout.preferredHeight: 36
                        model: ["分钟", "小时", "天"]
                        currentIndex: Math.max(0, model.indexOf(forecastButton.currentUnit))
                    }

                    TextField {
                        id: amountInput
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        text: String(Math.max(1, forecastButton.currentAmount))
                        validator: IntValidator {
                            bottom: 1
                            top: 43200
                        }
                        selectByMouse: true
                        color: Theme.text
                        placeholderText: "数值"
                        placeholderTextColor: Theme.faint
                        font.pixelSize: 13
                        leftPadding: 10

                        background: Rectangle {
                            radius: 9
                            color: Theme.background
                            border.color: amountInput.activeFocus ? Theme.primary : Theme.border
                        }
                    }
                }

                Text {
                    text: "天数最高 30 天；分钟/小时会按 30 天等价上限截断。"
                    color: Theme.faint
                    font.pixelSize: 11
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                Button {
                    id: applyForecastButton
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    text: "绘制预测线"
                    onClicked: {
                        watchlist.requestPrediction(forecastButton.symbol, unitBox.currentText, amountInput.text);
                        forecastPopup.close();
                    }

                    contentItem: Text {
                        text: applyForecastButton.text
                        color: Theme.text
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        radius: 10
                        color: applyForecastButton.hovered ? Theme.primaryHover : Theme.primary
                    }
                }
            }
        }
    }

    component FavoriteButton: Button {
        id: favoriteButton
        property string symbol: ""
        property bool favorite: false

        text: favorite ? "取消收藏" : "收藏"
        onClicked: watchlist.toggleFavorite(symbol)

        ToolTip.visible: hovered
        ToolTip.delay: 450
        ToolTip.text: text

        contentItem: Item {
            implicitWidth: 16
            implicitHeight: 16
            opacity: favoriteButton.favorite ? 1 : favoriteButton.hovered ? 0.88 : 0.68

            Behavior on opacity {
                NumberAnimation {
                    duration: 120
                    easing.type: Easing.OutCubic
                }
            }

            Shape {
                anchors.centerIn: parent
                width: 15
                height: 15
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    fillColor: favoriteButton.favorite ? Theme.warning : "transparent"
                    strokeColor: favoriteButton.favorite ? Theme.warning : Theme.faint
                    strokeWidth: 1.55
                    strokeStyle: ShapePath.SolidLine
                    joinStyle: ShapePath.RoundJoin
                    capStyle: ShapePath.RoundCap

                    PathMove {
                        x: 7.5
                        y: 1.73
                    }
                    PathLine {
                        x: 9.27
                        y: 5.28
                    }
                    PathLine {
                        x: 13.2
                        y: 5.86
                    }
                    PathLine {
                        x: 10.35
                        y: 8.64
                    }
                    PathLine {
                        x: 11.03
                        y: 12.57
                    }
                    PathLine {
                        x: 7.5
                        y: 10.71
                    }
                    PathLine {
                        x: 3.98
                        y: 12.57
                    }
                    PathLine {
                        x: 4.65
                        y: 8.64
                    }
                    PathLine {
                        x: 1.8
                        y: 5.86
                    }
                    PathLine {
                        x: 5.73
                        y: 5.28
                    }
                    PathLine {
                        x: 7.5
                        y: 1.73
                    }
                }
            }
        }

        background: Rectangle {
            color: "transparent"
            border.color: "transparent"
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
                    NumberAnimation {
                        to: 0.35
                        duration: 520
                        easing.type: Easing.InOutQuad
                    }
                    NumberAnimation {
                        to: 1
                        duration: 520
                        easing.type: Easing.InOutQuad
                    }
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
        Layout.minimumWidth: Layout.preferredWidth
        Layout.maximumWidth: Layout.preferredWidth
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
        Layout.minimumWidth: Layout.preferredWidth
        Layout.maximumWidth: Layout.preferredWidth
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
            Behavior on color {
                ColorAnimation {
                    duration: 150
                }
            }
            Behavior on border.color {
                ColorAnimation {
                    duration: 150
                }
            }
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
                Behavior on color {
                    ColorAnimation {
                        duration: 120
                    }
                }
            }
        }
    }
}
