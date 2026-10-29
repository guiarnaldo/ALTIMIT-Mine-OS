import QtQuick
import QtQml
import Quickshell.Networking

Item {
    id: wifi

    readonly property var connectedNetwork: networks.find(n => n.connected) || null
    readonly property string description: "Connect to wireless networks\nand manage saved ones."
    readonly property var device: {
        const list = Networking.devices.values;
        for (let i = 0; i < list.length; i++) {
            if (list[i].type === DeviceType.Wifi)
                return list[i];
        }
        return null;
    }
    readonly property var entries: [
        {
            title: "Networks",
            icon: placeholderIcon,
            description: "Nearby and saved networks.\nConnect, disconnect or forget them.",
            hint: "Manage Wi-Fi networks.",
            status: connectedNetwork ? label(connectedNetwork) : "Not connected"
        },
        {
            title: "Scan",
            icon: placeholderIcon,
            description: "Search for nearby\nwireless networks.",
            hint: "Search for nearby networks.",
            status: device && device.scannerEnabled ? "Searching" : "OFF"
        },
        {
            title: "Power",
            icon: placeholderIcon,
            description: "Turn wireless networking\non or off.",
            hint: "Turn Wi-Fi on or off.",
            status: Networking.wifiHardwareEnabled ? onOff(Networking.wifiEnabled) : "Blocked"
        },
        {
            title: "Auto Connect",
            icon: placeholderIcon,
            description: "Join saved networks\nautomatically.",
            hint: "Join saved networks automatically.",
            status: onOff(device && device.autoconnect)
        }
    ]
    readonly property string hint: "Change Wi-Fi settings."
    property var hud
    readonly property string icon: placeholderIcon
    readonly property var items: networks.map(n => ({
                label: label(n),
                checked: n.known,
                status: stateText(n) + "  " + strength(n) + "%"
            }))
    readonly property string key: "wifi"
    property string lastError: ""
    readonly property string listTitle: "networks"
    readonly property var networks: {
        if (!device)
            return [];
        return device.networks.values.slice().sort((a, b) => (b.connected - a.connected) || (b.known - a.known) || (b.signalStrength - a.signalStrength) || label(a).localeCompare(label(b)));
    }
    readonly property string panelTitle: "Wi-Fi"
    property var passwordRequest: null
    readonly property string placeholderIcon: "theworld2.png"
    property bool startedScan: false
    readonly property string title: "Wi-Fi"

    function activate(i) {
        switch (i) {
        case 0:
            if (device && !device.scannerEnabled)
                setScan(true);
            return true;
        case 1:
            if (device && device.scannerEnabled) {
                setScan(false);
                return false;
            }
            if (!Networking.wifiEnabled)
                Networking.wifiEnabled = true;
            setScan(true);
            return true;
        case 2:
            Networking.wifiEnabled = !Networking.wifiEnabled;
            return false;
        case 3:
            if (device)
                device.autoconnect = !device.autoconnect;
            return false;
        }
        return false;
    }
    function cancelPassword() {
        passwordRequest = null;
    }
    function close() {
        passwordRequest = null;
        if (startedScan)
            setScan(false);
    }
    function isOpen(n) {
        return n.security === WifiSecurityType.Open || n.security === WifiSecurityType.Owe;
    }
    function itemAction(i, action) {
        if (action === "scan") {
            setScan(!(device && device.scannerEnabled));
            return;
        }
        const n = networks[i];
        if (!n)
            return;
        if (action === "confirm") {
            if (n.stateChanging)
                return;
            lastError = "";
            if (n.connected)
                n.disconnect();
            else if (n.known || isOpen(n))
                n.connect();
            else if (needsPsk(n))
                passwordRequest = n;
            else
                n.connect();
        } else if (action === "check" || action === "forget") {
            if (n.known)
                n.forget();
        }
    }
    function label(n) {
        return n.name || "Hidden network";
    }
    function needsPsk(n) {
        return n.security === WifiSecurityType.WpaPsk || n.security === WifiSecurityType.Wpa2Psk || n.security === WifiSecurityType.Sae;
    }
    function onOff(value) {
        return value ? "ON" : "OFF";
    }
    function pad(i) {
        return ("00" + i).slice(-3);
    }
    function panelHints(i) {
        const n = networks[i];
        let text = "Search for nearby networks.";
        if (n)
            text = (n.connected ? "Disconnect from " : "Connect to ") + label(n) + ".";
        return [
            {
                text: text
            },
            {
                key: "↵",
                tone: "green",
                text: ": Confirm"
            },
            {
                key: "Del",
                tone: "gray",
                text: ": Forget"
            },
            {
                key: "S",
                tone: "gray",
                text: ": Scan"
            },
            {
                key: "Esc",
                tone: "gray",
                text: ": Back"
            }
        ];
    }
    function preview(i) {
        const n = networks[i];
        if (!n) {
            let text = "No Wi-Fi device";
            if (device)
                text = !Networking.wifiEnabled ? "Wi-Fi is off" : device.scannerEnabled ? "Searching..." : "No networks";
            return {
                image: placeholderIcon,
                number: "",
                title: text,
                lines: []
            };
        }
        const lines = ["Signal " + strength(n) + "%", WifiSecurityType.toString(n.security), stateText(n)];
        if (lastError !== "" && passwordRequest === null)
            lines.push(lastError);
        return {
            image: placeholderIcon,
            number: pad(i),
            title: label(n),
            lines: lines
        };
    }
    function setScan(on) {
        if (!device)
            return;
        startedScan = on;
        device.scannerEnabled = on;
    }
    function stateText(n) {
        if (n.state === ConnectionState.Connecting)
            return "Connecting";
        if (n.state === ConnectionState.Disconnecting)
            return "Disconnecting";
        if (n.connected)
            return "Connected";
        if (n.known)
            return "Saved";
        return isOpen(n) ? "Open" : "Secured";
    }
    function strength(n) {
        return Math.round((n.signalStrength || 0) * 100);
    }
    function submitPassword(text) {
        const n = passwordRequest;
        passwordRequest = null;
        if (n && text !== "")
            n.connectWithPsk(text);
    }

    visible: false

    Instantiator {
        model: wifi.device ? wifi.device.networks : null

        delegate: Connections {
            required property var modelData

            function onConnectionFailed(reason) {
                const n = modelData;
                if (reason === ConnectionFailReason.NoSecrets && wifi.needsPsk(n)) {
                    wifi.passwordRequest = n;
                    return;
                }
                wifi.lastError = ConnectionFailReason.toString(reason);
            }

            ignoreUnknownSignals: true
            target: modelData
        }
    }
}
