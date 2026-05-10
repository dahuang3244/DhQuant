pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Item {
    id: root

    // ── Shared helper ─────────────────────────────────────────────────────────
    function sentimentColor(s) {
        if (s === "positive") return Theme.positive
        if (s === "negative") return Theme.negative
        return Theme.warning
    }

    function sentimentLabel(s) {
        if (s === "positive") return "利多"
        if (s === "negative") return "利空"
        return "中性"
    }

    function rateColor(r) {
        if (r >= 8.0) return Theme.positive
        if (r >= 5.5) return Theme.warning
        return Theme.negative
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 16

        // ── Page header ──────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 72
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
                anchors.topMargin: 10
                anchors.bottomMargin: 10
                spacing: 16

                ColumnLayout {
                    spacing: 2
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        text: "行业新闻"
                        color: Theme.text
                        font.pixelSize: 20
                        font.weight: Font.DemiBold
                    }

                    Text {
                        text: "AI 驱动的多行业资讯聚合与投资分析"
                        color: Theme.muted
                        font.pixelSize: 12
                    }
                }

                Item { Layout.fillWidth: true }

                // Last refresh label
                Text {
                    text: "上次更新 " + news.lastRefresh
                    color: Theme.faint
                    font.pixelSize: 12
                    Layout.alignment: Qt.AlignVCenter
                }

                // Refresh button
                Rectangle {
                    width: 96
                    height: 36
                    radius: 10
                    color: refreshMa.containsMouse ? Theme.panel3 : Theme.panel2
                    border.color: refreshMa.containsMouse ? Theme.primary : Theme.border
                    Layout.alignment: Qt.AlignVCenter

                    Behavior on color { ColorAnimation { duration: 120 } }
                    Behavior on border.color { ColorAnimation { duration: 120 } }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 5

                        Text {
                            text: news.loading ? "⟳" : "⟳"
                            color: Theme.primary
                            font.pixelSize: 15

                            RotationAnimator on rotation {
                                running: news.loading
                                from: 0; to: 360
                                duration: 900
                                loops: Animation.Infinite
                            }
                        }

                        Text {
                            text: news.loading ? "刷新中" : "刷新"
                            color: Theme.text
                            font.pixelSize: 13
                            font.weight: Font.Medium
                        }
                    }

                    MouseArea {
                        id: refreshMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: news.refresh()
                    }
                }
            }
        }

        // ── Main content: list + detail ──────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 16

            // ── Left: industry filter + news list ────────────────────────────
            Rectangle {
                Layout.preferredWidth: 380
                Layout.fillHeight: true
                radius: Theme.radiusLarge
                color: Theme.surface
                border.color: Theme.line
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    // Industry filter tabs
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 46
                        color: Theme.panel
                        radius: Theme.radiusLarge

                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: Theme.radiusLarge
                            color: Theme.panel
                        }

                        ScrollView {
                            anchors.fill: parent
                            anchors.margins: 8
                            clip: true
                            ScrollBar.horizontal.policy: ScrollBar.AsNeeded
                            ScrollBar.vertical.policy: ScrollBar.AlwaysOff

                            Row {
                                spacing: 4

                                Repeater {
                                    model: news.industries

                                    Rectangle {
                                        id: tabRect
                                        required property string modelData
                                        required property int index

                                        readonly property bool active: news.industry === modelData

                                        width: tabLabel.implicitWidth + 20
                                        height: 30
                                        radius: 8
                                        color: active ? Theme.primarySoft : tabMa.containsMouse ? Theme.panel2 : "transparent"
                                        border.color: active ? Theme.primary : "transparent"

                                        Behavior on color { ColorAnimation { duration: 130 } }
                                        Behavior on border.color { ColorAnimation { duration: 130 } }

                                        Text {
                                            id: tabLabel
                                            anchors.centerIn: parent
                                            text: tabRect.modelData
                                            color: tabRect.active ? Theme.primary : Theme.muted
                                            font.pixelSize: 13
                                            font.weight: tabRect.active ? Font.DemiBold : Font.Normal

                                            Behavior on color { ColorAnimation { duration: 130 } }
                                        }

                                        MouseArea {
                                            id: tabMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: news.setIndustry(tabRect.modelData)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Thin divider
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: Theme.line
                    }

                    // News list
                    ListView {
                        id: newsListView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        model: news.newsList
                        clip: true
                        spacing: 0
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                        delegate: NewsCard {
                            required property var modelData
                            required property int index
                            width: newsListView.width
                        }
                    }
                }
            }

            // ── Right: article detail + AI analysis ──────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 16

                // Article detail panel
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: parent.height * 0.45
                    radius: Theme.radiusLarge
                    color: Theme.surface
                    border.color: Theme.line
                    clip: true

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 22
                        spacing: 14

                        // Article header
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            // Industry badge
                            Rectangle {
                                width: industryBadgeText.implicitWidth + 16
                                height: 24
                                radius: 6
                                color: Theme.primarySoft
                                border.color: Theme.primary
                                opacity: 0.85

                                Text {
                                    id: industryBadgeText
                                    anchors.centerIn: parent
                                    text: news.selectedNews["industry"] || ""
                                    color: Theme.primary
                                    font.pixelSize: 12
                                    font.weight: Font.Medium
                                }
                            }

                            // Sentiment badge
                            Rectangle {
                                width: sentimentText.implicitWidth + 16
                                height: 24
                                radius: 6
                                color: Qt.rgba(
                                    root.sentimentColor(news.selectedNews["sentiment"] || "neutral").r,
                                    root.sentimentColor(news.selectedNews["sentiment"] || "neutral").g,
                                    root.sentimentColor(news.selectedNews["sentiment"] || "neutral").b,
                                    0.12
                                )
                                border.color: root.sentimentColor(news.selectedNews["sentiment"] || "neutral")
                                border.width: 0.8

                                Text {
                                    id: sentimentText
                                    anchors.centerIn: parent
                                    text: root.sentimentLabel(news.selectedNews["sentiment"] || "neutral")
                                    color: root.sentimentColor(news.selectedNews["sentiment"] || "neutral")
                                    font.pixelSize: 12
                                    font.weight: Font.Medium
                                }
                            }

                            Item { Layout.fillWidth: true }

                            // Source + time
                            Text {
                                text: (news.selectedNews["source"] || "") + "  ·  " + (news.selectedNews["time"] || "")
                                color: Theme.faint
                                font.pixelSize: 12
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }

                        // Title
                        Text {
                            Layout.fillWidth: true
                            text: news.selectedNews["title"] || ""
                            color: Theme.text
                            font.pixelSize: 17
                            font.weight: Font.DemiBold
                            wrapMode: Text.WordWrap
                            lineHeight: 1.4
                        }

                        // Divider
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: Theme.line
                        }

                        // Content
                        ScrollView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                            Text {
                                width: parent.width
                                text: news.selectedNews["content"] || ""
                                color: Theme.muted
                                font.pixelSize: 14
                                wrapMode: Text.WordWrap
                                lineHeight: 1.75
                            }
                        }
                    }
                }

                // AI Analysis card
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Theme.radiusLarge
                    color: Theme.surface
                    border.color: Theme.line
                    clip: true

                    // Subtle gradient accent at top
                    Rectangle {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 3
                        radius: Theme.radiusLarge
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: Theme.primary }
                            GradientStop { position: 1.0; color: "#4a7fa5" }
                        }
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 22
                        anchors.topMargin: 18
                        spacing: 16

                        // AI header
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Rectangle {
                                width: 30
                                height: 30
                                radius: 8
                                color: Theme.primarySoft
                                border.color: Theme.primary

                                Text {
                                    anchors.centerIn: parent
                                    text: "AI"
                                    color: Theme.primary
                                    font.pixelSize: 11
                                    font.weight: Font.Bold
                                }
                            }

                            Text {
                                text: "AI 投资分析"
                                color: Theme.text
                                font.pixelSize: 15
                                font.weight: Font.DemiBold
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Item { Layout.fillWidth: true }

                            // Rating display
                            RowLayout {
                                spacing: 6
                                Layout.alignment: Qt.AlignVCenter

                                Text {
                                    text: "综合评分"
                                    color: Theme.faint
                                    font.pixelSize: 12
                                }

                                Text {
                                    id: rateText
                                    readonly property var ai: news.selectedNews["ai"] || {}
                                    readonly property real rateVal: ai["rate"] !== undefined ? ai["rate"] : 0
                                    text: rateVal.toFixed(1)
                                    color: root.rateColor(rateVal)
                                    font.pixelSize: 22
                                    font.weight: Font.Bold
                                }

                                Text {
                                    text: "/ 10"
                                    color: Theme.faint
                                    font.pixelSize: 13
                                    Layout.alignment: Qt.AlignBottom
                                    bottomPadding: 2
                                }
                            }
                        }

                        // Rating bar
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: "熊市风险"; color: Theme.faint; font.pixelSize: 11 }
                                Item { Layout.fillWidth: true }
                                Text { text: "牛市机会"; color: Theme.faint; font.pixelSize: 11 }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 8
                                radius: 4
                                color: Theme.panel2

                                Rectangle {
                                    id: ratingFill
                                    readonly property var ai: news.selectedNews["ai"] || {}
                                    readonly property real rateVal: ai["rate"] !== undefined ? ai["rate"] : 0
                                    width: parent.width * (rateVal / 10.0)
                                    height: parent.height
                                    radius: parent.radius
                                    color: root.rateColor(rateVal)

                                    Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                                    Behavior on color { ColorAnimation { duration: 300 } }

                                    // Glow effect
                                    Rectangle {
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 14
                                        height: 14
                                        radius: 7
                                        color: ratingFill.color
                                        opacity: 0.4
                                    }

                                    Rectangle {
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 10
                                        height: 10
                                        radius: 5
                                        color: ratingFill.color
                                    }
                                }
                            }
                        }

                        // Divider
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: Theme.line
                        }

                        // AI summary
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Text {
                                text: "分析摘要"
                                color: Theme.muted
                                font.pixelSize: 12
                                font.weight: Font.Medium
                            }

                            Text {
                                readonly property var ai: news.selectedNews["ai"] || {}
                                Layout.fillWidth: true
                                text: ai["summary"] || ""
                                color: Theme.text
                                font.pixelSize: 13
                                wrapMode: Text.WordWrap
                                lineHeight: 1.65
                            }
                        }

                        // Investment advice
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                text: "投资建议"
                                color: Theme.muted
                                font.pixelSize: 12
                                font.weight: Font.Medium
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: adviceText.implicitHeight + 16
                                radius: 10
                                color: Theme.panel2
                                border.color: Theme.border

                                Text {
                                    id: adviceText
                                    readonly property var ai: news.selectedNews["ai"] || {}
                                    anchors {
                                        left: parent.left; right: parent.right
                                        verticalCenter: parent.verticalCenter
                                        leftMargin: 14; rightMargin: 14
                                    }
                                    text: ai["advice"] || ""
                                    color: Theme.text
                                    font.pixelSize: 13
                                    wrapMode: Text.WordWrap
                                    lineHeight: 1.5
                                }
                            }

                            // Tags row
                            Row {
                                spacing: 8

                                Repeater {
                                    readonly property var ai: news.selectedNews["ai"] || {}
                                    model: ai["tags"] || []

                                    Rectangle {
                                        required property string modelData
                                        width: tagText.implicitWidth + 18
                                        height: 26
                                        radius: 7
                                        color: Theme.panel3
                                        border.color: Theme.border

                                        Text {
                                            id: tagText
                                            anchors.centerIn: parent
                                            text: modelData
                                            color: Theme.primary
                                            font.pixelSize: 12
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

    // ── Inline delegate component ─────────────────────────────────────────────
    component NewsCard: Item {
        id: card
        required property var modelData
        height: cardContent.implicitHeight + 1

        readonly property bool isSelected: news.selectedId === modelData["id"]

        Rectangle {
            anchors.fill: parent
            anchors.bottomMargin: 0
            color: card.isSelected ? Theme.panel3 : cardMa.containsMouse ? Theme.panel2 : "transparent"
            Behavior on color { ColorAnimation { duration: 120 } }

            // Selected indicator bar
            Rectangle {
                width: 3
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                color: Theme.primary
                opacity: card.isSelected ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }

            ColumnLayout {
                id: cardContent
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 16
                anchors.rightMargin: 14
                anchors.topMargin: 14
                anchors.bottomMargin: 13
                spacing: 8

                // Top row: industry badge + sentiment + time
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Rectangle {
                        width: industryText.implicitWidth + 12
                        height: 20
                        radius: 5
                        color: Theme.primarySoft
                        border.color: Theme.primary
                        opacity: 0.75

                        Text {
                            id: industryText
                            anchors.centerIn: parent
                            text: card.modelData["industry"] || ""
                            color: Theme.primary
                            font.pixelSize: 11
                        }
                    }

                    // Sentiment dot
                    Rectangle {
                        width: 7; height: 7
                        radius: 3.5
                        color: root.sentimentColor(card.modelData["sentiment"] || "neutral")
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Text {
                        text: root.sentimentLabel(card.modelData["sentiment"] || "neutral")
                        color: root.sentimentColor(card.modelData["sentiment"] || "neutral")
                        font.pixelSize: 11
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: (card.modelData["time"] || "").substring(11, 16)
                        color: Theme.faint
                        font.pixelSize: 11
                    }
                }

                // Title
                Text {
                    Layout.fillWidth: true
                    text: card.modelData["title"] || ""
                    color: card.isSelected ? Theme.text : Theme.muted
                    font.pixelSize: 13
                    font.weight: card.isSelected ? Font.Medium : Font.Normal
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    lineHeight: 1.45

                    Behavior on color { ColorAnimation { duration: 120 } }
                }

                // Brief / source row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        text: card.modelData["source"] || ""
                        color: Theme.faint
                        font.pixelSize: 11
                    }

                    Text { text: "·"; color: Theme.faint; font.pixelSize: 11 }

                    // AI rate mini badge
                    Rectangle {
                        readonly property var ai: card.modelData["ai"] || {}
                        readonly property real rateVal: ai["rate"] !== undefined ? ai["rate"] : 0
                        width: rateLabel.implicitWidth + 10
                        height: 18
                        radius: 5
                        color: Qt.rgba(
                            root.rateColor(rateVal).r,
                            root.rateColor(rateVal).g,
                            root.rateColor(rateVal).b,
                            0.15
                        )

                        Text {
                            id: rateLabel
                            anchors.centerIn: parent
                            readonly property var ai: card.modelData["ai"] || {}
                            readonly property real rateVal: ai["rate"] !== undefined ? ai["rate"] : 0
                            text: "AI " + rateVal.toFixed(1)
                            color: root.rateColor(rateVal)
                            font.pixelSize: 11
                            font.weight: Font.Medium
                        }
                    }
                }
            }

            // Bottom border line
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: Theme.line
            }
        }

        MouseArea {
            id: cardMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: news.selectNews(card.modelData["id"])
        }
    }
}
