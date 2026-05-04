import QtQuick
import "../components"

Item {
    property string title: ""
    property string hint: ""

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 24
        height: 180
        radius: Theme.radius
        color: Theme.panel
        border.color: Theme.border

        Text {
            x: 24
            y: 24
            text: title
            color: Theme.text
            font.pixelSize: 26
            font.weight: Font.DemiBold
        }

        Text {
            x: 24
            y: 72
            width: parent.width - 48
            text: hint
            color: Theme.muted
            font.pixelSize: 16
            wrapMode: Text.WordWrap
        }
    }
}
