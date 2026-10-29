import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications

Scope {
    id: root

    property string fontFamily: "M PLUS 1p"
    readonly property string fontName: Qt.fontFamilies().indexOf(fontFamily) >= 0 ? fontFamily : "sans-serif"
    property bool history: true
    property int historyLimit: 100
    readonly property var list: server.trackedNotifications.values
    readonly property var mails: list.filter(n => !n.transient || popupIds[n.id]).reverse()
    property int maxVisible: 4
    property var popupIds: ({})
    readonly property var popupList: list.filter(n => popupIds[n.id])
    property var readIds: ({})
    property string screenName: ""
    readonly property var targetScreen: {
        const screens = Quickshell.screens;
        for (let i = 0; i < screens.length; i++) {
            if (screens[i].name === screenName)
                return screens[i];
        }
        return null;
    }
    property real timeout: 6
    readonly property int unreadCount: mails.filter(n => !readIds[n.id]).length

    signal openRequested(int id)

    function clear() {
        const all = list.slice();
        for (const n of all)
            n.dismiss();
    }
    function defaultAction(n) {
        if (!n)
            return null;
        for (let i = 0; i < n.actions.length; i++) {
            if (n.actions[i].identifier === "default")
                return n.actions[i];
        }
        return null;
    }
    function iconFor(n) {
        let src = n.appIcon;
        if (!src && n.desktopEntry) {
            const entry = DesktopEntries.heuristicLookup(n.desktopEntry);
            src = entry ? entry.icon : "";
        }
        src = src || n.image;
        if (!src)
            return "";
        if (src.startsWith("/"))
            return "file://" + src;
        if (src.indexOf("://") >= 0)
            return src;
        return Quickshell.iconPath(src, true);
    }
    function invokeDefault(n) {
        const action = defaultAction(n);
        if (!action)
            return false;
        markRead(n);
        action.invoke();
        return true;
    }
    function markRead(n) {
        if (!n || readIds[n.id])
            return;
        const next = Object.assign({}, readIds);
        next[n.id] = true;
        readIds = next;
    }
    function pictureFor(n) {
        const src = n.image;
        if (!src)
            return iconFor(n);
        if (src.startsWith("/"))
            return "file://" + src;
        if (src.indexOf("://") >= 0)
            return src;
        return Quickshell.iconPath(src, true);
    }
    function remove(n) {
        if (n)
            n.dismiss();
    }
    function setPopup(n, on) {
        if (!!popupIds[n.id] === on)
            return;
        const next = Object.assign({}, popupIds);
        if (on)
            next[n.id] = true;
        else
            delete next[n.id];
        popupIds = next;
    }
    function unreadFrom(appName) {
        return mails.filter(n => n.appName === appName && !readIds[n.id]).length;
    }

    NotificationServer {
        id: server

        actionsSupported: true
        bodyMarkupSupported: true
        imageSupported: true
        keepOnReload: root.history
        persistenceSupported: root.history

        onNotification: n => {
            n.tracked = true;
            if (!n.lastGeneration)
                root.setPopup(n, true);
            const old = root.list.filter(m => !root.popupIds[m.id]);
            for (let i = 0; i < old.length - root.historyLimit; i++)
                old[i].expire();
        }
    }
    PanelWindow {
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "altimit-notifications"
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        implicitHeight: Math.max(1, column.implicitHeight)
        implicitWidth: Math.max(1, column.implicitWidth)
        screen: root.targetScreen
        visible: root.popupList.length > 0

        anchors {
            right: true
            top: true
        }
        margins {
            right: 20
            top: 20
        }
        Column {
            id: column

            spacing: 6

            move: Transition {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutCubic
                    property: "y"
                }
            }

            Repeater {
                model: server.trackedNotifications

                NotificationCard {
                    id: card

                    required property Notification modelData
                    readonly property int rank: root.popupList.indexOf(modelData)
                    property bool timedOut: false

                    appName: modelData.appName
                    body: modelData.body
                    count: Math.max(1, root.unreadFrom(modelData.appName))
                    fontName: root.fontName
                    icon: root.iconFor(modelData)
                    summary: modelData.summary
                    visible: rank >= 0 && rank >= root.popupList.length - root.maxVisible

                    onActivated: {
                        if (!root.invokeDefault(modelData))
                            root.openRequested(modelData.id);
                        close();
                    }
                    onCloseClicked: close()
                    onClosed: {
                        root.setPopup(modelData, false);
                        if (!root.history || modelData.transient) {
                            if (timedOut)
                                modelData.expire();
                            else
                                modelData.dismiss();
                        }
                    }

                    Timer {
                        interval: (card.modelData.expireTimeout > 0 ? card.modelData.expireTimeout : root.timeout) * 1000
                        running: card.modelData.urgency !== NotificationUrgency.Critical && !card.hovered && !card.closing && card.visible

                        onTriggered: {
                            card.timedOut = true;
                            card.close();
                        }
                    }
                }
            }
        }
    }
}
