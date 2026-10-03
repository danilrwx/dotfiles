//@ pragma IconTheme Adwaita
// The bar under Hyprland (config/eww is i3's), GNOME's top bar: the workspaces as dots at the left, the clock in
// the middle (a click: the calendar), at the right the keyboard layout, the tray (StatusNotifierItem, Discord's
// menu included) and the status as one pill, Wi-Fi, VPN, sound and battery in Adwaita's symbolic icons (a
// click: the quick settings, the wheel: the volume). Sound, battery, tray, workspaces and the clock from
// Quickshell's own services and the layout from Hyprland's event, live; brightness from bin/wm-status once a
// second, Wi-Fi, Bluetooth, VLESS and the power profile from bin/wm-quick every 3 s. bin/wl-autostart starts it; linked to
// ~/.config/quickshell by install.
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

ShellRoot {
    id: root

    readonly property string bin: Quickshell.env("HOME") + "/dotfiles/bin/"
    readonly property string fnkeys: bin + "wm-fnkeys"

    // bin/wm-status's last line: the layout, brightness, VLESS and OpenVPN as text
    property var status: ({})
    Process {
        command: [root.bin + "wm-status"]
        running: true
        stdout: SplitParser { onRead: line => { try { root.status = JSON.parse(line) } catch (e) {} } }
    }
    // bin/wm-quick's: Wi-Fi, Bluetooth, VLESS, the power profile and their lists
    property var q: ({})
    Process {
        id: quickProc
        command: [root.bin + "wm-quick"]
        stdout: StdioCollector { onStreamFinished: { try { root.q = JSON.parse(text) } catch (e) {} } }
    }
    Timer {
        interval: 3000; repeat: true; running: true; triggeredOnStart: true
        onTriggered: quickProc.running = true
    }
    // the state again soon after a change, not in 3 s
    Timer { id: soon; interval: 400; onTriggered: quickProc.running = true }
    function refresh() { soon.restart() }

    PwObjectTracker { objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource] }
    readonly property var sink: Pipewire.defaultAudioSink?.audio ?? null
    readonly property var source: Pipewire.defaultAudioSource?.audio ?? null
    readonly property var battery: UPower.displayDevice

    SystemClock { id: clock; precision: SystemClock.Minutes }

    // run CMD...: a command, detached
    function run(cmd) { Quickshell.execDetached(cmd) }

    // the icons the status shows, GNOME's names for the state
    function volumeIcon(a) {
        if (!a || a.muted || a.volume === 0) return "audio-volume-muted-symbolic"
        return a.volume < 0.34 ? "audio-volume-low-symbolic" : a.volume < 0.67 ? "audio-volume-medium-symbolic"
                                                                              : "audio-volume-high-symbolic"
    }
    function micIcon(a) {
        if (!a || a.muted || a.volume === 0) return "microphone-sensitivity-muted-symbolic"
        return a.volume < 0.34 ? "microphone-sensitivity-low-symbolic"
             : a.volume < 0.67 ? "microphone-sensitivity-medium-symbolic" : "microphone-sensitivity-high-symbolic"
    }
    function wifiIcon() {
        if (!q.wifi) return "network-wireless-disabled-symbolic"
        const on = (q.networks ?? []).find(n => n.on)
        if (!on) return "network-wireless-offline-symbolic"
        return "network-wireless-signal-" + ["none", "weak", "ok", "good", "excellent"][on.signal] + "-symbolic"
    }
    function batteryIcon() {
        const level = Math.round(battery.percentage * 10) * 10
        const charging = battery.state === UPowerDeviceState.Charging
        const full = battery.state === UPowerDeviceState.FullyCharged
        return "battery-level-" + level + (full && level === 100 ? "-charged" : charging ? "-charging" : "")
            + "-symbolic"
    }
    // the keyboard layout, Hyprland's word on every switch, at once; until the first, bin/wm-status's
    property bool ru: status.ru ?? false
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "activelayout") root.ru = /Russian/.test(event.data)
        }
    }
    readonly property bool vpn: (q.vless ?? "off") !== "off" || (status.openvpn ?? "") !== ""

    // the panels, one at a time (QuickSettings.qml, CalendarPopup.qml)
    QuickSettings { id: qs; shell: root }
    CalendarPopup { id: cal }
    function panel(which) {
        (which === qs ? cal : qs).open = false
        which.toggle()
    }
    // and from outside: quickshell ipc call panel ctl|calendar (a key, a script)
    IpcHandler {
        target: "panel"
        function ctl(): void { root.panel(qs) }
        function calendar(): void { root.panel(cal) }
    }
    // the bar's mode, i3's bar mode toggle: docked, or hidden and shown over the windows while Super is held.
    // quickshell ipc call bar toggle ($mod+b), peek and unpeek (Super down and up, config/hypr)
    property bool docked: true
    property bool peeking: false
    IpcHandler {
        target: "bar"
        function toggle(): void { root.docked = !root.docked }
        function peek(): void { root.peeking = true }
        function unpeek(): void { root.peeking = false }
    }

    // a pill of the bar: rounded, lit under the pointer, what it holds in a row; clicks and the wheel given
    component Pill: MouseArea {
        id: pill
        default property alias content: row.data
        property bool lit: false
        signal wheelUp
        signal wheelDown
        implicitWidth: row.implicitWidth + 20
        implicitHeight: 21
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onWheel: w => w.angleDelta.y > 0 ? wheelUp() : wheelDown()
        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: pill.lit ? Qt.rgba(1, 1, 1, 0.18) : pill.containsMouse ? Theme.hover : "transparent"
            Behavior on color { ColorAnimation { duration: Theme.quick } }
        }
        RowLayout { id: row; anchors.centerIn: parent; spacing: 7 }
    }
    component BarText: Text {
        color: Theme.fg
        font.family: Theme.font
        font.pointSize: 10
        font.bold: true
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: bar
            required property var modelData
            screen: modelData
            visible: root.docked || root.peeking
            anchors { top: true; left: true; right: true }
            implicitHeight: 25
            // docked it takes its strip from the windows; hidden it comes over them
            exclusiveZone: root.docked ? implicitHeight : 0
            WlrLayershell.layer: root.docked ? WlrLayer.Top : WlrLayer.Overlay
            color: "#000000"

            // the workspaces as dots, the focused one a longer pill, a click to go there
            Pill {
                anchors { left: parent.left; leftMargin: 6; verticalCenter: parent.verticalCenter }
                onWheelUp: Hyprland.dispatch("workspace e-1")
                onWheelDown: Hyprland.dispatch("workspace e+1")
                Repeater {
                    model: Hyprland.workspaces.values.filter(w => w.id > 0).sort((a, b) => a.id - b.id)
                    MouseArea {
                        required property var modelData
                        readonly property bool focused: modelData.id === Hyprland.focusedWorkspace?.id
                        implicitWidth: focused ? 26 : 7
                        implicitHeight: 7
                        onClicked: Hyprland.dispatch("workspace " + modelData.id)
                        Behavior on implicitWidth { NumberAnimation { duration: Theme.quick } }
                        Rectangle {
                            anchors.fill: parent
                            radius: 3.5
                            color: modelData.urgent ? Theme.accent : parent.focused ? Theme.fg : Qt.rgba(1, 1, 1, 0.5)
                        }
                    }
                }
            }

            // the clock, GNOME's "Sat Oct 3  13:31"
            Pill {
                anchors.centerIn: parent
                lit: cal.open
                onClicked: root.panel(cal)
                BarText { text: Qt.formatDateTime(clock.date, "ddd MMM d  hh:mm") }
            }

            RowLayout {
                anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
                spacing: 2

                Pill {
                    BarText { text: root.ru ? "ru" : "en" }
                }

                // the tray: a click activates, a right click opens the item's menu
                Repeater {
                    model: SystemTray.items
                    Pill {
                        id: item
                        required property SystemTrayItem modelData
                        onClicked: m => {
                            if (m.button === Qt.RightButton || modelData.onlyMenu) {
                                if (modelData.hasMenu) menu.open()
                            } else {
                                modelData.activate()
                            }
                        }
                        QsMenuAnchor {
                            id: menu
                            menu: item.modelData.menu
                            anchor.item: item
                            anchor.edges: Edges.Bottom
                        }
                        IconImage { implicitSize: 15; source: item.modelData.icon }
                    }
                }

                // the status: Wi-Fi, VPN, Bluetooth while a device is on, sound, the mic while muted, battery
                Pill {
                    lit: qs.open
                    onClicked: root.panel(qs)
                    onWheelUp: root.run([root.fnkeys, "vol-up"])
                    onWheelDown: root.run([root.fnkeys, "vol-down"])
                    Icon { name: root.wifiIcon() }
                    Icon { visible: root.vpn; name: "network-vpn-symbolic" }
                    Icon { visible: (root.q.btdev ?? "") !== ""; name: "bluetooth-active-symbolic" }
                    Icon { name: root.volumeIcon(root.sink) }
                    Icon { visible: root.source?.muted ?? false; name: "microphone-disabled-symbolic" }
                    Icon { visible: root.battery.isLaptopBattery; name: root.batteryIcon() }
                    BarText {
                        visible: root.battery.isLaptopBattery
                        text: Math.round(root.battery.percentage * 100) + "%"
                    }
                }
            }
        }
    }
}
