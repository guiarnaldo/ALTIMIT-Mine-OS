import QtQuick

Item {
    id: opts

    property real anchorX: width * 0.3
    property bool animateSheet: false
    readonly property var available: [
        {
            key: "wifi",
            title: "Wi-Fi",
            source: "WifiOptions.qml"
        },
        {
            key: "bluetooth",
            title: "Bluetooth",
            source: "BluetoothOptions.qml"
        },
        {
            key: "background",
            title: "Background",
            source: "BackgroundOptions.qml"
        }
    ]
    readonly property real boxSize: colW * 0.4
    readonly property var categories: {
        void loaderRepeater.count;
        void loadedCount;
        const out = [];
        for (let i = 0; i < enabledDefs.length; i++) {
            const loader = loaderRepeater.itemAt(i);
            out.push(loader && loader.item ? loader.item : unavailable(enabledDefs[i]));
        }
        return out;
    }
    readonly property var category: categories[categoryIndex] || null
    property int categoryIndex: 0
    readonly property real col1X: anchorX - colW / 2
    readonly property real colW: height * 0.22
    readonly property var cssEase: [0.25, 0.1, 0.25, 1.0, 1.0, 1.0]
    property var enabledCategories: ["wifi", "bluetooth", "background"]
    readonly property var enabledDefs: available.filter(d => enabledCategories.indexOf(d.key) >= 0)
    readonly property var entries: category ? category.entries : []
    readonly property var entry: entries[entryIndex] || null
    property int entryIndex: 0
    readonly property var hints: {
        if (passwordRequest)
            return [
                {
                    text: "Enter the network password."
                },
                {
                    key: "↵",
                    tone: "green",
                    text: ": Connect"
                },
                {
                    key: "Esc",
                    tone: "gray",
                    text: ": Cancel"
                }
            ];
        const back = {
            key: "Esc",
            tone: "gray",
            text: level === 0 ? ": Return" : ": Back"
        };
        if (level === 2 && category)
            return category.panelHints(itemIndex);
        if (level === 1 && entry)
            return [
                {
                    text: entry.hint
                },
                {
                    key: "↵",
                    tone: "green",
                    text: ": Select"
                },
                back];
        return [
            {
                text: category ? category.hint : ""
            },
            {
                key: "↵",
                tone: "green",
                text: ": Select"
            },
            back];
    }
    required property var hud
    property int itemIndex: 0
    property string itemKey: ""
    readonly property var items: category ? category.items : []
    property int level: 0
    property int loadedCount: 0
    property bool open: false
    readonly property var passwordRequest: category && category.passwordRequest ? category.passwordRequest : null
    readonly property var preview: level === 2 && category ? category.preview(itemIndex) : ({
            image: "",
            number: "",
            title: "",
            lines: []
        })
    readonly property var tabs: level === 2 && category && category.tabs ? category.tabs : []

    function back() {
        if (level === 0)
            hide();
        else
            level -= 1;
    }
    function clamp(v, lo, hi) {
        return Math.max(lo, Math.min(hi, v));
    }
    function enter() {
        if (level === 0) {
            if (entries.length > 0)
                level = 1;
        } else if (level === 1) {
            if (category.activate(entryIndex)) {
                itemIndex = category.initialIndex !== undefined ? category.initialIndex : 0;
                level = 2;
            }
        } else {
            category.itemAction(itemIndex, "confirm");
        }
    }
    function handleKey(event) {
        if (passwordRequest) {
            password.handleKey(event);
            return;
        }
        if (tabs.length > 0) {
            if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab) {
                switchTab(-1);
                return;
            }
            if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab) {
                switchTab(1);
                return;
            }
        }
        switch (event.key) {
        case Qt.Key_Up:
            move(-1);
            break;
        case Qt.Key_Down:
            move(1);
            break;
        case Qt.Key_Right:
            if (level < 2)
                enter();
            break;
        case Qt.Key_Left:
        case Qt.Key_Escape:
        case Qt.Key_Backspace:
            back();
            break;
        case Qt.Key_Return:
        case Qt.Key_Enter:
            enter();
            break;
        case Qt.Key_Space:
            if (level === 2)
                category.itemAction(itemIndex, "check");
            else
                enter();
            break;
        case Qt.Key_Delete:
        case Qt.Key_F:
            if (level === 2)
                category.itemAction(itemIndex, "forget");
            break;
        case Qt.Key_S:
            if (level === 2)
                category.itemAction(itemIndex, "scan");
            break;
        case Qt.Key_R:
            if (level === 2)
                category.itemAction(itemIndex, "random");
            break;
        }
    }
    function hide() {
        if (category)
            category.close();
        animateSheet = visible;
        open = false;
        if (!visible || height === 0)
            visible = false;
        level = 0;
    }
    function move(delta) {
        if (level === 0)
            categoryIndex = clamp(categoryIndex + delta, 0, categories.length - 1);
        else if (level === 1)
            entryIndex = clamp(entryIndex + delta, 0, entries.length - 1);
        else
            itemIndex = clamp(itemIndex + delta, 0, Math.max(items.length - 1, 0));
    }
    function show(startLevel, key) {
        if (categories.length === 0)
            return;
        level = 0;
        entryIndex = 0;
        itemIndex = 0;
        if (key) {
            const i = categories.findIndex(c => c.key === key);
            if (i < 0)
                return;
            categoryIndex = i;
        }
        visible = true;
        animateSheet = true;
        open = true;
        if (startLevel >= 1)
            enter();
    }
    function switchTab(delta) {
        category.setTab(category.tabIndex + delta);
        itemIndex = category.initialIndex !== undefined ? category.initialIndex : itemIndex;
    }
    function unavailable(def) {
        return {
            key: def.key,
            title: def.title,
            icon: "accessories2.png",
            description: "This option needs a Quickshell\nmodule that is not installed.",
            hint: def.title + " is unavailable.",
            panelTitle: def.title,
            listTitle: "",
            entries: [],
            items: [],
            activate: () => false,
            preview: () => ({
                        image: "",
                        number: "",
                        title: "",
                        lines: []
                    }),
            itemAction: () => {},
            panelHints: () => [],
            close: () => {}
        };
    }

    visible: false

    onCategoriesChanged: if (categoryIndex >= categories.length)
        categoryIndex = Math.max(0, categories.length - 1)
    onItemIndexChanged: itemKey = items[itemIndex] ? items[itemIndex].label : ""
    onItemsChanged: {
        const i = items.findIndex(it => it.label === itemKey);
        itemIndex = i >= 0 ? i : Math.min(itemIndex, Math.max(0, items.length - 1));
    }

    Repeater {
        id: loaderRepeater

        model: opts.enabledDefs

        Loader {
            required property var modelData

            source: modelData.source

            onLoaded: {
                item.hud = opts.hud;
                opts.loadedCount++;
            }
        }
    }
    Item {
        id: sheet

        height: parent.height
        width: parent.width
        y: opts.open ? 0 : opts.height

        Behavior on y {
            enabled: opts.animateSheet

            Slide {
                onRunningChanged: if (!running && !opts.open)
                    opts.visible = false
            }
        }

        Rectangle {
            id: panel

            readonly property bool expanded: opts.level === 2

            border.color: "#99999a"
            border.width: Math.max(3, opts.height * 0.005)
            clip: true
            color: "#7e858c"
            height: parent.height
            width: expanded ? opts.colW * 3 : opts.colW
            x: expanded ? opts.col1X + opts.colW : opts.col1X

            Behavior on width {
                Slide {
                }
            }
            Behavior on x {
                Slide {
                }
            }

            Item {
                id: panelContent

                readonly property real pad: u * 1.8
                readonly property real u: opts.height / 100

                height: parent.height
                opacity: panel.expanded ? 1 : 0
                width: opts.colW * 3

                Behavior on opacity {
                    NumberAnimation {
                        duration: 250
                    }
                }

                Rectangle {
                    id: header

                    color: "#525d66"
                    height: panelContent.u * 8
                    width: parent.width

                    Row {
                        spacing: panelContent.u * 1.2
                        x: panelContent.pad
                        y: panelContent.u * 1.2

                        Text {
                            anchors.baseline: headerTitle.baseline
                            color: "white"
                            font.family: opts.hud.fontName
                            font.pixelSize: panelContent.u * 3
                            font.variableAxes: opts.hud.fontAxes
                            font.weight: Font.Medium
                            text: "Accessories"
                        }
                        Text {
                            id: headerTitle

                            color: "white"
                            font.family: opts.hud.fontName
                            font.pixelSize: panelContent.u * 4.2
                            font.variableAxes: opts.hud.fontAxes
                            font.weight: Font.Medium
                            text: opts.category ? opts.category.panelTitle : ""
                        }
                    }
                    Row {
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: panelContent.u * 0.6
                        anchors.right: parent.right
                        anchors.rightMargin: panelContent.pad
                        spacing: panelContent.u * 0.8

                        Text {
                            anchors.baseline: mineLabel.baseline
                            color: "white"
                            font.family: opts.hud.fontName
                            font.pixelSize: panelContent.u * 1.1
                            text: "©2016-2017 Mine All rights reserved."
                        }
                        Text {
                            id: mineLabel

                            color: "white"
                            font.family: opts.hud.fontName
                            font.pixelSize: panelContent.u * 1.7
                            font.variableAxes: opts.hud.fontAxes
                            font.weight: Font.Medium
                            text: "MINE OS"
                        }
                    }
                }
                Item {
                    id: previewArea

                    height: panelContent.u * 16.5
                    width: parent.width
                    y: header.height

                    Rectangle {
                        id: frame

                        border.color: "white"
                        border.width: Math.max(2, panelContent.u * 0.4)
                        color: "#dfe6ec"
                        height: panelContent.u * 14
                        width: panelContent.u * 19
                        x: panelContent.pad
                        y: panelContent.u * 1.2

                        Image {
                            anchors.fill: parent
                            anchors.margins: opts.preview.fill ? parent.border.width : parent.height * 0.14
                            asynchronous: true
                            clip: true
                            fillMode: opts.preview.fill ? Image.PreserveAspectCrop : Image.PreserveAspectFit
                            smooth: true
                            source: opts.hud.asset(opts.preview.image)
                            sourceSize: Qt.size(320, 320)
                        }
                    }
                    Column {
                        anchors.left: frame.right
                        anchors.leftMargin: panelContent.u * 0.8
                        spacing: panelContent.u * 0.5
                        y: frame.y

                        Text {
                            color: "white"
                            font.family: opts.hud.fontName
                            font.pixelSize: panelContent.u * 2.2
                            text: opts.preview.number
                        }
                        Text {
                            color: "white"
                            elide: Text.ElideRight
                            font.family: opts.hud.fontName
                            font.pixelSize: panelContent.u * 2.6
                            font.variableAxes: opts.hud.fontAxes
                            text: opts.preview.title
                            width: previewArea.width - frame.width - panelContent.pad * 2 - panelContent.u
                        }
                        Repeater {
                            model: opts.preview.lines

                            Text {
                                required property string modelData

                                color: "#d6e9f5"
                                font.family: opts.hud.fontName
                                font.pixelSize: panelContent.u * 1.8
                                text: modelData
                            }
                        }
                    }
                }
                Row {
                    id: tabStrip

                    anchors.right: parent.right
                    anchors.rightMargin: panelContent.pad
                    height: panelContent.u * 3
                    spacing: -panelContent.u * 0.6
                    visible: opts.tabs.length > 0
                    y: previewArea.y + previewArea.height - height

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        color: "#2f8fcf"
                        font.pixelSize: panelContent.u * 2
                        rightPadding: panelContent.u
                        text: "◀"

                        TapHandler {
                            onTapped: opts.switchTab(-1)
                        }
                    }
                    Repeater {
                        model: opts.tabs

                        Rectangle {
                            readonly property bool active: opts.category && index === opts.category.tabIndex
                            required property int index
                            required property string modelData

                            border.color: "#99999a"
                            border.width: Math.max(1, panelContent.u * 0.2)
                            color: active ? "#c8cacc" : "#7e858c"
                            height: tabStrip.height
                            radius: panelContent.u * 0.6
                            width: panelContent.u * 6.2
                            z: active ? 1 : 0

                            Rectangle {
                                anchors.bottom: parent.bottom
                                color: parent.color
                                height: parent.radius
                                width: parent.width
                            }
                            Text {
                                anchors.centerIn: parent
                                color: active ? "#7e858c" : "#c8cacc"
                                font.family: opts.hud.fontName
                                font.pixelSize: panelContent.u * 2.3
                                font.variableAxes: opts.hud.fontAxes
                                font.weight: Font.Medium
                                text: ("0" + (index + 1)).slice(-2)
                            }
                            TapHandler {
                                onTapped: opts.switchTab(index - opts.category.tabIndex)
                            }
                        }
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        color: "#2f8fcf"
                        font.pixelSize: panelContent.u * 2
                        leftPadding: panelContent.u
                        text: "▶"

                        TapHandler {
                            onTapped: opts.switchTab(1)
                        }
                    }
                }
                Rectangle {
                    id: listHeader

                    color: "#525d66"
                    height: panelContent.u * 3.4
                    width: parent.width
                    y: previewArea.y + previewArea.height

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        color: "white"
                        font.family: opts.hud.fontName
                        font.pixelSize: panelContent.u * 2.6
                        font.variableAxes: opts.hud.fontAxes
                        font.weight: Font.Medium
                        text: opts.category ? opts.category.listTitle : ""
                        x: panelContent.pad
                    }
                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: panelContent.pad
                        anchors.verticalCenter: parent.verticalCenter
                        color: "white"
                        font.family: opts.hud.fontName
                        font.pixelSize: panelContent.u * 2
                        text: opts.items.length > 0 ? (opts.itemIndex + 1) + "/" + opts.items.length : "0/0"
                    }
                }
                ListView {
                    id: list

                    readonly property real rowH: panelContent.u * 3.3

                    boundsBehavior: Flickable.StopAtBounds
                    clip: true
                    currentIndex: opts.itemIndex
                    height: opts.height * 0.88 - y
                    highlightMoveDuration: 0
                    model: opts.items
                    width: parent.width - panelContent.pad * 2 - scrollTrack.width - panelContent.u
                    x: panelContent.pad
                    y: listHeader.y + listHeader.height + panelContent.u * 0.8

                    delegate: Item {
                        id: row

                        required property int index
                        required property var modelData

                        height: list.rowH
                        width: list.width

                        Rectangle {
                            id: check

                            anchors.verticalCenter: parent.verticalCenter
                            border.color: "#9a9a9a"
                            border.width: 1
                            color: "#d9d9d9"
                            height: width
                            width: list.rowH * 0.72

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: parent.width * 0.22
                                color: "#2f8fcf"
                                visible: row.modelData.checked
                            }
                            TapHandler {
                                onTapped: {
                                    opts.itemIndex = row.index;
                                    opts.category.itemAction(row.index, "check");
                                }
                            }
                        }
                        Rectangle {
                            anchors.left: check.right
                            anchors.leftMargin: list.rowH * 0.15
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            color: row.index === opts.itemIndex ? "#5ea6cd" : "transparent"
                            height: list.rowH * 0.82

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                color: "white"
                                elide: Text.ElideRight
                                font.family: opts.hud.fontName
                                font.pixelSize: list.rowH * 0.55
                                text: ("00" + row.index).slice(-3) + " " + row.modelData.label
                                width: parent.width - statusText.width - list.rowH * 0.5
                                x: list.rowH * 0.15
                            }
                            Text {
                                id: statusText

                                anchors.right: parent.right
                                anchors.rightMargin: list.rowH * 0.2
                                anchors.verticalCenter: parent.verticalCenter
                                color: "#d6e9f5"
                                font.family: opts.hud.fontName
                                font.pixelSize: list.rowH * 0.42
                                text: row.modelData.status
                            }
                            TapHandler {
                                onDoubleTapped: opts.category.itemAction(row.index, "confirm")
                                onTapped: opts.itemIndex = row.index
                            }
                        }
                    }

                    onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                    Text {
                        anchors.centerIn: parent
                        color: "#d6e9f5"
                        font.family: opts.hud.fontName
                        font.pixelSize: list.rowH * 0.6
                        text: opts.preview.title
                        visible: list.count === 0
                    }
                }
                Rectangle {
                    id: scrollTrack

                    anchors.right: parent.right
                    anchors.rightMargin: panelContent.pad
                    color: "#5f6870"
                    height: list.height
                    width: panelContent.u * 1.2
                    y: list.y

                    Rectangle {
                        color: "#d6d9dc"
                        height: Math.max(parent.width, list.visibleArea.heightRatio * parent.height)
                        visible: list.visibleArea.heightRatio < 1
                        width: parent.width
                        y: list.visibleArea.yPosition * parent.height
                    }
                }
            }
        }
        Rectangle {
            id: column2

            color: "#7e858c"
            height: parent.height
            width: opts.colW
            x: opts.level === 1 ? opts.col1X + opts.colW : opts.col1X

            Behavior on x {
                Slide {
                }
            }

            Text {
                color: "#141414"
                font.family: opts.hud.fontName
                font.pixelSize: opts.height * 0.022
                font.variableAxes: opts.hud.fontAxes
                font.weight: Font.Medium
                text: opts.category ? opts.category.title : ""
                x: opts.colW * 0.1
                y: opts.height * 0.05
            }
            Repeater {
                model: opts.entries

                OptionBox {
                    required property int index
                    required property var modelData

                    focused: opts.level === 1 && index === opts.entryIndex
                    icon: modelData.icon
                    selected: opts.level >= 1 && index === opts.entryIndex
                    status: modelData.status
                    x: (opts.colW - width) / 2
                    y: opts.height * 0.27 + index * opts.height * 0.135

                    onClicked: {
                        opts.entryIndex = index;
                        opts.level = 1;
                        opts.enter();
                    }
                }
            }
        }
        Rectangle {
            id: column1

            color: opts.level >= 1 ? "#70777c" : "#7e858c"
            height: parent.height
            width: opts.colW
            x: opts.col1X

            Behavior on color {
                ColorAnimation {
                    duration: 500
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: opts.colW * 0.04
                y: opts.height * 0.035

                Dots {
                    y: opts.height * 0.006
                }
                Column {
                    Repeater {
                        model: opts.categories

                        Text {
                            required property var modelData

                            color: "#141414"
                            font.family: opts.hud.fontName
                            font.pixelSize: opts.height * 0.02
                            font.variableAxes: opts.hud.fontAxes
                            font.weight: Font.Medium
                            text: modelData.title
                        }
                    }
                }
            }
            Repeater {
                model: opts.categories

                OptionBox {
                    readonly property int count: opts.categories.length
                    readonly property real firstY: count <= 2 ? 0.3 : 0.12
                    readonly property real gapY: count <= 2 ? 0.16 : Math.min(0.14, 0.38 / (count - 1))
                    required property int index
                    required property var modelData

                    focused: opts.level === 0 && index === opts.categoryIndex
                    icon: modelData.icon
                    selected: index === opts.categoryIndex
                    x: (opts.colW - width) / 2
                    y: opts.height * (firstY + index * gapY)

                    onClicked: {
                        opts.categoryIndex = index;
                        opts.level = 0;
                        opts.enter();
                    }
                }
            }
        }
        InfoBox {
            readonly property real rightEdge: opts.col1X + opts.colW * (opts.level >= 1 ? 2 : 1)

            description: opts.level === 1 && opts.entry ? opts.entry.description : (opts.category ? opts.category.description : "")
            fontAxes: opts.hud.fontAxes
            fontName: opts.hud.fontName
            height: opts.height * 0.251
            icon: opts.hud.asset(opts.level === 1 && opts.entry ? opts.entry.icon : (opts.category ? opts.category.icon : ""))
            opacity: opts.level < 2 ? 1 : 0
            title: opts.level === 1 && opts.entry ? opts.entry.title : (opts.category ? opts.category.title : "")
            width: opts.width * 0.447
            x: Math.min(rightEdge + opts.colW * 0.08, opts.width - width - opts.width * 0.01)
            y: opts.height * 0.52
        }
        Rectangle {
            id: password

            property string text: ""
            readonly property real u: opts.height / 100

            function handleKey(event) {
                if (event.key === Qt.Key_Escape) {
                    text = "";
                    opts.category.cancelPassword();
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    const value = text;
                    text = "";
                    opts.category.submitPassword(value);
                } else if (event.key === Qt.Key_Backspace) {
                    text = text.slice(0, -1);
                } else if (event.text && event.text.length === 1 && event.text >= " ") {
                    text += event.text;
                }
            }

            border.color: "#99999a"
            border.width: Math.max(3, opts.height * 0.005)
            color: "#525d66"
            height: u * 17
            visible: opts.passwordRequest !== null
            width: opts.colW * 2.4
            x: panel.x + (panel.width - width) / 2
            y: opts.height * 0.4

            onVisibleChanged: text = ""

            Text {
                color: "white"
                font.family: opts.hud.fontName
                font.pixelSize: password.u * 3
                font.variableAxes: opts.hud.fontAxes
                font.weight: Font.Medium
                text: "Password"
                x: password.u * 2
                y: password.u * 1.6
            }
            Text {
                color: "#d6e9f5"
                elide: Text.ElideRight
                font.family: opts.hud.fontName
                font.pixelSize: password.u * 1.9
                text: opts.passwordRequest ? opts.passwordRequest.name : ""
                width: parent.width - password.u * 4
                x: password.u * 2
                y: password.u * 6
            }
            Rectangle {
                border.color: "#16699a"
                border.width: Math.max(2, opts.height * 0.004)
                color: "#efefef"
                height: password.u * 5
                width: parent.width - password.u * 4
                x: password.u * 2
                y: password.u * 9.5

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: password.u
                    anchors.right: parent.right
                    anchors.rightMargin: password.u
                    anchors.verticalCenter: parent.verticalCenter
                    color: "#141414"
                    elide: Text.ElideLeft
                    font.pixelSize: password.u * 2.4
                    text: "•".repeat(password.text.length) + "|"
                }
            }
        }
    }

    component Dots: Item {
        height: width * 0.6
        width: opts.colW * 0.12

        Rectangle {
            color: "#1e2226"
            height: width
            radius: width / 2
            width: parent.height * 0.75
        }
        Rectangle {
            color: "#1e2226"
            height: width
            radius: width / 2
            width: parent.height * 0.45
            x: parent.width * 0.55
            y: -parent.height * 0.15
        }
    }
    component OptionBox: Rectangle {
        id: optionBox

        property bool focused
        property string icon
        property bool selected
        property string status

        signal clicked

        border.color: selected || hover.hovered ? "#16699a" : "black"
        border.width: Math.max(2, opts.height * 0.005)
        color: selected ? "#bfe1f3" : "#efefef"
        height: width
        width: opts.boxSize

        HoverHandler {
            id: hover

            cursorShape: Qt.PointingHandCursor
        }
        Image {
            anchors.fill: parent
            anchors.margins: parent.width * 0.16
            fillMode: Image.PreserveAspectFit
            smooth: true
            source: opts.hud.asset(optionBox.icon)
            sourceSize: Qt.size(128, 128)
        }
        Text {
            anchors.right: parent.left
            anchors.rightMargin: parent.width * 0.14
            anchors.verticalCenter: parent.verticalCenter
            color: "#2f8fcf"
            font.pixelSize: parent.height * 0.3
            text: "▶"
            visible: optionBox.focused
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.bottom
            anchors.topMargin: parent.height * 0.08
            color: "white"
            font.family: opts.hud.fontName
            font.pixelSize: opts.height * 0.016
            text: optionBox.status
            visible: optionBox.status !== ""
        }
        TapHandler {
            onTapped: optionBox.clicked()
        }
    }
    component Slide: NumberAnimation {
        duration: 500
        easing.bezierCurve: opts.cssEase
        easing.type: Easing.Bezier
    }
}
