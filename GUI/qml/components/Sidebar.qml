pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    width: Theme.sidebarWidth - (Theme.sidebarWidth - Theme.sidebarCollapsedWidth) * collapseProgress
    color: Theme.surface
    border.color: Theme.line
    clip: false

    property string page: "watchlist"
    property bool collapsed: false
    property real collapseProgress: collapsed ? 1 : 0
    signal navigate(string page)

    FontLoader {
        id: iconFont
        source: "../assets/fonts/MaterialIconsRound-Regular.otf"
    }

    function labelFor(value) {
        const labels = {
            "news":      "行业新闻",
            "watchlist": "实时盯盘",
            "account":   "账户持仓",
            "strategy":  "策略中心",
            "backtest":  "回测工作台",
            "risk":      "风控中心",
            "agent":     "AI 决策台",
            "journal":   "交易日志"
        }
        return labels[value] || "未知页面"
    }

    function iconFor(value) {
        const icons = {
            "news":      "",
            "watchlist": "",
            "account":   "",
            "strategy":  "",
            "backtest":  "",
            "risk":      "",
            "agent":     "",
            "journal":   ""
        }
        return icons[value] || ""
    }

    Behavior on collapseProgress {
        NumberAnimation { duration: 240; easing.type: Easing.OutCubic }
    }

    // Boundary rail: the affordance lives on the sidebar/workspace edge and
    // only becomes prominent when the pointer approaches the divider.
    Item {
        id: collapseRail
        z: 20
        width: 18
        height: root.height
        x: root.width - width / 2
        y: 0

        readonly property bool active: collapseRailMA.containsMouse

        Rectangle {
            id: railLine
            width: collapseRail.active ? 2 : 1
            radius: width / 2
            anchors {
                top: parent.top
                bottom: parent.bottom
                horizontalCenter: parent.horizontalCenter
            }
            color: collapseRail.active ? Theme.primary : Theme.line
            opacity: collapseRail.active ? 0.78 : 0.72

            Behavior on width { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 140 } }
            Behavior on opacity { NumberAnimation { duration: 140 } }
        }

        Rectangle {
            id: railHandle
            width: collapseRail.active ? 26 : 8
            height: collapseRail.active ? 56 : 44
            radius: 13
            anchors {
                verticalCenter: parent.verticalCenter
                horizontalCenter: parent.horizontalCenter
            }
            color: collapseRail.active ? Theme.panel3 : Theme.panel2
            border.color: collapseRail.active ? Theme.primary : Theme.border
            opacity: collapseRail.active ? 1 : 0.42
            scale: collapseRailMA.pressed ? 0.94 : 1

            Behavior on width { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }
            Behavior on height { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }
            Behavior on opacity { NumberAnimation { duration: 150 } }
            Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }

            Rectangle {
                width: 1
                height: 24
                radius: 1
                anchors.centerIn: parent
                color: collapseRail.active ? Theme.primary : Theme.faint
                opacity: root.collapsed || !collapseRail.active ? 0 : 0.55
                Behavior on opacity { NumberAnimation { duration: 120 } }
            }

            Text {
                anchors.centerIn: parent
                text: root.collapsed ? "›" : "‹"
                color: collapseRail.active ? Theme.text : Theme.primary
                opacity: collapseRail.active ? 1 : 0
                font.pixelSize: 18
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

                Behavior on color { ColorAnimation { duration: 130 } }
                Behavior on opacity { NumberAnimation { duration: 120 } }
            }
        }

        MouseArea {
            id: collapseRailMA
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton
            onClicked: root.collapsed = !root.collapsed
        }

        ToolTip.visible: collapseRail.active
        ToolTip.delay: 450
        ToolTip.text: root.collapsed ? "展开侧边栏" : "折叠侧边栏"
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 22
        anchors.rightMargin: 22
        anchors.topMargin: 22
        anchors.bottomMargin: 18
        spacing: 16

        // Header: app icon remains anchored in both expanded and collapsed states.
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            Layout.bottomMargin: 12

            Image {
                id: appLogo
                source: "../assets/icons/dhquant-logo.svg"
                width: 38
                height: 38
                sourceSize: Qt.size(38, 38)
                smooth: true
                anchors.verticalCenter: parent.verticalCenter
                x: 0
            }

            ColumnLayout {
                anchors.left: appLogo.right
                anchors.leftMargin: 10
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0
                opacity: Math.max(0, 1 - root.collapseProgress * 1.35)
                clip: true

                Text {
                    text: "DhQuant"
                    color: Theme.text
                    font.pixelSize: 24
                    font.weight: Font.DemiBold
                }

                Text {
                    text: "LIVE TRADING DESK"
                    color: Theme.faint
                    font.pixelSize: 10
                    font.letterSpacing: 1.4
                }
            }
        }

        Repeater {
            model: [
                "news", "watchlist", "account", "strategy",
                "backtest", "risk", "agent", "journal"
            ]

            Button {
                id: navButton
                required property string modelData
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                text: root.labelFor(modelData)
                flat: true
                onClicked: root.navigate(modelData)
                scale: pressed ? 0.98 : 1

                Behavior on scale {
                    NumberAnimation { duration: 110; easing.type: Easing.OutCubic }
                }

                contentItem: Item {
                    id: btnContent

                    Text {
                        id: navLabel
                        anchors.fill: parent
                        text: navButton.text
                        font.pixelSize: 15
                        color: root.page === navButton.modelData ? Theme.text : Theme.muted
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignLeft
                        leftPadding: 14
                        opacity: Math.max(0, 1 - root.collapseProgress * 1.5)
                    }

                    Text {
                        id: navIcon
                        anchors.centerIn: parent
                        width: parent.width
                        text: root.iconFor(navButton.modelData)
                        font.family: iconFont.name
                        font.pixelSize: 24
                        color: root.page === navButton.modelData ? Theme.text : Theme.muted
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        opacity: Math.max(0, (root.collapseProgress - 0.25) / 0.75)
                    }
                }

                background: Rectangle {
                    // Protrude 6 px into the left margin for the selected item
                    readonly property bool selected: root.page === navButton.modelData
                    x: selected ? -6 : 0
                    width: parent.width + (selected ? 6 : 0)
                    height: parent.height
                    radius: 12

                    color: selected ? Theme.panel3
                                    : navButton.hovered ? Theme.panel2 : "transparent"
                    border.color: selected ? Theme.primary : "transparent"

                    Behavior on x     { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation  { duration: 160 } }
                    Behavior on border.color { ColorAnimation { duration: 160 } }

                    Rectangle {
                        width: 3
                        height: 22
                        radius: 2
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        color: Theme.primary
                        opacity: root.page === navButton.modelData ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 160 } }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
