import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    width: collapsed ? Theme.sidebarCollapsedWidth : Theme.sidebarWidth
    color: Theme.surface
    border.color: Theme.line
    clip: false

    property string page: "watchlist"
    property bool collapsed: false
    signal navigate(string page)

    FontLoader {
        id: iconFont
        source: "../assets/fonts/MaterialIconsRound-Regular.otf"
    }

    function labelFor(value) {
        const labels = {
            "overview": "系统总览",
            "watchlist": "实时盯盘",
            "account": "账户持仓",
            "strategy": "策略中心",
            "backtest": "回测工作台",
            "risk": "风控中心",
            "agent": "AI 决策台",
            "journal": "日志与 Journal"
        }
        return labels[value] || "未知页面"
    }

    function iconFor(value) {
        const icons = {
            "overview":  "",
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

    Behavior on width {
        NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
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
        anchors.leftMargin: root.collapsed ? 14 : 22
        anchors.rightMargin: root.collapsed ? 14 : 22
        anchors.topMargin: 22
        anchors.bottomMargin: 18
        spacing: 16

        Behavior on anchors.leftMargin {
            NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
        }
        Behavior on anchors.rightMargin {
            NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
        }

        // Header: DQ badge + brand text (collapse button is absolute, not in this row)
        RowLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: 12
            spacing: 10

            Rectangle {
                width: 38
                height: 38
                radius: 12
                color: Theme.primarySoft
                border.color: Theme.border

                Text {
                    anchors.centerIn: parent
                    text: "DQ"
                    color: Theme.text
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.maximumWidth: root.collapsed ? 0 : 9999
                spacing: 0
                opacity: root.collapsed ? 0 : 1
                clip: true

                Behavior on Layout.maximumWidth {
                    NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
                }
                Behavior on opacity {
                    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                }

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
                "overview", "watchlist", "account", "strategy",
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
                    property bool iconMode: root.collapsed

                    Text {
                        id: navText
                        anchors.fill: parent
                        text: btnContent.iconMode
                              ? root.iconFor(navButton.modelData)
                              : navButton.text
                        font.family: btnContent.iconMode ? iconFont.name : ""
                        font.pixelSize: btnContent.iconMode ? 24 : 15
                        color: root.page === navButton.modelData ? Theme.text : Theme.muted
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: btnContent.iconMode
                                             ? Text.AlignHCenter
                                             : Text.AlignLeft
                        leftPadding: btnContent.iconMode ? 0 : 14
                    }

                    SequentialAnimation {
                        id: textTransition
                        running: false
                        NumberAnimation {
                            target: navText; property: "opacity"; to: 0
                            duration: 90; easing.type: Easing.InCubic
                        }
                        PropertyAction {
                            target: btnContent; property: "iconMode"
                            value: root.collapsed
                        }
                        NumberAnimation {
                            target: navText; property: "opacity"; to: 1
                            duration: 150; easing.type: Easing.OutCubic
                        }
                    }

                    Connections {
                        target: root
                        function onCollapsedChanged() { textTransition.restart() }
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
