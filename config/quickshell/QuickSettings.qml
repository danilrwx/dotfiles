// The quick settings, GNOME's layout in the old look (Theme.qml): a popover under the bar's status. Up top the battery and round buttons for a
// screenshot, the lock and the power menu; then the sliders, volume and mic (their device lists behind an arrow)
// and brightness; then the toggles, two a row, GNOME's split pills: Wi-Fi, Bluetooth, the power mode, VLESS
// and the headset's mode, the left side flips one (inverted while on), the arrow opens its menu. A menu unfolds in place under its
// row, one at a time, in 100 ms. Closed by a click outside (Hyprland's focus grab) or on the pill again. The
// toggles' state from the bar's bin/wm-quick, the devices from bin/wm-audio json every 2 s while open, volume
// and mute straight through PipeWire.
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: panel

    // the bar's ShellRoot: status, q, sink, source, battery, run(), refresh(), the icon functions
    required property var shell
    property bool open: false
    function toggle() { open = !open }
    readonly property var q: shell.q
    readonly property string bin: shell.bin

    // the menu unfolded: "", system, outs, ins, wifi, bt, power, vless; folded on every opening
    property string menu: ""
    function flip(m) { menu = menu === m ? "" : m }
    onOpenChanged: menu = ""

    property var audio: ({})
    Process {
        id: audioProc
        command: [panel.bin + "wm-audio", "json"]
        stdout: StdioCollector { onStreamFinished: { try { panel.audio = JSON.parse(text) } catch (e) {} } }
    }
    Timer {
        interval: 2000; repeat: true; triggeredOnStart: true
        running: panel.visible
        onTriggered: audioProc.running = true
    }
    // run ARGS..., then the state again at once
    function act(cmd) {
        shell.run(cmd)
        shell.refresh()
        later.restart()
    }
    Timer { id: later; interval: 400; onTriggered: audioProc.running = true }
    // close, then run ARGS... (what takes the screen: a tool, the lock)
    function leave(cmd) {
        open = false
        shell.run(cmd)
    }

    visible: open
    anchors { top: true; right: true }
    margins { top: 4; right: 6 }
    exclusiveZone: 0
    implicitWidth: 390
    implicitHeight: (screen?.height ?? 1040) - 40
    color: "transparent"
    // the window runs down the screen so the popover can grow without it resizing; only the popover is hit
    mask: Region { item: pop }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-panel"

    HyprlandFocusGrab {
        active: panel.visible
        windows: [panel]
        onCleared: panel.open = false
    }

    component Label: Text {
        color: Theme.fg
        font.family: Theme.font
        font.pointSize: 10
        elide: Text.ElideRight
    }

    // a round button: an icon on a pill, lit under the pointer
    component RoundButton: MouseArea {
        id: rb
        property string icon
        property bool lit: false
        implicitWidth: 40; implicitHeight: 40
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        Rectangle {
            anchors.fill: parent; radius: 0
            color: rb.lit ? Theme.accent : rb.containsMouse ? Theme.hover : Theme.pill
            border.color: Theme.rule
            Behavior on color { ColorAnimation { duration: Theme.quick } }
        }
        Icon { anchors.centerIn: parent; name: rb.icon; tint: rb.lit ? Theme.inverse : Theme.fg }
    }

    // an arrow button that opens a menu, turned while it is open
    component Arrow: MouseArea {
        id: ar
        property bool unfolded
        implicitWidth: 32; implicitHeight: 32
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        Rectangle {
            anchors.fill: parent; radius: 0
            color: ar.unfolded ? Theme.accent : ar.containsMouse ? Theme.hover : "transparent"
        }
        Icon {
            anchors.centerIn: parent; name: "go-next-symbolic"; tint: ar.unfolded ? Theme.inverse : Theme.fg
            rotation: ar.unfolded ? 90 : 0
            Behavior on rotation { NumberAnimation { duration: Theme.quick } }
        }
    }

    // a slider: an icon (a button, mute), a thick square bar filled white as far as the level, an arrow
    component Slider: RowLayout {
        id: sl
        property string icon
        property real value
        property string menuName: ""
        signal moved(real v)
        signal iconClicked
        spacing: 6
        MouseArea {
            implicitWidth: 32; implicitHeight: 32
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: sl.iconClicked()
            Rectangle { anchors.fill: parent; radius: 0; color: parent.containsMouse ? Theme.hover : "transparent" }
            Icon { anchors.centerIn: parent; name: sl.icon }
        }
        Item {
            id: track
            Layout.fillWidth: true
            implicitHeight: 24
            readonly property real shown: Math.min(1, Math.max(0, drag.pressed ? drag.v : sl.value))
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width; height: 14; radius: 0
                color: Theme.rule
            }
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: track.shown * parent.width; height: 14; radius: 0
                color: Theme.accent
            }
            MouseArea {
                id: drag
                property real v: 0
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                function set(x) { v = Math.min(1, Math.max(0, x / width)); sl.moved(v) }
                onPressed: m => set(m.x)
                onPositionChanged: m => { if (pressed) set(m.x) }
                onWheel: w => { v = Math.min(1, Math.max(0, sl.value + (w.angleDelta.y > 0 ? 0.02 : -0.02))); sl.moved(v) }
            }
        }
        Arrow {
            visible: sl.menuName !== ""
            unfolded: panel.menu === sl.menuName
            onClicked: panel.flip(sl.menuName)
        }
    }

    // GNOME's split toggle: the pill flips it (lit in the accent while on), the arrow side opens its menu
    component Toggle: Item {
        id: tg
        property string icon
        property string title
        property string sub
        property bool on
        property string menuName: ""
        signal flip
        Layout.fillWidth: true
        Layout.preferredWidth: 1
        implicitHeight: 48
        Rectangle {
            anchors.fill: parent; radius: 0
            color: tg.on ? Theme.accent : Theme.pill
            border.color: tg.on ? Theme.accent : Theme.rule
            Behavior on color { ColorAnimation { duration: Theme.quick } }
        }
        MouseArea {
            id: main
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom; right: side.visible ? side.left : parent.right }
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: tg.flip()
            Rectangle {
                anchors.fill: parent; radius: 0
                color: main.containsMouse ? (tg.on ? "#d0d0d0" : Theme.hover) : "transparent"
            }
            RowLayout {
                anchors { fill: parent; leftMargin: 14; rightMargin: 6 }
                spacing: 10
                Icon { name: tg.icon; tint: tg.on ? Theme.inverse : Theme.fg }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Label { text: tg.title; font.bold: true; Layout.fillWidth: true; color: tg.on ? Theme.inverse : Theme.fg }
                    Label {
                        visible: tg.sub !== ""; text: tg.sub; font.pointSize: 8.5; Layout.fillWidth: true
                        color: tg.on ? "#333333" : Theme.dim
                    }
                }
            }
        }
        MouseArea {
            id: side
            visible: tg.menuName !== ""
            anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
            width: 40
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: panel.flip(tg.menuName)
            Rectangle {
                anchors.fill: parent; radius: 0
                color: side.containsMouse || panel.menu === tg.menuName ? (tg.on ? "#d0d0d0" : Theme.hover) : "transparent"
            }
            Rectangle {
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                width: 1; height: 24; color: tg.on ? "#999999" : Theme.rule
            }
            Icon {
                anchors.centerIn: parent; name: "go-next-symbolic"; tint: tg.on ? Theme.inverse : Theme.fg
                rotation: panel.menu === tg.menuName ? 90 : 0
                Behavior on rotation { NumberAnimation { duration: Theme.quick } }
            }
        }
    }

    // GNOME's menu under a row: a raised box with a header (the icon on an accent circle, the title) and items,
    // sliding open while its name is the one unfolded
    component Menu: Item {
        id: mn
        default property alias content: items.data
        property list<string> names
        property string icon
        property string title
        readonly property bool unfolded: names.indexOf(panel.menu) >= 0
        Layout.fillWidth: true
        implicitHeight: unfolded ? box.implicitHeight + 4 : 0
        // gone once folded, so the column's spacing does not pile up around it
        visible: implicitHeight > 0
        clip: true
        Behavior on implicitHeight { NumberAnimation { duration: Theme.quick; easing.type: Easing.OutCubic } }
        Rectangle {
            id: box
            y: 4; width: parent.width
            implicitHeight: col.implicitHeight + 20
            radius: 0
            color: Theme.card
            border.color: Theme.rule
            ColumnLayout {
                id: col
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                spacing: 2
                RowLayout {
                    visible: mn.title !== ""
                    spacing: 10
                    Layout.bottomMargin: 6
                    Rectangle {
                        implicitWidth: 32; implicitHeight: 32; radius: 0; color: Theme.accent
                        Icon { anchors.centerIn: parent; name: mn.icon; tint: Theme.inverse }
                    }
                    Label { text: mn.title; font.bold: true; font.pointSize: 11 }
                }
                ColumnLayout { id: items; Layout.fillWidth: true; spacing: 0 }
            }
        }
    }

    // a menu item: its text, a check while on (or a note), a click picks it
    component Item_: MouseArea {
        id: it
        property string text
        property bool on
        property string note
        property string icon
        Layout.fillWidth: true
        implicitHeight: 34
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        Rectangle { anchors.fill: parent; radius: 0; color: it.on ? Theme.accent : it.containsMouse ? Theme.hover : "transparent" }
        RowLayout {
            anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
            spacing: 10
            Icon { visible: it.icon !== ""; name: it.icon; tint: it.on ? Theme.inverse : Theme.fg }
            Label { text: it.text; Layout.fillWidth: true; color: it.on ? Theme.inverse : Theme.fg }
            Label { visible: it.note !== ""; text: it.note; color: it.on ? "#333333" : Theme.dim }
        }
    }
    component Separator: Rectangle { Layout.fillWidth: true; Layout.margins: 4; implicitHeight: 1; color: Theme.rule }

    Rectangle {
        id: pop
        width: parent.width
        height: col.implicitHeight + 28
        radius: 0
        color: Theme.popover
        border.color: Theme.fg
        border.width: 1
        opacity: panel.visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.quick } }

        ColumnLayout {
            id: col
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
            spacing: 10

            // the battery, then a screenshot, the lock, the power menu
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Rectangle {
                    visible: panel.shell.battery.isLaptopBattery
                    implicitWidth: bat.implicitWidth + 28; implicitHeight: 40; radius: 0
                    color: Theme.pill
                    RowLayout {
                        id: bat
                        anchors.centerIn: parent
                        spacing: 8
                        Icon { name: panel.shell.batteryIcon() }
                        Label { text: Math.round(panel.shell.battery.percentage * 100) + "%"; font.bold: true }
                    }
                }
                Item { Layout.fillWidth: true }
                RoundButton { icon: "applets-screenshooter-symbolic"; onClicked: panel.leave([panel.bin + "screenshot-select"]) }
                RoundButton { icon: "system-lock-screen-symbolic"; onClicked: panel.leave(["swaylock", "-f", "-c", "000000"]) }
                RoundButton {
                    icon: "system-shutdown-symbolic"; lit: panel.menu === "system"
                    onClicked: panel.flip("system")
                }
            }
            Menu {
                names: ["system"]; icon: "system-shutdown-symbolic"; title: "Power Off"
                Item_ { text: "Suspend"; icon: "weather-clear-night-symbolic"; onClicked: panel.leave(["systemctl", "suspend"]) }
                Item_ { text: "Restart…"; icon: "view-refresh-symbolic"; onClicked: panel.leave(["systemctl", "reboot"]) }
                Item_ { text: "Power Off…"; icon: "system-shutdown-symbolic"; onClicked: panel.leave(["systemctl", "poweroff"]) }
                Separator {}
                Item_ { text: "Log Out"; icon: "system-log-out-symbolic"; onClicked: panel.leave(["hyprctl", "dispatch", "exit"]) }
            }

            // the sliders
            Slider {
                Layout.fillWidth: true
                icon: panel.shell.volumeIcon(panel.shell.sink); value: panel.shell.sink?.volume ?? 0
                menuName: "outs"
                onMoved: v => { if (panel.shell.sink) panel.shell.sink.volume = v }
                onIconClicked: if (panel.shell.sink) panel.shell.sink.muted = !panel.shell.sink.muted
            }
            Menu {
                names: ["outs"]; icon: "audio-speakers-symbolic"; title: "Sound Output"
                Repeater {
                    model: panel.audio.sinks ?? []
                    Item_ {
                        required property var modelData
                        text: modelData.name; on: modelData.def
                        onClicked: panel.act(["wpctl", "set-default", String(modelData.id)])
                    }
                }
            }
            Slider {
                Layout.fillWidth: true
                icon: panel.shell.micIcon(panel.shell.source); value: panel.shell.source?.volume ?? 0
                menuName: "ins"
                onMoved: v => { if (panel.shell.source) panel.shell.source.volume = v }
                onIconClicked: if (panel.shell.source) panel.shell.source.muted = !panel.shell.source.muted
            }
            Menu {
                names: ["ins"]; icon: "audio-input-microphone-symbolic"; title: "Sound Input"
                Repeater {
                    model: panel.audio.sources ?? []
                    Item_ {
                        required property var modelData
                        text: modelData.name; on: modelData.def
                        onClicked: panel.act(["wpctl", "set-default", String(modelData.id)])
                    }
                }
            }
            Slider {
                Layout.fillWidth: true
                icon: "display-brightness-symbolic"; value: (panel.shell.status.bri ?? 0) / 100
                onMoved: v => panel.shell.run(["brightnessctl", "-q", "set", Math.max(1, Math.round(v * 100)) + "%"])
            }

            // the toggles, two a row, each row's menu under it
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Toggle {
                    icon: panel.shell.wifiIcon(); title: "Wi-Fi"; on: panel.q.wifi ?? false
                    sub: on ? (panel.q.ssid ?? "") : ""
                    menuName: "wifi"
                    onFlip: panel.act(["rfkill", on ? "block" : "unblock", "wlan"])
                }
                Toggle {
                    icon: on ? "bluetooth-active-symbolic" : "bluetooth-disabled-symbolic"; title: "Bluetooth"
                    on: panel.q.bt ?? false; sub: panel.q.btdev ?? ""
                    menuName: "bt"
                    onFlip: panel.act(["rfkill", on ? "block" : "unblock", "bluetooth"])
                }
            }
            Menu {
                names: ["wifi"]; icon: "network-wireless-symbolic"; title: "Wi-Fi"
                Repeater {
                    model: panel.q.networks ?? []
                    Item_ {
                        required property var modelData
                        icon: "network-wireless-signal-" + ["none", "weak", "ok", "good", "excellent"][modelData.signal] + "-symbolic"
                        text: modelData.ssid; on: modelData.on
                        // a known network joins; a new one needs its passphrase, typed in impala
                        onClicked: modelData.known ? panel.act(["iwctl", "station", "wlan0", "connect", modelData.ssid])
                                                   : panel.leave([panel.bin + "wm-ctl", "wifi"])
                    }
                }
                Separator {}
                Item_ { text: "Scan"; onClicked: panel.act(["iwctl", "station", "wlan0", "scan"]) }
                Item_ { text: "All Networks…"; onClicked: panel.leave([panel.bin + "wm-ctl", "wifi"]) }
            }
            Menu {
                names: ["bt"]; icon: "bluetooth-active-symbolic"; title: "Bluetooth"
                Repeater {
                    model: panel.q.devices ?? []
                    Item_ {
                        required property var modelData
                        icon: "audio-headphones-symbolic"
                        text: modelData.name; on: modelData.on
                        onClicked: panel.act(["bluetoothctl", modelData.on ? "disconnect" : "connect", modelData.mac])
                    }
                }
                Separator {}
                Item_ { text: "Bluetooth Settings…"; onClicked: panel.leave([panel.bin + "wm-ctl", "bluetooth"]) }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Toggle {
                    readonly property var order: ["power-saver", "balanced", "performance"]
                    readonly property var names: ({ "power-saver": "Power Saver", "balanced": "Balanced", "performance": "Performance" })
                    icon: "power-profile-" + (panel.q.power || "balanced") + "-symbolic"
                    title: "Power Mode"; sub: names[panel.q.power] ?? ""
                    on: (panel.q.power ?? "balanced") !== "balanced"
                    menuName: "power"
                    onFlip: panel.act(["powerprofilesctl", "set", order[(order.indexOf(panel.q.power) + 1) % 3]])
                }
                Toggle {
                    icon: "network-vpn-symbolic"; title: "VLESS"
                    on: (panel.q.vless ?? "off") !== "off"; sub: on ? (panel.q.vprofile ?? "") : ""
                    menuName: "vless"
                    onFlip: panel.act(on ? [panel.bin + "vless", "off"] : [panel.bin + "vless", "on", "tun"])
                }
            }
            Menu {
                names: ["power"]; icon: "power-profile-balanced-symbolic"; title: "Power Mode"
                Repeater {
                    model: [["performance", "Performance"], ["balanced", "Balanced"], ["power-saver", "Power Saver"]]
                    Item_ {
                        required property var modelData
                        icon: "power-profile-" + modelData[0] + "-symbolic"
                        text: modelData[1]; on: panel.q.power === modelData[0]
                        onClicked: panel.act(["powerprofilesctl", "set", modelData[0]])
                    }
                }
            }
            Menu {
                names: ["vless"]; icon: "network-vpn-symbolic"; title: "VLESS"
                Item_ { text: "TUN, every app"; on: panel.q.vless === "tun"; onClicked: panel.act([panel.bin + "vless", "on", "tun"]) }
                Item_ { text: "System proxy"; on: panel.q.vless === "proxy"; onClicked: panel.act([panel.bin + "vless", "on", "proxy"]) }
                ColumnLayout {
                    visible: (panel.q.vless ?? "off") !== "off"
                    Layout.fillWidth: true
                    spacing: 0
                    Separator {}
                    Item_ { text: "Rule: Russia direct"; on: panel.q.vmode === "rule"; onClicked: panel.act([panel.bin + "vless", "mode", "rule"]) }
                    Item_ { text: "Global"; on: panel.q.vmode === "global"; onClicked: panel.act([panel.bin + "vless", "mode", "global"]) }
                    Separator {}
                    Repeater {
                        model: panel.q.profiles ?? []
                        Item_ {
                            required property string modelData
                            text: modelData; on: modelData === panel.q.vprofile
                            onClicked: panel.act([panel.bin + "vless", "profile", modelData])
                        }
                    }
                }
            }

            RowLayout {
                visible: (panel.audio.headset ?? "") !== ""
                Layout.fillWidth: true
                spacing: 10
                Toggle {
                    icon: "audio-headphones-symbolic"; title: "Headset"
                    sub: panel.audio.headset === "handsfree" ? "Handsfree, with the mic" : "Headphones"
                    on: panel.audio.headset === "handsfree"
                    onFlip: panel.act([panel.bin + "wm-ctl", "headset"])
                }
                Item { Layout.fillWidth: true; Layout.preferredWidth: 1 }
            }
        }
    }
}
