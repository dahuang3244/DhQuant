import QtQuick
import QtQuick.Controls

Rectangle {
    id: root
    width: 320
    height: visible ? 82 : 0
    radius: Theme.radius
    color: Theme.panel2
    border.color: Theme.border
    opacity: visible ? 1 : 0

    property string title: ""
    property string message: ""
    signal dismiss()

    Behavior on opacity { NumberAnimation { duration: 140 } }

    Column {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 6
        Text {
            text: root.title
            color: Theme.text
            font.pixelSize: 14
            font.weight: Font.DemiBold
        }
        Text {
            text: root.message
            color: Theme.muted
            font.pixelSize: 12
            width: parent.width
            elide: Text.ElideRight
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.dismiss()
    }
}
