pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import "components"
import "pages"

ApplicationWindow {
    id: root
    width: 1440
    height: 900
    minimumWidth: designWidth
    minimumHeight: designHeight
    visible: true
    title: "DhQuant"
    flags: Qt.Window | Qt.FramelessWindowHint
    color: Theme.background
    readonly property int designWidth: 1440
    readonly property int designHeight: 900
    readonly property int titleBarHeight: 34

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            id: titleBar
            Layout.fillWidth: true
            Layout.preferredHeight: root.titleBarHeight
            color: Theme.background
            border.color: Theme.line

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                onPressed: root.startSystemMove()
                onDoubleClicked: {
                    if (root.visibility === Window.Maximized) {
                        root.showNormal()
                    } else {
                        root.showMaximized()
                    }
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                spacing: 8

                WindowButton {
                    dotColor: "#ff5f57"
                    hoverColor: Qt.rgba(1.0, 0.373, 0.341, 0.18)
                    onClicked: root.close()
                }

                WindowButton {
                    dotColor: "#ffbd2e"
                    hoverColor: Qt.rgba(1.0, 0.741, 0.180, 0.18)
                    onClicked: root.showMinimized()
                }

                WindowButton {
                    dotColor: "#28c840"
                    hoverColor: Qt.rgba(0.157, 0.784, 0.251, 0.18)
                    onClicked: {
                        if (root.visibility === Window.Maximized) {
                            root.showNormal()
                        } else {
                            root.showMaximized()
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: root.title
                    color: Theme.muted
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    Layout.alignment: Qt.AlignVCenter
                }

                Item { Layout.fillWidth: true }

                Item { Layout.preferredWidth: 58 }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            RowLayout {
                anchors.fill: parent
                spacing: 0

                Sidebar {
                    id: sidebar
                    Layout.fillHeight: true
                    Layout.preferredWidth: width
                    page: dashboard.page
                    onNavigate: function(nextPage) { dashboard.setPage(nextPage) }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    NewsPage {
                        anchors.fill: parent
                        visible: dashboard.page === "news"
                    }

                    WatchlistPage {
                        anchors.fill: parent
                        visible: dashboard.page === "watchlist"
                    }

                    BacktestPage {
                        anchors.fill: parent
                        visible: dashboard.page === "backtest"
                    }

                    StrategyPage {
                        anchors.fill: parent
                        visible: dashboard.page === "strategy"
                    }

                    TradingPage {
                        anchors.fill: parent
                        visible: dashboard.page === "account"
                    }

                    RiskPage {
                        anchors.fill: parent
                        visible: dashboard.page === "risk"
                    }

                    JournalPage {
                        anchors.fill: parent
                        visible: dashboard.page === "journal"
                    }

                    PlaceholderPage {
                        anchors.fill: parent
                        visible: dashboard.page !== "news"
                              && dashboard.page !== "watchlist"
                              && dashboard.page !== "backtest"
                              && dashboard.page !== "strategy"
                              && dashboard.page !== "account"
                              && dashboard.page !== "risk"
                              && dashboard.page !== "journal"
                        title: sidebar.labelFor(dashboard.page)
                        hint: "这个页面会沿用相同的 PySide 控制器 + QML 页面结构继续补齐。"
                    }
                }
            }
        }
    }

    Toast {
        id: toastItem
        visible: dashboard.toastVisible
        title: dashboard.toastTitle
        message: dashboard.toastMessage
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 20
        onDismiss: { dashboard.dismissToast(); toastTimer.stop() }
    }

    Timer {
        id: toastTimer
        interval: 3200
        repeat: false
        running: dashboard.toastVisible
        onTriggered: dashboard.dismissToast()
    }

    ResizeHandle {
        edges: Qt.LeftEdge
        cursor: Qt.SizeHorCursor
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        thickness: 6
    }

    ResizeHandle {
        edges: Qt.RightEdge
        cursor: Qt.SizeHorCursor
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        thickness: 6
    }

    ResizeHandle {
        edges: Qt.TopEdge
        cursor: Qt.SizeVerCursor
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        thickness: 6
    }

    ResizeHandle {
        edges: Qt.BottomEdge
        cursor: Qt.SizeVerCursor
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        thickness: 6
    }

    ResizeHandle {
        edges: Qt.LeftEdge | Qt.TopEdge
        cursor: Qt.SizeFDiagCursor
        anchors.left: parent.left
        anchors.top: parent.top
        thickness: 12
    }

    ResizeHandle {
        edges: Qt.RightEdge | Qt.TopEdge
        cursor: Qt.SizeBDiagCursor
        anchors.right: parent.right
        anchors.top: parent.top
        thickness: 12
    }

    ResizeHandle {
        edges: Qt.LeftEdge | Qt.BottomEdge
        cursor: Qt.SizeBDiagCursor
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        thickness: 12
    }

    ResizeHandle {
        edges: Qt.RightEdge | Qt.BottomEdge
        cursor: Qt.SizeFDiagCursor
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        thickness: 12
    }

    component WindowButton: Item {
        id: buttonRoot
        signal clicked()
        property color dotColor: Theme.faint
        property color hoverColor: Theme.panel3

        Layout.preferredWidth: 14
        Layout.preferredHeight: 34

        Rectangle {
            anchors.centerIn: parent
            width: buttonMouse.containsMouse ? 14 : 12
            height: width
            radius: width / 2
            color: buttonMouse.containsMouse ? buttonRoot.hoverColor : "transparent"
            border.color: buttonRoot.dotColor
            border.width: 1
            Behavior on width { NumberAnimation { duration: 100 } }
            Behavior on color { ColorAnimation { duration: 100 } }

            Rectangle {
                anchors.centerIn: parent
                width: 8
                height: 8
                radius: 4
                color: buttonRoot.dotColor
            }
        }

        MouseArea {
            id: buttonMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: buttonRoot.clicked()
        }
    }

    component ResizeHandle: Item {
        id: resizeRoot
        property int edges: Qt.RightEdge
        property int cursor: Qt.ArrowCursor
        property int thickness: 6

        z: 100
        width: thickness
        height: thickness

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: resizeRoot.cursor
            acceptedButtons: Qt.LeftButton
            onPressed: root.startSystemResize(resizeRoot.edges)
        }
    }
}
