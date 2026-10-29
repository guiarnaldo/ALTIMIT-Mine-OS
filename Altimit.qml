import QtQuick
import QtQuick3D

Item {
    id: root

    property bool active: true
    property var apps: []
    readonly property bool busy: settle.running || revealAnim.running || explodeAnim.running
    property real cameraPitch: -26
    property var clipboardService: null
    property real clock: 0
    readonly property int count: Math.max(apps.length, 1)
    readonly property int current: ((step % count) + count) % count
    readonly property var elasticCurve: [0.0, 0.018, 0.064, 0.146, 0.256, 0.376, 0.497, 0.618, 0.732, 0.833, 0.923, 1.001, 1.065, 1.118, 1.151, 1.148, 1.114, 1.069, 1.025, 0.987, 0.955, 0.931, 0.922, 0.929, 0.946, 0.968, 0.986, 0.995, 1.0, 1.003, 1.0]
    property real explode: 0
    readonly property var fontAxes: ({
            "wdth": fontWidth
        })
    property string fontFamily: "Archivo"
    readonly property string fontName: pickFont(fontFamily)
    property real fontWidth: 125
    property string hintFontFamily: "M PLUS 1p"
    readonly property string hintFontName: pickFont(hintFontFamily)
    readonly property var hints: optionsOpen ? options.hints : [
        {
            text: "Launch " + shownApp.title + "."
        },
        {
            key: "↵",
            tone: "green",
            text: ": Confirm"
        },
        {
            key: "Esc",
            tone: "gray",
            text: ": Return to Title Screen"
        }
    ]
    readonly property bool idle: !active && reveal === 0
    readonly property var keyTones: ({
            green: ["#2f9a2a", "#1c4d1c"],
            blue: ["#2f6fcf", "#1c3a6d"],
            gray: ["#8a8c8e", "#4a4a4a"]
        })
    readonly property real liveRadius: ringRadius * (1 + explode * 2.4)
    readonly property bool mailOpen: mail.open || mail.visible
    property var mailService: null
    property var optionCategories: ["wifi", "bluetooth", "background"]
    readonly property bool optionsOpen: options.open
    readonly property bool panelOpen: optionsOpen || mailOpen
    property real reveal: 0
    property real ringRadius: 600
    property string screenName: ""
    property real selectorAngle: -8
    readonly property vector3d selectorPoint: {
        void (view.width + view.height + ringRadius + selectorAngle);
        const a = root.selectorAngle * Math.PI / 180;
        return view.mapFrom3DScene(Qt.vector3d(Math.sin(a) * ringRadius, 0, Math.cos(a) * ringRadius));
    }
    property bool showHintBar: true
    property int shown: 0
    readonly property var shownApp: apps.length > 0 ? apps[shown] : ({
            title: "",
            icon: "",
            iconBox: "",
            description: ""
        })
    readonly property string shownWallpaper: wallpapers ? wallpapers.wallpaperFor(screenName || wallpapers.outputs[0] || "") : wallpaper
    readonly property real slotAngle: 360 / (count * 2)
    property int step: 0
    readonly property real uiReveal: Math.max(0, Math.min(1, (reveal - 0.65) / 0.35))
    readonly property int unreadMail: mailService ? mailService.unreadCount : 0
    property string wallpaper: ""
    property var wallpapers: null

    signal closeRequested
    signal hidden
    signal launchRequested(var app)

    function animateReveal(on) {
        revealAnim.to = on ? 1 : 0;
        revealAnim.duration = on ? 1100 : 800;
        revealAnim.restart();
    }
    function asset(name) {
        if (!name)
            return "";
        if (name.startsWith("/"))
            return "file://" + name;
        if (name.indexOf("://") > 0)
            return name;
        return Qt.resolvedUrl("assets/" + name);
    }
    function elastic(t) {
        const c = elasticCurve;
        const last = c.length - 1;
        if (t <= 0)
            return 0;
        if (t >= 1)
            return 1;
        const f = t * last;
        const i = Math.floor(f);
        const u = f - i;
        const p0 = c[Math.max(i - 1, 0)];
        const p1 = c[i];
        const p2 = c[Math.min(i + 1, last)];
        const p3 = c[Math.min(i + 2, last)];
        return 0.5 * (2 * p1 + (p2 - p0) * u + (2 * p0 - 5 * p1 + 4 * p2 - p3) * u * u + (3 * p1 - p0 - 3 * p2 + p3) * u * u * u);
    }
    function itemProgress(order) {
        const spread = 0.45;
        const start = count > 1 ? order / (count - 1) * spread : 0;
        return Math.max(0, Math.min(1, (reveal - start) / (1 - spread)));
    }
    function launch() {
        if (apps.length === 0 || busy)
            return;
        if (apps[current].options)
            options.show(0);
        else if (apps[current].mail)
            mail.show(-1);
        else
            explodeAnim.start();
    }
    function openMail(id) {
        options.hide();
        mail.show(id);
    }
    function openOptions(startLevel, key) {
        mail.hide();
        options.show(startLevel, key);
    }
    function orderOf(index) {
        return ((index - current) % count + count) % count;
    }
    function pickFont(family) {
        return Qt.fontFamilies().indexOf(family) >= 0 ? family : "sans-serif";
    }
    function rotate(delta) {
        if (apps.length === 0 || reveal < 1)
            return;
        const current = ring.yaw;
        swingAnim.stop();
        ring.swing = 0;
        ring.fromYaw = current;
        step += delta;
        swingAnim.start();
        settle.restart();
    }

    focus: true
    visible: !idle

    Component.onCompleted: if (active)
        animateReveal(true)
    Keys.onPressed: event => {
        event.accepted = true;
        if (optionsOpen) {
            options.handleKey(event);
            return;
        }
        if (mailOpen) {
            mail.handleKey(event);
            return;
        }
        switch (event.key) {
        case Qt.Key_Left:
        case Qt.Key_Up:
            rotate(-1);
            break;
        case Qt.Key_Right:
        case Qt.Key_Down:
            rotate(1);
            break;
        case Qt.Key_Return:
        case Qt.Key_Enter:
        case Qt.Key_Space:
            launch();
            break;
        case Qt.Key_Escape:
            closeRequested();
            break;
        default:
            event.accepted = false;
        }
    }
    onActiveChanged: {
        if (!active && explode > 0) {
            revealAnim.stop();
            reveal = 0;
            hidden();
            return;
        }
        if (active)
            explode = 0;
        else {
            options.hide();
            mail.hide();
        }
        animateReveal(active);
    }

    FrameAnimation {
        running: !root.idle

        onTriggered: root.clock += frameTime
    }
    NumberAnimation {
        id: swingAnim

        duration: 1000
        easing.type: Easing.Linear
        from: 0
        property: "swing"
        target: ring
        to: 1
    }
    NumberAnimation {
        id: revealAnim

        easing.type: Easing.Linear
        property: "reveal"
        target: root

        onFinished: if (root.reveal === 0)
            root.hidden()
    }
    SequentialAnimation {
        id: explodeAnim

        NumberAnimation {
            duration: 650
            easing.type: Easing.InQuad
            from: 0
            property: "explode"
            target: root
            to: 1
        }
        ScriptAction {
            script: root.launchRequested(root.apps[root.current])
        }
    }
    Timer {
        id: settle

        interval: 220

        onTriggered: root.shown = root.current
    }
    AnimatedImage {
        anchors.fill: parent
        asynchronous: true
        cache: false
        fillMode: Image.PreserveAspectCrop
        opacity: Math.min(1, root.reveal * 4)
        playing: !root.idle
        source: root.asset(root.shownWallpaper)
        visible: root.shownWallpaper !== ""
    }
    WheelHandler {
        property real acc: 0

        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad

        onWheel: event => {
            acc += event.angleDelta.y;
            if (Math.abs(acc) >= 120) {
                if (root.optionsOpen)
                    options.move(acc > 0 ? -1 : 1);
                else if (root.mailOpen)
                    mail.move(acc > 0 ? -1 : 1);
                else
                    root.rotate(acc > 0 ? -1 : 1);
                acc = 0;
            }
        }
    }
    View3D {
        id: view

        anchors.fill: parent
        camera: camera
        opacity: root.panelOpen ? 0 : 1
        renderMode: View3D.Offscreen

        environment: SceneEnvironment {
            antialiasingMode: SceneEnvironment.MSAA
            antialiasingQuality: SceneEnvironment.High
            backgroundMode: SceneEnvironment.Transparent
        }
        Behavior on opacity {
            NumberAnimation {
                duration: 300
            }
        }

        PerspectiveCamera {
            id: camera

            clipFar: 10000
            clipNear: 10
            eulerRotation.x: root.cameraPitch
            fieldOfView: 40
            position: Qt.vector3d(150, 600, 1400)
        }
        DirectionalLight {
            ambientColor: Qt.rgba(0.32, 0.32, 0.34, 1)
            brightness: 1.5
            eulerRotation: Qt.vector3d(-62, -28, 0)
        }
        DirectionalLight {
            brightness: 0.6
            eulerRotation: Qt.vector3d(-10, 120, 0)
        }
        Node {
            id: ring

            property real fromYaw: 0
            property real swing: 1
            readonly property real targetYaw: root.selectorAngle - root.step * 2 * root.slotAngle
            readonly property real totalYaw: yaw + (1 - root.reveal) * 120
            readonly property real yaw: fromYaw + (targetYaw - fromYaw) * root.elastic(swing)

            eulerRotation.y: totalYaw

            Repeater3D {
                model: root.apps.length

                Node {
                    id: slot

                    readonly property real angle: index * 2 * root.slotAngle
                    required property int index
                    readonly property real p: root.itemProgress(root.orderOf(index))

                    eulerRotation.y: angle

                    Node {
                        eulerRotation.y: -(ring.totalYaw + slot.angle)
                        y: (1 - slot.p) * (1 - slot.p) * 1400
                        z: root.liveRadius

                        Node {
                            eulerRotation.x: root.cameraPitch

                            Item {
                                id: icon

                                readonly property var app: root.apps[slot.index]
                                readonly property real phase: (slot.index % 2) ? 1 : -1

                                height: 80
                                opacity: Math.min(1, slot.p * 3)
                                width: 80
                                x: -width / 2
                                y: -height / 2

                                Image {
                                    anchors.fill: parent
                                    anchors.margins: -parent.width * 0.15
                                    mipmap: true
                                    smooth: true
                                    source: Qt.resolvedUrl("assets/icon-back.png")
                                }
                                Image {
                                    anchors.centerIn: parent
                                    fillMode: Image.PreserveAspectFit
                                    height: width
                                    mipmap: true
                                    smooth: true
                                    source: root.asset(icon.app.icon)
                                    sourceSize: Qt.size(256, 256)
                                    width: parent.width * 0.62

                                    transform: Translate {
                                        SequentialAnimation on y {
                                            loops: Animation.Infinite
                                            paused: root.idle

                                            NumberAnimation {
                                                duration: 2000
                                                easing.type: Easing.InOutSine
                                                from: -5 * icon.phase
                                                to: 5 * icon.phase
                                            }
                                            NumberAnimation {
                                                duration: 2000
                                                easing.type: Easing.InOutSine
                                                from: 5 * icon.phase
                                                to: -5 * icon.phase
                                            }
                                        }
                                    }

                                    NewBadge {
                                        fontFamily: root.hintFontName
                                        italic: true
                                        size: icon.height * 0.2
                                        visible: !!icon.app.mail && root.unreadMail > 0
                                        x: -parent.width * 0.45
                                        y: -parent.height * 0.3
                                    }
                                }
                            }
                        }
                    }
                }
            }
            Repeater3D {
                model: root.apps.length

                Node {
                    id: cubeSlot

                    readonly property real angle: (index * 2 + 1) * root.slotAngle
                    required property int index
                    readonly property real p: root.itemProgress(root.orderOf(index))
                    readonly property real phase: index * 1.7
                    readonly property real t: root.clock + phase

                    eulerRotation.y: angle

                    Node {
                        eulerRotation.y: -(ring.totalYaw + cubeSlot.angle)
                        scale: Qt.vector3d(1, 1, 1).times(Math.min(1, cubeSlot.p * 2))
                        visible: cubeSlot.p > 0
                        y: (1 - cubeSlot.p) * (1 - cubeSlot.p) * 1400
                        z: root.liveRadius

                        Node {
                            eulerRotation.x: root.cameraPitch

                            Node {
                                z: -20

                                Image {
                                    height: 44
                                    mipmap: true
                                    smooth: true
                                    source: Qt.resolvedUrl("assets/icon-back.png")
                                    width: 44
                                    x: -width / 2 + 3 * Math.sin(cubeSlot.t * 1.57)
                                    y: -height / 2 + 3 * Math.cos(cubeSlot.t * 1.57)
                                }
                            }
                            Image {
                                height: width * 407 / 511
                                mipmap: true
                                smooth: true
                                source: Qt.resolvedUrl("assets/cube.png")
                                width: 24
                                x: -width / 2 + 5 * Math.sin(cubeSlot.t * 1.57 + Math.PI)
                                y: -height / 2 + 4 * Math.cos(cubeSlot.t * 1.57 + Math.PI)
                            }
                        }
                    }
                }
            }
        }
    }
    InfoBox {
        id: box

        description: root.shownApp.description || ""
        fontAxes: root.fontAxes
        fontName: root.fontName
        height: root.height * 0.251
        icon: root.asset(root.shownApp.iconBox || root.shownApp.icon)
        opacity: root.busy || root.panelOpen ? 0 : root.uiReveal
        title: root.shownApp.title
        width: root.width * 0.447
        x: root.width * 0.396
        y: root.height * 0.354
    }
    Options {
        id: options

        anchorX: selector.x + selector.width / 2
        anchors.fill: parent
        enabledCategories: root.optionCategories
        hud: root
    }
    Item {
        id: selector

        property real away: root.mailOpen ? 1 : 0

        height: width
        opacity: Math.min(1, root.reveal * 4) * (1 - Math.max(0, (root.explode - 0.6) / 0.4)) * (1 - away)
        scale: 0.6 + 0.4 * Math.min(1, root.reveal * 2.5)
        width: root.height * 0.275
        x: root.selectorPoint.x - width / 2
        y: root.selectorPoint.y - height / 2

        Behavior on away {
            NumberAnimation {
                duration: 300
            }
        }

        Image {
            height: width
            mipmap: true
            source: Qt.resolvedUrl("assets/selectorBack.png")
            width: parent.width * 0.9103
            x: parent.width * 0.0052
            y: parent.height * 0.0461
        }
        Item {
            id: lens

            clip: true
            height: parent.height * 0.56
            width: parent.width * 0.62
            x: parent.width * 0.188
            y: parent.height * 0.254

            Image {
                id: selectorIcon

                anchors.centerIn: parent
                fillMode: Image.PreserveAspectFit
                height: width
                mipmap: true
                opacity: settle.running || revealAnim.running ? 0 : 0.9
                source: root.asset(root.shownApp.icon)
                sourceSize: Qt.size(256, 256)
                width: parent.width * 0.9

                Behavior on opacity {
                    NumberAnimation {
                        duration: 180
                    }
                }
                transform: Translate {
                    SequentialAnimation on x {
                        loops: Animation.Infinite
                        paused: root.idle

                        NumberAnimation {
                            duration: 2000
                            easing.type: Easing.InOutSine
                            from: -lens.width * 0.05
                            to: lens.width * 0.05
                        }
                        NumberAnimation {
                            duration: 2000
                            easing.type: Easing.InOutSine
                            from: lens.width * 0.05
                            to: -lens.width * 0.05
                        }
                    }
                    SequentialAnimation on y {
                        loops: Animation.Infinite
                        paused: root.idle

                        NumberAnimation {
                            duration: 2000
                            easing.type: Easing.InOutSine
                            from: -lens.height * 0.08
                            to: lens.height * 0.08
                        }
                        NumberAnimation {
                            duration: 2000
                            easing.type: Easing.InOutSine
                            from: lens.height * 0.08
                            to: -lens.height * 0.08
                        }
                    }
                }
            }
        }
        Image {
            anchors.fill: parent
            mipmap: true
            source: Qt.resolvedUrl("assets/selector.png")
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor

            onClicked: root.optionsOpen ? options.hide() : root.launch()
        }
    }
    MailStation {
        id: mail

        anchors.fill: parent
        clipboard: root.clipboardService
        hud: root
        service: root.mailService
    }
    Rectangle {
        id: hintBar

        readonly property real edge: Math.max(3, root.height * 0.006)

        anchors.horizontalCenter: parent.horizontalCenter
        color: "#c3c4c6"
        height: root.height * 0.07
        visible: root.showHintBar && !root.mailOpen
        width: parent.width * 0.98
        y: root.height * 0.894 + (1 - root.uiReveal * (1 - root.explode)) * root.height * 0.15

        Rectangle {
            color: "#d8d8da"
            height: hintBar.edge

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
            }
        }
        Rectangle {
            color: "#d8d8da"
            width: hintBar.edge

            anchors {
                bottom: parent.bottom
                left: parent.left
                top: parent.top
            }
        }
        Rectangle {
            color: "#7c7c7c"
            height: hintBar.edge

            anchors {
                bottom: parent.bottom
                left: parent.left
                right: parent.right
            }
        }
        Rectangle {
            color: "#7c7c7c"
            width: hintBar.edge

            anchors {
                bottom: parent.bottom
                right: parent.right
                top: parent.top
            }
        }
        Row {
            id: hintRow

            readonly property real room: hintBar.width - x - hintBar.height * 0.4

            anchors.verticalCenter: parent.verticalCenter
            scale: implicitWidth > room ? room / implicitWidth : 1
            spacing: hintBar.height * 0.18
            transformOrigin: Item.Left
            x: hintBar.height * 0.4

            Text {
                anchors.verticalCenter: parent.verticalCenter
                color: "#22a51e"
                font.pixelSize: hintBar.height * 0.3
                text: "▶"
            }
            Repeater {
                model: root.hints

                Row {
                    required property int index
                    required property var modelData

                    anchors.verticalCenter: parent.verticalCenter
                    leftPadding: index > 1 && modelData.key ? hintBar.height * 0.25 : 0
                    spacing: hintBar.height * 0.08

                    KeyBadge {
                        barHeight: hintBar.height
                        border.color: (root.keyTones[modelData.tone] || root.keyTones.gray)[1]
                        color: (root.keyTones[modelData.tone] || root.keyTones.gray)[0]
                        label: modelData.key || ""
                        visible: !!modelData.key
                    }
                    HintText {
                        barHeight: hintBar.height
                        text: modelData.text
                    }
                }
            }
        }
    }

    component HintText: Text {
        property real barHeight: 40

        anchors.verticalCenter: parent.verticalCenter
        color: "#141414"
        font.family: root.hintFontName
        font.pixelSize: barHeight * 0.42
        font.weight: Font.Medium
    }
    component KeyBadge: Rectangle {
        property real barHeight: 40
        property alias label: badgeText.text

        anchors.verticalCenter: parent.verticalCenter
        border.width: Math.max(1, height * 0.08)
        height: barHeight * 0.56
        radius: height / 2
        width: Math.max(height, badgeText.implicitWidth + height * 0.5)

        Text {
            id: badgeText

            anchors.centerIn: parent
            color: "white"
            font.family: root.hintFontName
            font.pixelSize: parent.height * 0.55
            font.weight: Font.Bold
        }
    }
}
