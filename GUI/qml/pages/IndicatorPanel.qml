import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Rectangle {
    id: root
    radius: Theme.radiusLarge
    color: Theme.surface
    border.color: Theme.line
    clip: true

    property var rowData: ({})

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: "指标细分"
                    color: Theme.text
                    font.pixelSize: 17
                    font.weight: Font.DemiBold
                }

                Text {
                    text: "TECHNICAL / FUNDAMENTAL / TIMING"
                    color: Theme.faint
                    font.pixelSize: 10
                    font.letterSpacing: 1.1
                }
            }

            Rectangle {
                width: 9
                height: 9
                radius: 5
                color: Theme.primary

                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.35; duration: 760; easing.type: Easing.InOutQuad }
                    NumberAnimation { to: 1; duration: 760; easing.type: Easing.InOutQuad }
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            rowSpacing: 10
            columnSpacing: 10

            Metric { label: "MA5"; value: number(root.rowData.technical.ma5) }
            Metric { label: "MA20"; value: number(root.rowData.technical.ma20) }
            Metric { label: "RSI(14)"; value: number(root.rowData.technical.rsi) }
            Metric { label: "MACD"; value: number(root.rowData.technical.macd_hist) }
            Metric { label: "KD-K/D"; value: number(root.rowData.technical.kd_k) + " / " + number(root.rowData.technical.kd_d) }
            Metric { label: "Vol MA5"; value: compact(root.rowData.technical.volume_ma5) }
            Metric { label: "P/E"; value: number(root.rowData.fundamental.pe) }
            Metric { label: "P/B"; value: number(root.rowData.fundamental.pb) }
            Metric { label: "EPS"; value: number(root.rowData.fundamental.eps) }
            Metric { label: "股息率"; value: number(root.rowData.fundamental.dividend_yield) + "%" }
            Metric { label: "情绪分"; value: number(root.rowData.timing.sentiment_score) }
            Metric { label: "EMS"; value: number(root.rowData.timing.ems_value) }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.line
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                text: "Kronos 预测"
                color: Theme.text
                font.pixelSize: 15
                font.weight: Font.DemiBold
                Layout.fillWidth: true
            }

            Repeater {
                model: ["30m", "2h", "1d", "1w"]
                Button {
                    id: rangeButton
                    required property string modelData
                    text: modelData
                    Layout.preferredWidth: 48
                    Layout.preferredHeight: 32
                    onClicked: watchlist.setPredictionRange(modelData)
                    scale: pressed ? 0.96 : 1

                    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

                    background: Rectangle {
                        radius: 9
                        color: watchlist.predictionRange === rangeButton.text ? Theme.primary : rangeButton.hovered ? Theme.panel3 : Theme.panel2
                        border.color: watchlist.predictionRange === rangeButton.text ? Theme.primaryHover : Theme.line
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    contentItem: Text {
                        text: rangeButton.text
                        color: Theme.text
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }

        Button {
            id: predictButton
            text: "请求预测"
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            scale: pressed ? 0.98 : 1

            Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

            contentItem: Text {
                text: predictButton.text
                color: Theme.text
                font.pixelSize: 14
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            background: Rectangle {
                radius: 11
                color: predictButton.hovered ? Theme.panel3 : Theme.panel2
                border.color: Theme.border
                Behavior on color { ColorAnimation { duration: 150 } }
            }
        }

        Item { Layout.fillHeight: true }
    }

    function number(value) {
        if (value === undefined || value === null || isNaN(value))
            return "--"
        return Number(value).toFixed(2)
    }

    function compact(value) {
        if (value === undefined || value === null || isNaN(value))
            return "--"
        if (Math.abs(value) >= 1000000)
            return (value / 1000000).toFixed(2) + "M"
        if (Math.abs(value) >= 1000)
            return (value / 1000).toFixed(2) + "K"
        return Number(value).toFixed(0)
    }

    component Metric: ColumnLayout {
        property string label: ""
        property string value: ""
        Layout.fillWidth: true
        spacing: 4

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            radius: 10
            color: Theme.background
            border.color: Theme.line

            ColumnLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                anchors.topMargin: 7
                anchors.bottomMargin: 7
                spacing: 2

                Text {
                    text: label
                    color: Theme.faint
                    font.pixelSize: 10
                    font.letterSpacing: 0.6
                }

                Text {
                    text: value
                    color: Theme.text
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    font.family: "Menlo"
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }
        }
    }
}
