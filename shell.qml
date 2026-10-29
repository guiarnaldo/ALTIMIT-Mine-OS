import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: shell

    readonly property var apps: {
        void DesktopEntries.applications.values;
        return (config.apps || []).map(resolveApp);
    }
    readonly property var config: {
        try {
            const data = JSON.parse(appsFile.text());
            return Array.isArray(data) ? {
                apps: data
            } : data;
        } catch (e) {
            console.warn("apps.json missing or invalid (copy apps.example.json to apps.json):", e);
            return {
                apps: []
            };
        }
    }
    property bool mounted: false
    property bool open: false
    property var pendingMail: null
    property var pendingOptions: null

    function expandHome(path) {
        if (typeof path !== "string")
            return "";
        if (path === "~" || path.startsWith("~/"))
            return Quickshell.env("HOME") + path.slice(1);
        return path;
    }
    function resolveApp(app) {
        const entry = app.desktop ? DesktopEntries.heuristicLookup(app.desktop) : null;

        return {
            title: app.title || (entry ? entry.name : ""),
            mail: app.mail === true,
            options: app.options === true,
            description: app.description || (entry ? entry.comment : ""),
            icon: app.icon || "",
            iconBox: app.iconBox || app.icon || "",
            command: app.command || [],
            entry: entry
        };
    }
    function show() {
        mounted = true;
        open = true;
    }
    function showMail(id) {
        pendingMail = {
            id: id
        };
        show();
    }
    function showOptions(level, key) {
        pendingOptions = {
            level: level,
            key: key
        };
        show();
    }

    FileView {
        id: appsFile

        blockLoading: true
        path: Qt.resolvedUrl("apps.json")
        watchChanges: true

        onFileChanged: reload()
    }
    WallpaperService {
        id: wallpaperService

        defaultWallpaper: shell.expandHome(shell.config.wallpaper ?? "")
        directory: shell.expandHome(shell.config.wallpaperDir ?? "")
    }
    Variants {
        model: (shell.config.desktopWallpaper ?? true) ? Quickshell.screens : []

        Wallpaper {
            service: wallpaperService
        }
    }
    LazyLoader {
        id: notifications

        active: shell.config.notifications ?? true

        Notifications {
            fontFamily: shell.config.hintFont ?? "M PLUS 1p"
            history: shell.config.notificationHistory ?? true
            screenName: shell.config.notificationScreen ?? ""
            timeout: shell.config.notificationTimeout ?? 6

            onOpenRequested: id => shell.showMail(id)
        }
    }
    LazyLoader {
        id: clipboard

        active: shell.config.clipboardHistory ?? true

        ClipboardService {
        }
    }
    IpcHandler {
        function background(): void {
            shell.showOptions(1, "background");
        }
        function bluetooth(): void {
            shell.showOptions(1, "bluetooth");
        }
        function hide(): void {
            shell.open = false;
        }
        function mail(): void {
            shell.showMail(-1);
        }
        function options(): void {
            shell.showOptions(0, "");
        }
        function show(): void {
            shell.show();
        }
        function toggle(): void {
            if (shell.open)
                shell.open = false;
            else
                shell.show();
        }
        function wifi(): void {
            shell.showOptions(1, "wifi");
        }

        target: "altimit"
    }
    LazyLoader {
        active: shell.mounted

        PanelWindow {
            id: win

            WlrLayershell.keyboardFocus: shell.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "altimit"
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            screen: null

            anchors {
                bottom: true
                left: true
                right: true
                top: true
            }
            Altimit {
                id: hud

                function takeOptions() {
                    const mailReq = shell.pendingMail;
                    if (mailReq) {
                        shell.pendingMail = null;
                        openMail(mailReq.id);
                    }
                    const req = shell.pendingOptions;
                    if (!req)
                        return;
                    shell.pendingOptions = null;
                    openOptions(req.level, req.key);
                }

                active: shell.open
                anchors.fill: parent
                apps: shell.apps
                clipboardService: clipboard.item
                focus: shell.open
                fontFamily: shell.config.font ?? "Archivo"
                fontWidth: shell.config.fontWidth ?? 125
                hintFontFamily: shell.config.hintFont ?? "M PLUS 1p"
                mailService: notifications.item
                optionCategories: shell.config.options ?? ["wifi", "bluetooth", "background"]
                screenName: win.screen ? win.screen.name : ""
                showHintBar: shell.config.hintBar ?? true
                wallpapers: wallpaperService

                Component.onCompleted: takeOptions()
                onCloseRequested: shell.open = false
                onHidden: Qt.callLater(() => {
                    if (!shell.open)
                        shell.mounted = false;
                })
                onLaunchRequested: app => {
                    if (app.entry && app.command.length === 0)
                        app.entry.execute();
                    else
                        Quickshell.execDetached(app.command);
                    shell.open = false;
                }

                Connections {
                    function onPendingMailChanged() {
                        hud.takeOptions();
                    }
                    function onPendingOptionsChanged() {
                        hud.takeOptions();
                    }

                    target: shell
                }
            }
        }
    }
}
