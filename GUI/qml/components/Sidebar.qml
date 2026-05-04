import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    width: collapsed ? Theme.sidebarCollapsedWidth : Theme.sidebarWidth
    color: Theme.surface
    border.color: Theme.line
    clip: true

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

    // Collapse toggle — absolute-positioned, glued to the right edge of the sidebar.
    // x follows root.width (no separate Behavior) so it slides purely horizontally
    // with the sidebar animation. y is fixed at header level — no diagonal movement.
    Rectangle {
        id: collapseBtn
        z: 10
        width: 28
        height: 28
        radius: 9

        x: root.width - width - 2
        y: 27

        color: collapseBtnMA.containsMouse ? Theme.panel3 : Theme.panel2
        border.color: collapseBtnMA.containsMouse ? Theme.primary : Theme.border
        Behavior on color        { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        Text {
            anchors.centerIn: parent
            text: root.collapsed ? "›" : "‹"
            color: Theme.primary
            font.pixelSize: 16
            font.weight: Font.Bold
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        MouseArea {
            id: collapseBtnMA
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.collapsed = !root.collapsed
        }
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
