import QtQuick

Item {
    id: bg

    readonly property var choices: [""].concat(svc ? svc.files : [])
    readonly property string current: svc && output ? (svc.assignments[output] || "") : ""
    readonly property string description: "Choose the wallpaper\nfor each screen."
    readonly property var entries: [
        {
            title: "BG Setting",
            icon: placeholderIcon,
            description: "Set the wallpaper shown on\neach screen.",
            hint: "Change wallpaper.",
            status: tabs.length + (tabs.length === 1 ? " screen" : " screens")
        },
        {
            title: "Randomize",
            icon: placeholderIcon,
            description: "Pick a random wallpaper\nfor every screen.",
            hint: "Randomize wallpaper on every screen.",
            status: ""
        }
    ]
    readonly property string hint: "Change wallpaper setting."
    property var hud
    readonly property string icon: placeholderIcon
    readonly property int initialIndex: Math.max(0, choices.indexOf(current))
    readonly property var items: choices.map(p => ({
                label: name(p),
                checked: p === current,
                status: ""
            }))
    readonly property string key: "background"
    readonly property string listTitle: "Background"
    readonly property string output: tabs[tabIndex] || ""
    readonly property string panelTitle: "BG Setting"
    readonly property string placeholderIcon: "accessories2.png"
    readonly property var svc: hud ? hud.wallpapers : null
    property int tabIndex: 0
    readonly property var tabs: svc ? svc.outputs : []
    readonly property string title: "Background"

    function activate(i) {
        if (!svc)
            return false;
        if (i === 0) {
            svc.refresh();
            return true;
        }
        svc.refresh();
        tabs.forEach(o => random(o));
        return false;
    }
    function close() {
    }
    function itemAction(i, action) {
        if (!svc || !output)
            return;
        if (action === "confirm" && i < choices.length)
            svc.set(output, choices[i]);
        else if (action === "random")
            random(output);
    }
    function name(path) {
        if (!path)
            return "Default";
        return path.split("/").pop().replace(/\.[^.]+$/, "").replace(/[_-]+/g, " ");
    }
    function pad(i) {
        return ("00" + i).slice(-3);
    }
    function panelHints(i) {
        return [
            {
                text: "Set current file as wallpaper."
            },
            {
                key: "↵",
                tone: "green",
                text: ": Confirm"
            },
            {
                key: "◀▶",
                tone: "gray",
                text: ": Screen"
            },
            {
                key: "R",
                tone: "blue",
                text: ": Randomize"
            },
            {
                key: "Esc",
                tone: "gray",
                text: ": Back"
            }
        ];
    }
    function preview(i) {
        if (!svc)
            return {
                image: placeholderIcon,
                number: "",
                title: "Unavailable",
                lines: []
            };
        const path = choices[i];
        const image = path === undefined ? "" : (path || svc.resolve(svc.defaultWallpaper));
        return {
            image: image,
            number: pad(i),
            title: name(path),
            lines: ["Screen " + ("0" + (tabIndex + 1)).slice(-2) + " · " + output],
            fill: true
        };
    }
    function random(output) {
        if (choices.length < 2)
            return;
        svc.set(output, choices[1 + Math.floor(Math.random() * (choices.length - 1))]);
    }
    function setTab(i) {
        if (tabs.length === 0)
            return;
        tabIndex = (i + tabs.length) % tabs.length;
    }

    visible: false
}
