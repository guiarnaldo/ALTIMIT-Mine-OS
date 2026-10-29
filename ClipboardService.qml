import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    readonly property string cacheDir: Quickshell.cachePath("clipboard")
    property var current: null
    property url currentImage: ""
    property string currentText: ""
    property var entries: []
    readonly property var imagePattern: /^\[\[ binary data .* (png|jpe?g|gif|bmp|webp|svg\+xml|tiff?)( \d+x\d+)? \]\]$/i
    property var queued: null

    function copy(entry) {
        if (!entry)
            return;
        Quickshell.execDetached(["sh", "-c", "printf '%s\\t\\n' \"$1\" | cliphist decode | wl-copy", "sh", entry.id]);
        refreshLater.restart();
    }
    function isCurrent(entry) {
        return !!entry && !!current && current.id === entry.id;
    }
    function load(entry) {
        current = entry;
        currentText = "";
        currentImage = "";
        textDecoder.running = false;
        imageDecoder.running = false;
        if (!entry)
            return;
        if (entry.ext) {
            const path = cacheDir + "/" + entry.id + "." + entry.ext;
            imageDecoder.path = path;
            imageDecoder.command = ["sh", "-c", "mkdir -p \"$(dirname \"$2\")\" && { [ -s \"$2\" ] || printf '%s\\t\\n' \"$1\" | cliphist decode > \"$2\"; }", "sh", entry.id, path];
            imageDecoder.running = true;
        } else {
            textDecoder.command = ["sh", "-c", "printf '%s\\t\\n' \"$1\" | cliphist decode", "sh", entry.id];
            textDecoder.running = true;
        }
    }
    function parse(text) {
        const out = [];
        for (const line of text.split("\n")) {
            const tab = line.indexOf("\t");
            if (tab <= 0)
                continue;
            const id = line.slice(0, tab);
            const preview = line.slice(tab + 1);
            const image = preview.match(imagePattern);
            const ext = image ? image[1].toLowerCase().replace("jpeg", "jpg").replace("svg+xml", "svg") : "";
            out.push({
                id: id,
                appName: image ? "Image" : "Text",
                summary: image ? preview.slice(3, -3).trim() : preview.trim().replace(/\s+/g, " "),
                body: "",
                ext: ext,
                actions: [],
                clip: true
            });
        }
        return out;
    }
    function refresh() {
        if (lister.running)
            queued = true;
        else
            lister.running = true;
    }
    function remove(entry) {
        if (!entry)
            return;
        run(["sh", "-c", "printf '%s\\t\\n' \"$1\" | cliphist delete; rm -f \"$2\"/\"$1\".*", "sh", entry.id, cacheDir]);
    }
    function run(command) {
        runner.running = false;
        runner.command = command;
        runner.running = true;
    }

    Process {
        id: lister

        command: ["cliphist", "list"]

        stdout: StdioCollector {
            onStreamFinished: {
                root.entries = root.parse(text);
                if (root.queued) {
                    root.queued = false;
                    root.refresh();
                }
            }
        }
    }
    Process {
        id: textDecoder

        stdout: StdioCollector {
            onStreamFinished: root.currentText = text
        }
    }
    Process {
        id: imageDecoder

        property string path

        onExited: (code, status) => {
            if (code === 0)
                root.currentImage = "file://" + path;
        }
    }
    Process {
        id: runner

        onExited: root.refresh()
    }
    Timer {
        id: refreshLater

        interval: 400

        onTriggered: root.refresh()
    }
}
