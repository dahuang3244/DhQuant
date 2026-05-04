import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    height: Theme.topbarHeight
    color: Theme.background
    border.color: Theme.border

    property string runtime: "Stopped"
    property string runId: ""
    property string connection: ""
    signal startClicked()
    signal stopClicked()

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 28
        anchors.rightMargin: 28
        spacing: 16

        Rectangle {
            width: 10
            height: 10
            radius: 5
            color: root.runtime === "Running" ? Theme.positive : Theme.muted
        }

        Text {
            text: root.runtime
            color: Theme.text
            font.pixelSize: 17
            font.weight: Font.DemiBold
        }

        Text {
            text: "runId: " + root.runId + " / " + root.connection
            color: Theme.muted
            font.pixelSize: 14
            Layout.leftMargin: 80
        }

        Item { Layout.fillWidth: true }

        Button {
            text: "启动"
            enabled: root.runtime !== "Running"
            Layout.preferredWidth: 124
            Layout.preferredHeight: 42
            onClicked: root.startClicked()
            contentItem: Text {
                text: parent.text
                color: Theme.text
                font.pixelSize: 15
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                radius: Theme.radius
                color: parent.enabled ? (parent.hovered ? Theme.primaryHover : Theme.primary) : Theme.panel2
            }
        }

        Button {
            text: "停止"
            enabled: root.runtime === "Running"
            Layout.preferredWidth: 124
            Layout.preferredHeight: 42
            onClicked: root.stopClicked()
            contentItem: Text {
                text: parent.text
                color: Theme.text
                font.pixelSize: 15
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                radius: Theme.radius
                color: parent.hovered ? Theme.panel3 : Theme.panel
                border.color: Theme.border
            }
        }
    }
}
