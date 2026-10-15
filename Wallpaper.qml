import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: desktop

    required property var modelData
    required property var service
    property url shown: ""
    readonly property url source: service.urlFor(modelData.name)

    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "altimit-wallpaper"
    color: "black"
    exclusionMode: ExclusionMode.Ignore
    screen: modelData

    onSourceChanged: {
        previous.source = shown;
        previous.opacity = shown.toString() !== "" ? 1 : 0;
        shown = source;
    }

    anchors {
        bottom: true
        left: true
        right: true
        top: true
    }
    AnimatedImage {
        id: current

        anchors.fill: parent
        asynchronous: true
        cache: false
        fillMode: Image.PreserveAspectCrop
        playing: true
        source: desktop.source

        onStatusChanged: if (status === Image.Ready)
            fade.restart()
    }
    Image {
        id: previous

        anchors.fill: parent
        asynchronous: true
        fillMode: Image.PreserveAspectCrop
        opacity: 0
        visible: opacity > 0
    }
    NumberAnimation {
        id: fade

        duration: 400
        property: "opacity"
        target: previous
        to: 0
    }
}
