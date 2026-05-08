import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "components"
import "pages"

ApplicationWindow {
    id: root
    width: 1440
    height: 900
    minimumWidth: 1180
    minimumHeight: 720
    visible: true
    title: "DhQuant"
    color: Theme.background

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

            PlaceholderPage {
                anchors.fill: parent
                visible: dashboard.page !== "watchlist"
                      && dashboard.page !== "backtest"
                      && dashboard.page !== "strategy"
                      && dashboard.page !== "account"
                title: sidebar.labelFor(dashboard.page)
                hint: "这个页面会沿用相同的 PySide 控制器 + QML 页面结构继续补齐。"
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
}
