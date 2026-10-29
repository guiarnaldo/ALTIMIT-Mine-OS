import QtQuick

Item {
    id: badge

    property string fontFamily: "sans-serif"
    property bool italic: false
    property real size: 26
    readonly property real stroke: Math.max(1.5, size * 0.09)

    implicitHeight: label.implicitHeight + stroke * 2
    implicitWidth: label.implicitWidth + stroke * 2

    Repeater {
        model: 16

        Text {
            required property int index

            color: "black"
            font: label.font
            text: label.text
            x: badge.stroke + Math.cos(index * Math.PI / 8) * badge.stroke
            y: badge.stroke + Math.sin(index * Math.PI / 8) * badge.stroke
        }
    }
    Text {
        id: label

        color: "#f5d417"
        font.family: badge.fontFamily
        font.italic: badge.italic
        font.pixelSize: badge.size
        font.weight: Font.Black
        text: "NEW"
        x: badge.stroke
        y: badge.stroke
    }
}
