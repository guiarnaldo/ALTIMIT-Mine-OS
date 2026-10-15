import QtQuick

Rectangle {
    id: box

    property string description
    property var fontAxes: ({})
    property string fontName: "sans-serif"
    property url icon
    readonly property real line: Math.max(2, height * 0.016)
    readonly property real lineGap: u * 2.5
    readonly property real minLineWidth: u * 10
    property string title
    readonly property real u: width / 100

    color: Qt.rgba(0.0, 0.62, 0.76, 0.52)

    Behavior on opacity {
        NumberAnimation {
            duration: 140
        }
    }

    Text {
        id: title

        color: "white"
        font.family: box.fontName
        font.pixelSize: box.u * 6.6
        font.variableAxes: box.fontAxes
        font.weight: Font.Medium
        fontSizeMode: Text.HorizontalFit
        height: box.height * 0.2
        minimumPixelSize: Math.round(box.u * 3)
        text: box.title
        verticalAlignment: Text.AlignTop
        width: Math.min(implicitWidth, box.width - x - box.lineGap - box.minLineWidth)
        x: box.u * 2
        y: box.height * 0.06
    }
    Repeater {
        model: [0.112, 0.148, 0.245]

        Rectangle {
            required property real modelData

            color: "white"
            height: box.line
            width: box.width - x
            x: title.x + title.contentWidth + box.lineGap
            y: box.height * modelData
        }
    }
    Text {
        color: "white"
        font.family: box.fontName
        font.pixelSize: box.u * 1.75
        font.variableAxes: box.fontAxes
        font.weight: Font.Light
        lineHeight: 0.95
        text: box.description || "MINE OS offers a creative and\ncomfortable lifestyle for everyone."
        x: box.u * 5
        y: box.height * 0.33
    }
    Image {
        fillMode: Image.PreserveAspectFit
        height: width
        mipmap: true
        source: box.icon
        sourceSize: Qt.size(256, 256)
        width: box.u * 7
        x: box.width - width - box.u * 1.6
        y: box.height * 0.3
    }
    Text {
        anchors.baseline: mine.baseline
        anchors.right: mine.left
        anchors.rightMargin: box.u * 1.2
        color: "white"
        font.family: box.fontName
        font.pixelSize: box.u * 1.75
        font.variableAxes: box.fontAxes
        font.weight: Font.Light
        text: "©2016-2017 Mine All rights reserved."
    }
    Text {
        id: mine

        anchors.right: parent.right
        anchors.rightMargin: box.u * 1.6
        color: "white"
        font.family: box.fontName
        font.pixelSize: box.u * 3.6
        font.variableAxes: box.fontAxes
        font.weight: Font.Medium
        text: "MINE OS"
        y: box.height * 0.71
    }
    Rectangle {
        color: "white"
        height: box.line
        width: parent.width
        y: box.height * 0.88
    }
    Text {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: box.height * 0.005
        color: "white"
        font.family: box.fontName
        font.pixelSize: box.u * 2.4
        font.variableAxes: box.fontAxes
        font.weight: Font.Medium
        text: "Altimit Mine"
        x: box.u * 2.7
    }
}
