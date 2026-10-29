import QtQuick

Item {
    id: station

    readonly property bool busy: openAnim.running || closeAnim.running || listAnim.running
    readonly property bool clipFolder: folder === 1
    property var clipboard: null
    readonly property var clips: clipboard ? clipboard.entries : []
    readonly property real collapseP: ease(clamp((listP - 0.4) / 0.3, 0, 1))
    property bool contentOn: false
    property bool copied: false
    readonly property real fadeP: clamp(listP / 0.4, 0, 1)
    property int folder: 0
    readonly property var folders: [
        {
            icon: "mail2.png",
            text: "Read mail."
        },
        {
            icon: "data2.png",
            text: "Send greeting card."
        },
        {
            icon: "news2.png",
            text: "Check addresses."
        }
    ]
    readonly property real headerH: px(232) - px(111) * collapseP
    readonly property var hints: {
        const back = {
            key: "Esc",
            tone: "gray",
            text: ": Return"
        };
        const del = {
            key: "Del",
            tone: "blue",
            text: ": Delete"
        };
        if (mode === "folders")
            return [
                {
                    text: folders[folder].text
                }
            ];
        if (mode === "list") {
            const items = [
                {
                    text: copied ? "Copied to the clipboard." : listMails.length > 0 || clipFolder ? folders[folder].text : "There is no mail."
                }
            ];
            if (listMails.length > 0)
                items.push({
                    key: "↵",
                    tone: "green",
                    text: clipFolder ? ": Copy" : ": Read"
                }, del, back);
            return items;
        }
        const items = [
            {
                text: "Read mail."
            }
        ];
        if (reading && service && service.defaultAction(reading))
            items.push({
                key: "↵",
                tone: "green",
                text: ": Open"
            });
        items.push(del, back);
        return items;
    }
    required property var hud
    property int index: 0
    readonly property var listMails: folder === 0 ? mails : folder === 1 ? clips : []
    property real listP: 0
    property real loadP: 0
    readonly property var mails: service ? service.mails : []
    property real meet: 0
    property string mode: "folders"
    property bool open: false
    readonly property real pageH: px(840)
    property int pendingId: -1
    property var reading: null
    readonly property real rowH: px(59.15)
    readonly property real s: height / 1080
    property var service: null
    property bool shown: false
    readonly property string textFont: hud.hintFontName

    function back() {
        if (busy)
            return;
        if (mode === "folders") {
            hide();
        } else if (mode === "list") {
            mode = "folders";
            listAnim.to = 0;
            listAnim.restart();
        } else {
            loadAnim.stop();
            mode = "list";
            reading = null;
        }
    }
    function clamp(v, lo, hi) {
        return Math.max(lo, Math.min(hi, v));
    }
    function copyClip(i) {
        const n = listMails[i];
        if (!n || !clipboard)
            return;
        index = i;
        clipboard.copy(n);
        copied = true;
        copiedTimer.restart();
    }
    function ease(t) {
        return 1 - Math.pow(1 - t, 3);
    }
    function enterFolder() {
        if (busy || mode !== "folders")
            return;
        index = 0;
        if (clipFolder && clipboard)
            clipboard.refresh();
        mode = "list";
        listAnim.to = 1;
        listAnim.restart();
    }
    function handleKey(event) {
        if (busy)
            return;
        const shift = event.modifiers & Qt.ShiftModifier;
        switch (event.key) {
        case Qt.Key_Left:
            if (mode === "folders")
                move(-1);
            else
                back();
            break;
        case Qt.Key_Right:
            if (mode === "folders")
                move(1);
            break;
        case Qt.Key_Up:
            if (mode !== "folders")
                move(-1);
            break;
        case Qt.Key_Down:
            if (mode !== "folders")
                move(1);
            break;
        case Qt.Key_PageUp:
            move(mode === "list" ? -12 : -14);
            break;
        case Qt.Key_PageDown:
            move(mode === "list" ? 12 : 14);
            break;
        case Qt.Key_Return:
        case Qt.Key_Enter:
        case Qt.Key_Space:
            if (mode === "folders")
                enterFolder();
            else if (mode === "list" && clipFolder)
                copyClip(index);
            else if (mode === "list")
                openMail(index);
            else if (mode === "read" && service)
                service.invokeDefault(reading);
            break;
        case Qt.Key_Delete:
            if (mode === "folders" || folder === 2)
                break;
            if (clipFolder) {
                if (clipboard && listMails[index])
                    clipboard.remove(listMails[index]);
                break;
            }
            if (!service)
                break;
            if (mode !== "list")
                service.remove(reading);
            else if (shift)
                service.clear();
            else if (listMails[index])
                service.remove(listMails[index]);
            break;
        case Qt.Key_Escape:
        case Qt.Key_Backspace:
            back();
            break;
        default:
            if (mode === "read" && reading && event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
                const action = reading.actions[event.key - Qt.Key_1];
                if (action)
                    action.invoke();
            }
        }
    }
    function hide() {
        if (!open)
            return;
        open = false;
        openAnim.stop();
        listAnim.stop();
        loadAnim.stop();
        if (!shown) {
            contentOn = false;
            return;
        }
        contentOn = true;
        closeAnim.restart();
    }
    function move(delta) {
        if (busy)
            return;
        if (mode === "folders") {
            folder = clamp(folder + delta, 0, folders.length - 1);
        } else if (mode === "list") {
            index = clamp(index + delta, 0, Math.max(0, listMails.length - 1));
        } else if (mode === "read") {
            const max = Math.max(0, reader.contentHeight - reader.height);
            reader.contentY = clamp(reader.contentY + delta * px(48), 0, max);
        }
    }
    function openMail(i) {
        const n = listMails[i];
        if (!n)
            return;
        index = i;
        reading = n;
        reader.contentY = 0;
        mode = "loading";
        loadAnim.restart();
    }
    function px(v) {
        return v * s;
    }
    function show(id) {
        const target = id !== undefined && id >= 0 ? mails.findIndex(n => n.id === id) : -1;
        if (open) {
            if (target >= 0 && !busy) {
                folder = 0;
                listP = 1;
                openMail(target);
            }
            return;
        }
        closeAnim.stop();
        open = true;
        reading = null;
        index = 0;
        folder = 0;
        loadAnim.stop();
        if (target >= 0) {
            mode = "list";
            listP = 1;
        } else {
            mode = "folders";
            listP = 0;
        }
        pendingId = target;
        openAnim.restart();
    }

    visible: shown

    onClipFolderChanged: previewTimer.restart()
    onIndexChanged: previewTimer.restart()
    onListMailsChanged: {
        index = clamp(index, 0, Math.max(0, listMails.length - 1));
        previewTimer.restart();
        if ((mode === "read" || mode === "loading") && reading && !listMails.some(n => n.id === reading.id)) {
            loadAnim.stop();
            mode = "list";
            reading = null;
        }
    }

    SequentialAnimation {
        id: openAnim

        ScriptAction {
            script: {
                station.shown = false;
                station.contentOn = false;
                station.meet = 0;
            }
        }
        PauseAnimation {
            duration: 300
        }
        ScriptAction {
            script: station.shown = true
        }
        NumberAnimation {
            duration: 370
            easing.type: Easing.OutQuad
            from: 0
            property: "meet"
            target: station
            to: 1
        }
        ScriptAction {
            script: station.contentOn = true
        }
        PauseAnimation {
            duration: 270
        }
        NumberAnimation {
            duration: 530
            easing.type: Easing.InOutQuad
            from: 1
            property: "meet"
            target: station
            to: 0
        }
        ScriptAction {
            script: {
                if (station.pendingId >= 0)
                    station.openMail(station.pendingId);
                station.pendingId = -1;
            }
        }
    }
    SequentialAnimation {
        id: closeAnim

        NumberAnimation {
            duration: 370
            easing.type: Easing.InOutQuad
            property: "meet"
            target: station
            to: 1
        }
        ScriptAction {
            script: station.contentOn = false
        }
        PauseAnimation {
            duration: 150
        }
        NumberAnimation {
            duration: 300
            easing.type: Easing.InQuad
            from: 1
            property: "meet"
            target: station
            to: 0
        }
        ScriptAction {
            script: {
                station.shown = false;
                station.mode = "folders";
                station.reading = null;
                station.listP = 0;
            }
        }
    }
    NumberAnimation {
        id: listAnim

        duration: 500
        easing.type: Easing.Linear
        property: "listP"
        target: station
    }
    SequentialAnimation {
        id: loadAnim

        NumberAnimation {
            duration: 750
            easing.type: Easing.Linear
            from: 0
            property: "loadP"
            target: station
            to: 1
        }
        ScriptAction {
            script: {
                station.mode = "read";
                if (station.service)
                    station.service.markRead(station.reading);
            }
        }
    }
    Timer {
        id: previewTimer

        interval: 120

        onTriggered: {
            if (!station.clipFolder || !station.clipboard)
                return;
            const n = station.listMails[station.index] || null;
            if (!station.clipboard.isCurrent(n) || !n)
                station.clipboard.load(n);
        }
    }
    Timer {
        id: copiedTimer

        interval: 1500

        onTriggered: station.copied = false
    }
    MouseArea {
        acceptedButtons: Qt.AllButtons
        anchors.fill: parent
    }
    Item {
        id: viewport

        clip: true
        height: Math.max(0, footer.y - y)
        visible: station.contentOn
        width: parent.width
        y: header.y + header.height

        Rectangle {
            anchors.fill: parent
            color: "#b3b3b3"
        }
        Item {
            id: page

            height: station.pageH
            width: parent.width

            Item {
                id: inbox

                height: station.pageH
                opacity: !station.clipFolder && (station.mode === "list" || station.mode === "folders") ? 1 : 0
                visible: opacity > 0
                width: parent.width

                Behavior on opacity {
                    NumberAnimation {
                        duration: 120
                    }
                }

                Rectangle {
                    color: "#adadad"
                    height: station.px(70)
                    width: parent.width
                    y: station.px(1)

                    Rectangle {
                        color: "#3c3c3c"
                        height: station.px(4)
                        width: parent.width
                        y: station.px(66)

                        Rectangle {
                            color: "#5e5e5e"
                            height: Math.max(1, station.px(1))
                            width: parent.width
                        }
                    }
                    MailText {
                        anchors.baseline: parent.top
                        anchors.baselineOffset: station.px(48)
                        text: "Sender"
                        x: station.px(96)
                    }
                    MailText {
                        anchors.baseline: parent.top
                        anchors.baselineOffset: station.px(48)
                        text: "Subject"
                        x: station.px(774)
                    }
                    Rectangle {
                        color: "#414141"
                        height: parent.height
                        width: station.px(6)
                        x: station.px(644)
                    }
                    Rectangle {
                        color: "#c8c8c8"
                        height: parent.height
                        width: station.px(7)
                        x: station.px(651)
                    }
                }
                Repeater {
                    model: 13

                    Rectangle {
                        required property int index

                        color: index % 2 ? "#b0b0b0" : "#858585"
                        height: station.rowH
                        width: list.width
                        y: list.y + index * station.rowH
                    }
                }
                ListView {
                    id: list

                    boundsBehavior: Flickable.StopAtBounds
                    clip: true
                    currentIndex: station.index
                    height: station.rowH * 13
                    highlightMoveDuration: 0
                    model: station.listMails
                    width: parent.width - station.px(143)
                    y: station.px(71)

                    delegate: Rectangle {
                        id: row

                        required property int index
                        required property var modelData
                        readonly property bool unread: !modelData.clip && station.service ? !station.service.readIds[modelData.id] : false

                        color: index % 2 ? "#b0b0b0" : "#858585"
                        height: station.rowH
                        width: list.width

                        MailText {
                            anchors.verticalCenter: parent.verticalCenter
                            elide: Text.ElideRight
                            text: row.modelData.appName || "Unknown"
                            width: station.px(540)
                            x: station.px(96)
                        }
                        NewBadge {
                            anchors.verticalCenter: parent.verticalCenter
                            fontFamily: station.textFont
                            size: station.px(26)
                            visible: row.unread
                            x: station.px(700)
                        }
                        MailText {
                            anchors.verticalCenter: parent.verticalCenter
                            elide: Text.ElideRight
                            text: row.modelData.summary
                            textFormat: Text.PlainText
                            width: list.width - x - station.px(24)
                            x: station.px(774)
                        }
                        Rectangle {
                            border.color: "#78b9d1"
                            border.width: Math.max(2, station.px(3))
                            color: "transparent"
                            height: parent.height - station.px(4)
                            visible: station.mode === "list" && row.index === station.index
                            width: parent.width - x - station.px(1)
                            x: station.px(92)
                            y: station.px(2)
                        }
                        MouseArea {
                            anchors.fill: parent
                            enabled: station.mode === "list"

                            onClicked: station.index = row.index
                            onDoubleClicked: station.openMail(row.index)
                        }
                    }

                    onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)
                }
                Repeater {
                    model: Math.floor(list.height / station.px(8.6))

                    Rectangle {
                        required property int index

                        color: "black"
                        height: width
                        width: Math.max(2, station.px(4))
                        x: station.px(645)
                        y: list.y + station.px(3) + index * station.px(8.6)
                    }
                }
                ScrollBar {
                    flick: list
                    height: list.height
                    y: list.y
                }
            }
            Item {
                id: clipView

                height: station.pageH
                opacity: station.clipFolder && (station.mode === "list" || station.mode === "folders") ? 1 : 0
                visible: opacity > 0
                width: parent.width

                Behavior on opacity {
                    NumberAnimation {
                        duration: 120
                    }
                }

                Rectangle {
                    color: "#b1b1b1"
                    height: station.px(74)
                    width: parent.width
                    y: station.px(1)

                    Rectangle {
                        color: "#484848"
                        height: station.px(7)
                        width: parent.width
                        y: station.px(66)
                    }
                    MailText {
                        anchors.baseline: parent.top
                        anchors.baselineOffset: station.px(49)
                        text: "Type"
                        x: station.px(373) - width / 2
                    }
                    MailText {
                        anchors.baseline: parent.top
                        anchors.baselineOffset: station.px(49)
                        text: "Preview"
                        x: station.px(1310) - width / 2
                    }
                    Rectangle {
                        color: "#464646"
                        height: station.px(66)
                        width: station.px(6)
                        x: station.px(705)
                    }
                    Rectangle {
                        color: "#cccccc"
                        height: station.px(66)
                        width: station.px(6)
                        x: station.px(712)
                    }
                }
                Repeater {
                    model: 13

                    Rectangle {
                        required property int index

                        color: index % 2 ? "#787878" : "#b8b8ba"
                        height: clipList.rowH
                        width: clipList.width
                        y: clipList.y + index * clipList.rowH
                    }
                }
                ListView {
                    id: clipList

                    readonly property real rowH: station.px(59.07)

                    boundsBehavior: Flickable.StopAtBounds
                    clip: true
                    currentIndex: station.clipFolder ? station.index : -1
                    height: rowH * 13
                    highlightMoveDuration: 0
                    model: station.clipFolder ? station.listMails : []
                    width: station.px(705)
                    y: station.px(76)

                    delegate: Rectangle {
                        id: clipRow

                        required property int index
                        required property var modelData

                        color: index % 2 ? "#787878" : "#b8b8ba"
                        height: clipList.rowH
                        width: clipList.width

                        MailText {
                            anchors.verticalCenter: parent.verticalCenter
                            elide: Text.ElideRight
                            text: clipRow.modelData.ext ? clipRow.modelData.appName : "Text: '" + (clipRow.modelData.summary.length > 15 ? clipRow.modelData.summary.slice(0, 15) + "..." : clipRow.modelData.summary) + "'"
                            textFormat: Text.PlainText
                            width: station.px(510)
                            x: station.px(96)
                        }
                        Rectangle {
                            border.color: "#78b9d1"
                            border.width: Math.max(2, station.px(3))
                            color: "transparent"
                            height: parent.height - station.px(4)
                            visible: station.mode === "list" && clipRow.index === station.index
                            width: parent.width - x - station.px(1)
                            x: station.px(92)
                            y: station.px(2)
                        }
                        MouseArea {
                            anchors.fill: parent
                            enabled: station.mode === "list"

                            onClicked: station.index = clipRow.index
                            onDoubleClicked: station.copyClip(clipRow.index)
                        }
                    }

                    onCurrentIndexChanged: if (currentIndex >= 0)
                        positionViewAtIndex(currentIndex, ListView.Contain)
                }
                Repeater {
                    model: Math.floor(clipList.height / station.px(8.6))

                    Rectangle {
                        required property int index

                        color: "black"
                        height: width
                        width: Math.max(2, station.px(4))
                        x: station.px(615)
                        y: clipList.y + station.px(3) + index * station.px(8.6)
                    }
                }
                Rectangle {
                    height: parent.height - y
                    width: station.px(6)
                    x: station.px(705)
                    y: clipList.y

                    gradient: Gradient {
                        orientation: Gradient.Horizontal

                        GradientStop {
                            color: "#9b9b9d"
                            position: 0
                        }
                        GradientStop {
                            color: "#5b5b5e"
                            position: 0.6
                        }
                        GradientStop {
                            color: "#717172"
                            position: 1
                        }
                    }
                }
                Rectangle {
                    id: previewPane

                    readonly property var entry: station.clipFolder ? station.listMails[station.index] || null : null
                    readonly property bool loaded: !!entry && !!station.clipboard && station.clipboard.isCurrent(entry)

                    clip: true
                    color: "#787878"
                    height: parent.height - y
                    width: parent.width - x
                    x: station.px(711)
                    y: clipList.y

                    Image {
                        anchors.verticalCenter: parent.verticalCenter
                        asynchronous: true
                        fillMode: Image.PreserveAspectFit
                        height: implicitWidth > 0 ? width * implicitHeight / implicitWidth : 0
                        mipmap: true
                        source: previewPane.loaded && previewPane.entry.ext ? station.clipboard.currentImage : ""
                        visible: source.toString() !== ""
                        width: parent.width
                    }
                    MailText {
                        clip: true
                        color: "#101010"
                        height: parent.height - y - station.px(36)
                        lineHeight: station.px(48)
                        lineHeightMode: Text.FixedHeight
                        text: previewPane.loaded && !previewPane.entry.ext ? station.clipboard.currentText : ""
                        textFormat: Text.PlainText
                        visible: text !== ""
                        width: parent.width - station.px(80)
                        wrapMode: Text.WrapAnywhere
                        x: station.px(40)
                        y: station.px(30)
                    }
                }
            }
            Item {
                id: readerView

                height: station.pageH
                opacity: station.mode === "read" ? 1 : 0
                visible: opacity > 0
                width: parent.width

                Behavior on opacity {
                    NumberAnimation {
                        duration: 200
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    color: "#b5b5b5"
                }
                Flickable {
                    id: reader

                    boundsBehavior: Flickable.StopAtBounds
                    clip: true
                    contentHeight: body.y + body.height + station.px(48)
                    height: parent.height
                    width: parent.width - station.px(140)

                    Rectangle {
                        border.color: "#8a8a8a"
                        border.width: Math.max(1, station.px(2))
                        color: "white"
                        height: width
                        width: station.px(224)
                        x: station.px(152)
                        y: station.px(15)

                        Image {
                            id: logo

                            anchors.fill: parent
                            anchors.margins: station.px(30)
                            fillMode: Image.PreserveAspectFit
                            mipmap: true
                            source: station.reading && station.service ? station.service.pictureFor(station.reading) : ""
                            sourceSize: Qt.size(256, 256)
                        }
                        MailText {
                            anchors.centerIn: parent
                            color: "#6e6e6e"
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignHCenter
                            text: station.reading ? station.reading.appName : ""
                            visible: logo.status !== Image.Ready
                            width: parent.width - station.px(20)
                        }
                    }
                    MailText {
                        anchors.baseline: parent.top
                        anchors.baselineOffset: station.px(85)
                        elide: Text.ElideRight
                        text: "Sender: " + (station.reading ? station.reading.appName || "Unknown" : "")
                        width: reader.width - x - station.px(40)
                        x: station.px(438)
                    }
                    MailText {
                        anchors.baseline: parent.top
                        anchors.baselineOffset: station.px(131)
                        elide: Text.ElideRight
                        text: "Subject: " + (station.reading ? station.reading.summary : "")
                        textFormat: Text.PlainText
                        width: reader.width - x - station.px(40)
                        x: station.px(438)
                    }
                    Flow {
                        spacing: station.px(14)
                        width: reader.width - x - station.px(40)
                        x: station.px(438)
                        y: station.px(170)

                        Repeater {
                            model: station.reading ? station.reading.actions : []

                            Rectangle {
                                required property int index
                                required property var modelData

                                border.color: actionHover.hovered ? "#16699a" : "#3c3c3c"
                                border.width: Math.max(1, station.px(3))
                                color: actionHover.hovered ? "#bfe1f3" : "#a9a9a9"
                                height: station.px(46)
                                radius: height / 2
                                width: actionText.implicitWidth + station.px(56)

                                MailText {
                                    id: actionText

                                    anchors.centerIn: parent
                                    font.pixelSize: station.px(30)
                                    text: (index < 9 ? (index + 1) + ". " : "") + (modelData.text || "Open")
                                }
                                HoverHandler {
                                    id: actionHover

                                    cursorShape: Qt.PointingHandCursor
                                }
                                MouseArea {
                                    anchors.fill: parent

                                    onClicked: modelData.invoke()
                                }
                            }
                        }
                    }
                    Rectangle {
                        height: Math.max(2, station.px(3))
                        width: station.px(1190)
                        x: station.px(152)
                        y: station.px(277)

                        gradient: Gradient {
                            orientation: Gradient.Horizontal

                            GradientStop {
                                color: "#8c8c8c"
                                position: 0
                            }
                            GradientStop {
                                color: "#a0a0a0"
                                position: 0.6
                            }
                            GradientStop {
                                color: "#00b5b5b5"
                                position: 1
                            }
                        }
                    }
                    MailText {
                        id: body

                        lineHeight: station.px(48)
                        lineHeightMode: Text.FixedHeight
                        linkColor: "#16699a"
                        text: station.reading ? station.reading.body : ""
                        textFormat: Text.StyledText
                        width: reader.width - x - station.px(60)
                        wrapMode: Text.Wrap
                        x: station.px(152)
                        y: station.px(290)

                        onLinkActivated: link => Qt.openUrlExternally(link)
                    }
                }
                ScrollBar {
                    flick: reader
                    height: station.pageH
                }
            }
            Item {
                id: loading

                readonly property real band: station.px(372) * (1 - station.ease(station.loadP))

                height: station.pageH
                opacity: station.mode === "loading" ? 1 : 0
                visible: opacity > 0
                width: parent.width

                Behavior on opacity {
                    NumberAnimation {
                        duration: 200
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    color: "#b3b3b3"
                }
                Rectangle {
                    color: "#707070"
                    height: loading.band
                    width: parent.width
                }
                Rectangle {
                    color: "#707070"
                    height: loading.band
                    width: parent.width
                    y: parent.height - height
                }
                Rectangle {
                    id: pill

                    border.color: "#565656"
                    border.width: Math.max(2, station.px(3))
                    color: "#b3b3b3"
                    height: station.px(50)
                    radius: station.px(14)
                    width: parent.width - station.px(492)
                    x: station.px(246)
                    y: station.px(403)

                    MailText {
                        anchors.verticalCenter: parent.verticalCenter
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                        text: station.reading ? station.reading.summary : ""
                        textFormat: Text.PlainText
                        width: track.x - station.px(40)
                        x: station.px(20)
                    }
                    Rectangle {
                        id: track

                        anchors.verticalCenter: parent.verticalCenter
                        border.color: "#8a8a8a"
                        border.width: 1
                        color: "#c4c4c4"
                        height: station.px(18)
                        width: station.px(432)
                        x: parent.width - width - station.px(28)

                        Rectangle {
                            anchors.right: parent.right
                            anchors.rightMargin: station.px(2)
                            anchors.verticalCenter: parent.verticalCenter
                            color: "#6e6e6e"
                            height: parent.height - station.px(6)
                            width: (parent.width - station.px(4)) * (1 - station.loadP)
                        }
                    }
                }
            }
            Rectangle {
                anchors.fill: parent
                color: "black"
                opacity: 0.55 * (1 - station.fadeP)
            }
        }
    }
    Item {
        id: header

        height: station.headerH
        width: parent.width
        y: station.meet * (station.px(550) - height)
        z: 1

        Rectangle {
            anchors.fill: parent

            gradient: Gradient {
                GradientStop {
                    color: "#b9babd"
                    position: 0
                }
                GradientStop {
                    color: "#c9cacd"
                    position: 1
                }
            }
        }
        Rectangle {
            color: "#848484"
            height: Math.max(2, station.px(3))
            width: parent.width
            y: parent.height - station.px(3)
        }
        Text {
            anchors.baseline: parent.top
            anchors.baselineOffset: station.px(110)
            color: "black"
            font.family: station.textFont
            font.pixelSize: station.px(62)
            font.weight: Font.DemiBold
            text: "Mail Station"
            x: station.px(96)
        }
        Spinner {
            opacity: 1 - station.clamp((station.listP - 0.4) / 0.15, 0, 1)
            x: station.px(383) - width / 2
            y: station.px(173) - height / 2
        }
        Spinner {
            opacity: station.clamp((station.listP - 0.7) / 0.3, 0, 1)
            x: parent.width * 0.393 - width / 2
            y: station.px(57) - height / 2
        }
        Item {
            id: folderRow

            height: parent.height
            opacity: 1 - station.fadeP
            visible: opacity > 0
            width: parent.width

            Repeater {
                model: station.folders

                FolderBox {
                    required property int index
                    required property var modelData

                    icon: modelData.icon
                    selected: index === station.folder
                    unread: index === 0 && station.service ? station.service.unreadCount > 0 : false
                    x: station.px(781 + index * 179.5) - width / 2
                    y: station.px(80)

                    onClicked: station.folder = index
                    onDoubleClicked: {
                        station.folder = index;
                        station.enterFolder();
                    }
                }
            }
            Canvas {
                height: station.px(20)
                width: station.px(32)
                x: station.px(781 + station.folder * 179.5) - width / 2
                y: station.px(42)

                onHeightChanged: requestPaint()
                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();
                    ctx.fillStyle = "#1c6ab9";
                    ctx.beginPath();
                    ctx.moveTo(0, 0);
                    ctx.lineTo(width, 0);
                    ctx.lineTo(width / 2, height);
                    ctx.closePath();
                    ctx.fill();
                }
            }
            Rectangle {
                border.color: "black"
                border.width: Math.max(2, station.px(3))
                color: "#8e908d"
                height: station.px(54)
                radius: height / 2
                width: station.px(366)
                x: station.px(1270)
                y: station.px(88)

                MailText {
                    anchors.centerIn: parent
                    font.pixelSize: station.px(34)
                    text: station.folders[station.folder].text
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor

                    onClicked: station.enterFolder()
                }
            }
        }
        Item {
            id: brand

            height: station.px(121)
            width: parent.width
            y: parent.height - station.px(121)

            Text {
                anchors.baseline: parent.top
                anchors.baselineOffset: station.px(80)
                color: "black"
                font.capitalization: Font.SmallCaps
                font.family: station.hud.fontName
                font.pixelSize: station.px(44)
                font.variableAxes: station.hud.fontAxes
                font.weight: Font.Medium
                text: "Mine OS"
                x: parent.width - station.px(372) - width
            }
            Text {
                anchors.baseline: parent.top
                anchors.baselineOffset: station.px(104)
                color: "black"
                font.family: station.hud.fontName
                font.pixelSize: station.px(22)
                text: "©2016-2017 Mine All rights reserved."
                x: parent.width - station.px(364) - width
            }
            Repeater {
                model: [[1590.5, 88, 29], [1615.5, 75.5, 18], [1630.5, 85, 8.5], [1633.5, 94.5, 4]]

                Rectangle {
                    required property var modelData

                    color: "black"
                    height: width
                    radius: width / 2
                    width: station.px(modelData[2])
                    x: brand.width - station.px(1920 - modelData[0]) - width / 2
                    y: station.px(modelData[1]) - height / 2
                }
            }
        }
    }
    Item {
        id: footer

        height: station.px(115)
        width: parent.width
        y: station.px(965) - station.meet * station.px(437)

        Rectangle {
            anchors.fill: parent
            color: "#bdbcbf"
        }
        Rectangle {
            color: "#cfcfcf"
            height: station.px(7)
            width: parent.width
            y: station.px(1)
        }
        Rectangle {
            height: station.px(14)
            width: parent.width
            y: parent.height - height

            gradient: Gradient {
                GradientStop {
                    color: "#b9b9b9"
                    position: 0
                }
                GradientStop {
                    color: "#a6a8a8"
                    position: 1
                }
            }
        }
        Canvas {
            height: station.px(22)
            width: station.px(20)
            x: station.px(36)
            y: station.px(32)

            onHeightChanged: requestPaint()
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                ctx.fillStyle = "#22a51e";
                ctx.beginPath();
                ctx.moveTo(0, 0);
                ctx.lineTo(width, height / 2);
                ctx.lineTo(0, height);
                ctx.closePath();
                ctx.fill();
            }
        }
        Row {
            spacing: station.px(28)
            x: station.px(98)
            y: station.px(45) - height / 2 - station.px(4)

            Repeater {
                model: station.hints

                Row {
                    required property var modelData

                    spacing: station.px(8)

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        border.color: (station.hud.keyTones[modelData.tone] || station.hud.keyTones.gray)[1]
                        border.width: Math.max(1, height * 0.08)
                        color: (station.hud.keyTones[modelData.tone] || station.hud.keyTones.gray)[0]
                        height: station.px(42)
                        radius: height / 2
                        visible: !!modelData.key
                        width: Math.max(height, keyLabel.implicitWidth + height * 0.5)

                        Text {
                            id: keyLabel

                            anchors.centerIn: parent
                            color: "white"
                            font.family: station.textFont
                            font.pixelSize: parent.height * 0.55
                            font.weight: Font.Bold
                            text: modelData.key || ""
                        }
                    }
                    MailText {
                        anchors.verticalCenter: parent.verticalCenter
                        font.pixelSize: station.px(34)
                        text: modelData.text
                    }
                }
            }
        }
    }

    component FolderBox: Rectangle {
        id: box

        property string icon
        property bool selected
        property bool unread

        signal clicked
        signal doubleClicked

        border.color: selected ? "#2a7bc8" : "black"
        border.width: Math.max(2, station.px(3))
        height: station.px(90)
        width: station.px(103)

        gradient: Gradient {
            orientation: Gradient.Horizontal

            GradientStop {
                color: box.selected ? "#e1f4ff" : "#fbfbfb"
                position: 0
            }
            GradientStop {
                color: box.selected ? "#adc7d1" : "#a7a7a7"
                position: 1
            }
        }

        Image {
            anchors.fill: parent
            anchors.margins: station.px(10)
            fillMode: Image.PreserveAspectFit
            mipmap: true
            source: Qt.resolvedUrl("assets/" + box.icon)
            sourceSize: Qt.size(128, 128)
        }
        NewBadge {
            fontFamily: station.textFont
            size: station.px(26)
            visible: box.unread
            x: -station.px(26)
            y: -station.px(14)
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor

            onClicked: box.clicked()
            onDoubleClicked: box.doubleClicked()
        }
    }
    component MailText: Text {
        color: "#101010"
        font.family: station.textFont
        font.pixelSize: station.px(40)
        font.weight: Font.Medium
    }
    component ScrollBar: Item {
        required property Flickable flick

        width: parent.width

        Rectangle {
            color: "#6e6e6e"
            height: parent.height
            width: station.px(100)
            x: parent.width - width
        }
        Rectangle {
            border.color: "#6f6f6f"
            border.width: 1
            color: "#555555"
            height: parent.height
            width: station.px(41)
            x: parent.width - station.px(141)

            Repeater {
                model: [0, 1]

                Rectangle {
                    required property int modelData

                    color: "#b8b8b8"
                    height: station.px(26)
                    width: parent.width - station.px(4)
                    x: station.px(2)
                    y: modelData ? parent.height - height - station.px(2) : station.px(2)

                    Text {
                        anchors.centerIn: parent
                        color: "#343434"
                        font.pixelSize: station.px(22)
                        text: parent.modelData ? "▼" : "▲"
                    }
                }
            }
            Rectangle {
                readonly property real room: parent.height - station.px(60)

                height: Math.max(station.px(30), room * Math.min(1, flick.visibleArea.heightRatio))
                width: parent.width - station.px(6)
                x: station.px(3)
                y: station.px(30) + Math.max(0, flick.visibleArea.yPosition) * room

                gradient: Gradient {
                    orientation: Gradient.Horizontal

                    GradientStop {
                        color: "#c0c0c0"
                        position: 0
                    }
                    GradientStop {
                        color: "#b4b4b4"
                        position: 0.5
                    }
                    GradientStop {
                        color: "#808080"
                        position: 1
                    }
                }
            }
        }
    }
    component Spinner: Item {
        height: width
        width: station.px(108)

        Item {
            anchors.fill: parent

            RotationAnimation on rotation {
                duration: 8000
                from: 0
                loops: Animation.Infinite
                running: station.visible
                to: 360
            }

            Repeater {
                model: 30

                Item {
                    required property int index

                    anchors.fill: parent
                    rotation: index * 12

                    Rectangle {
                        antialiasing: true
                        color: parent.index % 3 ? "#2d5fb8" : "#8fb2e6"
                        height: station.px(15)
                        radius: width / 3
                        width: station.px(6)
                        x: (parent.width - width) / 2
                        y: station.px(3)
                    }
                }
            }
        }
        Image {
            anchors.centerIn: parent
            fillMode: Image.PreserveAspectFit
            height: width
            mipmap: true
            source: Qt.resolvedUrl("assets/mail2.png")
            sourceSize: Qt.size(128, 128)
            width: station.px(60)
        }
    }
}
