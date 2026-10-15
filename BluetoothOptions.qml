import QtQuick
import QtQml
import Quickshell.Bluetooth

Item {
    id: bt

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property int connectedCount: devices.filter(d => d.connected).length
    readonly property string description: "Connect headphones, controllers\nand other wireless devices."
    readonly property var devices: {
        if (!adapter)
            return [];
        return adapter.devices.values.slice().sort((a, b) => rank(b) - rank(a) || label(a).localeCompare(label(b)));
    }
    readonly property var entries: [
        {
            title: "Devices",
            icon: placeholderIcon,
            description: "Paired and nearby devices.\nConnect, disconnect or forget them.",
            hint: "Manage Bluetooth devices.",
            status: connectedCount + " connected"
        },
        {
            title: "Scan",
            icon: placeholderIcon,
            description: "Search for nearby devices\nready to pair.",
            hint: "Search for nearby devices.",
            status: adapter && adapter.discovering ? "Searching" : "OFF"
        },
        {
            title: "Power",
            icon: placeholderIcon,
            description: "Turn the Bluetooth adapter\non or off.",
            hint: "Turn Bluetooth on or off.",
            status: onOff(adapter && adapter.enabled)
        },
        {
            title: "Visibility",
            icon: placeholderIcon,
            description: "Allow other devices to find\nthis computer.",
            hint: "Make this computer discoverable.",
            status: onOff(adapter && adapter.discoverable)
        }
    ]
    readonly property string hint: "Change Bluetooth settings."
    property var hud
    readonly property string icon: placeholderIcon
    readonly property var items: devices.map(d => ({
                label: label(d),
                checked: d.trusted,
                status: stateText(d)
            }))
    readonly property string key: "bluetooth"
    readonly property string listTitle: "devices"
    readonly property string panelTitle: "Bluetooth"
    property var pendingConnect: ({})
    readonly property string placeholderIcon: "accessories2.png"
    property bool scanWhenPowered: false
    property bool startedScan: false
    readonly property string title: "Bluetooth"

    function activate(i) {
        if (!adapter)
            return false;
        switch (i) {
        case 0:
            return true;
        case 1:
            if (adapter.discovering) {
                setScan(false);
                return false;
            }
            setScan(true);
            return true;
        case 2:
            adapter.enabled = !adapter.enabled;
            return false;
        case 3:
            adapter.discoverable = !adapter.discoverable;
            return false;
        }
        return false;
    }
    function close() {
        if (startedScan)
            setScan(false);
    }
    function itemAction(i, action) {
        if (action === "scan") {
            setScan(!(adapter && adapter.discovering));
            return;
        }
        const d = devices[i];
        if (!d)
            return;
        if (action === "confirm") {
            if (d.pairing || d.state === BluetoothDeviceState.Connecting || d.state === BluetoothDeviceState.Disconnecting)
                return;
            if (d.connected) {
                d.disconnect();
            } else if (!d.paired) {
                pendingConnect[d.address] = true;
                d.pair();
            } else {
                d.connect();
            }
        } else if (action === "check") {
            d.trusted = !d.trusted;
        } else if (action === "forget") {
            d.forget();
        }
    }
    function label(d) {
        return d.name || d.address;
    }
    function onOff(value) {
        return value ? "ON" : "OFF";
    }
    function pad(i) {
        return ("00" + i).slice(-3);
    }
    function panelHints(i) {
        const d = devices[i];
        let text = "Search for nearby devices.";
        if (d)
            text = (d.connected ? "Disconnect from " : d.paired ? "Connect to " : "Pair with ") + label(d) + ".";
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
                key: "Space",
                tone: "blue",
                text: ": Auto Connect"
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
        const d = devices[i];
        if (!d) {
            let text = "No adapter";
            if (adapter)
                text = adapter.discovering ? "Searching..." : "No devices";
            return {
                image: placeholderIcon,
                number: "",
                title: text,
                lines: []
            };
        }
        const lines = [d.address, stateText(d) + (d.trusted ? " · Auto Connect" : "")];
        if (d.batteryAvailable)
            lines.push("Battery " + Math.round(d.battery * 100) + "%");
        return {
            image: placeholderIcon,
            number: pad(i),
            title: label(d),
            lines: lines
        };
    }
    function rank(d) {
        return d.paired ? 1 : 0;
    }
    function setScan(on) {
        if (!adapter)
            return;
        if (!on) {
            scanWhenPowered = false;
            startedScan = false;
            adapter.discovering = false;
            return;
        }
        startedScan = true;
        if (adapter.enabled) {
            adapter.discovering = true;
        } else {
            scanWhenPowered = true;
            adapter.enabled = true;
        }
    }
    function stateText(d) {
        if (d.pairing)
            return "Pairing";
        if (d.state === BluetoothDeviceState.Connecting)
            return "Connecting";
        if (d.state === BluetoothDeviceState.Disconnecting)
            return "Disconnecting";
        if (d.connected)
            return "Connected";
        if (d.paired)
            return "Paired";
        return "New";
    }

    visible: false

    Connections {
        function onEnabledChanged() {
            if (bt.adapter.enabled && bt.scanWhenPowered) {
                bt.scanWhenPowered = false;
                bt.adapter.discovering = true;
            }
        }

        ignoreUnknownSignals: true
        target: bt.adapter
    }
    Instantiator {
        model: bt.adapter ? bt.adapter.devices : null

        delegate: Connections {
            required property var modelData

            function onPairedChanged() {
                const d = modelData;
                if (!d.paired || !bt.pendingConnect[d.address])
                    return;
                delete bt.pendingConnect[d.address];
                d.trusted = true;
                d.connect();
            }

            ignoreUnknownSignals: true
            target: modelData
        }
    }
}
