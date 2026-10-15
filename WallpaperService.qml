import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io

Item {
    id: svc

    property var assignments: ({})
    property string defaultWallpaper: ""
    property string directory: ""
    property var files: []
    readonly property var outputs: Quickshell.screens.map(s => s.name)
    readonly property string statePath: Quickshell.statePath("wallpapers.json")

    function refresh() {
        const list = [];
        for (let i = 0; i < folder.count; i++)
            list.push(folder.get(i, "filePath"));
        files = directory ? list : [];
        console.info("Wallpapers:", files.length, "images in", folder.folder, "status", folder.status);
    }
    function resolve(path) {
        if (!path)
            return "";
        if (path.startsWith("/") || path.indexOf("://") > 0)
            return path;
        return Quickshell.shellDir + "/assets/" + path;
    }
    function set(output, path) {
        const next = Object.assign({}, assignments);
        if (path)
            next[output] = path;
        else
            delete next[output];
        assignments = next;
        stateFile.setText(JSON.stringify(next, null, 2));
    }
    function urlFor(output) {
        const path = wallpaperFor(output);
        if (!path)
            return "";
        return path.indexOf("://") > 0 ? path : "file://" + path;
    }
    function wallpaperFor(output) {
        return assignments[output] || resolve(defaultWallpaper);
    }

    visible: false

    Component.onCompleted: Quickshell.execDetached(["mkdir", "-p", Quickshell.stateDir])

    FileView {
        id: stateFile

        path: svc.statePath
        printErrors: false

        onLoaded: {
            try {
                svc.assignments = JSON.parse(text()) || {};
            } catch (e) {
                svc.assignments = {};
            }
        }
    }
    FolderListModel {
        id: folder

        caseSensitive: false
        folder: svc.directory ? "file://" + svc.directory : ""
        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.gif"]
        showDirs: false
        showDotAndDotDot: false
        sortCaseSensitive: false
        sortField: FolderListModel.Name

        onCountChanged: svc.refresh()
        onStatusChanged: if (status === FolderListModel.Ready)
            svc.refresh()
    }
}
