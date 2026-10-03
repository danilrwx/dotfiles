// The control panel, macOS's Control Center: cards on a dark see-through ground, under the bar at its right
// end. Wi-Fi, Bluetooth, VLESS and the power profile as toggles (the circle flips one), each with its list
// unfolding under its arrow; the headset's mode while one is connected; the display, the sound and the mic
// as sliders, the sound devices under their arrows. Short motion: it fades in, a list slides open, in 100 ms.
// Closed by a click outside it (Hyprland's focus grab) or on its bar block again. The state from
// bin/wm-quick and bin/wm-audio json every 2 s while open; volume and mute straight through PipeWire.
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: panel

    // the bar's ShellRoot: status, sink, source, run(), fnkeys
    required property var shell
    property bool open: false
    function toggle() { open = !open }

    readonly property string bin: Quickshell.env("HOME") + "/dotfiles/bin/"
    readonly property color blue: "#0a84ff"
    readonly property int quick: 100   // ms, every motion here

    // the lists, folded on every opening
    property bool wifis: false
    property bool bts: false
    property bool vlesss: false
    property bool powers: false
    property bool outs: false
    property bool ins: false
    onOpenChanged: if (!open) wifis = bts = vlesss = powers = outs = ins = false

    property var q: ({})
    property var audio: ({})
    Process {
        id: quickProc
        command: [panel.bin + "wm-quick"]
        stdout: StdioCollector { onStreamFinished: { try { panel.q = JSON.parse(text) } catch (e) {} } }
    }
    Process {
        id: audioProc
        command: [panel.bin + "wm-audio", "json"]
        stdout: StdioCollector { onStreamFinished: { try { panel.audio = JSON.parse(text) } catch (e) {} } }
    }
    Timer {
        interval: 2000; repeat: true; triggeredOnStart: true
        running: panel.visible
        onTriggered: { quickProc.running = true; audioProc.running = true }
    }
    // run ARGS..., then the state again at once rather than in 2 s
    function act(cmd) {
        shell.run(cmd)
        refresh.restart()
    }
    Timer { id: refresh; interval: 400; onTriggered: { quickProc.running = true; audioProc.running = true } }

    visible: open
    anchors { top: true; right: true }
    margins { top: 4; right: 6 }
    exclusiveZone: 0
    implicitWidth: 330
    implicitHeight: (screen?.height ?? 1040) - 40
    color: "transparent"
    // the window runs down the screen so the card can grow without it resizing; only the card takes the pointer
    mask: Region { item: card }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-panel"

    HyprlandFocusGrab {
        active: panel.visible
        windows: [panel]
        onCleared: panel.open = false
    }

    // a card: a rounded block a shade lighter than the ground
    component Card: Rectangle {
        default property alias content: col.data
        Layout.fillWidth: true
        implicitHeight: col.implicitHeight + 16
        radius: 14
        color: Qt.rgba(1, 1, 1, 0.08)
        ColumnLayout {
            id: col
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 8; leftMargin: 10; rightMargin: 10 }
            spacing: 4
        }
    }

    component Label: Text {
        color: "#ffffff"
        font.family: "Noto Sans"
        font.pointSize: 10
        elide: Text.ElideRight
    }

    // an arrow that folds or unfolds a list, turning as it does
    component Arrow: MouseArea {
        property bool unfolded
        signal flip
        implicitWidth: 22; implicitHeight: 22
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: flip()
        Rectangle { anchors.fill: parent; radius: 11; color: parent.containsMouse ? Qt.rgba(1, 1, 1, 0.10) : "transparent" }
        Label {
            anchors.centerIn: parent
            text: "›"
            color: Qt.rgba(1, 1, 1, 0.6)
            font.pointSize: 13
            rotation: parent.unfolded ? 90 : 0
            Behavior on rotation { NumberAnimation { duration: panel.quick } }
        }
    }

    // a toggle: a circle lit while on (a click flips it), the name and what it is on to, the list's arrow
    component Toggle: RowLayout {
        id: tg
        property string icon
        property string name
        property string sub
        property bool on
        property bool unfolded
        property bool foldable: true
        signal flip
        signal fold
        spacing: 8
        MouseArea {
            implicitWidth: 34; implicitHeight: 34
            cursorShape: Qt.PointingHandCursor
            onClicked: tg.flip()
            Rectangle {
                anchors.fill: parent; radius: 17
                color: tg.on ? panel.blue : Qt.rgba(1, 1, 1, 0.14)
                Behavior on color { ColorAnimation { duration: panel.quick } }
            }
            Text { anchors.centerIn: parent; text: tg.icon; font.family: "Noto Color Emoji"; font.pointSize: 11 }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            Label { text: tg.name; font.bold: true; Layout.fillWidth: true }
            Label { text: tg.sub; color: Qt.rgba(1, 1, 1, 0.55); font.pointSize: 8.5; Layout.fillWidth: true }
        }
        Arrow { visible: tg.foldable; unfolded: tg.unfolded; onFlip: tg.fold() }
    }

    // a list under its card, sliding open while unfolded
    component Fold: Item {
        default property alias content: inner.data
        property bool unfolded
        Layout.fillWidth: true
        implicitHeight: unfolded ? inner.implicitHeight + 4 : 0
        clip: true
        Behavior on implicitHeight { NumberAnimation { duration: panel.quick; easing.type: Easing.OutCubic } }
        ColumnLayout { id: inner; y: 4; width: parent.width; spacing: 0 }
    }

    // a row of a list: ticked while on, a click picks it
    component Row: MouseArea {
        id: row
        property bool on
        property string text
        property string note
        signal pick
        Layout.fillWidth: true
        implicitHeight: 26
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: pick()
        Rectangle { anchors.fill: parent; radius: 6; color: row.containsMouse ? Qt.rgba(1, 1, 1, 0.10) : "transparent" }
        RowLayout {
            anchors { fill: parent; leftMargin: 4; rightMargin: 6 }
            spacing: 4
            Label { text: row.on ? "✓" : ""; color: panel.blue; Layout.preferredWidth: 16 }
            Label { text: row.text; color: row.on ? "#ffffff" : Qt.rgba(1, 1, 1, 0.75); Layout.fillWidth: true }
            Label { text: row.note; color: Qt.rgba(1, 1, 1, 0.55) }
        }
    }

    component Subtitle: Label { color: Qt.rgba(1, 1, 1, 0.55); font.pointSize: 8.5; topPadding: 6 }

    // a slider: a thick bar from 0 to 1, the icon before it a button; moved(v) while dragged
    component Slider: RowLayout {
        id: sl
        property string icon
        property real value
        signal moved(real v)
        signal iconClicked
        spacing: 8
        MouseArea {
            implicitWidth: 22; implicitHeight: 22
            cursorShape: Qt.PointingHandCursor
            onClicked: sl.iconClicked()
            Text { anchors.centerIn: parent; text: sl.icon; font.family: "Noto Color Emoji"; font.pointSize: 10 }
        }
        Item {
            Layout.fillWidth: true
            implicitHeight: 22
            // while dragged it follows the pointer, not the value coming back
            property real shown: drag.pressed ? drag.v : sl.value
            Rectangle { anchors.fill: parent; radius: 11; color: Qt.rgba(1, 1, 1, 0.16) }
            Rectangle {
                height: parent.height; radius: 11; color: "#ffffff"
                width: Math.max(height, parent.width * Math.min(1, Math.max(0, parent.shown)))
            }
            MouseArea {
                id: drag
                property real v: 0
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                function set(x) { v = Math.min(1, Math.max(0, x / width)); sl.moved(v) }
                onPressed: m => set(m.x)
                onPositionChanged: m => { if (pressed) set(m.x) }
            }
        }
    }

    Rectangle {
        id: card
        width: parent.width
        height: cards.implicitHeight + 20
        radius: 18
        color: Qt.rgba(28 / 255, 28 / 255, 30 / 255, 0.92)
        border.color: Qt.rgba(1, 1, 1, 0.12)
        border.width: 1
        opacity: panel.visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: panel.quick } }

        ColumnLayout {
            id: cards
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
            spacing: 10

            Card {
                Toggle {
                    icon: "📶"; name: "Wi-Fi"; on: panel.q.wifi ?? false
                    sub: on ? (panel.q.ssid ?? "") : "Off"
                    unfolded: panel.wifis
                    onFlip: panel.act(["rfkill", on ? "block" : "unblock", "wlan"])
                    onFold: panel.wifis = !panel.wifis
                }
                Fold {
                    unfolded: panel.wifis
                    Repeater {
                        model: panel.q.networks ?? []
                        Row {
                            required property var modelData
                            on: modelData.on; text: modelData.ssid
                            note: "▂▄▆█".substring(0, modelData.signal)
                            // a known network joins; a new one needs its passphrase, typed in impala
                            onPick: {
                                if (modelData.known) panel.act(["iwctl", "station", "wlan0", "connect", modelData.ssid])
                                else { panel.open = false; panel.shell.run([panel.bin + "wm-ctl", "wifi"]) }
                            }
                        }
                    }
                    Row { text: "Scan"; onPick: panel.act(["iwctl", "station", "wlan0", "scan"]) }
                    Row { text: "Other networks…"; onPick: { panel.open = false; panel.shell.run([panel.bin + "wm-ctl", "wifi"]) } }
                }
            }

            Card {
                Toggle {
                    icon: "🔵"; name: "Bluetooth"; on: panel.q.bt ?? false
                    sub: on ? ((panel.q.btdev ?? "") || "On") : "Off"
                    unfolded: panel.bts
                    onFlip: panel.act(["rfkill", on ? "block" : "unblock", "bluetooth"])
                    onFold: panel.bts = !panel.bts
                }
                Fold {
                    unfolded: panel.bts
                    Repeater {
                        model: panel.q.devices ?? []
                        Row {
                            required property var modelData
                            on: modelData.on; text: modelData.name
                            onPick: panel.act(["bluetoothctl", modelData.on ? "disconnect" : "connect", modelData.mac])
                        }
                    }
                    Row { text: "Pair a device…"; onPick: { panel.open = false; panel.shell.run([panel.bin + "wm-ctl", "bluetooth"]) } }
                }
            }

            Card {
                Toggle {
                    icon: "🛡️"; name: "VLESS"; on: (panel.q.vless ?? "off") !== "off"
                    sub: panel.shell.status.vless || "Off"
                    unfolded: panel.vlesss
                    onFlip: panel.act(on ? [panel.bin + "vless", "off"] : [panel.bin + "vless", "on", "tun"])
                    onFold: panel.vlesss = !panel.vlesss
                }
                Fold {
                    unfolded: panel.vlesss
                    Row { on: panel.q.vless === "tun"; text: "TUN, every app"; onPick: panel.act([panel.bin + "vless", "on", "tun"]) }
                    Row { on: panel.q.vless === "proxy"; text: "System proxy"; onPick: panel.act([panel.bin + "vless", "on", "proxy"]) }
                    ColumnLayout {
                        visible: (panel.q.vless ?? "off") !== "off"
                        Layout.fillWidth: true
                        spacing: 0
                        Subtitle { text: "Mode" }
                        Row { on: panel.q.vmode === "rule"; text: "Rule: Russia direct"; onPick: panel.act([panel.bin + "vless", "mode", "rule"]) }
                        Row { on: panel.q.vmode === "global"; text: "Global"; onPick: panel.act([panel.bin + "vless", "mode", "global"]) }
                        Subtitle { text: "Profile" }
                        Repeater {
                            model: panel.q.profiles ?? []
                            Row {
                                required property string modelData
                                on: modelData === panel.q.vprofile; text: modelData
                                onPick: panel.act([panel.bin + "vless", "profile", modelData])
                            }
                        }
                    }
                }
            }

            Card {
                Toggle {
                    readonly property var order: ["power-saver", "balanced", "performance"]
                    icon: "⚡"; name: "Power"; sub: panel.q.power ?? ""
                    on: panel.q.power === "performance"
                    unfolded: panel.powers
                    onFlip: panel.act(["powerprofilesctl", "set", order[(order.indexOf(panel.q.power) + 1) % 3]])
                    onFold: panel.powers = !panel.powers
                }
                Fold {
                    unfolded: panel.powers
                    Repeater {
                        model: ["power-saver", "balanced", "performance"]
                        Row {
                            required property string modelData
                            on: modelData === panel.q.power; text: modelData
                            onPick: panel.act(["powerprofilesctl", "set", modelData])
                        }
                    }
                }
            }

            Card {
                visible: (panel.audio.headset ?? "") !== ""
                Toggle {
                    icon: "🎧"; name: "Headset"; sub: panel.audio.headset ?? ""
                    on: panel.audio.headset === "handsfree"; foldable: false
                    onFlip: panel.act([panel.bin + "wm-ctl", "headset"])
                }
            }

            Card {
                Label { text: "Display"; font.bold: true }
                Slider {
                    Layout.fillWidth: true
                    icon: "🌞"; value: (panel.shell.status.bri ?? 0) / 100
                    onMoved: v => panel.shell.run(["brightnessctl", "-q", "set", Math.max(1, Math.round(v * 100)) + "%"])
                }
            }

            Card {
                RowLayout {
                    Layout.fillWidth: true
                    Label { text: "Sound"; font.bold: true; Layout.fillWidth: true }
                    Arrow { unfolded: panel.outs; onFlip: panel.outs = !panel.outs }
                }
                Slider {
                    Layout.fillWidth: true
                    icon: panel.shell.sink?.muted ? "🔇" : "🔊"; value: panel.shell.sink?.volume ?? 0
                    onMoved: v => { if (panel.shell.sink) panel.shell.sink.volume = v }
                    onIconClicked: if (panel.shell.sink) panel.shell.sink.muted = !panel.shell.sink.muted
                }
                Fold {
                    unfolded: panel.outs
                    Repeater {
                        model: panel.audio.sinks ?? []
                        Row {
                            required property var modelData
                            on: modelData.def; text: modelData.name
                            onPick: panel.act(["wpctl", "set-default", String(modelData.id)])
                        }
                    }
                }
            }

            Card {
                RowLayout {
                    Layout.fillWidth: true
                    Label { text: "Microphone"; font.bold: true; Layout.fillWidth: true }
                    Arrow { unfolded: panel.ins; onFlip: panel.ins = !panel.ins }
                }
                Slider {
                    Layout.fillWidth: true
                    icon: panel.shell.source?.muted ? "🙊" : "🎙️"; value: panel.shell.source?.volume ?? 0
                    onMoved: v => { if (panel.shell.source) panel.shell.source.volume = v }
                    onIconClicked: if (panel.shell.source) panel.shell.source.muted = !panel.shell.source.muted
                }
                Fold {
                    unfolded: panel.ins
                    Repeater {
                        model: panel.audio.sources ?? []
                        Row {
                            required property var modelData
                            on: modelData.def; text: modelData.name
                            onPick: panel.act(["wpctl", "set-default", String(modelData.id)])
                        }
                    }
                }
            }
        }
    }
}
