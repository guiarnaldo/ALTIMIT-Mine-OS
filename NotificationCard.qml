import QtQuick

Item {
    id: card

    property string appName
    property string body
    property bool closing: false
    property int count: 1
    property string fontName: "sans-serif"
    readonly property bool hovered: hover.hovered
    property url icon
    readonly property real shadowOffset: 8
    property string summary

    signal activated
    signal closeClicked
    signal closed

    function close() {
        if (closing)
            return;
        closing = true;
        leave.start();
    }

    implicitHeight: box.height + shadowOffset
    implicitWidth: 400 + shadowOffset
    opacity: 0

    Component.onCompleted: enter.start()

    ParallelAnimation {
        id: enter

        NumberAnimation {
            duration: 220
            easing.type: Easing.OutCubic
            from: 0
            property: "opacity"
            target: card
            to: 1
        }
        NumberAnimation {
            duration: 260
            easing.type: Easing.OutCubic
            from: 28
            property: "x"
            target: content
            to: 0
        }
    }
    SequentialAnimation {
        id: leave

        ParallelAnimation {
            NumberAnimation {
                duration: 180
                easing.type: Easing.InCubic
                property: "opacity"
                target: card
                to: 0
            }
            NumberAnimation {
                duration: 180
                easing.type: Easing.InCubic
                property: "x"
                target: content
                to: 28
            }
        }
        ScriptAction {
            script: card.closed()
        }
    }
    Item {
        id: content

        height: card.height
        width: card.width

        Rectangle {
            color: Qt.rgba(0, 0, 0, 0.3)
            height: box.height
            radius: box.radius
            width: box.width
            x: card.shadowOffset
            y: card.shadowOffset
        }
        Rectangle {
            id: box

            color: Qt.rgba(0.094, 0.353, 0.404, card.hovered ? 0.94 : 0.88)
            height: Math.max(78, texts.height + footer.height + 30)
            radius: 12
            width: card.width - card.shadowOffset

            Behavior on color {
                ColorAnimation {
                    duration: 120
                }
            }

            HoverHandler {
                id: hover
            }
            MouseArea {
                anchors.fill: parent

                onClicked: card.activated()
            }
            Column {
                id: texts

                spacing: 3
                width: box.width - x - 20
                x: 22
                y: 14

                Text {
                    color: "white"
                    elide: Text.ElideRight
                    font.family: card.fontName
                    font.pixelSize: 16
                    font.weight: Font.Medium
                    maximumLineCount: 2
                    text: card.summary || card.appName
                    textFormat: Text.PlainText
                    width: parent.width
                    wrapMode: Text.Wrap
                }
                Text {
                    color: Qt.rgba(1, 1, 1, 0.86)
                    elide: Text.ElideRight
                    font.family: card.fontName
                    font.pixelSize: 14
                    linkColor: "#aab9fd"
                    maximumLineCount: 3
                    text: card.body
                    textFormat: Text.StyledText
                    visible: text !== ""
                    width: parent.width
                    wrapMode: Text.Wrap
                }
            }
            Row {
                id: footer

                anchors.right: closeButton.left
                anchors.rightMargin: 14
                spacing: 6
                y: texts.y + texts.height + 4

                Image {
                    anchors.verticalCenter: parent.verticalCenter
                    fillMode: Image.PreserveAspectFit
                    height: 22
                    mipmap: true
                    source: card.icon
                    sourceSize: Qt.size(64, 64)
                    visible: status === Image.Ready
                    width: 22
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    color: "white"
                    font.family: card.fontName
                    font.pixelSize: 16
                    text: ": " + card.count
                }
            }
            Rectangle {
                id: closeButton

                anchors.bottom: parent.bottom
                anchors.bottomMargin: 9
                anchors.right: parent.right
                anchors.rightMargin: 12
                border.color: closeHover.hovered ? "white" : "#c9cfd8"
                border.width: 1.5
                color: closeHover.hovered ? "#353b48" : "#262a33"
                height: 22
                radius: width / 2
                width: 22

                Repeater {
                    model: [45, -45]

                    Rectangle {
                        required property real modelData

                        anchors.centerIn: parent
                        antialiasing: true
                        color: "#aab9fd"
                        height: 2
                        radius: 1
                        rotation: modelData
                        width: 11
                    }
                }
                HoverHandler {
                    id: closeHover

                    cursorShape: Qt.PointingHandCursor
                }
                MouseArea {
                    anchors.fill: parent

                    onClicked: card.closeClicked()
                }
            }
        }
    }
}
