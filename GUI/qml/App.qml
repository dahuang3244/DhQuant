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

            PlaceholderPage {
                anchors.fill: parent
                visible: dashboard.page !== "watchlist"
                title: sidebar.labelFor(dashboard.page)
                hint: "这个页面会沿用相同的 PySide 控制器 + QML 页面结构继续补齐。"
            }
        }
    }

    Toast {
        visible: dashboard.toastVisible
        title: dashboard.toastTitle
        message: dashboard.toastMessage
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 20
        onDismiss: dashboard.dismissToast()
    }
}
